# omageeko: port of omarchy-pkgs/pkgbuilds/ttf-jetbrains-mono-nerd-basic (3.5.1-2)
# Omarchy configs use the family name "JetBrainsMono Nerd Font".
Name:           jetbrains-mono-nerd-fonts
Version:        3.5.1
Release:        2.omageeko%{?dist}
Summary:        JetBrains Mono Nerd Font (Regular, Bold, Italic, BoldItalic)
License:        OFL-1.1
URL:            https://github.com/ryanoasis/nerd-fonts
Source0:        %{url}/releases/download/v%{version}/JetBrainsMono.zip#/JetBrainsMono-%{version}.zip
BuildArch:      noarch
BuildRequires:  unzip
BuildRequires:  fontpackages-devel
Provides:       ttf-jetbrains-mono-nerd = %{version}

%description
The basic JetBrains Mono Nerd Font family patched with Nerd Fonts glyphs.

%prep
%setup -q -c -T
unzip -q %{SOURCE0}

%build

%install
for font in Regular Bold Italic BoldItalic; do
  install -Dm644 JetBrainsMonoNerdFont-${font}.ttf %{buildroot}%{_ttfontsdir}/JetBrainsMonoNerdFont-${font}.ttf
done

%reconfigure_fonts_scriptlets

%files
%license OFL.txt
%{_ttfontsdir}/JetBrainsMonoNerdFont-*.ttf
