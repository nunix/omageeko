# Layer 06 — notes

## 06a (2026-10-15) — done, verified; menu walk-through with the user pending
- Audit before: 22 of 83 names resolved. After: 62 resolved, 14 explicitly "not ported yet", 0 broken.
- All vendor repos and keys were checked to be live: each repo publishes the mapped package, and each key URL serves a PGP key.
- Not ported yet (Omarchy/AUR repackages without a TW, vendor or Flathub source): claude-desktop, openai-codex-desktop, hermes-desktop, t3code-bin, grok-bot, perplexity, once-bin, openclaw, lmstudio-bin, omazed, omarchy-emacs, voxtype-bin, symfony-cli. Candidates for `@build` ports from omarchy-pkgs later.
- Install scripts may do more than install a package (browser policy dirs, 1Password browser integration, Dropbox autostart). Those paths get checked entry by entry during the menu walk-through.
- `nautilus-dropbox` maps to `@none`: Flathub's Dropbox has no Nautilus extension.
