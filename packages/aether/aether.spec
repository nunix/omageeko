# omageeko: port of omarchy-pkgs/pkgbuilds/aether (4.32.0-2), upstream release binary
%global debug_package %{nil}
%global __requires_exclude ^lib.*$

Name:           aether
Version:        4.32.0
Release:        2.omageeko%{?dist}
Summary:        Desktop theming: extract colors from wallpapers and apply cohesive Omarchy themes
License:        MIT
URL:            https://github.com/omacom/aether
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/aether-%{version}.tar.gz
Source1:        %{url}/releases/download/v%{version}/aether-linux-amd64#/aether-linux-amd64-%{version}
ExclusiveArch:  x86_64
Requires:       libwebkit2gtk-4_1-0
Requires:       libgtk-3-0

%description
Aether builds Omarchy themes from wallpapers and applies them system-wide.

%prep
%setup -q

%build

%install
install -Dm755 %{SOURCE1} %{buildroot}%{_bindir}/aether
install -Dm644 build/linux/aether.desktop %{buildroot}%{_datadir}/applications/aether.desktop
install -Dm644 li.oever.aether.url-handler.desktop %{buildroot}%{_datadir}/applications/li.oever.aether.url-handler.desktop
install -Dm644 icon.png %{buildroot}%{_datadir}/pixmaps/aether.png
install -Dm644 assets/aether-icon-512.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/aether.png

%files
%doc README.md
%{_bindir}/aether
%{_datadir}/applications/aether.desktop
%{_datadir}/applications/li.oever.aether.url-handler.desktop
%{_datadir}/pixmaps/aether.png
%{_datadir}/icons/hicolor/512x512/apps/aether.png
