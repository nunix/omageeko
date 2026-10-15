# omageeko: port of omarchy-pkgs/pkgbuilds/omarchy-hyprland-titlebars (0.2.2-1)
# A Hyprland plugin only loads into the exact Hyprland it was built against:
# rebuild this package whenever Tumbleweed updates hyprland.
%global debug_package %{nil}
%global hypr_ver %(rpm -q --qf '%%{VERSION}' hyprland-devel 2>/dev/null | grep -E '^[0-9.]+$' || echo 0)

Name:           omarchy-hyprland-titlebars
Version:        0.2.2
Release:        1.omageeko.h%{hypr_ver}%{?dist}
Summary:        Titlebars for Omarchy's floating workspaces (Hyprland plugin)
License:        BSD-3-Clause AND MIT
URL:            https://github.com/omacom/omarchy-hyprland-titlebars
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig
BuildRequires:  hyprland-devel
# TW hyprland-devel headers include glslang but do not require it (packaging gap)
BuildRequires:  glslang-devel
# Hyprland 0.56 Lua bindings include <lua.h>; TW keeps it in /usr/include/lua5.5
BuildRequires:  lua55-devel
Requires:       hyprland = %{hypr_ver}

%description
Hyprland plugin that draws titlebars on Omarchy's floating workspaces.
Upstream Omarchy loads it from /usr/lib/omarchy-hyprland-titlebars/titlebars.so.

%prep
%autosetup -p1

%build
export CXXFLAGS="%{optflags} $(pkg-config --cflags lua5.5)"
# Plugins resolve Hyprland/Lua symbols from the compositor at dlopen time:
# drop SUSE's default -Wl,--no-undefined for this shared object.
%cmake -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--as-needed -Wl,-z,now"
%cmake_build

%install
%cmake_install

%files
%license LICENSE LICENSE.MIT
%{_prefix}/lib/omarchy-hyprland-titlebars/
