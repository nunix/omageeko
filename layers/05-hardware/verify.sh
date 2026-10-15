#!/bin/bash
# Layer 05 - verify hardware

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }
info() { printf '  \e[33minfo\e[0m %s\n' "$1"; }
check() { local d=$1; shift; if "$@" &>/dev/null; then ok "$d"; else bad "$d"; fi; }

check "omageeko-hardware installed" rpm -q omageeko-hardware

# Bluetooth
check "bluetooth.service active" systemctl is-active bluetooth.service
check "bt-agent installed (bluez-tools)" command -v bt-agent
if systemctl --user is-active --quiet graphical-session.target; then
  check "pairing agent running (bt-agent.service)" systemctl --user is-active bt-agent.service
else
  info "not in the uwsm session: bt-agent.service starts with graphical-session.target"
fi
check "Bluetooth controller visible" bash -c 'bluetoothctl show | grep -q "Controller"'

# Power profiles
check "power-profiles-daemon active" systemctl is-active power-profiles-daemon.service
profiles=$(powerprofilesctl list 2>/dev/null | grep -oE '^[ *]+[a-z-]+:' | tr -d ' *:' | tr '\n' ' ')
if [[ $profiles == *performance* && $profiles == *power-saver* ]]; then ok "power profiles: $profiles"; else bad "power profiles incomplete: $profiles"; fi

# Audio: laptop codec devices carry readable names
nicks=$(pw-dump 2>/dev/null | jq -r '.[] | .info.props? // empty | select(."node.name"? // "" | test("^alsa_.*pci-.*HiFi__(Headphones|Speaker|Mic1|Mic2)__")) | ."node.nick"')
if [[ -n $nicks ]] && ! grep -qiE 'analog|ALC[0-9]' <<<"$nicks"; then ok "audio device names: $(tr '\n' ',' <<<"$nicks" | sed 's/,$//')"; else bad "laptop audio devices still use codec names: $(tr '\n' ',' <<<"$nicks")"; fi

# Lock screen PAM: file present and every included stack exists on TW
if [[ -f /etc/pam.d/omarchy-lock-password ]]; then
  missing=$(awk '$2 == "include" { print $3 }' /etc/pam.d/omarchy-lock-password | while read -r inc; do
    [[ -e /etc/pam.d/$inc || -e /usr/lib/pam.d/$inc ]] || echo "$inc"; done)
  if [[ -z $missing ]]; then ok "lock screen PAM (includes resolve)"; else bad "lock PAM includes missing stacks: $missing"; fi
else
  bad "lock screen PAM missing (/etc/pam.d/omarchy-lock-password)"
fi

# Fingerprint reader driven by libfprint (enrollment is a manual step)
check "fingerprint reader seen by fprintd" bash -c 'fprintd-list "$USER" 2>&1 | grep -q "found 1 devices"'
if [[ -f /etc/pam.d/omarchy-lock-fingerprint ]]; then ok "fingerprint enrolled and wired into PAM"; else info "fingerprint not set up yet: run omarchy-setup-security-fingerprint"; fi

# omageeko policy: fingerprint unlocks the lock screen only; sudo/polkit stay password-only
fp_in_auth=$(grep -ls pam_fprintd /etc/pam.d/sudo /etc/pam.d/polkit-1 /etc/pam.d/common-auth 2>/dev/null)
if [[ -z $fp_in_auth ]]; then ok "fingerprint not used by sudo/polkit/common-auth (lock screen only)"; else bad "pam_fprintd found in: $fp_in_auth (omageeko keeps sudo/polkit password-only)"; fi

check "AMD Vulkan driver" rpm -q libvulkan_radeon

exit $fail
