#!/bin/bash
# Layer 01 - base packages
# CLI/TUI tools, dev libraries, Wayland helpers, fonts and themes from
# upstream's omarchy-base.packages, mapped to Tumbleweed names in packages.map.
# Only installs packages; Omarchy configs for them arrive in layer 03.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user
snap_begin "01-base-packages"

# mise (Omarchy's tool installer) belongs to the Omarchy layer: layer 03.

# 1. Replacements: TW defaults that conflict with what Omarchy expects.
#    hyprland-qtutils is the old name of hyprland-guiutils (only recommended by
#    the hyprland pattern); busybox-man conflicts with the real man.
declare -A REPLACES=([hyprland-guiutils]=hyprland-qtutils [man]=busybox-man)
swap=()
for new in "${!REPLACES[@]}"; do
  old=${REPLACES[$new]}
  rpm -q "$old" &>/dev/null && swap+=("$new" "-$old")
done
if (( ${#swap[@]} )); then
  log "Replacing: ${swap[*]}"
  sudo zypper --non-interactive install --no-recommends "${swap[@]}"
fi

# 2. Packages mapped to layer 01
mapfile -t packages < <(map_packages 01)
zypper_install "${packages[@]}"

# 3. Refresh font cache so new fonts are visible to running apps
fc-cache -f >/dev/null

snap_end
log "Layer 01 done. Run layers/01-base-packages/verify.sh"
