# omageeko: port of omarchy-pkgs/pkgbuilds/disktree-bin (0.11.0-3), upstream release binary
%global debug_package %{nil}
%global __requires_exclude ^lib.*$

Name:           disktree
Version:        0.11.0
Release:        3.omageeko%{?dist}
Summary:        Disk space treemap for Omarchy
License:        MIT
URL:            https://github.com/tobi/disktree
Source0:        %{url}/releases/download/v%{version}/disktree-%{version}-x86_64-linux.tar.gz
ExclusiveArch:  x86_64
Requires:       libxkbcommon0
Requires:       libxkbcommon-x11-0
Requires:       libwayland-client0
Requires:       libglvnd
Requires:       libvulkan1
Provides:       disktree-bin = %{version}

%description
See what fills a disk by kind, mark what should go, and remove it.

%prep
%setup -q -n disktree-%{version}-x86_64-linux

%build

%install
install -Dm755 disktree %{buildroot}%{_bindir}/disktree
install -dm755 %{buildroot}%{_datadir}/applications
sed -e 's|@BINDIR@/||' -e 's|@VERSION@|%{version}|' disktree.desktop.in > %{buildroot}%{_datadir}/applications/disktree.desktop
install -Dm644 disktree.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/disktree.svg

%files
%license LICENSE
%doc README.md
%{_bindir}/disktree
%{_datadir}/applications/disktree.desktop
%{_datadir}/icons/hicolor/scalable/apps/disktree.svg
