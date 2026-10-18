#!/bin/bash
# Layer 03 - verify omarchy core

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }
check() { local d=$1; shift; if "$@" &>/dev/null; then ok "$d"; else bad "$d"; fi; }

for rpm in omageeko omageeko-settings; do
  info=$(rpm -q --qf '%{VERSION}-%{RELEASE}' "$rpm" 2>/dev/null)
  if [[ $info == *omageeko* ]]; then ok "$rpm $info"; else bad "$rpm not installed"; fi
done

shipped=$(cat /usr/share/omageeko/upstream-commit 2>/dev/null)
if [[ $shipped == "$UPSTREAM_COMMIT" ]]; then ok "installed upstream = upstream.lock (${UPSTREAM_COMMIT:0:12})"; else bad "installed upstream ${shipped:0:12} != lock ${UPSTREAM_COMMIT:0:12}: re-run install.sh"; fi

check "shell tree (/usr/share/omarchy/shell/shell.qml)" test -f /usr/share/omarchy/shell/shell.qml
check "hypr defaults (default/hypr/bootstrap.lua)" test -f /usr/share/omarchy/default/hypr/bootstrap.lua
check "themes present" test -d /usr/share/omarchy/themes
check "mise installed (Omarchy layer)" command -v mise
check "mise repo enabled" zypper --no-refresh lr mise
check "base-devel + mise build headers (map_packages 03)" rpm -q $(map_packages 03)
check "skel user config (hypr/hyprland.lua)" test -f /etc/skel/.config/hypr/hyprland.lua

upstream_bins=$(find "$OMAGEEKO_UPSTREAM/bin" -maxdepth 1 -type f | wc -l)
installed_bins=$(find /usr/bin -maxdepth 1 -name 'omarchy*' | wc -l)
if (( installed_bins >= upstream_bins )); then ok "all $upstream_bins upstream commands installed"; else bad "only $installed_bins of $upstream_bins commands installed"; fi

# No shipped command may still invoke Arch tooling (stubs only mention it in their message)
leftover=()
for f in /usr/bin/omarchy-*; do
  grep -q '^# omageeko: stub' "$f" && continue
  grep -q '^# omageeko: pacman-inside-box' "$f" && continue
  if grep -vE '^[[:space:]]*#' "$f" | grep -qE '(^|[[:space:];&|(`])(sudo +)?(pacman|yay|expac|paccache|checkupdates|makepkg|mkinitcpio|limine[a-z-]*|ufw)([[:space:]]|$)'; then
    leftover+=("$(basename "$f")")
  fi
done
if (( ${#leftover[@]} == 0 )); then ok "no command invokes pacman/yay/limine/mkinitcpio/ufw"; else bad "Arch tooling still invoked by: ${leftover[*]} (port or stub them)"; fi

# The installed name map must match packages.map (prepare.sh regenerates it on every build)
"$OMAGEEKO_ROOT/packages/omageeko/prepare.sh"
if cmp -s "$OMAGEEKO_ROOT/packages/omageeko/pkgmap.tsv" /usr/share/omageeko/pkgmap.tsv; then
  ok "installed pkgmap.tsv matches packages.map"
else
  bad "installed pkgmap.tsv is stale vs packages.map: rebuild omageeko (any layer 03+ install.sh)"
fi

# Package primitives translate Arch names
check "pkg-present jq" omarchy-pkg-present jq
check "pkg-present via map (noto-fonts-emoji, tldr)" omarchy-pkg-present noto-fonts-emoji tldr
check "pkg-missing for skipped yay" omarchy-pkg-missing yay
check "omarchy-version" omarchy-version
check "omarchy CLI router" omarchy --help

# Pending migrations that would do Arch things (relevant after an upstream.lock bump)
audit=$("$OMAGEEKO_ROOT/layers/03-omarchy-core/tools/migration-audit.sh")
if (( $? == 0 )); then ok "no Arch-coupled migrations pending ($(tail -1 <<<"$audit"))"; else bad "Arch-coupled migrations pending: $(grep '^ARCH' <<<"$audit" | tr '\n' ';')"; fi

# Tumbleweed identity and lookups untouched
check "os-release still Tumbleweed" grep -q '^ID="opensuse-tumbleweed"' /etc/os-release
# TW ships nsswitch.conf in /usr/etc; omageeko must not create an Arch-style /etc copy
check "nsswitch untouched (TW /usr/etc, usrfiles)" bash -c '[[ ! -e /etc/nsswitch.conf ]] || grep -q usrfiles /etc/nsswitch.conf'
check "sudoers parse" sudo visudo -cq
# Clean environment: TW's /etc/profile skips profile.d when PROFILEREAD is inherited
check "login shells get OMARCHY_PATH" env -i HOME="$HOME" bash -lc '[[ $OMARCHY_PATH == /usr/share/omarchy ]]'

exit $fail
