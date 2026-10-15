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
