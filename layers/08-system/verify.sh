#!/bin/bash
# Layer 08 - verify system (memory and scheduling part)

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }
info() { printf '  \e[33minfo\e[0m %s\n' "$1"; }
check() { local d=$1; shift; if "$@" &>/dev/null; then ok "$d"; else bad "$d"; fi; }

check "omageeko-system installed" rpm -q omageeko-system

# Swap on zram, preferred over the disk swap; zswap off in front of it
check "zram0 swap active" systemctl is-active dev-zram0.swap
check "zram0 compresses with zstd" grep -q '\[zstd\]' /sys/block/zram0/comp_algorithm
zram_prio=$(awk '$1 == "/dev/zram0" { print $5 }' /proc/swaps)
if [[ $zram_prio == 100 ]]; then ok "zram0 swap priority 100"; else bad "zram0 swap priority is '${zram_prio:-none}', expected 100"; fi
check "zswap off" grep -qx N /sys/module/zswap/parameters/enabled

# Multi-gen LRU, every component (Omarchy's kernel default)
check "multi-gen LRU enabled (0x0007)" grep -qx 0x0007 /sys/kernel/mm/lru_gen/enabled

# Every value in Omarchy's sysctl files is live, unless /etc overrides that key
for file in /usr/lib/sysctl.d/99-omarchy-sysctl.conf /usr/lib/sysctl.d/90-omarchy-file-watchers.conf; do
  [[ -f $file ]] || { bad "missing $file"; continue; }
  while IFS='=' read -r key value; do
    key=${key//[[:space:]]/}
    value=${value//[[:space:]]/}
    [[ -z $key || $key == \#* ]] && continue
    if grep -qsE "^[[:space:]]*${key//./\\.}[[:space:]]*=" /etc/sysctl.d/*.conf /etc/sysctl.conf; then
      info "$key overridden in /etc"
      continue
    fi
    live=$(tr -s '[:space:]' ' ' <"/proc/sys/${key//.//}" 2>/dev/null)
    live=${live% }
    if [[ $live == "$value" ]]; then ok "$key = $value"; else bad "$key is '$live', expected '$value'"; fi
  done <"$file"
done

# Kyber on whole disks (nvme, sd, mmcblk, vd)
for queue in /sys/block/{nvme*,sd*,mmcblk*,vd*}/queue/scheduler; do
  [[ -f $queue ]] || continue
  disk=${queue#/sys/block/}
  disk=${disk%%/*}
  if grep -q '\[kyber\]' "$queue"; then ok "$disk I/O scheduler kyber"; else bad "$disk I/O scheduler: $(cat "$queue")"; fi
done

# systemd-oomd with Omarchy's policy: only app.slice is a kill candidate
check "systemd-oomd active" systemctl is-active systemd-oomd.service
check "oomd pressure limit from Omarchy (50% for 20s)" bash -c 'systemd-analyze cat-config systemd/oomd.conf | grep -q "^DefaultMemoryPressureLimit=50%"'
# The user manager registers with oomd when it starts, so a session older than
# systemd-oomd only shows up after the next login.
if oomctl 2>/dev/null | grep -q "app.slice"; then
  ok "app.slice monitored by systemd-oomd"
elif [[ $(systemctl --user show app.slice -p ManagedOOMMemoryPressure --value 2>/dev/null) == kill ]]; then
  info "app.slice has the oomd kill policy; it registers with systemd-oomd at the next login"
else
  bad "app.slice has no oomd kill policy (user manager not reloaded?)"
fi

# sched_ext: scx_lavd loaded through scx.service
check "scx.service enabled" systemctl is-enabled scx.service
check "scx.service active" systemctl is-active scx.service
# scx_lavd takes a few seconds to load after a (re)start
for _ in {1..20}; do
  state=$(cat /sys/kernel/sched_ext/state 2>/dev/null)
  [[ $state == enabled ]] && break
  sleep 0.5
done
ops=$(cat /sys/kernel/sched_ext/root/ops 2>/dev/null)
if [[ $state == enabled && $ops == lavd* ]]; then ok "sched_ext running $ops"; else bad "sched_ext state '${state:-?}', ops '${ops:-none}' (expected lavd)"; fi

# SELinux: nothing from this layer denied since boot
denials=$(sudo journalctl -k -b --no-pager -g 'avc:.*denied' 2>/dev/null | grep -cE 'oomd|zram|scx|lavd')
if (( denials == 0 )); then ok "no SELinux denials for oomd/zram/scx this boot"; else bad "$denials SELinux denials for oomd/zram/scx this boot (journalctl -k -g avc)"; fi

exit $fail
