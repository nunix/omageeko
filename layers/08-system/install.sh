#!/bin/bash
# Layer 08 - system (memory and scheduling part)
# Omarchy's memory and scheduling stack on the stock Tumbleweed kernel, through
# the omageeko-system RPM (its Requires pull in zram-generator,
# systemd-experimental for systemd-oomd, and scx):
#   - swap on zram (zstd), above the disk swap; zswap off
#   - Omarchy's reclaim/writeback sysctls, BBR + fq, inotify limits
#   - systemd-oomd: kills user apps (app.slice) under sustained memory pressure
#   - Kyber I/O scheduler on whole disks
#   - multi-gen LRU on (built into Omarchy's kernel)
#   - sched_ext scx_lavd --autopower in place of Omarchy's BORE kernel patch
# The rest of layer 08 (printing, mDNS, podman, firewalld, ...) is not ported yet,
# so this deliberately does not install map_packages 08.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

require_user

check_builder_snapshot
build_packages omageeko

snap_begin "08-system"

install_local_rpms omageeko omageeko-settings omageeko-session omageeko-system

# zram0 comes from a generator: reload, then start it now rather than at the
# next boot (as Omarchy's migration 1790984500 does)
sudo systemctl daemon-reload
if ! systemctl is-active --quiet dev-zram0.swap; then
  sudo systemctl start dev-zram0.swap
fi

# dbus-broker reloads its policy as soon as systemd-experimental's files land,
# before sysusers creates systemd-oom, and then rejects oomd's bus name until
# the next reload ("Invalid user-name ... systemd-oom"). Reload it now.
sudo busctl call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
sudo systemctl enable systemd-oomd.service
sudo systemctl restart systemd-oomd.service
# The user manager reads app.slice.d/10-oomd.conf (oomd's kill policy) on reload
systemctl --user daemon-reload
sudo systemctl enable scx.service
# scx.service allows 2 starts per 30 s; a rerun right after an install would trip it
sudo systemctl reset-failed scx.service 2>/dev/null || true
sudo systemctl restart scx.service
# scx_lavd needs a few seconds to load its BPF programs
for _ in {1..20}; do
  [[ $(cat /sys/kernel/sched_ext/state 2>/dev/null) == enabled ]] && break
  sleep 0.5
done
[[ $(cat /sys/kernel/sched_ext/state 2>/dev/null) == enabled ]] || warn "sched_ext not enabled yet: journalctl -u scx"

snap_end

log "Layer 08 (system: memory and scheduling) done. Run layers/08-system/verify.sh"
