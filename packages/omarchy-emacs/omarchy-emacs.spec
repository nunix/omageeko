# omageeko: port of omarchy-pkgs/pkgbuilds/omarchy-emacs (1.10.1-1)
Name:           omarchy-emacs
Version:        1.10.1
Release:        1.omageeko%{?dist}
Summary:        Emacs integration for Omarchy with automatic theme and font syncing
License:        MIT
URL:            https://github.com/scottjones/omarchy-emacs
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildArch:      noarch
# Arch's emacs-wayland; Tumbleweed's GUI Emacs is emacs-x11
Requires:       emacs-x11
Requires:       bash

%description
Keeps Emacs in sync with Omarchy themes and fonts through theme-set/font-set hooks.

%prep
%autosetup -p1

%build

%install
install -dm755 %{buildroot}%{_datadir}/%{name}/config/themes
install -Dm644 config/init.el %{buildroot}%{_datadir}/%{name}/config/init.el
install -Dm644 config/omarchy.el %{buildroot}%{_datadir}/%{name}/config/omarchy.el
install -Dm644 config/shell-bashrc %{buildroot}%{_datadir}/%{name}/config/shell-bashrc
install -Dm644 config/themes/omarchy-theme.el %{buildroot}%{_datadir}/%{name}/config/themes/omarchy-theme.el
install -Dm644 omarchy-colors.el.tpl %{buildroot}%{_datadir}/%{name}/omarchy-colors.el.tpl
install -Dm755 hooks/font-set %{buildroot}%{_datadir}/%{name}/hooks/font-set
install -Dm755 hooks/theme-set %{buildroot}%{_datadir}/%{name}/hooks/theme-set
for b in omarchy-emacs-setup omarchy-emacs-sync-hooks omarchy-restart-emacs omarchy-install-emacs; do
  install -Dm755 bin/$b %{buildroot}%{_bindir}/$b
done

%files
%license LICENSE
%{_datadir}/%{name}/
%{_bindir}/omarchy-emacs-setup
%{_bindir}/omarchy-emacs-sync-hooks
%{_bindir}/omarchy-restart-emacs
%{_bindir}/omarchy-install-emacs
