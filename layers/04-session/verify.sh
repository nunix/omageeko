#!/bin/bash
# Layer 04 - verify session and user provisioning

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }
check() { local d=$1; shift; if "$@" &>/dev/null; then ok "$d"; else bad "$d"; fi; }
export OMARCHY_PATH=/usr/share/omarchy

# System
check "omageeko-session installed" rpm -q omageeko-session
check "session visible to lightdm (/usr/share/wayland-sessions/omarchy.desktop)" test -f /usr/share/wayland-sessions/omarchy.desktop
check "uwsm env.d/10-omarchy" test -f /usr/share/uwsm/env.d/10-omarchy
check "Hyprland session uwsm targets (hyprland.desktop)" test -f /usr/share/wayland-sessions/hyprland.desktop

check "default lightdm session is omarchy" bash -c 'grep -q "^Session=omarchy" ~/.dmrc'
check "fcitx5 installed (omarchy-fcitx5.service needs it)" command -v fcitx5

# User config
check "hyprland.lua uses the Omarchy bootstrap" grep -q 'default/hypr/bootstrap.lua' ~/.config/hypr/hyprland.lua
# Hyprland 0.56.2 segfaults on hl.timer in --verify-config (no event loop), so
# validate through a wrapper that stubs it; success = exit 0 and "config ok".
wrapper=$(mktemp --suffix=.lua)
printf '%s\n' 'hl.timer = function() end' "dofile(\"$HOME/.config/hypr/hyprland.lua\")" > "$wrapper"
verify_out=$(Hyprland --verify-config -c "$wrapper" 2>&1)
verify_status=$?
rm -f "$wrapper"
if (( verify_status == 0 )) && grep -q '^config ok' <<<"$verify_out"; then
  ok "Hyprland --verify-config (config ok)"
else
  bad "Hyprland --verify-config exit $verify_status: $(sed -n '/parsing result/,$p' <<<"$verify_out" | tail -n +2 | head -3 | tr '\n' ' ')"
fi
check "only omarchy-fcitx5.service starts fcitx5 (~/.i18n INPUT_METHOD=none)" grep -q "^export INPUT_METHOD=none" ~/.i18n
check "~/.bashrc sources Omarchy" grep -q 'default/bash/rc' ~/.bashrc
patterns=$(grep -v '^#' "$OMAGEEKO_ROOT/layers/04-session/carryover.patterns" | grep -v '^$')
if [[ -z $patterns ]] || grep -qEf <(echo "$patterns") ~/.bashrc; then ok "carry-over lines present in ~/.bashrc"; else bad "carry-over lines missing from ~/.bashrc"; fi
check "screensaver shows the omageeko logo" cmp -s ~/.config/omarchy/branding/screensaver.txt /usr/share/omarchy/logo.txt
check "ttfx available for the screensaver" command -v ttfx
check "theme set" test -s ~/.local/state/omarchy/current/theme.name
check "finalize-user marker" omarchy-done check finalize-user
shipped=$(ls "$OMARCHY_PATH"/migrations/*.sh | wc -l)
marked=$(ls ~/.local/state/omarchy/migrations/ 2>/dev/null | wc -l)
if (( marked >= shipped )); then ok "all $shipped migrations marked done"; else bad "$marked of $shipped migrations marked"; fi

# Things that must survive
check "Claude settings kept (~/.claude/settings.json)" test -s ~/.claude/settings.json
if [[ -L ~/.local/bin/claude || ! -e ~/.local/bin/claude ]] || [[ $(sed -n 3p ~/.local/bin/claude) != "mise use -g --quiet "* ]]; then
  ok "native claude not replaced by a mise wrapper"
else
  bad "~/.local/bin/claude was replaced by a mise wrapper"
fi

exit $fail
