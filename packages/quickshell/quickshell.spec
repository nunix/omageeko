# omageeko: port of omarchy-pkgs/pkgbuilds/quickshell (0.3.2-4)
%global debug_package %{nil}
%define __builder ninja

Name:           quickshell
Version:        0.3.2
Release:        4.omageeko%{?dist}
Summary:        Flexible toolkit for making desktop shells with QtQuick
License:        LGPL-3.0-only
URL:            https://github.com/quickshell-mirror/quickshell
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
# Omarchy: opt-in "//@ pragma OmarchyLoadPatch" pins unversioned QtQuick imports to 6.11
Patch0:         load_qtquick_611.patch
BuildRequires:  cmake
BuildRequires:  ninja
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig
BuildRequires:  cli11-devel
BuildRequires:  cpptrace-devel
BuildRequires:  jemalloc-devel
BuildRequires:  spirv-tools
BuildRequires:  vulkan-headers
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel
BuildRequires:  pam-devel
BuildRequires:  cmake(Qt6Gui)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  cmake(Qt6Quick)
BuildRequires:  cmake(Qt6QuickControls2)
BuildRequires:  cmake(Qt6Widgets)
BuildRequires:  cmake(Qt6ShaderTools)
BuildRequires:  cmake(Qt6DBus)
BuildRequires:  cmake(Qt6Network)
BuildRequires:  cmake(Qt6WaylandClient)
BuildRequires:  cmake(Qt6Svg)
BuildRequires:  qt6-base-private-devel
BuildRequires:  qt6-declarative-private-devel
BuildRequires:  qt6-wayland-private-devel
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(egl)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gobject-2.0)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(polkit-agent-1)
BuildRequires:  pkgconfig(polkit-gobject-1)
BuildRequires:  pkgconfig(xcb)
# QML runtime modules loaded by the Omarchy shell
Requires:       qt6-declarative-imports
Requires:       qt6-wayland
# libQt6Svg6 also ships the qsvg image/icon plugins QtQuick uses for SVG
Requires:       libQt6Svg6
Requires:       qt6-imageformats
Requires:       qt6-multimedia-imports

%description
Quickshell is a toolkit for building desktop shells (bars, widgets, lock
screens, notification centers) with QtQuick. This build carries Omarchy's
QtQuick 6.11 import-pinning patch and powers the omageeko/Omarchy desktop.

%prep
%autosetup -p1

%build
%cmake -W no-dev \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DDISTRIBUTOR="omageeko (openSUSE Tumbleweed)" \
  -DCRASH_HANDLER=OFF \
  -DINSTALL_QML_PREFIX=%{_lib}/qt6/qml
%cmake_build

%install
%cmake_install

%check
# Upstream ships no runnable tests without BUILD_TESTING; smoke-test the binary
%{buildroot}%{_bindir}/quickshell --version

%files
%license LICENSE
%{_bindir}/quickshell
%{_bindir}/qs
%{_libdir}/qt6/qml/Quickshell/
%{_datadir}/applications/*.desktop
%{_datadir}/icons/hicolor/*/apps/*
