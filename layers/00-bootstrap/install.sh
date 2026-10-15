#!/bin/bash
# Layer 00 - bootstrap
# Host prerequisites, Packman codecs, local RPM repo, pinned upstream tree,
# and the omageeko-builder container image.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
LAYER_DIR="$OMAGEEKO_ROOT/layers/00-bootstrap"

PACKMAN_ALIAS="packman-essentials"
PACKMAN_URL="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/"

require_user
snap_begin "00-bootstrap"

# 1. Host tools. Toolchains live in the builder image, not on the host.
zypper_install git-core podman

# 2. Packman Essentials for full codecs (ffmpeg, gstreamer, libav*)
if ! zypper lr "$PACKMAN_ALIAS" &>/dev/null; then
  log "Adding Packman Essentials repo"
  sudo zypper --non-interactive addrepo --refresh --priority 90 "$PACKMAN_URL" "$PACKMAN_ALIAS"
fi
sudo zypper --non-interactive --gpg-auto-import-keys refresh "$PACKMAN_ALIAS"
log "Switching codec packages to Packman (vendor change)"
sudo zypper --non-interactive dist-upgrade --from "$PACKMAN_ALIAS" --allow-vendor-change

# 3. Local RPM repo (filled by layer 02, served to zypper)
if [[ ! -d $OMAGEEKO_REPO_DIR ]]; then
  sudo install -d -o "$USER" -g "$(id -gn)" -m 0755 "$OMAGEEKO_REPO_DIR"
fi
podman image exists "$OMAGEEKO_BUILDER_IMAGE" || NEED_BUILDER=1

# 4. Builder image
if [[ ${NEED_BUILDER:-0} == 1 || ${OMAGEEKO_REBUILD_BUILDER:-0} == 1 ]]; then
  log "Building $OMAGEEKO_BUILDER_IMAGE"
  podman build --pull=newer -t "$OMAGEEKO_BUILDER_IMAGE" -f "$LAYER_DIR/Containerfile" "$LAYER_DIR"
fi

if [[ ! -d $OMAGEEKO_REPO_DIR/repodata ]]; then
  in_builder createrepo_c -q /repo
fi
if ! zypper lr "$OMAGEEKO_REPO_ALIAS" &>/dev/null; then
  log "Registering local repo $OMAGEEKO_REPO_ALIAS"
  # Local, self-built, unsigned: gpgcheck off for this repo only; priority beats OSS
  sudo zypper --non-interactive addrepo --refresh --priority 80 --no-gpgcheck \
    "dir:$OMAGEEKO_REPO_DIR" "$OMAGEEKO_REPO_ALIAS"
fi
sudo zypper --non-interactive refresh "$OMAGEEKO_REPO_ALIAS"

# 5. Pinned upstream omarchy
fetch_upstream

snap_end
log "Layer 00 done. Run layers/00-bootstrap/verify.sh"
