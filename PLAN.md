# omageeko — Omarchy (quattro) on openSUSE Tumbleweed

Goal: reach Omarchy's desktop experience on Tumbleweed while consuming as much of upstream Omarchy **verbatim** as possible. TW-specific work lives in a thin overlay (package mapping, shims, patches), so following upstream means bumping a pin and re-applying a small patch set.

## 1. Upstream baseline

| Branch | State (2026-10-14) | Use |
|---|---|---|
| `quattro` (default) | v4.0.4 released 2026-09-15, active daily | **Base. Pinned in `upstream.lock`** |
| `rc`, `dev` | 3.8.5, ~2,680 commits behind quattro | Stale, ignore |
| milestone `4.5` | only "native video wallpaper" (owe), already merged into quattro | Comes in automatically via quattro |

Repo moved from `basecamp/omarchy` to `omacom/omarchy`. Packages are built from `omacom/omarchy-pkgs`.

### What quattro is now (very different from 3.x)

- **Hyprland 0.56.2 with Lua config** (`default/hypr/*.lua`, user `~/.config/hypr/hyprland.lua` loads `$OMARCHY_PATH/default/hypr/bootstrap.lua`).
- **Quickshell desktop** (`shell/`): one long-running process provides the bar, notifications, OSD, launcher/menu, lock screen, polkit agent, clipboard, emoji picker, dock, background picker, panels. **waybar, mako, walker/elephant, swayosd, hyprlock, hypridle and hyprpolkitagent are no longer used.**
- **uwsm** session (`default/wayland-sessions/omarchy.desktop`), `$OMARCHY_PATH=/usr/share/omarchy`.
- Shipped as two Arch packages: `omarchy` (bin, install, migrations, themes, shell → `/usr/share/omarchy`, `/usr/bin`) and `omarchy-settings` (`/etc/skel`, `/etc` drop-ins, fonts, plymouth, sddm theme).
- Per-user setup: `/etc/skel` seed → `omarchy-provision-user` → `omarchy-reinstall-configs` for resync.
- ~519 `omarchy-*` commands; ~40 touch pacman/yay, ~10 limine, ~8 mkinitcpio, 5 ufw, 5 snapper.
- Boot stack: limine + mkinitcpio + limine-snapper-sync, plymouth, SDDM (autologin + Omarchy theme).

## 2. This machine vs Omarchy

Machine: Lenovo ThinkPad P14s Gen 4 (AMD Ryzen 7 PRO 7840U / Radeon 780M), 54 GiB RAM. TW 20261013, kernel 7.2.9. Root is btrfs with snapper, `/home` is XFS. Boots with systemd-boot + sdbootutil. SELinux is enforcing. Installed patterns: basic_desktop (IceWM), x11, hyprland, hyprland_extra, podman, kvm_tools, laptop, selinux.

| Area | Omarchy quattro | This TW install | Gap / decision |
|---|---|---|---|
| Compositor | Hyprland 0.56.2 (stock on x86) | Hyprland 0.56.2 ✅ | none, same version |
| Config format | Lua | Lua (`~/.config/hypr/hyprland.lua`) ✅ | replace with Omarchy bootstrap |
| Session mgr | uwsm | uwsm in OSS, not installed | install |
| Desktop shell | quickshell 0.3.2 (+ Qt 6.11 patch) | **not in TW**; all build deps are (Qt 6.11.2, cpptrace, cli11, jemalloc, private-devel) | **build RPM** |
| Bar/notif/OSD/lock/launcher | inside quickshell | waybar, mako, swaync, wofi, rofi installed | remove later (optional) |
| Display manager | SDDM + Omarchy theme, autologin | lightdm (display-manager-legacy) | **keep lightdm**, add omarchy uwsm session |
| Boot | limine + mkinitcpio + limine-snapper-sync | systemd-boot + sdbootutil + dracut + snapper | **keep TW stack**, stub/port limine/mkinitcpio commands |
| Snapshots | snapper + omarchy snapshot cmds | snapper ✅ (timeline off) | port `omarchy-snapshot`-style cmds to `snapper` + `sdbootutil` |
| Packages | pacman + yay + omarchy repo | zypper (+ OBS) | `omarchy-pkg-*` → zypper shims |
| Containers | docker (+ ufw-docker) | podman (chosen at install) | map docker features to podman / podman-docker |
| Firewall | ufw | firewalld (inactive) | use firewalld, port `omarchy-*` ufw bits |
| Network | NetworkManager (+ impala TUI) | NetworkManager ✅ | none |
| Audio | pipewire + wireplumber | ✅ | add Omarchy wireplumber/tuning configs |
| Power | power-profiles-daemon | none active | install ppd (amd-pstate is active) |
| Terminal | alacritty / ghostty / kitty / foot | alacritty, kitty | add ghostty, foot (both in OSS) |
| CLI set | bat eza fzf zoxide rg fd starship btop fastfetch lazygit nvim gum mise tldr tmux… | mostly missing, all but mise in OSS | install; mise from mise's rpm repo |
| Fonts | JetBrains Mono Nerd, Noto (+CJK, emoji), Font Awesome, iA Writer | partial | `jetbrains-mono-fonts` + `nerdfonts-symbolsonly-fonts`, google-noto-*; build/fetch iA Writer |
| Omarchy-own apps | owe, owe-lockfeed, omasnap, omacalc, omacut, omawrite, signed, hype, aether, gliff, herdr, ttfx, titlebars plugin… | none | build from omacom sources (C/C++/Rust/Go); owe and titlebars first |
| Proprietary apps | obsidian, 1password, localsend, typora… | none | Flatpak (Flathub) or vendor RPMs |
| SELinux | not used | enforcing | keep enforcing; fix denials per layer |

## 3. Decisions (2026-10-15)

| Topic | Decision |
|---|---|
| Base | `quattro` HEAD, pinned in `upstream.lock` |
| Missing software | **local RPMs**: specs in `packages/`, built with rpmbuild, served from a local zypper repo (`/var/lib/omageeko/repo`). OBS stays possible later. |
| Boot | **keep systemd-boot + sdbootutil + dracut + snapper**. Omarchy limine/mkinitcpio code is skipped or ported. |
| Codecs | **Packman Essentials** with a vendor change for the codec stack (layer 00) |
| Display manager | **keep lightdm**, add Omarchy's uwsm session |
| Containers | podman (Omarchy docker features mapped to podman) |
| SELinux | stays enforcing; fix denials per layer |

## 4. Architecture

```
upstream omarchy (pinned commit, untouched)
        +  packages/omageeko/overlay/   TW replacements + generated stubs for Arch-coupled commands
        +  packages/omageeko/patches/   minimal diffs where a whole-file overlay is overkill
        +  packages/<name>/             RPM specs for software missing on TW (quickshell, owe, …)
        =  /usr/share/omarchy  +  /usr/bin/omarchy-*  +  /etc drop-ins  +  /etc/skel
```

Install layout mirrors the Arch packages so upstream code finds files where it expects them (`$OMARCHY_PATH=/usr/share/omarchy`). Final consolidation turns this into `omageeko` and `omageeko-settings` RPMs, plus an OBS project or local repo.

## 5. Layers

Each layer is done only when its `verify.sh` passes and it has been checked in a real session. Then its `AGENT.md` (prompt to rebuild it) and `install.sh` (the human script) are frozen. Every layer is idempotent, takes a snapper pre/post pair, and touches only what it owns.

| # | Layer | Content | Risk |
|---|---|---|---|
| 00 ✅ | bootstrap | git, devel tools (rpm-build, cmake, ninja, meson, go, rust), `opi`; fetch pinned upstream into `~/omageeko/upstream`; optional Packman for full codecs | low |
| 01 ✅ | base-cli | SUSE-name map of `omarchy-base.packages` (CLI, fonts, terminals, TUIs); mise | low |
| 02 ✅ | build-deps | RPMs: **quickshell**, owe/owe-lockfeed, omarchy-hyprland-titlebars, hyprland-preview-share-picker, ia-writer font. Later: omasnap, gliff, herdr, ttfx, aether, omacalc/omacut/omawrite/signed/hype | medium |
| 03 ✅ (session test in 04) | omarchy-core | install upstream tree to `/usr/share/omarchy`, `bin` → `/usr/bin`, `etc/` drop-ins vetted for TW, `/etc/skel` content; TW overlay for pkg/update/boot/firewall commands | medium |
| 04 | session | uwsm + `omarchy.desktop` session, user provisioning (`omarchy-provision-user`), Hyprland Lua bootstrap; test from a TTY before touching the DM | medium |
| 05 | shell | omarchy-shell (quickshell) running: bar, notifications, OSD, launcher, polkit, **lock (PAM + SELinux)**, clipboard; theme switching | medium |
| 06 | login-boot | lightdm defaults to the omarchy session (optional greeter theming), plymouth Omarchy theme via dracut, snapshot cmds via snapper/sdbootutil, faillock/sudoers tweaks | **high** (boot/login) |
| 07 | system | power-profiles-daemon, firewalld, bluetooth, podman docker-compat, fcitx5/XCompose, wireplumber tuning, `omarchy-update` → `zypper dup` + snapper | medium |
| 08 | apps | chromium + webapps, nautilus, mpv, imv, LibreOffice, Flatpak apps, nvim (LazyVim) | low |
| 09 | hardware | P14s Gen 4: amd-pstate/ppd, fingerprint (fprintd + PAM), 780M VA-API/Vulkan, ThinkPad keys, battery thresholds | low |
| 10 | cleanup | drop IceWM/x11 patterns, waybar/mako/swaync/wofi/rofi if unwanted | low |
| 99 | consolidate | single `omageeko-install`, RPM packaging, upstream bump procedure, optional kiwi image | — |

## 6. Upstream tracking

- `upstream.lock` holds the quattro commit. Bumping it means: fetch, diff `bin/` and `install/` against the overlay index, re-apply patches, run all `verify.sh`.
- `packages/omageeko/overlay/INDEX.md` lists every upstream file we replace, patch, stub or skip, and why. That's the whole maintenance surface.
- Arch-only features (limine UKI, mkinitcpio hooks, Apple/T2 hardware, pacman hooks) are explicitly listed as skipped, not silently dropped.
