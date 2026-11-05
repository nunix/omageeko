# omageeko: port of omarchy-pkgs/pkgbuilds/owe (0.2.13-1) and owe-lockfeed (0.2.13-1)
%global debug_package %{nil}

Name:           owe
Version:        0.2.13
Release:        1.omageeko%{?dist}
Summary:        High-performance wallpaper engine for Omarchy (mp4, gif, stills)
License:        MIT
URL:            https://github.com/omacom/owe
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
# Restarts running owed user services after upgrades (pacman hook on Arch)
Source1:        package-restart
BuildRequires:  meson
BuildRequires:  ninja
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig
BuildRequires:  python3
# media/decode tests shell out to the ffmpeg CLI (Packman build)
BuildRequires:  ffmpeg
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-egl)
BuildRequires:  pkgconfig(egl)
BuildRequires:  pkgconfig(glesv2)
BuildRequires:  pkgconfig(gl)
BuildRequires:  pkgconfig(epoxy)
BuildRequires:  pkgconfig(mpv) >= 0.35
BuildRequires:  pkgconfig(libavformat)
BuildRequires:  pkgconfig(libavcodec)
BuildRequires:  pkgconfig(libavutil)
BuildRequires:  pkgconfig(libswscale)
BuildRequires:  pkgconfig(libsystemd)
BuildRequires:  cmake
BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6Gui)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6Quick)
BuildRequires:  cmake(Qt6Test)
Requires:       socat
Requires:       ffmpeg
Recommends:     libva-mesa-driver

%description
OWE renders video (mp4), animated (gif) and still wallpapers on Wayland
layer surfaces for the Omarchy desktop, and feeds frames to the lock screen.

%package        lockfeed
Summary:        Lock screen video feed QML module for OWE
Requires:       qt6-declarative-imports

%description    lockfeed
QML plugin that lets the Omarchy lock screen show OWE's current wallpaper frames.

%prep
%autosetup -p1

%build
%meson
%meson_build
cmake -S qml-plugin -B build-lockfeed \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=%{_prefix} \
  -DCMAKE_INSTALL_LIBDIR=%{_lib}
cmake --build build-lockfeed %{?_smp_mflags}

%install
%meson_install
DESTDIR=%{buildroot} cmake --install build-lockfeed
install -Dm755 %{SOURCE1} %{buildroot}%{_prefix}/lib/owe/package-restart
install -d %{buildroot}%{_userunitdir}
sed 's|%%h/.local/bin/owed|%{_bindir}/owed|' systemd/owed.service > %{buildroot}%{_userunitdir}/owed.service
install -Dm755 hooks/owe-idle %{buildroot}%{_bindir}/owe-idle
install -Dm644 hooks/theme-set.d/10-owe-sync %{buildroot}%{_datadir}/owe/10-owe-sync
install -Dm644 config/config.toml %{buildroot}%{_docdir}/%{name}/config.toml.example

%check
# The transition test needs real GL frame timing; containers render with
# software GL, so run everything else.
skip=transition
# The media test encodes with libx264, which only Packman's ffmpeg has. When the
# build fell back to Tumbleweed's ffmpeg (lib/build-rpm.sh), skip it: at runtime
# owe uses the host's Packman ffmpeg (same libavcodec soname).
ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx264 || skip="$skip|media"
tests=$(meson test -C %{_vpath_builddir} --list 2>/dev/null | sed 's/^owe://' | grep -vxE "$skip" || true)
meson test -C %{_vpath_builddir} --print-errorlogs $tests
QT_QPA_PLATFORM=offscreen ctest --test-dir build-lockfeed --output-on-failure

%posttrans
# Arch does this in a pacman hook. try-restart only touches running services, so fresh installs are unaffected.
if [ "$1" -ge 1 ] && [ -x %{_prefix}/lib/owe/package-restart ]; then
  %{_prefix}/lib/owe/package-restart || :
fi

%files
%{_bindir}/*
%{_prefix}/lib/owe/
%{_userunitdir}/owed.service
%{_datadir}/owe/
%{_docdir}/%{name}/

%files lockfeed
%{_libdir}/qt6/qml/*
