# omageeko: Omarchy (quattro) for openSUSE Tumbleweed.
# Port of omarchy-pkgs/pkgbuilds/{omarchy,omarchy-settings}: upstream tree at
# the pinned commit + Tumbleweed patches (patches/) + overlay (overlay/bin
# replacements, generated stubs from overlay/stubs.tsv) + pkgmap.tsv.
# The commit lines are synced from upstream.lock by layers/03-omarchy-core/install.sh.
%global commit 84cfb93959f4fe0bbb71de71593b36647d2ba78d
%global commit_date 20261014
%global upstream_release 4.0.4
%global shortcommit %(echo %{commit} | cut -c1-7)

Name:           omageeko
Version:        %{upstream_release}+git%{commit_date}.%{shortcommit}
Release:        1.omageeko%{?dist}
Summary:        Omarchy desktop (quattro) on openSUSE Tumbleweed
License:        MIT
URL:            https://github.com/omacom/omarchy
Source0:        %{url}/archive/%{commit}.tar.gz#/omarchy-%{commit}.tar.gz
BuildArch:      noarch
BuildRequires:  ImageMagick
BuildRequires:  sudo
BuildRequires:  patch
BuildRequires:  python3
Requires:       %{name}-settings = %{version}-%{release}
Requires:       hyprland
Requires:       quickshell
Requires:       uwsm
Requires:       xdg-desktop-portal-hyprland
Requires:       wireplumber
Requires:       pipewire
Requires:       gnome-keyring
Requires:       gum
Requires:       jq
Requires:       git-core
Requires:       perl
Requires:       fakeroot
Requires:       snapper
Requires:       jetbrains-mono-nerd-fonts
# Implicit on Arch: omarchy-provision-user and notifications call these
Requires:       xdg-user-dirs
Requires:       libnotify-tools
# omarchy-pkg-add installs Flathub apps where Tumbleweed has no package (omageeko's AUR stand-in)
Requires:       flatpak
# omageeko-box: apps from Omarchy's Arch repo in a distrobox
Requires:       distrobox
Requires:       podman
# Scripts are run by Omarchy's own launchers; don't derive interpreter/module deps
%global __requires_exclude_from ^%{_datadir}/omarchy/.*$

%description
The Omarchy desktop from omacom/omarchy (branch quattro) packaged for openSUSE
Tumbleweed: omarchy-* commands, the Quickshell desktop shell, themes,
migrations and install scripts under /usr/share/omarchy. Arch-specific
commands are ported to zypper/snapper/sdbootutil or stubbed with a reason.

%package        settings
Summary:        Omarchy user defaults, /etc/skel content, fonts and system defaults
Requires:       bash
Requires:       curl
Requires:       gum
Requires:       hicolor-icon-theme

%description    settings
Static defaults shipped before user creation: /etc/skel (configs, launchers,
state markers), the resync copy under /usr/share/omarchy, application defaults
in /etc, sudoers rules for Omarchy helpers, fonts, icons and systemd user units.
Tumbleweed-sensitive upstream files (os-release, nsswitch.conf, limine,
mkinitcpio, sddm) are deliberately not shipped.

%package        session
Summary:        Omarchy Hyprland session managed by uwsm
Requires:       %{name} = %{version}-%{release}
Requires:       uwsm
Requires:       hyprland

%description    session
The "Omarchy (Hyprland uwsm)" Wayland session for display managers, the uwsm
environment file that sets OMARCHY_PATH/PATH/TERMINAL/EDITOR for the session,
and the systemd drop-in that keeps the shell alive across compositor exits.

%package        hardware
Summary:        omageeko hardware integration for Tumbleweed laptops
Requires:       wireplumber
Requires:       socat
Requires:       jq
# btmgmt for the Bluetooth LE Device Privacy Mode helper
Requires:       bluez

%description    hardware
Hardware defaults omageeko adds on top of Omarchy: readable names for laptop
codec devices exposed through ALSA UCM (headphone jack, headset mic, speakers,
internal microphone) so Omarchy's audio panel can tell them apart, and a watcher
that re-wakes monitors listed in ~/.config/omageeko/monitor-wake-kick when they
reconnect after deep standby but stay dark, and a service that puts bonded
Bluetooth LE devices into Device Privacy Mode so they can reconnect.

%prep
%setup -q -n omarchy-%{commit}
for p in %{_sourcedir}/patches/*.patch; do
  patch -p1 --fuzz=0 --no-backup-if-mismatch -i "$p"
done
# Menu: Tumbleweed labels/icons and dropped entries (fails on upstream drift)
python3 %{_sourcedir}/menu-transform.py
# Overlay: full replacements of Arch-coupled commands
cp -f %{_sourcedir}/overlay/bin/* bin/
# Overlay: additions to the Quickshell desktop tree (e.g. agent icons)
cp -a %{_sourcedir}/overlay/shell/. shell/
# Stubs: keep upstream's omarchy: metadata so the CLI router still lists them
while IFS=$'\t' read -r cmd where reason; do
  [[ -z $cmd || $cmd == \#* ]] && continue
  [[ -f bin/$cmd ]] || { echo "stub target bin/$cmd not in upstream" >&2; exit 1; }
  if [[ $where == "n/a" ]]; then
    msg="not applicable on Tumbleweed: $reason"
  else
    msg="not ported yet (omageeko $where): $reason"
  fi
  {
    echo '#!/bin/bash'
    echo
    grep -E '^# omarchy:' "bin/$cmd" || true
    echo "# omageeko: stub, $msg"
    echo
    printf 'echo %q >&2\n' "omageeko: $cmd is $msg"
    echo 'exit 1'
  } > "bin/$cmd.new"
  mv "bin/$cmd.new" "bin/$cmd"
done < %{_sourcedir}/overlay/stubs.tsv

%build

%install
# ---- omageeko (core): mirrors pkgbuilds/omarchy
install -d %{buildroot}%{_bindir} %{buildroot}%{_datadir}/omarchy/bin
for bin in bin/*; do
  [[ -f $bin ]] || continue
  base=$(basename "$bin")
  case "$base" in
    omarchy-debug|omarchy-debug-idle|omarchy-upload-log) continue ;;
  esac
  install -m755 "$bin" %{buildroot}%{_bindir}/$base
  ln -s %{_bindir}/$base %{buildroot}%{_datadir}/omarchy/bin/$base
done
cp -a install themes migrations shell %{buildroot}%{_datadir}/omarchy/
install -m644 version %{buildroot}%{_datadir}/omarchy/version
install -d %{buildroot}%{_sysconfdir}/skel/.local/state/omarchy/migrations
for migration in migrations/*.sh; do
  touch %{buildroot}%{_sysconfdir}/skel/.local/state/omarchy/migrations/$(basename "$migration")
done
# omageeko helpers and data
install -Dm644 %{_sourcedir}/overlay/share/lib/pkg.sh %{buildroot}%{_datadir}/omageeko/lib/pkg.sh
install -Dm644 %{_sourcedir}/pkgmap.tsv %{buildroot}%{_datadir}/omageeko/pkgmap.tsv
install -Dm644 %{_sourcedir}/overlay/stubs.tsv %{buildroot}%{_datadir}/omageeko/stubs.tsv
install -Dm644 %{_sourcedir}/overlay/share/repos.tsv %{buildroot}%{_datadir}/omageeko/repos.tsv
install -Dm755 %{_sourcedir}/omageeko-bump %{buildroot}%{_datadir}/omageeko/tools/omageeko-bump
install -Dm644 %{_sourcedir}/migrations.tsv %{buildroot}%{_datadir}/omageeko/migrations.tsv
mkdir -p %{buildroot}%{_datadir}/omageeko/agents/skills
cp -a %{_sourcedir}/overlay/share/agents/skills/omageeko %{buildroot}%{_datadir}/omageeko/agents/skills/
echo "%{commit}" > %{buildroot}%{_datadir}/omageeko/upstream-commit

# ---- omageeko-settings: mirrors pkgbuilds/omarchy-settings (Tumbleweed subset)
install -d %{buildroot}%{_sysconfdir}/skel/.config %{buildroot}%{_datadir}/omarchy/config
cp -a config/. %{buildroot}%{_sysconfdir}/skel/.config/
cp -a config/. %{buildroot}%{_datadir}/omarchy/config/
install -Dm644 default/bashrc %{buildroot}%{_sysconfdir}/skel/.bashrc

# /etc defaults safe on Tumbleweed (the rest belongs to later layers or doesn't apply)
for path in fastfetch/config.jsonc mpv/mpv.conf xdg/kitty/kitty.conf xkb/rules/evdev xkb/symbols/omarchy \
            gnupg/dirmngr.conf profile.d/omarchy.sh tmpfiles.d/omarchy-nopasswd-sudo.conf; do
  install -Dm644 etc/$path %{buildroot}%{_sysconfdir}/$path
done
for f in etc/mise/conf.d/*; do
  install -Dm644 "$f" %{buildroot}%{_sysconfdir}/mise/conf.d/$(basename "$f")
done
install -d -m750 %{buildroot}%{_sysconfdir}/sudoers.d
for f in etc/sudoers.d/*; do
  install -m440 "$f" %{buildroot}%{_sysconfdir}/sudoers.d/$(basename "$f")
done

install -Dm644 default/fontconfig/conf.avail/50-omarchy.conf %{buildroot}%{_datadir}/fontconfig/conf.avail/50-omarchy.conf
install -d %{buildroot}%{_sysconfdir}/fonts/conf.d
ln -sfn %{_datadir}/fontconfig/conf.avail/50-omarchy.conf %{buildroot}%{_sysconfdir}/fonts/conf.d/50-omarchy.conf
install -Dm644 default/xdg-terminal-exec/hyprland-xdg-terminals.list %{buildroot}%{_datadir}/xdg-terminal-exec/hyprland-xdg-terminals.list
install -Dm644 default/applications/mimeapps.list %{buildroot}%{_datadir}/applications/mimeapps.list
# Hidden chromium.desktop alias for TW's chromium-browser.desktop
install -Dm644 %{_sourcedir}/overlay/share/applications/chromium.desktop %{buildroot}%{_datadir}/applications/chromium.desktop

install -d %{buildroot}%{_userunitdir}
for unit in default/systemd/user/*.service; do
  install -m644 "$unit" %{buildroot}%{_userunitdir}/$(basename "$unit")
done
ln -sfn omarchy-migrate-notify.service %{buildroot}%{_userunitdir}/omarchy-update-user-notify.service

install -d %{buildroot}%{_datadir}/omarchy/applications %{buildroot}%{_sysconfdir}/skel/.local/share/applications
cp -a applications/. %{buildroot}%{_datadir}/omarchy/applications/
rm -rf %{buildroot}%{_datadir}/omarchy/applications/icons
cp applications/*.desktop %{buildroot}%{_sysconfdir}/skel/.local/share/applications/
if compgen -G 'applications/hidden/*.desktop' >/dev/null; then
  cp applications/hidden/*.desktop %{buildroot}%{_sysconfdir}/skel/.local/share/applications/
fi
for icon in applications/icons/*; do
  [[ -f $icon ]] || continue
  icon_name=$(basename "$icon")
  icon_id=$(printf '%%s\n' "${icon_name%%.*}" | tr '[:upper:]' '[:lower:]' | sed 's/[^[:alnum:]]\+/-/g; s/^-//; s/-$//')
  case "$icon_name" in
    *.svg) install -Dm644 "$icon" %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/$icon_id.svg ;;
    *)
      install -d %{buildroot}%{_datadir}/icons/hicolor/{256x256,48x48}/apps
      magick "$icon" -thumbnail 256x256 -background transparent -gravity center -extent 256x256 \
        "PNG32:%{buildroot}%{_datadir}/icons/hicolor/256x256/apps/$icon_id.png"
      magick "$icon" -thumbnail 48x48 -background transparent -gravity center -extent 48x48 \
        "PNG32:%{buildroot}%{_datadir}/icons/hicolor/48x48/apps/$icon_id.png"
      ;;
  esac
done

install -d %{buildroot}%{_datadir}/omarchy/default
cp -a default/. %{buildroot}%{_datadir}/omarchy/default/
install -Dm644 default/fonts/omarchy/omarchy.ttf %{buildroot}%{_datadir}/fonts/omarchy/omarchy.ttf

# omageeko wordmark (same block font as Omarchy's) replaces the Omarchy logo
install -Dm644 %{_sourcedir}/overlay/share/branding/logo.txt %{buildroot}%{_datadir}/omarchy/logo.txt
install -Dm644 logo.svg %{buildroot}%{_datadir}/omarchy/logo.svg
install -Dm644 icon.txt %{buildroot}%{_datadir}/omarchy/icon.txt
install -Dm644 icon.png %{buildroot}%{_datadir}/omarchy/icon.png
install -Dm644 icon.png %{buildroot}%{_datadir}/pixmaps/omarchy.png
install -Dm644 icon.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/omarchy.png
install -Dm644 %{_sourcedir}/overlay/share/branding/logo.txt %{buildroot}%{_sysconfdir}/skel/.config/omarchy/branding/screensaver.txt
install -Dm644 logo.txt %{buildroot}%{_datadir}/omageeko/omarchy-logo.txt
install -Dm644 icon.txt %{buildroot}%{_sysconfdir}/skel/.config/omarchy/branding/about.txt
install -Dm644 default/hypr/toggles/flags.lua %{buildroot}%{_sysconfdir}/skel/.local/state/omarchy/toggles/hypr/flags.lua
install -Dm644 default/nautilus-python/extensions/localsend.py %{buildroot}%{_sysconfdir}/skel/.local/share/nautilus-python/extensions/localsend.py
install -Dm644 default/nautilus-python/extensions/transcode.py %{buildroot}%{_sysconfdir}/skel/.local/share/nautilus-python/extensions/transcode.py
install -Dm644 default/tensaku/state.toml %{buildroot}%{_sysconfdir}/skel/.local/state/tensaku/state.toml

install -m755 bin/omarchy-upload-log bin/omarchy-debug bin/omarchy-debug-idle %{buildroot}%{_bindir}/

# ---- omageeko-session (layer 04)
# Upstream installs the session to /usr/local/share for sddm; lightdm reads /usr/share
install -Dm644 default/wayland-sessions/omarchy.desktop %{buildroot}%{_datadir}/wayland-sessions/omarchy.desktop
install -Dm644 default/uwsm/env.d/10-omarchy %{buildroot}%{_datadir}/uwsm/env.d/10-omarchy
install -Dm644 %{_sourcedir}/overlay/share/uwsm/20-omageeko-flatpak %{buildroot}%{_datadir}/uwsm/env.d/20-omageeko-flatpak
install -Dm644 etc/systemd/user/wayland-wm@hyprland.desktop.service.d/10-keep-shell.conf \
  %{buildroot}%{_sysconfdir}/systemd/user/wayland-wm@hyprland.desktop.service.d/10-keep-shell.conf

# ---- omageeko-hardware (layer 05)
install -Dm644 %{_sourcedir}/overlay/share/wireplumber/60-omageeko-ucm-labels.conf \
  %{buildroot}%{_datadir}/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf
install -Dm644 %{_sourcedir}/overlay/share/udev/60-omageeko-ddcutil-i2c.rules %{buildroot}%{_udevrulesdir}/60-omageeko-ddcutil-i2c.rules
install -Dm644 %{_sourcedir}/overlay/share/systemd/omageeko-monitor-wake-kick.service \
  %{buildroot}%{_userunitdir}/omageeko-monitor-wake-kick.service
install -Dm755 %{_sourcedir}/overlay/share/libexec/bt-device-privacy %{buildroot}%{_libexecdir}/omageeko/bt-device-privacy
install -Dm644 %{_sourcedir}/overlay/share/systemd/omageeko-bt-device-privacy.service %{buildroot}%{_unitdir}/omageeko-bt-device-privacy.service
install -Dm644 %{_sourcedir}/overlay/share/systemd/omageeko-bt-device-privacy.timer %{buildroot}%{_unitdir}/omageeko-bt-device-privacy.timer

%check
# Every sudoers rule must parse
for f in %{buildroot}%{_sysconfdir}/sudoers.d/*; do
  visudo -cqf "$f"
done
# Stubs and overlay must not leave pacman calls in the commands we touched
# (code lines only: upstream's # omarchy:summary= text still says "pacman")
for f in $(cut -f1 %{_sourcedir}/overlay/stubs.tsv | grep -v '^#') $(ls %{_sourcedir}/overlay/bin); do
  # Commands that run pacman inside the Arch distrobox opt out explicitly
  grep -q '^# omageeko: pacman-inside-box' %{buildroot}%{_bindir}/$f && continue
  if grep -vE '^[[:space:]]*#' %{buildroot}%{_bindir}/$f | grep -qE '(^|[[:space:];&|(`])(pacman|yay|expac|paccache|checkupdates)([[:space:]]|$)'; then
    echo "pacman left in $f" >&2
    exit 1
  fi
done

%files
%license LICENSE
%{_bindir}/omarchy*
%{_bindir}/omageeko-box
%{_bindir}/omageeko-update
%{_bindir}/omageeko-link-skills
%exclude %{_bindir}/omarchy-upload-log
%exclude %{_bindir}/omarchy-debug
%exclude %{_bindir}/omarchy-debug-idle
%dir %{_datadir}/omarchy
%{_datadir}/omarchy/bin/
%{_datadir}/omarchy/install/
%{_datadir}/omarchy/themes/
%{_datadir}/omarchy/migrations/
%{_datadir}/omarchy/shell/
%{_datadir}/omarchy/version
%{_datadir}/omageeko/
%dir %{_sysconfdir}/skel/.local
%dir %{_sysconfdir}/skel/.local/state
%dir %{_sysconfdir}/skel/.local/state/omarchy
%{_sysconfdir}/skel/.local/state/omarchy/migrations/

%files settings
%{_bindir}/omarchy-upload-log
%{_bindir}/omarchy-debug
%{_bindir}/omarchy-debug-idle
%{_datadir}/omarchy/config/
%{_datadir}/omarchy/applications/
%{_datadir}/omarchy/default/
%{_datadir}/omarchy/logo.*
%{_datadir}/omarchy/icon.*
%config(noreplace) %{_sysconfdir}/skel/.bashrc
%{_sysconfdir}/skel/.config/
%{_sysconfdir}/skel/.local/share/
%{_sysconfdir}/skel/.local/state/omarchy/toggles/
%{_sysconfdir}/skel/.local/state/tensaku/
%config(noreplace) %{_sysconfdir}/fastfetch/
%config(noreplace) %{_sysconfdir}/mpv/
%config(noreplace) %{_sysconfdir}/xdg/kitty/
%config %{_sysconfdir}/xkb/
%config(noreplace) %{_sysconfdir}/gnupg/dirmngr.conf
%dir %{_sysconfdir}/gnupg
%config %{_sysconfdir}/profile.d/omarchy.sh
%config %{_sysconfdir}/tmpfiles.d/omarchy-nopasswd-sudo.conf
%config(noreplace) %{_sysconfdir}/mise/
%config %attr(0440,root,root) %{_sysconfdir}/sudoers.d/omarchy-*
%{_datadir}/fontconfig/conf.avail/50-omarchy.conf
%config %{_sysconfdir}/fonts/conf.d/50-omarchy.conf
%dir %{_datadir}/xdg-terminal-exec
%{_datadir}/xdg-terminal-exec/hyprland-xdg-terminals.list
%{_datadir}/applications/mimeapps.list
%{_datadir}/applications/chromium.desktop
%{_userunitdir}/*.service
%{_datadir}/fonts/omarchy/
%{_datadir}/pixmaps/omarchy.png
%{_datadir}/icons/hicolor/*/apps/*

%files session
%{_datadir}/wayland-sessions/omarchy.desktop
%dir %{_datadir}/uwsm/env.d
%{_datadir}/uwsm/env.d/10-omarchy
%{_datadir}/uwsm/env.d/20-omageeko-flatpak
%dir %{_sysconfdir}/systemd/user/wayland-wm@hyprland.desktop.service.d
%config %{_sysconfdir}/systemd/user/wayland-wm@hyprland.desktop.service.d/10-keep-shell.conf

%post hardware
# ddcutil i2c rule: apply to the existing devices without a reboot
udevadm control --reload >/dev/null 2>&1 || :
udevadm trigger --subsystem-match=i2c-dev --action=change >/dev/null 2>&1 || :

%files hardware
%{_datadir}/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf
%{_udevrulesdir}/60-omageeko-ddcutil-i2c.rules
%{_bindir}/omageeko-monitor-wake-kick
%{_userunitdir}/omageeko-monitor-wake-kick.service
%dir %{_libexecdir}/omageeko
%{_libexecdir}/omageeko/bt-device-privacy
%{_unitdir}/omageeko-bt-device-privacy.service
%{_unitdir}/omageeko-bt-device-privacy.timer
