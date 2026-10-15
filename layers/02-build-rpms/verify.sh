#!/bin/bash
# Layer 02 - verify built RPMs

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }

for rpm in quickshell owe owe-lockfeed omarchy-hyprland-titlebars hyprland-preview-share-picker jetbrains-mono-nerd-fonts ia-writer-fonts; do
  info=$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$rpm" 2>/dev/null)
  if [[ $info == *omageeko* ]]; then ok "$rpm $info"; else bad "$rpm not installed from omageeko-local"; fi
done

# quickshell runs and passes its own Qt compatibility check (Qt private API)
if quickshell --version &>/dev/null; then ok "quickshell --version"; else bad "quickshell does not start"; fi
if quickshell --private-check-compat &>/dev/null; then ok "quickshell Qt compat check"; else bad "quickshell built against a different Qt: rebuild (OMAGEEKO_REBUILD=quickshell)"; fi

# Titlebars plugin sits where upstream Lua loads it and matches the running Hyprland version
plugin=/usr/lib/omarchy-hyprland-titlebars/titlebars.so
if [[ -f $plugin ]]; then ok "titlebars plugin at $plugin"; else bad "titlebars plugin missing at $plugin"; fi
built_for=$(rpm -q --qf '%{RELEASE}' omarchy-hyprland-titlebars | sed -n 's/.*\.h//p')
hypr=$(rpm -q --qf '%{VERSION}' hyprland)
if [[ $built_for == "$hypr" ]]; then ok "titlebars built for hyprland $hypr"; else bad "titlebars built for $built_for, hyprland is $hypr: rebuild"; fi

for cmd in owed owe owe-idle hyprland-preview-share-picker; do
  if command -v "$cmd" &>/dev/null; then ok "command: $cmd"; else bad "command missing: $cmd"; fi
done
if [[ -f /usr/lib/systemd/user/owed.service ]]; then ok "owed user unit"; else bad "owed user unit missing"; fi
if [[ -f /usr/lib64/qt6/qml/Owe/LockFeed/qmldir ]]; then ok "Owe.LockFeed QML module"; else bad "Owe.LockFeed QML module missing"; fi

families=$(fc-list : family)
for fam in "JetBrainsMono Nerd Font" "iA Writer Mono S" "iA Writer Duo S" "iA Writer Quattro S"; do
  if grep -qF "$fam" <<<"$families"; then ok "font: $fam"; else bad "font missing: $fam"; fi
done

exit $fail
