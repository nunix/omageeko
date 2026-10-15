#!/bin/bash
# Layer 01 - base packages
# CLI/TUI tools, dev libraries, Wayland helpers, fonts and themes from
# upstream's omarchy-base.packages, mapped to Tumbleweed names in packages.map.
# Only installs packages; Omarchy configs for them arrive in layer 03.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

MISE_REPO_ALIAS="mise"
MISE_REPO_URL="https://mise.jdx.dev/rpm"
MISE_GPG_KEY="https://mise.jdx.dev/gpg-key.pub"

require_user
snap_begin "01-base-packages"

# 1. mise upstream RPM repo (mise is not packaged for Tumbleweed)
if ! zypper lr "$MISE_REPO_ALIAS" &>/dev/null; then
  log "Adding mise repo"
  sudo rpm --import "$MISE_GPG_KEY"
  sudo zypper --non-interactive addrepo --refresh --priority 95 "$MISE_REPO_URL" "$MISE_REPO_ALIAS"
fi
sudo zypper --non-interactive refresh "$MISE_REPO_ALIAS"

# 2. Replacements: TW defaults that conflict with what Omarchy expects.
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

# 3. Packages mapped to layer 01, plus mise from its repo
mapfile -t packages < <(map_packages 01)
packages+=(mise)
zypper_install "${packages[@]}"

# 4. Refresh font cache so new fonts are visible to running apps
fc-cache -f >/dev/null

snap_end
log "Layer 01 done. Run layers/01-base-packages/verify.sh"
