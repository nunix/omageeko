# omageeko: port of omarchy-pkgs/pkgbuilds/once-bin (0.3.4-1)
%global debug_package %{nil}

Name:           once
Version:        0.3.4
Release:        1.omageeko%{?dist}
Summary:        CLI/TUI for installing and managing self-hosted web applications (37signals ONCE)
License:        MIT
URL:            https://github.com/basecamp/once
Source0:        %{url}/releases/download/v%{version}/once-linux-amd64#/once-%{version}-linux-amd64
Source1:        https://raw.githubusercontent.com/basecamp/once/v%{version}/MIT-LICENSE#/MIT-LICENSE-%{version}
Source2:        once-background.service
ExclusiveArch:  x86_64
BuildRequires:  systemd-rpm-macros
# ONCE drives Docker. omageeko uses podman (install-time decision): its Docker CLI and
# socket. An OR dependency (podman-docker or docker) made libsolv pick real Docker.
Requires:       podman-docker
Provides:       once-bin = %{version}

%description
ONCE installs and manages self-hosted web applications as containers.

%prep
%setup -q -c -T

%build

%install
install -Dm755 %{SOURCE0} %{buildroot}%{_bindir}/once
install -Dm644 %{SOURCE1} %{buildroot}%{_datadir}/licenses/%{name}/LICENSE
install -Dm644 %{SOURCE2} %{buildroot}%{_unitdir}/once-background.service

%post
echo ':: Enable the background service with: systemctl enable --now once-background.service'

%preun
if [ "$1" -eq 0 ] && systemctl is-active --quiet once-background.service; then
  systemctl disable --now once-background.service || :
fi

%postun
if [ "$1" -ge 1 ] && systemctl is-active --quiet once-background.service; then
  systemctl restart once-background.service || :
fi

%files
%{_datadir}/licenses/%{name}/
%{_bindir}/once
%{_unitdir}/once-background.service
