# omageeko: port of omarchy-pkgs/pkgbuilds/omasnap (1.24.0-1)
%global debug_package %{nil}
%define __builder ninja

Name:           omasnap
Version:        1.24.0
Release:        1.omageeko%{?dist}
Summary:        Native Wayland screenshot and annotation overlay for Hyprland
License:        MIT AND OFL-1.1
URL:            https://github.com/omacom/omasnap
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildRequires:  cmake
BuildRequires:  ninja
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig
BuildRequires:  pkgconfig(libdeflate)
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel
BuildRequires:  layer-shell-qt6-devel
BuildRequires:  cmake(Qt6Concurrent)
BuildRequires:  cmake(Qt6Core)
BuildRequires:  cmake(Qt6Gui)
BuildRequires:  cmake(Qt6Test)
BuildRequires:  cmake(Qt6Widgets)
Requires:       hyprland
Requires:       wl-clipboard
Requires:       tesseract-ocr
Requires:       tesseract-ocr-traineddata-eng

%description
omasnap captures regions, windows or outputs on Hyprland and opens an
annotation overlay. Omarchy's screenshot command (Print key) runs it.

%prep
%autosetup -p1

%build
%cmake -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%{_bindir}/omasnap
%{_datadir}/licenses/omasnap/
%{_datadir}/applications/omasnap.desktop
