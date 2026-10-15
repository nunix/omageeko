#!/bin/bash
# Layer 01 - verify base packages

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }

# Every upstream base package is accounted for in packages.map
unmapped=$(comm -23 \
  <(grep -vE '^\s*(#|$)' "$OMAGEEKO_UPSTREAM/install/omarchy-base.packages" | sed 's/\s*#.*//' | sort -u) \
  <(awk '!/^#/ && NF && $1 !~ /^\+/ { print $1 }' "$OMAGEEKO_ROOT/packages.map" | sort -u))
if [[ -z $unmapped ]]; then ok "packages.map covers upstream base list"; else bad "unmapped upstream packages: $(echo $unmapped)"; fi

# All layer 01 packages installed
missing=()
for pkg in $(map_packages 01) mise; do
  rpm -q --whatprovides "$pkg" &>/dev/null || missing+=("$pkg")
done
if (( ${#missing[@]} == 0 )); then ok "all layer 01 packages installed"; else bad "missing: ${missing[*]}"; fi

# Key commands run
for cmd in bat btop eza fd fzf rg zoxide starship fastfetch lazygit gum jq nvim tldr tmux mise foot wl-copy grim slurp hyprpicker magick tesseract ffmpeg yt-dlp; do
  command -v "$cmd" &>/dev/null || { bad "command missing: $cmd"; continue; }
done
(( fail == 0 )) && ok "key commands present"

# ffmpeg is the Packman build with H.264 encoding.
# Capture output first: with pipefail, grep -q closing the pipe early SIGPIPEs the producer.
encoders=$(ffmpeg -hide_banner -encoders 2>/dev/null)
if [[ $encoders == *libx264* ]]; then ok "ffmpeg has libx264"; else bad "ffmpeg lacks libx264"; fi

# Fonts Omarchy relies on (Nerd JetBrains Mono comes in layer 02)
families=$(fc-list : family)
for fam in "Noto Sans" "Noto Serif" "Noto Sans CJK SC" "Noto Color Emoji" "Symbols Nerd Font" "Font Awesome"; do
  if grep -qiF "$fam" <<<"$families"; then ok "font: $fam"; else bad "font missing: $fam"; fi
done

exit $fail
