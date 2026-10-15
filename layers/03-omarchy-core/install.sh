#!/bin/bash
# Layer 03 - omarchy core
# Builds the omageeko RPMs from upstream Omarchy at the pinned commit plus the
# Tumbleweed patches/overlay (packages/omageeko), and installs them:
#   omageeko           omarchy-* commands, /usr/share/omarchy (shell, themes, install, migrations)
#   omageeko-settings  /etc/skel, resync defaults, /etc app defaults, sudoers, fonts, icons, user units
# The running desktop is untouched: the user's Hyprland config switches in layer 04.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user

# Spec sync with upstream.lock and pkgmap.tsv generation: packages/omageeko/prepare.sh
# (run by build_packages, so every layer that builds omageeko gets fresh inputs)

# Build and install
check_builder_snapshot
build_packages omageeko

snap_begin "03-omarchy-core"
install_local_rpms omageeko omageeko-settings
fc-cache -f >/dev/null
snap_end

log "Layer 03 done. Run layers/03-omarchy-core/verify.sh"
