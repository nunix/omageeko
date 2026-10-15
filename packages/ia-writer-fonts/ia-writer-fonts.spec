# omageeko: port of omarchy-pkgs/pkgbuilds/ttf-ia-writer (20261002.r63-3)
%global commit c6588670c71e9ac628acc27b72cde4bf12726b7f
# Duospace was removed upstream; Omarchy keeps the legacy family at its last pin
%global legacy_commit b337fe1a4c93026268f70e4b2678371f3e89e2ce
%global base https://github.com/iaolo/iA-Fonts/raw/%{commit}
%global legacy https://github.com/iaolo/iA-Fonts/raw/%{legacy_commit}

Name:           ia-writer-fonts
Version:        20261002.r63
Release:        3.omageeko
Summary:        iA Writer Mono, Duo, Quattro and Duospace fonts
License:        OFL-1.1
URL:            https://github.com/iaolo/iA-Fonts
BuildArch:      noarch
BuildRequires:  fontpackages-devel
Provides:       ttf-ia-writer = %{version}
Source0:        %{base}/iA%%20Writer%%20Mono/Static/iAWriterMonoS-Bold.ttf
Source1:        %{base}/iA%%20Writer%%20Mono/Static/iAWriterMonoS-BoldItalic.ttf
Source2:        %{base}/iA%%20Writer%%20Mono/Static/iAWriterMonoS-Italic.ttf
Source3:        %{base}/iA%%20Writer%%20Mono/Static/iAWriterMonoS-Regular.ttf
Source4:        %{base}/iA%%20Writer%%20Quattro/Static/iAWriterQuattroS-Bold.ttf
Source5:        %{base}/iA%%20Writer%%20Quattro/Static/iAWriterQuattroS-BoldItalic.ttf
Source6:        %{base}/iA%%20Writer%%20Quattro/Static/iAWriterQuattroS-Italic.ttf
Source7:        %{base}/iA%%20Writer%%20Quattro/Static/iAWriterQuattroS-Regular.ttf
Source8:        %{base}/iA%%20Writer%%20Duo/Static/iAWriterDuoS-Bold.ttf
Source9:        %{base}/iA%%20Writer%%20Duo/Static/iAWriterDuoS-BoldItalic.ttf
Source10:        %{base}/iA%%20Writer%%20Duo/Static/iAWriterDuoS-Italic.ttf
Source11:        %{base}/iA%%20Writer%%20Duo/Static/iAWriterDuoS-Regular.ttf
Source12:        %{legacy}/iA%%20Writer%%20Duospace/TTF%%20(PC)/iAWriterDuospace-Bold.ttf
Source13:        %{legacy}/iA%%20Writer%%20Duospace/TTF%%20(PC)/iAWriterDuospace-BoldItalic.ttf
Source14:        %{legacy}/iA%%20Writer%%20Duospace/TTF%%20(PC)/iAWriterDuospace-Italic.ttf
Source15:        %{legacy}/iA%%20Writer%%20Duospace/TTF%%20(PC)/iAWriterDuospace-Regular.ttf

%description
The iA Writer typefaces (Mono, Duo, Quattro, plus the legacy Duospace) used
by Omarchy's writing tools and themes.

%prep
%setup -q -c -T

%build

%install
install -d %{buildroot}%{_ttfontsdir}/ia-writer
install -m644 %{_sourcedir}/iAWriter*.ttf %{buildroot}%{_ttfontsdir}/ia-writer/

%reconfigure_fonts_scriptlets

%files
%{_ttfontsdir}/ia-writer/
