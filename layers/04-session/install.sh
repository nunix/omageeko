#!/bin/bash
# Layer 04 - session
# System: omageeko-session (uwsm session "Omarchy (Hyprland uwsm)", uwsm env,
#         keep-shell drop-in); rebuilds omageeko for the mise-install patch.
# User:   resets dotfiles from /etc/skel (Omarchy defaults), keeps a backup and
#         carries chosen ~/.bashrc lines over, marks shipped migrations done and
#         runs omarchy-provision-user (theme, git, XCompose, mise wrappers, ...).
# ~/.claude and ~/.claude.json are never touched.

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
LAYER_DIR="$OMAGEEKO_ROOT/layers/04-session"
STATE_DIR="$HOME/.local/state/omageeko"
CARRY_BEGIN="# >>> omageeko carry-over (layers/04-session/carryover.patterns) >>>"
CARRY_END="# <<< omageeko carry-over <<<"

require_user

# ---- System
check_builder_snapshot
build_packages omageeko
snap_begin "04-session"
# Layer 04 packages from packages.map (uwsm, hyprland, chromium: provision-user makes it the default browser)
mapfile -t packages < <(map_packages 04)
zypper_install "${packages[@]}"
install_local_rpms omageeko omageeko-settings omageeko-session
snap_end

# ---- User
export OMARCHY_PATH=/usr/share/omarchy
mkdir -p "$STATE_DIR/backups"

# Identity for git.sh / xcompose.sh: env, then git, then GitHub, then GECOS
OMARCHY_USER_NAME=${OMAGEEKO_USER_NAME:-$(git config --global user.name || true)}
OMARCHY_USER_EMAIL=${OMAGEEKO_USER_EMAIL:-$(git config --global user.email || true)}
if [[ -z $OMARCHY_USER_NAME || -z $OMARCHY_USER_EMAIL ]] && gh auth status &>/dev/null; then
  : "${OMARCHY_USER_NAME:=$(gh api user --jq '.name // empty')}"
  : "${OMARCHY_USER_EMAIL:=$(gh api user --jq '.email // empty')}"
fi
: "${OMARCHY_USER_NAME:=$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)}"
export OMARCHY_USER_NAME OMARCHY_USER_EMAIL
log "User identity: ${OMARCHY_USER_NAME:-?} <${OMARCHY_USER_EMAIL:-?}>"

claude_sum=$(sha256sum ~/.claude/settings.json 2>/dev/null | cut -d' ' -f1)

# Lines to carry over from the current ~/.bashrc (skip an earlier carry-over block's markers)
carry=""
if [[ -f ~/.bashrc ]]; then
  carry=$(grep -v '^#' "$LAYER_DIR/carryover.patterns" | grep -v '^$' | grep -Ef - ~/.bashrc | grep -vxF -e "$CARRY_BEGIN" -e "$CARRY_END" || true)
fi

# Keep a running Hyprland from live-reloading the config files we replace
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl &>/dev/null; then
  hyprctl eval 'hl.config({ misc = { disable_autoreload = true } })' &>/dev/null || true
fi

# Backup once, before the very first reset (/home is not covered by snapper)
if ! compgen -G "$STATE_DIR/backups/pre-04-*.tar.gz" >/dev/null; then
  backup="$STATE_DIR/backups/pre-04-$(date +%Y%m%d-%H%M%S).tar.gz"
  paths=()
  while IFS= read -r rel; do
    [[ -e $HOME/$rel ]] && paths+=("$rel")
  done < <(cd /etc/skel && find . -mindepth 1 -maxdepth 2 \( -path ./.config -o -path ./.local -o -path ./.local/state -o -path ./.local/share \) -prune -o -print; \
           cd /etc/skel && find .config .local/share .local/state -mindepth 1 -maxdepth 1)
  if (( ${#paths[@]} )); then
    tar -C "$HOME" -czf "$backup" "${paths[@]}"
    log "Backed up ${#paths[@]} existing dotfile paths to $backup"
  fi
fi

# Reset to Omarchy defaults (what omarchy-reinstall-configs does, without the boot refreshes)
log "Copying Omarchy defaults from /etc/skel"
cp -af /etc/skel/. "$HOME/"

if [[ -n $carry ]]; then
  printf '\n%s\n%s\n%s\n' "$CARRY_BEGIN" "$carry" "$CARRY_END" >> ~/.bashrc
  log "Carried over $(wc -l <<<"$carry") line(s) into ~/.bashrc"
fi

# A fresh account has nothing to migrate: mark every shipped migration done
mkdir -p ~/.local/state/omarchy/migrations
for migration in "$OMARCHY_PATH"/migrations/*.sh; do
  touch ~/.local/state/omarchy/migrations/"$(basename "$migration")"
done

# Omarchy's per-user finalize (runtime context; headless theme so nothing live reloads)
log "Running omarchy-provision-user"
OMARCHY_THEME_HEADLESS=1 PATH="$OMARCHY_PATH/bin:$PATH" omarchy-provision-user --force 2>&1 | tee "$STATE_DIR/provision-user.log"
(( PIPESTATUS[0] == 0 )) || die "omarchy-provision-user failed (log: $STATE_DIR/provision-user.log)"

if [[ $(sha256sum ~/.claude/settings.json 2>/dev/null | cut -d' ' -f1) != "$claude_sum" ]]; then
  die "~/.claude/settings.json changed during provisioning; check it"
fi

touch "$STATE_DIR/user-provisioned"
log "Layer 04 done. Run layers/04-session/verify.sh, then log out and pick 'Omarchy (Hyprland uwsm)' in lightdm."
