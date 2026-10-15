# Layer 04 — notes

Status: **installed and verified 2026-10-15** (snapper pairs from #47 on). **Waiting on the manual login test.**

## Results
- Backup of the pre-Omarchy dotfiles: `~/.local/state/omageeko/backups/pre-04-20261015-074010.tar.gz` (4 paths).
- `~/.bashrc` is Omarchy's, plus the carried-over Google Cloud SDK path/completion lines.
- Theme `tokyo-night`. All 169 migrations marked done. Default browser is resolved through Omarchy (`omarchy-browser.desktop` → Chromium).
- mise: Node 26 installed, ~20 CLI wrappers written to `~/.local/bin` (codex, crush, gh, opencode, …). `claude` kept as the native 2.1.300 install.
- Omarchy skills symlinked into `~/.claude/skills` (and other agents' dirs) by provision-user. `settings.json` unchanged.

## Watch during the login test
- TW Chromium's WM class is `Chromium-browser` (Arch: `chromium`). Omarchy window rules or web-app matching may need a tweak (layer 05).
- `hyprland-preview-share-picker`, owe (wallpaper) and the titlebars plugin load from the session for the first time.
- First-run tasks (`omarchy-provision-first-run`) enable the user units (owed, bt-agent, omarchy-*) and set GTK/gsettings.

## Hyprland bug found
- `Hyprland --verify-config` segfaults when the config calls `hl.timer` (Omarchy's startup-cursor does this in `config.reloaded`). Real sessions are unaffected. Upstream Hyprland candidate report.
