# omageeko: Nerd Fonts offered by Omarchy's Install > Style > Font menu.
# Arch ships them as ttf-*-nerd (extra); one subpackage per font, installed on
# demand by omarchy-pkg-add through packages.map (@build:<name>-nerd-fonts).
%global debug_package %{nil}

Name:           nerd-fonts-extra
Version:        3.5.1
Release:        1.omageeko%{?dist}
Summary:        Nerd Fonts offered by the Omarchy font menu
License:        OFL-1.1 AND MIT
URL:            https://github.com/ryanoasis/nerd-fonts
BuildArch:      noarch
BuildRequires:  unzip
BuildRequires:  fontpackages-devel
Source0:        %{url}/releases/download/v%{version}/CascadiaMono.zip#/CascadiaMono-%{version}.zip
Source1:        %{url}/releases/download/v%{version}/Meslo.zip#/Meslo-%{version}.zip
Source2:        %{url}/releases/download/v%{version}/FiraCode.zip#/FiraCode-%{version}.zip
Source3:        %{url}/releases/download/v%{version}/VictorMono.zip#/VictorMono-%{version}.zip
Source4:        %{url}/releases/download/v%{version}/BitstreamVeraSansMono.zip#/BitstreamVeraSansMono-%{version}.zip
Source5:        %{url}/releases/download/v%{version}/Iosevka.zip#/Iosevka-%{version}.zip

%description
Patched Nerd Font families for the Omarchy font menu. Install a single
subpackage; the source package itself ships nothing.

%package -n     cascadia-mono-nerd-fonts
Summary:        Cascadia Mono (Caskaydia) Nerd Font
Provides:       ttf-cascadia-mono-nerd = %{version}

%description -n cascadia-mono-nerd-fonts
Cascadia Mono (Caskaydia) Nerd Font (regular, Mono and Propo variants), patched with Nerd Fonts glyphs.

%package -n     meslo-nerd-fonts
Summary:        Meslo LG Nerd Font
Provides:       ttf-meslo-nerd = %{version}

%description -n meslo-nerd-fonts
Meslo LG Nerd Font (regular, Mono and Propo variants), patched with Nerd Fonts glyphs.

%package -n     firacode-nerd-fonts
Summary:        Fira Code Nerd Font
Provides:       ttf-firacode-nerd = %{version}

%description -n firacode-nerd-fonts
Fira Code Nerd Font (regular, Mono and Propo variants), patched with Nerd Fonts glyphs.

%package -n     victor-mono-nerd-fonts
Summary:        Victor Mono Nerd Font
Provides:       ttf-victor-mono-nerd = %{version}

%description -n victor-mono-nerd-fonts
Victor Mono Nerd Font (regular, Mono and Propo variants), patched with Nerd Fonts glyphs.

%package -n     bitstream-vera-mono-nerd-fonts
Summary:        Bitstream Vera Sans Mono (Bitstrom Wera) Nerd Font
Provides:       ttf-bitstream-vera-mono-nerd = %{version}

%description -n bitstream-vera-mono-nerd-fonts
Bitstream Vera Sans Mono (Bitstrom Wera) Nerd Font (regular, Mono and Propo variants), patched with Nerd Fonts glyphs.

%package -n     iosevka-nerd-fonts
Summary:        Iosevka Nerd Font
Provides:       ttf-iosevka-nerd = %{version}

%description -n iosevka-nerd-fonts
Iosevka Nerd Font (regular, Mono and Propo variants), patched with Nerd Fonts glyphs.

%prep
%setup -q -c -T
mkdir cascadia-mono && unzip -q -d cascadia-mono %{SOURCE0}
cp "$(find cascadia-mono -maxdepth 1 -iname "*licen[cs]e*" | head -1)" cascadia-mono/FONT-LICENSE.txt
mkdir meslo && unzip -q -d meslo %{SOURCE1}
cp "$(find meslo -maxdepth 1 -iname "*licen[cs]e*" | head -1)" meslo/FONT-LICENSE.txt
mkdir firacode && unzip -q -d firacode %{SOURCE2}
cp "$(find firacode -maxdepth 1 -iname "*licen[cs]e*" | head -1)" firacode/FONT-LICENSE.txt
mkdir victor-mono && unzip -q -d victor-mono %{SOURCE3}
cp "$(find victor-mono -maxdepth 1 -iname "*licen[cs]e*" | head -1)" victor-mono/FONT-LICENSE.txt
mkdir bitstream-vera-mono && unzip -q -d bitstream-vera-mono %{SOURCE4}
cp "$(find bitstream-vera-mono -maxdepth 1 -iname "*licen[cs]e*" | head -1)" bitstream-vera-mono/FONT-LICENSE.txt
mkdir iosevka && unzip -q -d iosevka %{SOURCE5}
cp "$(find iosevka -maxdepth 1 -iname "*licen[cs]e*" | head -1)" iosevka/FONT-LICENSE.txt

%build

%install
install -d %{buildroot}%{_ttfontsdir}/cascadia-mono-nerd
find cascadia-mono -maxdepth 1 \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t %{buildroot}%{_ttfontsdir}/cascadia-mono-nerd {} +
install -d %{buildroot}%{_ttfontsdir}/meslo-nerd
find meslo -maxdepth 1 \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t %{buildroot}%{_ttfontsdir}/meslo-nerd {} +
install -d %{buildroot}%{_ttfontsdir}/firacode-nerd
find firacode -maxdepth 1 \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t %{buildroot}%{_ttfontsdir}/firacode-nerd {} +
install -d %{buildroot}%{_ttfontsdir}/victor-mono-nerd
find victor-mono -maxdepth 1 \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t %{buildroot}%{_ttfontsdir}/victor-mono-nerd {} +
install -d %{buildroot}%{_ttfontsdir}/bitstream-vera-mono-nerd
find bitstream-vera-mono -maxdepth 1 \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t %{buildroot}%{_ttfontsdir}/bitstream-vera-mono-nerd {} +
install -d %{buildroot}%{_ttfontsdir}/iosevka-nerd
find iosevka -maxdepth 1 \( -name '*.ttf' -o -name '*.otf' \) -exec install -m644 -t %{buildroot}%{_ttfontsdir}/iosevka-nerd {} +

%reconfigure_fonts_scriptlets -n cascadia-mono-nerd-fonts

%reconfigure_fonts_scriptlets -n meslo-nerd-fonts

%reconfigure_fonts_scriptlets -n firacode-nerd-fonts

%reconfigure_fonts_scriptlets -n victor-mono-nerd-fonts

%reconfigure_fonts_scriptlets -n bitstream-vera-mono-nerd-fonts

%reconfigure_fonts_scriptlets -n iosevka-nerd-fonts

%files -n cascadia-mono-nerd-fonts
%license cascadia-mono/FONT-LICENSE.txt
%{_ttfontsdir}/cascadia-mono-nerd/

%files -n meslo-nerd-fonts
%license meslo/FONT-LICENSE.txt
%{_ttfontsdir}/meslo-nerd/

%files -n firacode-nerd-fonts
%license firacode/FONT-LICENSE.txt
%{_ttfontsdir}/firacode-nerd/

%files -n victor-mono-nerd-fonts
%license victor-mono/FONT-LICENSE.txt
%{_ttfontsdir}/victor-mono-nerd/

%files -n bitstream-vera-mono-nerd-fonts
%license bitstream-vera-mono/FONT-LICENSE.txt
%{_ttfontsdir}/bitstream-vera-mono-nerd/

%files -n iosevka-nerd-fonts
%license iosevka/FONT-LICENSE.txt
%{_ttfontsdir}/iosevka-nerd/

