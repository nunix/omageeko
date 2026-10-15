#!/bin/bash
# Layer 06 - verify Omarchy shell & menu alignment (parts completed so far)

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
ok() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
bad() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; fail=1; }
check() { local d=$1; shift; if "$@" &>/dev/null; then ok "$d"; else bad "$d"; fi; }

echo "06a: Install / Remove / Update"
check "flatpak installed" command -v flatpak
check "Flathub remote (system)" bash -c 'flatpak remotes --system | grep -q flathub'
check "vendor repo registry shipped" test -s /usr/share/omageeko/repos.tsv
check "native on-demand packages published (voxtype, once, openclaw, omarchy-emacs)" bash -c 'for p in voxtype once openclaw omarchy-emacs; do ls /var/lib/omageeko/repo/*/$p-[0-9]*.rpm >/dev/null || exit 1; done'
check "distrobox + omageeko-box available" bash -c 'command -v distrobox && command -v omageeko-box'
if podman container exists omageeko-arch 2>/dev/null; then
  check "box uses Omarchy's repo" distrobox enter --name omageeko-arch -- grep -q "^\[omarchy\]" /etc/pacman.conf
fi
check "font subpackages published (not installed)" bash -c 'ls /var/lib/omageeko/repo/noarch/iosevka-nerd-fonts-*.rpm'
M=/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc
check "menu: AUR entry is Flathub" grep -q '"install.aur": {[^}]*"label":"Flathub"' "$M"
check "menu: no Arch logo on package entries" bash -c '! grep -E "\"(install|remove)\.package\"" "'"$M"'" | grep -q "󰣇"'
check "menu: only stable/dev channels" bash -c '! grep -qE "\"update\.channel\.(rc|edge)\"" "'"$M"'"'
check "remove-preinstalls only deletes Omarchy mise wrappers (keeps native claude)" grep -q "only delete Omarchy's own mise wrappers" /usr/bin/omarchy-remove-preinstalls
check "update-time uses chrony" grep -q chronyc /usr/bin/omarchy-update-time
audit=$(python3 -I "$OMAGEEKO_ROOT/layers/06-shell/tools/pkgaudit.py" 2>&1); status=$?
summary=$(head -1 <<<"$audit")
if (( status == 0 )); then ok "menu package names: $summary"; else bad "menu package names: $summary"; sed -n '2,$p' <<<"$audit" | grep BROKEN; fi

exit $fail
