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

# The user reset runs once; later runs keep the user's changes. Force with OMAGEEKO_RESET_USER=1.
if [[ ! -f $STATE_DIR/user-provisioned || ${OMAGEEKO_RESET_USER:-0} == 1 ]]; then
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
else
  log "User already provisioned; keeping current dotfiles (OMAGEEKO_RESET_USER=1 to reset)"
fi

# omageeko branding: swap the screensaver text only while it is Omarchy's stock logo
branding=~/.config/omarchy/branding/screensaver.txt
if [[ ! -f $branding ]] || cmp -s "$branding" /usr/share/omageeko/omarchy-logo.txt; then
  install -Dm644 /usr/share/omarchy/logo.txt "$branding"
  log "Screensaver text: omageeko logo"
fi

# fastfetch/About logo: the omageeko mark, swapped only while it is Omarchy's stock logo
about=~/.config/omarchy/branding/about.txt
if [[ ! -f $about ]] || cmp -s "$about" /usr/share/omageeko/omarchy-about.txt; then
  install -Dm644 /etc/skel/.config/omarchy/branding/about.txt "$about"
  log "About/fastfetch logo: omageeko mark"
fi

# Make "Omarchy (Hyprland uwsm)" the default lightdm session for this user.
# lightdm reads AccountsService first and falls back to ~/.dmrc.
if busctl --system call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" \
     org.freedesktop.Accounts.User SetXSession s omarchy &>/dev/null; then
  log "Default lightdm session: omarchy (AccountsService)"
else
  warn "Could not set the AccountsService session; relying on ~/.dmrc"
fi
if [[ -f ~/.dmrc ]] && grep -q '^Session=' ~/.dmrc; then
  sed -i 's/^Session=.*/Session=omarchy/' ~/.dmrc
else
  printf '[Desktop]\nSession=omarchy\n' >> ~/.dmrc
fi

# lightdm runs Tumbleweed's xinitrc.common even for the Wayland session, and its
# /etc/X11/xim starts a second `fcitx5 -d` next to Omarchy's omarchy-fcitx5.service,
# which then fails on the taken D-Bus name and restarts every 2 s. Opt out per user.
if ! grep -q '^export INPUT_METHOD=none' ~/.i18n 2>/dev/null; then
  printf '\n# omageeko: fcitx5 runs as omarchy-fcitx5.service; keep /etc/X11/xim from starting another\nexport INPUT_METHOD=none\n' >> ~/.i18n
  log "Input method: ~/.i18n INPUT_METHOD=none (omarchy-fcitx5.service owns fcitx5)"
fi

touch "$STATE_DIR/user-provisioned"
log "Layer 04 done. Run layers/04-session/verify.sh, then log out and pick 'Omarchy (Hyprland uwsm)' in lightdm."
