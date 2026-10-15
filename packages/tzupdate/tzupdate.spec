# omageeko: port of omarchy-pkgs/pkgbuilds/tzupdate (3.1.0-2)
%global debug_package %{nil}

Name:           tzupdate
Version:        3.1.0
Release:        2.omageeko%{?dist}
Summary:        Set the system timezone based on IP geolocation
License:        MIT
URL:            https://github.com/cdown/tzupdate
Source0:        %{url}/archive/refs/tags/%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildRequires:  cargo
BuildRequires:  rust

%description
tzupdate looks up the timezone for the current public IP and sets it.
Omarchy's timezone menu uses it (sudoers allows timedatectl set-timezone).

%prep
%autosetup -p1

%build
cargo build --release --locked

%install
install -Dm755 target/release/tzupdate %{buildroot}%{_bindir}/tzupdate

%files
%license LICENSE
%{_bindir}/tzupdate
