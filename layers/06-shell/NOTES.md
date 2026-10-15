# Layer 06 — notes

## 06a (2026-10-15) — done, verified; menu walk-through with the user pending
- Audit before: 22 of 83 names resolved. After: 62 resolved, 14 explicitly "not ported yet", 0 broken.
- All vendor repos and keys were checked to be live: each repo publishes the mapped package, and each key URL serves a PGP key.
- Not ported yet (Omarchy/AUR repackages without a TW, vendor or Flathub source): claude-desktop, openai-codex-desktop, hermes-desktop, t3code-bin, grok-bot, perplexity, once-bin, openclaw, lmstudio-bin, omazed, omarchy-emacs, voxtype-bin, symfony-cli. Candidates for `@build` ports from omarchy-pkgs later.
- Install scripts may do more than install a package (browser policy dirs, 1Password browser integration, Dropbox autostart). Those paths get checked entry by entry during the menu walk-through.
- `nautilus-dropbox` maps to `@none`: Flathub's Dropbox has no Nautilus extension.

## 06a follow-up: not-yet-ported apps (2026-10-15)
- Feasibility: all 14 exist prebuilt in Omarchy's stable repo (237 packages). Prototype: Claude Desktop in an Arch distrobox ran as a native Wayland window with GPU and was exported to the launcher. Adopted as `omageeko-arch`.
- Hybrid implemented: 9 box apps, 4 native (voxtype vendor RPM, once, openclaw, omarchy-emacs), symfony-cli vendor repo. Audit: 75 resolved, 1 later (superwhisper-bin, proprietary), 0 broken.
- Round trip tested through `omarchy-pkg-add/present/drop` with `omazed` (box install, export, run on host, removal, state cleanup).
- Prototype artifact removed: a manual `distrobox-export --app claude` had matched the native Claude Code URL handler (shared $HOME) and exported a bogus copy.

## Zed theming (2026-10-15)
- omazed (box) generates `~/.config/zed/themes/omazed.json` from the current Omarchy theme (`~/.local/state/omarchy/current/theme/colors.toml`). `theme-set.d/omazed` runs `omazed set` on every theme switch; Zed reloads theme files live.
- Bug found (upstream too): omazed points Zed at "Omazed" once, then writes a marker (`~/.local/share/omazed/initialized`). That happened before Zed's first launch, and Zed's onboarding rewrote settings to "One Dark", so the Omarchy theme was never active. Fixed for the user (marker cleared plus `omazed sync`). The installer patch re-selects Omazed if onboarding overwrites it within 2 minutes.
- Manual recovery: `rm ~/.local/share/omazed/initialized && omazed sync`.

## 06b (2026-10-15) — done, verified
- Top-down menu review. Already working: Apps; Style (themes, backgrounds, fonts, look, screensaver, About); Trigger toggles, emoji, clipboard, reminders, OCR, colour picker, transcode; Setup monitors/keybindings/input/defaults/plugins/config/fingerprint; System lock/suspend/logout/reboot/**reboot-to-boot-menu** (systemd-boot)/shutdown.
- Fixed by 06b: screenshots (omasnap), file manager (nautilus, + sushi previews, python extensions), Share (localsend CLI), screen recording webcam overlay (v4l2-ctl), media (mpv, imv), PDF (evince), disks, herdr launcher/keybindings, Neovim (LazyVim, 52 plugins, Omarchy theme link).
- Still open: 06c Trigger details (speed tests, hardware toggles); 06d Setup: `omarchy-locale-generate` (locale-gen, Arch), `omarchy-setup-direct-boot` (limine/UKI EFI entry; meaningless on systemd-boot), sudoless docker → podman, DNS live test; 06e Learn (Arch wiki → openSUSE). Later layers: plymouth (Style › Unlock), factory reset, sshd/firewalld, hibernation.
- Share limitation: files must be under $HOME or /tmp (box mounts).

## omaweed port (2026-10-15)
- See `archive/omaweed/README.md`. Ported: agy/Hermes usage, Vertex model names, estimated spend, Remove › Flatpak, Install › OPI, session-persistent monitor disable, migration audit. `menu-transform.py` gained INSERT rules.
- Not visually verified yet: the monitor panel persistence (disable a display, switch theme, it should stay off) and the new menu entries.
