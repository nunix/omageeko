#!/bin/bash
# omageeko: list Omarchy migrations not yet run for this user and flag the ones that
# would do Arch-specific things on Tumbleweed. Run it after bumping upstream.lock,
# before the next login or `omarchy update` (omarchy-migrate runs pending migrations).
#   exit 0: nothing pending, or only portable migrations pending
#   exit 1: Arch-coupled migrations pending -> review, then patch or mark them done:
#           touch ~/.local/state/omarchy/migrations/<name>.sh
set -u
migrations=${OMARCHY_PATH:-/usr/share/omarchy}/migrations
done_dir=$HOME/.local/state/omarchy/migrations
arch_re='\b(pacman|yay|makepkg|expac|paccache|mkinitcpio|limine[a-z-]*|ufw|systemd-resolved|archlinux|/etc/pacman)'
pending=0 flagged=0
for m in "$migrations"/*.sh; do
  name=${m##*/}
  [[ -e $done_dir/$name ]] && continue
  pending=$((pending + 1))
  hits=$(grep -vE '^\s*#' "$m" | grep -oE "$arch_re" | sort -u | tr '\n' ' ')
  if [[ -n $hits ]]; then
    flagged=$((flagged + 1))
    printf 'ARCH     %s  (%s)\n' "$name" "${hits% }"
  else
    printf 'portable %s\n' "$name"
  fi
done
echo "pending=$pending arch-coupled=$flagged"
(( flagged == 0 ))
