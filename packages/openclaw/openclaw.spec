# omageeko: port of omarchy-pkgs/pkgbuilds/openclaw (2026.10.10-1)
# This is the release Omarchy ships, not the OpenClaw that runs: a copy in /usr
# belongs to rpm, and `openclaw update` refuses to write there.
# omarchy-install-openclaw-cli seeds a copy under ~/.openclaw from this tarball
# with the installer that came in it, and that copy updates itself.
%global debug_package %{nil}
%global __os_install_post %{nil}

Name:           openclaw
Version:        2026.10.10
Release:        1.omageeko%{?dist}
Summary:        Multi-channel AI gateway with extensible messaging integrations
License:        MIT
URL:            https://github.com/openclaw/openclaw
Source0:        https://registry.npmjs.org/%{name}/-/%{name}-%{version}.tgz
BuildArch:      noarch
BuildRequires:  bsdtar
# The installer brings its own Node, and git is the one thing it would
# otherwise try to install with sudo.
Requires:       bash
Requires:       curl
Requires:       git

%description
OpenClaw connects AI agents to messaging channels. Omarchy's
omarchy-install-openclaw-cli seeds a self-updating per-user copy under
~/.openclaw from the release this package ships.

%prep
%setup -q -c -T

%build

%install
install -Dm644 %{SOURCE0} %{buildroot}%{_datadir}/%{name}/%{name}.tgz
bsdtar -xf %{SOURCE0} \
  'package/scripts/install-*.sh' package/dist/control-ui/apple-touch-icon.png package/LICENSE
# install-cli.sh loads helpers from beside itself, so they ship with it; loading
# it from here fails this build, rather than every setup, if one is missing.
install -Dm644 -t %{buildroot}%{_datadir}/%{name} package/scripts/install-*.sh
bash %{buildroot}%{_datadir}/%{name}/install-cli.sh --help >/dev/null
install -Dm644 package/dist/control-ui/apple-touch-icon.png %{buildroot}%{_datadir}/%{name}/%{name}.png
install -Dm644 -t %{buildroot}%{_datadir}/licenses/%{name} package/LICENSE

%post
if [ "$1" -eq 1 ]; then
  printf '%%s\n' "==> This is the release a self-updating OpenClaw starts from." \
    "==> Set it up under ~/.openclaw: omarchy-install-openclaw-cli --now"
else
  printf '%%s\n' "==> OpenClaw runs from ~/.openclaw and updates itself: openclaw update" \
    "==> This package only sets the release new installs start from."
fi

%files
%{_datadir}/licenses/%{name}/
%{_datadir}/%{name}/
