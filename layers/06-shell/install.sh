#!/bin/bash
# Layer 06 - Omarchy shell & menu, aligned with Tumbleweed (built part by part, see PLAN.md §6)
#   06a  Install / Remove / Update: every package name the menus and omarchy-install-*
#        commands use resolves to a TW package, a vendor RPM repo (repos.tsv), Flathub,
#        a local build or vendor RPM, or Omarchy's own build in the omageeko distrobox.
#   06b  Omarchy base applications (packages.map layer 06) through omarchy-pkg-add, so
#        TW packages, native builds and box apps resolve exactly like the menus do.
#        Omarchy "preinstalls" are skipped once the user removed them (Omarchy's marker).

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user

check_builder_snapshot
# Published to the local repo only; omarchy-pkg-add installs them on demand
build_packages omageeko nerd-fonts-extra voxtype once openclaw omarchy-emacs \
  omasnap herdr disktree tzupdate aether omarchy-nvim

snap_begin "06-shell"
install_local_rpms omageeko omageeko-settings omageeko-session omageeko-hardware
# Flathub is omageeko's AUR stand-in (system-wide, like the Arch packages it replaces)
sudo flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
snap_end

# ---- 06b: Omarchy base applications
export OMARCHY_PATH=/usr/share/omarchy
source /usr/share/omageeko/lib/pkg.sh
# Omarchy's own preinstall list: the packages omarchy-remove-preinstalls drops
mapfile -t preinstalls < <(sed -n '/omarchy-pkg-drop/,/^fi/p' /usr/bin/omarchy-remove-preinstalls | grep -oE '^ +[a-z0-9][a-z0-9.+-]*' | tr -d ' ')
skip_preinstalls=0
[[ -f ~/.local/state/omarchy/preinstalls-removed ]] && skip_preinstalls=1
apps=()
while read -r name; do
  if (( skip_preinstalls )) && printf '%s\n' "${preinstalls[@]}" | grep -qx "$name"; then
    continue
  fi
  omageeko_pkg_installed "$name" || apps+=("$name")
done < <(awk '!/^#/ && $2 == "06" && $1 !~ /^\+/ && $3 != "-" { print $1 }' "$OMAGEEKO_ROOT/packages.map")
if (( ${#apps[@]} )); then
  log "Installing Omarchy base apps: ${apps[*]}"
  omarchy-pkg-add "${apps[@]}"
fi
(( skip_preinstalls )) && log "Preinstalls skipped (removed by the user; Install > Preinstalls brings them back)"
mapfile -t extras < <(awk '!/^#/ && $2 == "06" && $1 ~ /^\+/ { print $3 }' "$OMAGEEKO_ROOT/packages.map")
(( ${#extras[@]} )) && zypper_install "${extras[@]}"
# Omarchy's Neovim setup for this user (only fills in what is missing)
command -v omarchy-nvim-setup >/dev/null && omarchy-nvim-setup >/dev/null

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
