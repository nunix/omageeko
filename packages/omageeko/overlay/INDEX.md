# omageeko overlay index

Every upstream file omageeko changes, replaces, stubs or deliberately leaves out. When bumping `upstream.lock`, diff these upstream files between the old and new commit. Anything that changed here needs a look.

## Full replacements (`overlay/bin/`)

| Command | Tumbleweed implementation |
|---|---|
| omarchy-pkg-present, omarchy-pkg-missing | `rpm -q --whatprovides` / `flatpak info` on names translated by `pkgmap.tsv` |
| omarchy-pkg-add | translate, then `zypper install --no-recommends` and/or `flatpak install --system flathub`; skipped names error out |
| omarchy-pkg-aur-add | same as pkg-add (no AUR: local repo, Flathub or TW repos) |
| omarchy-pkg-drop | `zypper remove --clean-deps` (≈ `pacman -Rns`), `flatpak uninstall` |
| omarchy-pkg-install | fzf over `zypper search --uninstalled-only` |
| omarchy-pkg-remove | fzf over zypper's user-installed set (≈ `pacman -Qqe`) |
| omarchy-pkg-aur-install | fzf over Flathub apps |
| omarchy-update-pacman | `zypper` in a PID 1 scope (args are zypper args); passes `DISABLE_SNAPPER_ZYPP_PLUGIN` through sudo |
| omarchy-update-system-pkgs | `zypper refresh` + `zypper dup` (restricted with `--from` to `OMAGEEKO_DUP_FROM` when omageeko-update passes the Tumbleweed repos); file conflicts only with orphaned packages (renamed library packages, e.g. libhiredis1_3_0 → 1_5_0) retry with `--replacefiles`, then each orphan is removed if a dry run removes nothing else; interactive retry on solver questions |
| omarchy-update-system-pkgs-when-conflicted | re-runs update-system-pkgs |
| omarchy-update-pkg-prune | `zypper clean` (packages only) |
| omarchy-update-keyring | `zypper refresh` (repo keys are zypper's) |
| omarchy-update-pacman-guard | no-op (no pacman hooks) |
| omarchy-update-orphan-pkgs | zypper `--unneeded` set; reports only under `-y`, removal always asks (patterns can make packages look unneeded) |
| omarchy-update-aur-pkgs | `flatpak update` + `omageeko-box update` |
| omarchy-update-analyze-logs | warns on dracut/sdbootutil errors |
| omarchy-update-available | newer TW snapshot (`media.1/products`, last field: the file reads `/ openSUSE <date>-<n>`) + newer omageeko-local RPMs; feeds the bar's update widget |
| omarchy-version | omageeko RPM version-release |
| omarchy-version-pkgs | newest rpm install time |
| omarchy-version-channel | `tumbleweed / omageeko` |
| omarchy-channel-current | `stable` (pinned upstream) or `dev` (linked checkout) |
| omarchy-channel-set | explains omageeko follows `upstream.lock` |
| omarchy-install-and-launch | Flathub-resolved packages launch with `flatpak run <id>` |
| omarchy-pkg-flatpak-remove (new, from omaweed) | fzf picker removing system/user Flatpak apps (Remove › Flatpak) |
| omarchy-pkg-opi-install (new, from omaweed) | opi search over OBS/Packman (Install › OPI) |
| omarchy-theme-catalog (new) | Install › Style › Theme Catalog: opens the `omageeko.theme-catalog` shell overlay on the cached index (one IPC call; a stale index is rebuilt behind it). `--build` makes the index: each repo's tree, backgrounds, palette (colors.toml, else alacritty.toml), stars and last commit from batched GraphQL through gh (25 repos per query, retried), tree-only clones without gh or for themes in a subdirectory; apps each theme styles, most apps first. `--thumbs` makes 480×270 background thumbnails keyed by git blob id; `--prefetch` makes all of them; `--installed` lists the themes cloned into `~/.config/omarchy/themes` by origin repo; `--install owner/name [oid]` applies a theme already cloned from that repo (no re-clone) or else installs it, then sets that background (looked up in the index by blob id, as the terminal launcher re-splits its arguments); `--list` prints the index. Cached in `~/.cache/omageeko/theme-catalog` (index a week, thumbnails until their file changes); installs through `omarchy-theme-install` |
| omarchy-hyprland-workspace-carousel (new, from omarchy-mac feature/workspace-carousel) | wrapping workspace cycle within the focused monitor's own workspaces (4.5 per-monitor blocks); bound by host files (`docs/touchpad-and-mouse.md`) |
| omarchy-hyprland-window-swap-columns (new) | swap a workspace's two columns in one step (dwindle swapsplit / row swaps, scrolling swapcol); bound by host files (`docs/desk-workspaces.md`) |
| omarchy-update | thin wrapper: `exec omageeko-update` (upstream's pacman/AUR chain doesn't apply; `-y` accepted) |
| omageeko-update (new) | three stages, each runs regardless of the previous: Tumbleweed (`zypper dup` from openSUSE/Packman repos) → omageeko (gated upstream bump, rebuilt RPMs, mise + `mise up`, gated migrations, after restarting a stale shell as upstream 4.5.0 does) → apps (vendor repos, Flatpak, box); applies right away and reports reboot need (Aeon style). See `UPDATE-PLAN.md` |
| omageeko-link-skills (new) | links `/usr/share/omageeko/agents/skills/omageeko` into the agent skill dirs Omarchy uses (+ opencode) |
| omarchy-hyprland-window-equalize-splits (new) | reset the workspace's dwindle splits to even halves, recursively, from window geometry (Hyprland 0.56 `splitratio` only takes a delta); bound to Super+\\ in the host bindings |
| omarchy-snapshot | create: snapper (all configs), no inline `cleanup` (left to snapper-cleanup.timer; inline it waited on btrfs quotas). restore: guides through the systemd-boot snapshot entry, then `snapper rollback` |
| omageeko-session-restore (new, omageeko-session) | session restore (`docs/session-restore.md`): `save` records app windows (class, launcher, workspace, monitor identity + connector) to `~/.local/state/omageeko/session.json`; `restore` relaunches and moves each new window onto its workspace via Hyprland's event socket: own workspace when the monitor fingerprint matches, else the same number on the main monitor. Browser windows come back through the browser's own session restore and are matched by title; Chromium `--app` web apps are matched to their `omarchy-launch-webapp` launcher by class. Terminals and `org.omarchy.*` windows are skipped |

## Patches (`patches/`, applied with `--fuzz=0`)

| Patch | Change |
|---|---|
| omarchy-migrate | wait on zypper (`/run/zypp.pid` holding a live PID) instead of the pacman db lock |
| omarchy-remove-launcher-entry | owner via `rpm -qf`, removal via `zypper remove --clean-deps` |
| omarchy-reinstall-configs | drop the `omarchy-refresh-limine` call |
| omarchy-update-restart | kernel ownership via `rpm -qf` |
| omarchy-debug | package info from rpm |
| omarchy-upload-log | package list from rpm |
| omarchy-apply-lock | lock PAM `account include common-account` (TW has no system-local-login) |
| omarchy-setup-security-fingerprint | lock-screen-only by default (`--all` = upstream sudo+polkit+lock); for `--all`, copy /usr/lib/pam.d/{sudo,polkit-1} to /etc before editing; polkit stack includes common-*; packages via omarchy-pkg-add (+fprintd-pam) |
| omarchy-remove-security-fingerprint | guard the /etc/pam.d/sudo grep (only exists after --all) |
| omarchy-update-time | chronyd restart + `chronyc makestep` (TW uses chrony) |
| omarchy-remove-preinstalls | delete `~/.local/bin/{claude,codex,gh,…}` only when they are Omarchy mise wrappers (upstream deleted them unconditionally, which removed a native Claude Code) |
| omarchy-install-editor-zed | after launching Zed, re-select omazed's "Omazed" theme if Zed's first-run onboarding overwrites `settings.json` (omazed selects it only once, before Zed has run) |
| shell agents Main.qml | strip `google/`/`vertex/`/`anthropic/` prefixes and `@YYYYMMDD` from model names |
| shell agents Panel.qml | estimated-spend text for agents without prepaid credit |
| shell monitor Panel.qml + default/hypr/toggles.lua | displays switched off in the panel stay off for the session (`$XDG_RUNTIME_DIR/omarchy-disabled-monitors`) |
| omarchy-default-browser | `brave` checks for the `brave-browser` command (Brave's RPM; Arch's brave-bin ships `brave`), so Setup › Defaults › Browser › Brave no longer opens an install terminal |
| shell clipboard ClipboardHistory.js + Clipboard.qml | pinned entries (Ctrl+P): listed first with a pin mark, not trimmed by the 500-entry limit, kept by Shift+Delete (clear); history saved whole since addEntry bounds unpinned entries |
| shell bar Workspaces.qml | `count` setting on the `omarchy.workspaces` widget (1-10, default 5): how many of the monitor's own workspaces are always listed; the host `shell.json` sets 10 |
| shell menu BarWidget.qml | bar menu button draws U+E900 from the `omageeko` icon font (omageeko logo) instead of the `omarchy` font |
| omarchy-mise-install | keep an existing `~/.local/bin/<cmd>` that isn't an Omarchy mise wrapper (e.g. a native Claude Code symlink) instead of replacing it |
| omarchy-system | before closing windows, `omageeko-session-restore save --exit` (bounded 8 s): saves the session and SIGTERMs the browser so it keeps every window and exits cleanly (window-by-window closing left Chromium only the last window and a `Crashed` exit) |

## Added files (`overlay/share/`)

| File | Why |
|---|---|
| `/usr/share/applications/chromium.desktop` (hidden) | Omarchy uses the `chromium.desktop` ID (default browser, web apps, mimeapps.list); TW ships `chromium-browser.desktop` |
| `/usr/lib/udev/rules.d/60-omageeko-ddcutil-i2c.rules` (omageeko-hardware) | ddcutil's uaccess rule for display I2C buses: Arch installs it, TW only ships it as a sample, so the shell's `ddcutil detect` failed with EACCES and external-monitor brightness didn't work |
| `/usr/share/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf` (omageeko-hardware) | readable names for UCM laptop audio nodes (panel labels by node.nick) |
| `/usr/share/fonts/omageeko/omageeko.ttf` (omageeko-settings) | one-glyph icon font built at build time by `make-icon-font.py` from `overlay/share/branding/omageeko-icon.txt` (Omarchy's logo with a G as the inner square); U+E900 with Omarchy's font metrics |
| skel `branding/about.txt` (fastfetch/About logo) | the omageeko mark (`overlay/share/branding/omageeko-icon.txt`, same grid as the bar glyph); upstream's is kept at `/usr/share/omageeko/omarchy-about.txt`, layer 04 swaps the user's copy while it is the stock one |
| `/usr/share/omarchy/icon.png`, `pixmaps/omarchy.png`, hicolor 256 `omarchy.png` | the omageeko mark rendered from the same grid at build time, openSUSE green (#73ba25) on transparent |
| `/usr/share/omarchy/logo.txt` and skel `branding/screensaver.txt` | omageeko wordmark (Omarchy's block font; O/M/A glyphs reused) replaces the Omarchy logo; the original is kept at `/usr/share/omageeko/omarchy-logo.txt` |
| `/usr/bin/omageeko-monitor-wake-kick` + user unit (omageeko-hardware) | re-wake monitors listed in `~/.config/omageeko/monitor-wake-kick` with a DPMS cycle when they reconnect after deep standby (Odyssey G9 quirk) |
| `/usr/bin/omageeko-box` | apps from Omarchy's Arch repo in the `omageeko-arch` distrobox (`@box:` map targets) |
| `/usr/libexec/omageeko/bt-device-privacy` + `omageeko-bt-device-privacy.{service,timer}` (omageeko-hardware) | Device Privacy Mode (flag 0x02) for bonded BLE devices, so peers advertising from their identity address (MX mice) can reconnect with ll-privacy on |
| `/usr/share/omageeko/agents/skills/omageeko/` | agent skill: Tumbleweed-specific rules for packages, updates, boot, hardware, source; overrides the Arch parts of the omarchy skill |
| `/usr/share/omageeko/tools/omageeko-bump` + `migrations.tsv` | the migration classifier (copied from `tools/` by prepare.sh), so omageeko-update gates migrations without a checkout |
| `/usr/share/omageeko/lib/pkg.sh` | Arch-name translation for the pkg ports; `omageeko_flatpak_session_env` pushes Flatpak's export dirs into the running session after a Flatpak install (pkg-add, pkg-aur-install) |
| `/usr/share/uwsm/env.d/20-omageeko-flatpak` (omageeko-session) | Flatpak export dirs in every session's XDG_DATA_DIRS: TW's profile.d/flatpak.sh is skipped when the login already read /etc/profile, or absent until flatpak is installed. Without it, Flatpak URL handlers (slack:// after a browser login) give "no apps available" |
| `/usr/lib/tmpfiles.d/omageeko-mglru.conf` (omageeko-system) | multi-gen LRU on at boot: Omarchy's kernel enables it at build time (`CONFIG_LRU_GEN_ENABLED`), TW's builds it in but leaves it off |
| `/usr/lib/systemd/system/scx.service.d/10-omageeko-lavd.conf` (omageeko-system) | sched_ext `scx_lavd --autopower` (TW's `scx` package) in place of the BORE patch in Omarchy's kernel; overrides via `SCX_*_OVERRIDE`, so `/etc/default/scx` stays untouched |
| `omageeko-session-restore-{offer.service,save.service,save.timer}` user units (omageeko-session) | login offer (notification, or straight restore with the "Restore at login" switch on) and a 5-minute autosave for power cuts; enabled by layer 04 |
| `shell/plugins/omageeko-session-restore/` (bar widget `omageeko.session-restore`, from `overlay/shell/`) | restore button between weather and the update button, shown only while a saved session waits, restores or came back incomplete; right click opens the card with the "Restore at login" switch, Save now, Dismiss and the log |
| `shell/plugins/omageeko-theme-catalog/` (overlay `omageeko.theme-catalog`, keepLoaded, from `overlay/shell/`) | the theme catalog: community theme screenshots in the image picker's skewed carousel above a tempered-glass pane under the text and backgrounds (the selected theme's screenshot blurred under its colors.toml background, accent edge, foreground text; colors glide between themes), label (apps, stars, last commit, installed) and app list, and the selected theme's backgrounds as thumbnails below (one pane size for every theme: 6 slots, "+N" on the last when there are more; apps wrap to 2 lines); missing thumbnails are fetched for the selection first, then its neighbours out to ±4 (3 workers). Down moves into the backgrounds row, a carousel of its own (Left/Right scroll it, Up or Esc goes back; every background of the theme is thumbnailed once browsed), where Enter installs the theme and sets the highlighted background. A badge on each card's top-right corner shows whether the theme is on disk (computer, accent-filled: cloned from that very repo, so a same-named overlay doesn't count) or must be downloaded (cloud); the applied theme (`~/.local/state/omarchy/current/theme.name`, watched) gets a green check beside it and "current" in its label. Type to filter, Enter or click installs: an installed theme is applied in place (no terminal, no re-clone), anything else opens a terminal for the clone. Delete (or Backspace with an empty filter) uninstalls the selected installed theme after Omarchy's `ConfirmDialog` (Cancel preselected) through `omarchy-theme-remove`; the catalog stays open on the same theme, its badge back to a cloud. The current theme is refused with a note in the hint row |

## Menu edits (`menu-transform.py`, run in %prep; fails on upstream drift)

| Id | Change |
|---|---|
| install.package, remove.package | openSUSE logo instead of Arch |
| install.aur | label "Flathub" (all translations), package icon |
| install.opi, remove.flatpak | inserted (after install.aur / remove.package) |
| update.omarchy | label "Omageeko" (all translations), icon from the `omageeko` font: runs omageeko-update |
| shell string `bar.pendingUpdates` | "Omarchy" → "Omageeko" inside every translation (bar update button tooltip: "Pending Omageeko Updates") |
| update.channel.rc, update.channel.edge | dropped (omageeko: Stable = pinned upstream, Dev = linked checkout) |
| system.session | inserted before Logout: opens the session restore card (`omarchy-shell shell toggle omageeko.session-restore`) |

## Vendor repositories (`overlay/share/repos.tsv` → /usr/share/omageeko/repos.tsv)

Enabled on first use by `omarchy-pkg-add` for `@repo:<alias>:<rpm>` map targets: mise, google-chrome, microsoft-edge, vscode, brave, 1password, nordvpn, cursor, sublime-text.


## Path changes

| Upstream path | omageeko path | Why |
|---|---|---|
| `/usr/local/share/wayland-sessions/omarchy.desktop` | `/usr/share/wayland-sessions/omarchy.desktop` | lightdm reads /usr/share (upstream's location is for sddm) |

## Stubs (`stubs.tsv`, generated at build)

Not applicable: refresh-limine, refresh-pacman, upgrade-to-quattro, provision-owner, provision-hardware, dev-pkg-test, reinstall-pkgs, kernel (Limine default-kernel switcher for linux-omarchy; the stub lists no kernels, so Update › Kernel stays hidden), apply-pacman.

Ported in later layers: system-factory-reset (06), plymouth-set (06), hibernation-* (07), setup/remove-security-sshd (07), install-gaming-steam/retroarch (08), install/remove-service-sunshine (06).

## Upstream files not shipped

| Upstream | Why |
|---|---|
| `etc-overrides/os-release` | would break zypper and TW tooling (ID=opensuse-tumbleweed) |
| `etc/nsswitch.conf` | TW's `/usr/etc/nsswitch.conf` uses `usrfiles`; mDNS hosts line comes in layer 07 |
| `etc/limine-entry-tool.d/*`, `default/limine/*`, `etc/mkinitcpio.conf.d/*` | systemd-boot + sdbootutil + dracut |
| `default/libalpm/hooks/*` | no pacman |
| `etc/sddm.conf.d/*`, `default/sddm/*` | decision: keep lightdm |
| `default/snapper/root` template | TW's installer already configures snapper |
| `etc/docker/*`, docker drop-ins, `resolved.conf.d/20-docker-dns.conf` | podman |
| `default/plymouth/*`, `etc/plymouth/*`, `etc/security/faillock.conf` | layer 06 |
| `etc/systemd/{system,user,logind,resolved}.conf.d/*`, the other udev rules, NetworkManager, cups, sysusers, binfmt drop-ins, `environment.d` fcitx, `system-sleep/*` | layer 08 (system), each reviewed for TW. Already shipped by omageeko-system: zram-generator conf, `sysctl.d/99-omarchy-sysctl.conf` + `90-omarchy-file-watchers.conf`, `oomd.conf.d/10-omarchy.conf`, `app.slice.d/10-oomd.conf`, `tmpfiles.d/omarchy-zswap.conf`, `udev/rules.d/60-omarchy-io-scheduler.rules` (at TW's /usr/lib vendor paths) |
| `etc/modprobe.d/omarchy-usb-autosuspend.conf` | decision: not a performance setting, and disabling USB autosuspend costs battery on the laptop |
