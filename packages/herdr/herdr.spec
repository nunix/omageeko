# omageeko: port of omarchy-pkgs/pkgbuilds/herdr (0.9.1-2)
# Builds with zig 0.16 (Tumbleweed ships 0.15), fetched like the PKGBUILD does.
%global debug_package %{nil}
%global zigver 0.16.0

Name:           herdr
Version:        0.9.1
Release:        2.omageeko%{?dist}
Summary:        Terminal workspace manager for AI coding agents
License:        Apache-2.0
URL:            https://github.com/herdrdev/herdr
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
Source1:        https://ziglang.org/download/%{zigver}/zig-x86_64-linux-%{zigver}.tar.xz
ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  xz

%description
herdr manages terminal workspaces for AI coding agents. Omarchy launches it
from its terminal menu and ships keybindings and themes for it.

%prep
%setup -q
tar -xf %{SOURCE1} -C ..

%build
export CARGO_TARGET_DIR=target
export ZIG="$PWD/../zig-x86_64-linux-%{zigver}/zig"
export ZIG_GLOBAL_CACHE_DIR="$PWD/../zig-cache"
cargo build --locked --release

%install
install -Dm755 target/release/herdr %{buildroot}%{_bindir}/herdr

%files
%license LICENSE
%{_bindir}/herdr
