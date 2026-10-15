#!/bin/bash
# Layer 02 - build RPMs
# Builds software missing from Tumbleweed (packages/<name>/<name>.spec) in the
# omageeko-builder container, publishes it to the local repo, installs it.
#
# A package is rebuilt only when its stamp changes: hash of packages/<name>/
# plus the repo versions of the packages listed in packages/<name>/rebuild-on
# (ABI-bound dependencies, e.g. Qt for quickshell, hyprland for the plugin).
# Force with OMAGEEKO_REBUILD=all or OMAGEEKO_REBUILD="quickshell owe".

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

# Build order; also the install set for this layer
PACKAGES=(
  quickshell
  owe
  omarchy-hyprland-titlebars
  hyprland-preview-share-picker
  jetbrains-mono-nerd-fonts
  ia-writer-fonts
)
# RPM names to install (owe's spec also builds owe-lockfeed)
INSTALL=(
  quickshell
  owe
  owe-lockfeed
  omarchy-hyprland-titlebars
  hyprland-preview-share-picker
  jetbrains-mono-nerd-fonts
  ia-writer-fonts
)

require_user

check_builder_snapshot
build_packages "${PACKAGES[@]}"

snap_begin "02-build-rpms"
install_local_rpms "${INSTALL[@]}"
fc-cache -f >/dev/null
snap_end

log "Layer 02 done. Run layers/02-build-rpms/verify.sh"
