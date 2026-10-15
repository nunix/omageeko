#!/bin/bash
# Layer 06 - Omarchy shell & menu, aligned with Tumbleweed (built part by part, see PLAN.md §6)
#   06a  Install / Remove / Update: every package name the menus and omarchy-install-*
#        commands use resolves to a TW package, a vendor RPM repo (repos.tsv), Flathub,
#        a local build or vendor RPM, or Omarchy's own build in the omageeko distrobox.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user

check_builder_snapshot
# Published to the local repo only; omarchy-pkg-add installs them on demand
build_packages omageeko nerd-fonts-extra voxtype once openclaw omarchy-emacs

snap_begin "06-shell"
install_local_rpms omageeko omageeko-settings omageeko-session omageeko-hardware
# Flathub is omageeko's AUR stand-in (system-wide, like the Arch packages it replaces)
sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
snap_end

# Adopt @box apps already installed in an existing omageeko-arch box (e.g. the prototype)
if podman container exists omageeko-arch 2>/dev/null; then
  mapfile -t box_pkgs < <(awk '!/^#/ && $3 ~ /^@box:/ { sub(/^@box:/, "", $3); print $3 }' "$OMAGEEKO_ROOT/packages.map")
  mapfile -t installed < <(distrobox enter --name omageeko-arch -- pacman -Qq "${box_pkgs[@]}" 2>/dev/null)
  if (( ${#installed[@]} )); then
    log "Adopting box apps: ${installed[*]}"
    omageeko-box install "${installed[@]}" >/dev/null
  fi
fi

# The shell reads the menu at startup
omarchy-restart-shell >/dev/null 2>&1 || warn "Restart the shell to load the new menu: omarchy restart shell"

log "Layer 06 done. Run layers/06-shell/verify.sh"
