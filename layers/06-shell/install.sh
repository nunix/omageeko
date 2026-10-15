#!/bin/bash
# Layer 06 - Omarchy shell & menu, aligned with Tumbleweed (built part by part, see PLAN.md §6)
#   06a  Install / Remove / Update: every package name the menus and omarchy-install-*
#        commands use resolves to a TW package, a vendor RPM repo (repos.tsv), Flathub,
#        a local build, or an explicit "not available" message.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user

check_builder_snapshot
# nerd-fonts-extra is only published to the local repo; omarchy-pkg-add installs a font on demand
build_packages omageeko nerd-fonts-extra

snap_begin "06-shell"
install_local_rpms omageeko omageeko-settings omageeko-session omageeko-hardware
# Flathub is omageeko's AUR stand-in (system-wide, like the Arch packages it replaces)
sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
snap_end

# The shell reads the menu at startup
omarchy-restart-shell >/dev/null 2>&1 || warn "Restart the shell to load the new menu: omarchy restart shell"

log "Layer 06 done. Run layers/06-shell/verify.sh"
