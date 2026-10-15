# omageeko: port of omarchy-pkgs/pkgbuilds/openclaw (2026.10.3-1)
%global debug_package %{nil}
%global __requires_exclude_from ^%{_prefix}/lib/node_modules/.*$
%global __provides_exclude_from ^%{_prefix}/lib/node_modules/.*$

Name:           openclaw
Version:        2026.10.3
Release:        1.omageeko%{?dist}
Summary:        Multi-channel AI gateway with extensible messaging integrations
License:        MIT
URL:            https://github.com/openclaw/openclaw
Source0:        https://registry.npmjs.org/%{name}/-/%{name}-%{version}.tgz
ExclusiveArch:  x86_64
BuildRequires:  nodejs-default
BuildRequires:  npm-default
Requires:       nodejs >= 22

%description
OpenClaw connects AI agents to messaging channels. Omarchy's
omarchy-install-openclaw-cli seeds a self-updating per-user copy from this package.

%prep
%setup -q -c -T

%build

%install
export SHARP_IGNORE_GLOBAL_LIBVIPS=1
# Upstream's postinstall must run (it clears .openclaw-lifecycle-pending); give it a scratch home
mkdir -p home
env -u OPENCLAW_HOME -u OPENCLAW_STATE_DIR -u OPENCLAW_CONFIG_PATH HOME="$PWD/home" \
  npm install --silent --global --cache "$PWD/npm-cache" \
  --allow-scripts="file:%{SOURCE0}" \
  --prefix %{buildroot}%{_prefix} %{SOURCE0}
if [ -e %{buildroot}%{_prefix}/lib/node_modules/%{name}/.openclaw-lifecycle-pending ]; then
  echo "openclaw's postinstall did not run; the package would fail on first use" >&2
  exit 1
fi
rm -f %{buildroot}%{_bindir}/%{name}
cat > %{buildroot}%{_bindir}/%{name} <<'SH'
#!/bin/sh
export SHARP_IGNORE_GLOBAL_LIBVIPS=1
exec node /usr/lib/node_modules/openclaw/openclaw.mjs "$@"
SH
chmod 755 %{buildroot}%{_bindir}/%{name}
# Seed for omarchy-install-openclaw-cli
install -d %{buildroot}%{_datadir}
ln -s %{_prefix}/lib/node_modules/%{name} %{buildroot}%{_datadir}/%{name}

%post
printf '%%s\n' "==> Install gateway service: openclaw gateway install --force" "==> Perform onboarding once: openclaw onboard"

%files
%{_bindir}/%{name}
%{_prefix}/lib/node_modules/%{name}/
%{_datadir}/%{name}
