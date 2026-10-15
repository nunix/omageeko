# omageeko: port of omarchy-pkgs/pkgbuilds/hyprland-preview-share-picker (0.2.1-3)
%global debug_package %{nil}
%global protocols_commit 3a5c2bda1c1a4e55cc1330c782547695a93f05b2

Name:           hyprland-preview-share-picker
Version:        0.2.1
Release:        3.omageeko
Summary:        Alternative Hyprland screen share picker with window and monitor previews
License:        MIT
URL:            https://github.com/WhySoBad/hyprland-preview-share-picker
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
Source1:        https://github.com/hyprwm/hyprland-protocols/archive/%{protocols_commit}.tar.gz#/hyprland-protocols-%{protocols_commit}.tar.gz
BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  pkgconfig(gtk4)
BuildRequires:  pkgconfig(gtk4-layer-shell-0)
BuildRequires:  pkgconfig(wayland-client)
Requires:       xdg-desktop-portal-hyprland
Recommends:     slurp

%description
Screen share picker for xdg-desktop-portal-hyprland showing live previews of
windows and monitors. Omarchy sets it as custom_picker_binary in xdph.conf.

%prep
%autosetup -p1 -a1
rmdir lib/hyprland-protocols 2>/dev/null || rm -rf lib/hyprland-protocols
ln -s ../hyprland-protocols-%{protocols_commit} lib/hyprland-protocols
# build.rs shells out to git for the version string; there is no git checkout here
cat > build.rs <<'RS'
fn main() {
    println!("cargo::rustc-env=GIT_VERSION=v%{version}-r0-release");
}
RS

%build
export CARGO_TARGET_DIR=target
cargo build --locked --release
./target/release/%{name} schema > schema.json

%install
install -Dm755 target/release/%{name} %{buildroot}%{_bindir}/%{name}
install -Dm644 schema.json %{buildroot}%{_datadir}/%{name}/schema.json

%files
%license LICENSE
%{_bindir}/%{name}
%{_datadir}/%{name}/
