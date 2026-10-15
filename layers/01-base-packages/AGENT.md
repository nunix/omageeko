# Agent prompt — omageeko layer 01: base packages

You are rebuilding layer 01 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layer 00 must already verify (`layers/00-bootstrap/verify.sh`). Read `PLAN.md` and `packages.map` first.

## Goal

Install the Tumbleweed equivalents of upstream's `install/omarchy-base.packages` that belong to layer 01: CLI/TUI tools, Ruby/Rails dev libraries, Wayland helper tools, fonts and themes. **Install packages only.** Omarchy's configs for these tools arrive in layer 03.

## Source of truth: `packages.map`

- One line per upstream package: `<arch-name> <layer> <tw-packages|@build|@flatpak:id|@repo:alias|-> # note`.
- Lines whose name starts with `+` are omageeko extras, not in upstream's list.
- **Every package in upstream's list must have a line.** When the upstream pin moves, run `verify.sh`. It reports newly unmapped packages, which you then map: find the TW name with `zypper se -x`, `zypper se --provides <file>`, or a glob search. Pick an owning layer, or mark it `-` with a reason.
- Name mapping patterns found so far: Python libs → `python313-*`; `noto-fonts*` → `google-noto-*`; `nvim` → `neovim`; `tldr` → `tealdeer`; `man-db` → `man`; `lua51`/`luarocks` → `luajit`/`luajit-luarocks`; `gvfs-*` → `gvfs-backends`; Arch `-libs` → TW `lib<name><soversion>`.

## Steps (as in `install.sh`)

1. Add the mise upstream RPM repo (`https://mise.jdx.dev/rpm`, alias `mise`, priority 95). Import its key from `https://mise.jdx.dev/gpg-key.pub`.
2. Replace conflicting TW defaults in a single zypper transaction (`zypper install new -old`):
   - `hyprland-qtutils` → `hyprland-guiutils` (renamed upstream; the hyprland pattern only *recommends* qtutils)
   - `busybox-man` → `man`
3. Install `map_packages 01` plus `mise` with `--no-recommends` (only missing packages).
4. Run `fc-cache -f`.

Wrap the run in a snapper pre/post pair (`snap_begin "01-base-packages"` / `snap_end`). It must be idempotent.

## Gotchas

- Before a real run, dry-run with `zypper install --dry-run` to catch conflicts.
- `ffmpeg` resolves to Packman's ffmpeg 9 (from layer 00). That pulls in libavcodec63 next to the older 62 that other packages still use.
- In verify scripts that run under `set -o pipefail`, don't pipe big outputs into `grep -q`: the producer gets SIGPIPE and the check falsely fails. Capture to a variable first.
- `JetBrainsMono Nerd Font` (the family name Omarchy's configs use) is not on TW. It's built in layer 02. Layer 01 adds `nerdfonts-symbolsonly-fonts` as a glyph fallback.
- `usage` (jdx) isn't in the mise RPM repo. It's skipped; install per user with `mise use -g usage` if wanted.

## Verification

`layers/01-base-packages/verify.sh` must exit 0. It checks that the map covers upstream's list, that all layer 01 packages are installed, that key commands exist, that ffmpeg has libx264, and that the Noto, Noto CJK, Noto Color Emoji, Symbols Nerd Font and Font Awesome families are present.
