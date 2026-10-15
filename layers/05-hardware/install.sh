#!/bin/bash
# Layer 05 - hardware
# Laptop hardware working the Omarchy way on Tumbleweed:
#   - packages for layer 05 in packages.map (bluez, power-profiles-daemon, ...)
#   - Omarchy's own install/hardware/all.sh (vendor fixes gated on hardware
#     matches, Bluetooth, Vulkan) run as root with an omageeko skip-list
#   - bluetooth + power-profiles-daemon enabled
#   - lock screen PAM (omarchy-apply-lock, patched for TW's common-account)
#   - omageeko-hardware RPM: readable names for UCM laptop audio devices
# Fingerprint enrollment is interactive: omarchy-setup-security-fingerprint.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

# Upstream hardware scripts that don't apply on Tumbleweed
HARDWARE_SKIP="pacman.sh"

require_user

check_builder_snapshot
build_packages omageeko bluez-tools

snap_begin "05-hardware"

mapfile -t packages < <(map_packages 05)
zypper_install "${packages[@]}"
install_local_rpms omageeko omageeko-settings omageeko-session omageeko-hardware bluez-tools

log "Running Omarchy's install/hardware scripts (skipping: $HARDWARE_SKIP)"
sudo env OMARCHY_PATH=/usr/share/omarchy OMARCHY_INSTALL=/usr/share/omarchy/install \
  PATH=/usr/share/omarchy/bin:/usr/sbin:/usr/bin:/sbin:/bin HARDWARE_SKIP="$HARDWARE_SKIP" \
  bash -c '
    run_logged() {
      local script=$1 name=${1#"$OMARCHY_INSTALL"/hardware/} skip
      for skip in $HARDWARE_SKIP; do
        if [[ $name == "$skip" ]]; then
          echo "  skip $name"
          return 0
        fi
      done
      echo "  run  $name"
      bash -eE -c "source \"\$1\"" bash "$script"
    }
    source "$OMARCHY_INSTALL/hardware/all.sh"
  '

sudo systemctl enable --now bluetooth.service power-profiles-daemon.service

log "Configuring the lock screen PAM stack"
omarchy-apply-lock

snap_end

# Machine-specific user files (hosts/<DMI product_name>/home), e.g. the monitor layout
host_dir="$OMAGEEKO_ROOT/hosts/$(cat /sys/class/dmi/id/product_name 2>/dev/null)/home"
if [[ -d $host_dir ]]; then
  while IFS= read -r -d '' file; do
    rel=${file#"$host_dir"/}
    if ! cmp -s "$file" "$HOME/$rel"; then
      [[ -e $HOME/$rel ]] && cp -a "$HOME/$rel" "$HOME/$rel.bak.$(date +%s)"
      install -Dm644 "$file" "$HOME/$rel"
      log "Host file: ~/$rel"
    fi
  done < <(find "$host_dir" -type f -print0)
fi

# The audio labels now ship system-wide in omageeko-hardware
rm -f ~/.config/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf
systemctl --user restart wireplumber
# bt-agent is part of the graphical session (uwsm); start it if that session is up
if systemctl --user is-active --quiet graphical-session.target; then
  systemctl --user reset-failed bt-agent.service 2>/dev/null || true
  systemctl --user restart bt-agent.service || true
fi

log "Layer 05 done. Run layers/05-hardware/verify.sh. Fingerprint: omarchy-setup-security-fingerprint"
