# Agent prompt — omageeko layer 04: session

You are rebuilding layer 04 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00–03 must verify. This is the first layer that changes the user's desktop. Read `packages/omageeko/overlay/INDEX.md`.

## Goal

1. **System:** install `map_packages 04` (uwsm, hyprland, chromium) and the `omageeko-session` RPM (built from `packages/omageeko/omageeko.spec`):
   - `/usr/share/wayland-sessions/omarchy.desktop` ("Omarchy (Hyprland uwsm)", running `uwsm start -g -1 -e -D Hyprland hyprland.desktop`)
   - `/usr/share/uwsm/env.d/10-omarchy` (uwsm sources `uwsm/env.d/*` from the XDG config and data dirs)
   - `/etc/systemd/user/wayland-wm@hyprland.desktop.service.d/10-keep-shell.conf`
   - The display manager stays **lightdm** (user decision); it lists `/usr/share/wayland-sessions` automatically.
2. **User:** turn the (fresh) account into an Omarchy account:
   - Disable live config reload in a running Hyprland: `hyprctl eval 'hl.config({ misc = { disable_autoreload = true } })'`. (`hyprctl keyword` doesn't work with the Lua parser.)
   - Back up, **once**, every existing path `/etc/skel` would overwrite to `~/.local/state/omageeko/backups/pre-04-*.tar.gz`. `/home` is XFS and not covered by snapper.
   - Copy defaults with `cp -af /etc/skel/. ~/`, the same as `omarchy-reinstall-configs` minus the boot refreshes.
   - Carry lines matching `layers/04-session/carryover.patterns` (e.g. `google-cloud-sdk`) from the old `~/.bashrc` into an omageeko-marked block at the end of the new one.
   - Mark every shipped migration done (`~/.local/state/omarchy/migrations/*`).
   - Run `OMARCHY_THEME_HEADLESS=1 omarchy-provision-user --force` with `OMARCHY_USER_NAME/EMAIL` from env, then git config, then the GitHub profile (`gh api user`), then GECOS. **Don't** use `--first-install`: it switches to the ISO-chroot context, which expects bundled Node tarballs.
   - Never touch `~/.claude` or `~/.claude.json`. The script fails if `~/.claude/settings.json` changes.

## Fixes this layer needed (now in the omageeko spec / map)

- `omageeko` `Requires: xdg-user-dirs libnotify-tools`. Arch pulls these in implicitly, and provision-user calls `xdg-user-dirs-update`.
- `chromium` moved to layer 04 in `packages.map`: provision-user sets it as the default browser.
- A hidden `/usr/share/applications/chromium.desktop` alias, because TW names the file `chromium-browser.desktop`.
- Patch `omarchy-mise-install`: keep an existing non-wrapper `~/.local/bin/<cmd>`. Otherwise `install/user/mise.sh` deletes a native Claude Code install and replaces it with a mise wrapper.
- Every spec now has `Release: …%{?dist}`, and `build-rpm.sh` defines `dist` as `.bYYYYMMDDHHMMSS`. Each rebuild is a newer release, so zypper actually upgrades it (a same-NVR rebuild is silently not installed).

## Verification

`layers/04-session/verify.sh` must exit 0. It checks:
- the session RPM and files
- that `hyprland.lua` uses the bootstrap
- `Hyprland --verify-config` through a wrapper that stubs `hl.timer` (Hyprland 0.56.2 segfaults on `hl.timer` in verify mode because there's no event loop). Success means exit 0 plus `config ok`.
- the `.bashrc` source line and the carry-over block, the theme, the finalize-user marker and all migrations marked
- that Claude settings are kept and the native `claude` is not replaced

**Manual test:** log out, pick "Omarchy (Hyprland uwsm)" in lightdm, log in. The Omarchy desktop should come up (Quickshell bar, Tokyo Night). Fallbacks: the IceWM session in lightdm, or a TTY (Ctrl+Alt+F3).
