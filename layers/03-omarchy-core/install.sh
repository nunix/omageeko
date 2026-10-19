#!/bin/bash
# Layer 03 - omarchy core
# Builds the omageeko RPMs from upstream Omarchy at the pinned commit plus the
# Tumbleweed patches/overlay (packages/omageeko), and installs them:
#   omageeko           omarchy-* commands, /usr/share/omarchy (shell, themes, install, migrations)
#   omageeko-settings  /etc/skel, resync defaults, /etc app defaults, sudoers, fonts, icons, user units
# The running desktop is untouched: the user's Hyprland config switches in layer 04.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user

# Snapper: at most 5 normal and 5 important number snapshots (each one adds a
# boot entry per kernel; data lives remotely, snapshots only guard the system)
SNAPSHOT_LIMIT=5

MISE_REPO_ALIAS="mise"
MISE_REPO_URL="https://mise.jdx.dev/rpm"
MISE_GPG_KEY="https://mise.jdx.dev/gpg-key.pub"

# Spec sync with upstream.lock and pkgmap.tsv generation: packages/omageeko/prepare.sh
# (run by build_packages, so every layer that builds omageeko gets fresh inputs)

# Build and install
check_builder_snapshot
build_packages omageeko

snap_begin "03-omarchy-core"

if sudo snapper list-configs 2>/dev/null | grep -q '^root '; then
  sudo snapper -c root set-config NUMBER_LIMIT=$SNAPSHOT_LIMIT NUMBER_LIMIT_IMPORTANT=$SNAPSHOT_LIMIT
fi

# mise is Omarchy's installer for its default CLI tools and language runtimes
# (omarchy-mise-install, omarchy-install-dev-env, agent account wrappers), so it
# is part of the Omarchy layer: upstream RPM repo (not packaged for Tumbleweed),
# plus base-devel and the headers mise compiles runtimes against (packages.map 03)
if ! zypper lr "$MISE_REPO_ALIAS" &>/dev/null; then
  log "Adding mise repo"
  sudo rpm --import "$MISE_GPG_KEY"
  sudo zypper --non-interactive addrepo --refresh --priority 95 "$MISE_REPO_URL" "$MISE_REPO_ALIAS"
fi
sudo zypper --non-interactive refresh "$MISE_REPO_ALIAS" >/dev/null
mapfile -t packages < <(map_packages 03)
zypper_install mise "${packages[@]}"

install_local_rpms omageeko omageeko-settings
fc-cache -f >/dev/null
omageeko-link-skills
snap_end

log "Layer 03 done. Run layers/03-omarchy-core/verify.sh"
