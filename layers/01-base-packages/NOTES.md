# Layer 01 — notes

Status: **done, verified 2026-10-15** (snapper pair 13..18, plus 19..22 for the Symbols Nerd Font fix).

## Results
- 127 new packages, about 219 MiB. Replaced `hyprland-qtutils` → `hyprland-guiutils` and `busybox-man` → `man`.
- Already present from the TW install: alacritty, kitty, grim, slurp, hyprpicker, imagemagick, jq, wireplumber, etc.
- Font Awesome on TW is v7 (`Font Awesome 7 Free`). Omarchy's Arch package is `woff2-font-awesome` (also 7.x). Check glyph names when the shell is up (layer 05).
- neovim pulled in `nodejs26` (Mason/treesitter tooling).

## Open items
- `usage` is skipped (not in the mise RPM repo).
- Layer 02 builds JetBrainsMono Nerd Font and iA Writer.
