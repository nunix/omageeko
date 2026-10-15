#!/bin/bash
# Layer 03 - omarchy core
# Builds the omageeko RPMs from upstream Omarchy at the pinned commit plus the
# Tumbleweed patches/overlay (packages/omageeko), and installs them:
#   omageeko           omarchy-* commands, /usr/share/omarchy (shell, themes, install, migrations)
#   omageeko-settings  /etc/skel, resync defaults, /etc app defaults, sudoers, fonts, icons, user units
# The running desktop is untouched: the user's Hyprland config switches in layer 04.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
SPEC="$OMAGEEKO_ROOT/packages/omageeko/omageeko.spec"
PKGMAP="$OMAGEEKO_ROOT/packages/omageeko/pkgmap.tsv"

require_user

# 1. Sync the spec with upstream.lock (commit, date, release)
commit_date=${UPSTREAM_COMMIT_DATE%%T*}
sed -i -E \
  -e "s/^%global commit .*/%global commit $UPSTREAM_COMMIT/" \
  -e "s/^%global commit_date .*/%global commit_date ${commit_date//-/}/" \
  -e "s/^%global upstream_release .*/%global upstream_release ${UPSTREAM_RELEASE#v}/" \
  "$SPEC"

# 2. pkgmap.tsv for the omarchy-pkg-* ports: <arch-name> <target> <note>
awk '!/^#/ && NF >= 3 && $1 !~ /^\+/ {
  note = ""
  if ((i = index($0, "#")) > 0) { note = substr($0, i + 1); sub(/^ +/, "", note) }
  printf "%s\t%s\t%s\n", $1, $3, note
}' "$OMAGEEKO_ROOT/packages.map" > "$PKGMAP"

# 3. Build and install
check_builder_snapshot
build_packages omageeko

snap_begin "03-omarchy-core"
install_local_rpms omageeko omageeko-settings
fc-cache -f >/dev/null
snap_end

log "Layer 03 done. Run layers/03-omarchy-core/verify.sh"
