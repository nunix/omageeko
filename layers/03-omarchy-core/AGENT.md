# Agent prompt — omageeko layer 03: omarchy core

You are rebuilding layer 03 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00–02 must verify. Read `PLAN.md` and `packages/omageeko/overlay/INDEX.md` (the full list of what omageeko changes upstream).

## Goal

Install upstream Omarchy at the commit pinned in `upstream.lock`, laid out exactly like the Arch packages, so upstream code finds everything at `$OMARCHY_PATH=/usr/share/omarchy`. Tumbleweed-specific behaviour comes only from patches, overlay replacements and generated stubs. The user's running desktop must not change in this layer; the Hyprland config switch is layer 04.

## How

`packages/omageeko/omageeko.spec` ports `omarchy-pkgs/pkgbuilds/{omarchy,omarchy-settings}` into one noarch spec with two RPMs:

- **omageeko**:
  - `/usr/bin/omarchy-*`, each with a symlink in `/usr/share/omarchy/bin/`
  - `/usr/share/omarchy/{install,themes,migrations,shell,version}`
  - `/etc/skel` migration markers
  - `/usr/share/omageeko/{lib/pkg.sh,pkgmap.tsv,stubs.tsv,upstream-commit}`
- **omageeko-settings**:
  - `/etc/skel` (`.config`, launchers, `.bashrc`, branding, toggles, nautilus extensions)
  - `/usr/share/omarchy/{config,applications,default}` resync copies
  - Tumbleweed-safe `/etc` defaults (fastfetch, mpv, kitty, xkb, gnupg, mise, `profile.d/omarchy.sh`, sudoers.d with `visudo` checked in `%check`, the nopasswd tmpfiles rule)
  - fontconfig, xdg-terminal-exec list, mimeapps, systemd user units (not enabled), Omarchy font, icons, debug commands

`%prep` applies `patches/*.patch` with `--fuzz=0` (fails loudly on upstream drift). It then copies `overlay/bin/*` over `bin/` and generates stubs from `overlay/stubs.tsv`. Stubs keep upstream's `# omarchy:` metadata, so the `omarchy` CLI router still lists them, and exit 1 with a reason. `%check` fails if a touched command still invokes pacman/yay/expac/paccache/checkupdates as a command.

`packages/omageeko/prepare.sh` generates the spec's inputs: it syncs `%global commit/commit_date/upstream_release` from `upstream.lock` and writes `packages/omageeko/pkgmap.tsv` (`<arch>\t<target>\t<note>`, gitignored) from `packages.map`. `build_packages` runs any `packages/<name>/prepare.sh` **before** computing the stamp, so every layer that builds omageeko (03, 04, 05, …) ships a current map. Generating it in one layer's script once left a stale map installed when later layers rebuilt. `verify.sh` compares the installed map with `packages.map`.

`layers/03-omarchy-core/install.sh` runs `check_builder_snapshot` and `build_packages omageeko`, then `install_local_rpms omageeko omageeko-settings` in a snapper pair.

The build/stamp/install helpers are shared in `lib/common.sh`.

## Porting principles

- Keep upstream's orchestrators verbatim (e.g. `omarchy-update` is distro-neutral). Port the leaf commands they call.
- Arch package names stay in upstream scripts. `omarchy-pkg-*` translate them through `pkgmap.tsv`: plain TW names, `@build[:rpm]` from omageeko-local, `@flatpak:<id>` from Flathub, `-` means unavailable (error with the reason). Unmapped names are tried verbatim.
- "AUR" on omageeko means omageeko-local + Flathub.
- Small changes go in `.patch` files; whole-logic changes go in overlay replacements; meaningless or not-yet-ported commands become stubs.
- **Never ship** upstream `os-release` or `nsswitch.conf` overrides (they break zypper/TW lookups). Never ship limine, mkinitcpio, libalpm or sddm files.
- zypper table parsing: filter out the blank, header and `---+---` rows explicitly, not by line number.
- `/var/log/zypp/history` is root-only, so use the rpm database for user-level queries.
- `/run/zypp.pid` always exists. A transaction runs only while it holds a live PID.

## Upstream bumps and migrations

Shipped migrations are marked done at provisioning, but migrations added by a newer `upstream.lock` run at the next login or `omarchy update`. Many are Arch-specific (27 of the shipped ones touch pacman, limine, mkinitcpio, ufw or systemd-resolved). After a bump, run `layers/03-omarchy-core/tools/migration-audit.sh`. For each `ARCH` line, either ship a patch for that migration or mark it done (`touch ~/.local/state/omarchy/migrations/<name>.sh`) with the reason in `overlay/INDEX.md`. Layer 03 verify fails while Arch-coupled migrations are pending.

## Verification

`layers/03-omarchy-core/verify.sh` must exit 0. It checks:
- RPM versions, and that the installed upstream commit matches the lock
- the shell, hypr defaults, themes and skel files
- that all upstream commands are installed and no non-stub command invokes Arch tooling
- that the pkg primitives translate (jq, noto-fonts-emoji, tldr present; yay missing), that `omarchy --help` works, and `omarchy-version`
- that TW's os-release and nsswitch are untouched, sudoers parse, and clean login shells get `OMARCHY_PATH`

The current graphical session inherits `PROFILEREAD`, so `OMARCHY_PATH` appears only after a re-login.
