# omaweed archive

`omaweed` was the earlier attempt at Omarchy on openSUSE: a branch in `nunix/omarchy-mac` (fork of omacom/omarchy), 4 commits on top of `quattro` (see `COMMITS`). It was retired on 2026-10-15 in favour of omageeko. This directory keeps its unique work so the branch can be deleted.

## Contents

| File | What it is |
|---|---|
| `omaweed-vs-quattro.diff` | the full branch diff against upstream quattro at the time of archiving |
| `install-omaweed.sh` | one-shot Tumbleweed installer: pacman shims, opi, SDDM, polkit, WayVNC, sed patches over /usr/share/omarchy |
| `install-omatomic.sh` | installer for openSUSE MicroOS / Aeon (immutable, `transactional-update`, rootless userland). Reference if immutable openSUSE becomes a target |
| `bin/omarchy-agent-usage-agy` | Antigravity / Vertex AI and Hermes usage collector (ported) |
| `shell/plugins/agents/assets/*.svg` | agy and Hermes icons (ported) |
| `logo.txt` | the Omaweed wordmark |

## Ported to omageeko

| omaweed change | omageeko implementation |
|---|---|
| agy + Hermes usage provider and icons | `packages/omageeko/overlay/bin/omarchy-agent-usage-{agy,hermes}` and `overlay/shell/plugins/agents/assets/`. Fix added: an all-zero balance is no longer emitted, because upstream's panel would otherwise show empty tabs for agents never used |
| Vertex model names in the agents panel | patch `shell-agents-main-vertex-names.patch`: strips `google/`, `vertex/`, `anthropic/` prefixes and `@YYYYMMDD` suffixes |
| estimated-spend text for unfunded agents | patch `shell-agents-panel-estimated-spend.patch` |
| Remove › Flatpak picker | `overlay/bin/omarchy-pkg-flatpak-remove` (system and user installs) + `menu-transform.py` INSERT |
| Install › OPI picker | `overlay/bin/omarchy-pkg-opi-install` (installs opi on first use) + `menu-transform.py` INSERT |
| monitors disabled from the panel stay off for the session | patches `shell-monitor-panel-session-disable.patch` (name passed as an argument, not spliced into shell) and `hypr-toggles-session-disabled-monitors.patch` (re-applied after monitors.lua, from `$XDG_RUNTIME_DIR`) |
| migration guard (systemd-resolved restart) | generalised: `layers/03-omarchy-core/tools/migration-audit.sh` flags pending Arch-coupled migrations after an upstream bump, and layer 03 verify fails on them |

## Superseded (upstream or omageeko already does it better)

- **zypper ports of `omarchy-pkg-*`:** omageeko's also translate Arch names, use vendor repos, Flathub and the Arch box, and parse zypper tables robustly.
- **AI desktop apps as web apps** (ChatGPT, Grok, T3) and LM Studio via Flatpak: omageeko installs Omarchy's own builds through the box.
- **Agents panel carousel/dropdown, default-agent preselect, IPC next/prev/select:** upstream rewrote the panel (multi-account, ordering, keyboard navigation).
- **Monitor panel `hyprctl keyword` → `eval`:** upstream fixed it.
- **Hermes desktop launcher cleanup:** upstream added it.
- **AUR reachability → OBS:** nothing calls `omarchy-pkg-aur-accessible` anymore.
- **Shell restart dispatch quoting:** upstream's form works on Hyprland 0.56.2.
- **Pacman shims, `/usr/local/bin` symlinks, sed patches over /usr/share/omarchy:** replaced by omageeko RPMs, overlay and fuzz-0 patches.
- **SwayOSD, waybar, rofi, hypridle/hyprlock, dua:** quattro's Quickshell desktop and disktree cover them.

## Not ported (decided 2026-10-15)

- **WayVNC remote access:** omaweed bound `0.0.0.0:5900` with no password. Not wanted now; if revived, use localhost or auth plus firewalld.
- **Loupe as the image viewer:** omageeko keeps Omarchy's imv.
- **"Omaweed" window title, `omarchy-shell --any-display`:** not needed.
- **Polkit rule allowing power actions to the `users` group:** TW's defaults already allow them for the active session, and the rule would extend them to remote sessions.
- **WSL2 restart guard, rfkill guard, snapper non-btrfs guard:** not relevant to this hardware.
- **sddm:** omageeko keeps lightdm.
