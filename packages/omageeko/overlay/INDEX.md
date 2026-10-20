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
| omarchy-update-system-pkgs | `zypper refresh` + `zypper dup` (restricted with `--from` to `OMAGEEKO_DUP_FROM` when omageeko-update passes the Tumbleweed repos); interactive retry on solver questions |
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
| omarchy-agent-usage-agy / -hermes (new, from omaweed) | Antigravity/Vertex and Hermes usage collectors; no balance emitted when nothing was spent |
| omarchy-hyprland-workspace-carousel (new, from omarchy-mac feature/workspace-carousel) | wrapping workspace cycle on the focused monitor; bound by host files (`docs/touchpad-and-mouse.md`) |
| omarchy-hyprland-window-swap-columns (new) | swap a workspace's two columns in one step (dwindle swapsplit / row swaps, scrolling swapcol); bound by host files (`docs/desk-workspaces.md`) |
| omarchy-update | thin wrapper: `exec omageeko-update` (upstream's pacman/AUR chain doesn't apply; `-y` accepted) |
| omageeko-update (new) | three stages, each runs regardless of the previous: Tumbleweed (`zypper dup` from openSUSE/Packman repos) → omageeko (gated upstream bump, rebuilt RPMs, mise + `mise up`, gated migrations) → apps (vendor repos, Flatpak, box); applies right away and reports reboot need (Aeon style). See `UPDATE-PLAN.md` |
| omageeko-link-skills (new) | links `/usr/share/omageeko/agents/skills/omageeko` into the agent skill dirs Omarchy uses (+ opencode) |
| omarchy-snapshot | create: snapper (all configs), no inline `cleanup` (left to snapper-cleanup.timer; inline it waited on btrfs quotas). restore: guides through the systemd-boot snapshot entry, then `snapper rollback` |

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
| omarchy-mise-install | keep an existing `~/.local/bin/<cmd>` that isn't an Omarchy mise wrapper (e.g. a native Claude Code symlink) instead of replacing it |

## Added files (`overlay/share/`)

| File | Why |
|---|---|
| `/usr/share/applications/chromium.desktop` (hidden) | Omarchy uses the `chromium.desktop` ID (default browser, web apps, mimeapps.list); TW ships `chromium-browser.desktop` |
| `/usr/lib/udev/rules.d/60-omageeko-ddcutil-i2c.rules` (omageeko-hardware) | ddcutil's uaccess rule for display I2C buses: Arch installs it, TW only ships it as a sample, so the shell's `ddcutil detect` failed with EACCES and external-monitor brightness didn't work |
| `/usr/share/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf` (omageeko-hardware) | readable names for UCM laptop audio nodes (panel labels by node.nick) |
| `/usr/share/omarchy/logo.txt` and skel `branding/screensaver.txt` | omageeko wordmark (Omarchy's block font; O/M/A glyphs reused) replaces the Omarchy logo; the original is kept at `/usr/share/omageeko/omarchy-logo.txt` |
| `/usr/bin/omageeko-monitor-wake-kick` + user unit (omageeko-hardware) | re-wake monitors listed in `~/.config/omageeko/monitor-wake-kick` with a DPMS cycle when they reconnect after deep standby (Odyssey G9 quirk) |
| `/usr/bin/omageeko-box` | apps from Omarchy's Arch repo in the `omageeko-arch` distrobox (`@box:` map targets) |
| `/usr/libexec/omageeko/bt-device-privacy` + `omageeko-bt-device-privacy.{service,timer}` (omageeko-hardware) | Device Privacy Mode (flag 0x02) for bonded BLE devices, so peers advertising from their identity address (MX mice) can reconnect with ll-privacy on |
| `/usr/share/omageeko/agents/skills/omageeko/` | agent skill: Tumbleweed-specific rules for packages, updates, boot, hardware, source; overrides the Arch parts of the omarchy skill |
| `/usr/share/omageeko/tools/omageeko-bump` + `migrations.tsv` | the migration classifier (copied from `tools/` by prepare.sh), so omageeko-update gates migrations without a checkout |
| `/usr/share/omageeko/lib/pkg.sh` | Arch-name translation for the pkg ports; `omageeko_flatpak_session_env` pushes Flatpak's export dirs into the running session after a Flatpak install (pkg-add, pkg-aur-install) |
| `/usr/share/uwsm/env.d/20-omageeko-flatpak` (omageeko-session) | Flatpak export dirs in every session's XDG_DATA_DIRS: TW's profile.d/flatpak.sh is skipped when the login already read /etc/profile, or absent until flatpak is installed. Without it, Flatpak URL handlers (slack:// after a browser login) give "no apps available" |

## Menu edits (`menu-transform.py`, run in %prep; fails on upstream drift)

| Id | Change |
|---|---|
| install.package, remove.package | openSUSE logo instead of Arch |
| install.aur | label "Flathub" (all translations), package icon |
| install.opi, remove.flatpak | inserted (after install.aur / remove.package) |
| update.omarchy | label "Omageeko" (all translations): runs omageeko-update |
| shell string `bar.pendingUpdates` | "Omarchy" → "Omageeko" inside every translation (bar update button tooltip: "Pending Omageeko Updates") |
| update.channel.rc, update.channel.edge | dropped (omageeko: Stable = pinned upstream, Dev = linked checkout) |

## Vendor repositories (`overlay/share/repos.tsv` → /usr/share/omageeko/repos.tsv)

Enabled on first use by `omarchy-pkg-add` for `@repo:<alias>:<rpm>` map targets: mise, google-chrome, microsoft-edge, vscode, brave, 1password, nordvpn, cursor, sublime-text.

Shell tree additions: `overlay/shell/` is copied over `shell/` (agy/hermes agent icons).

## Path changes

| Upstream path | omageeko path | Why |
|---|---|---|
| `/usr/local/share/wayland-sessions/omarchy.desktop` | `/usr/share/wayland-sessions/omarchy.desktop` | lightdm reads /usr/share (upstream's location is for sddm) |

## Stubs (`stubs.tsv`, generated at build)

Not applicable: refresh-limine, refresh-pacman, upgrade-to-quattro, provision-owner, provision-hardware, dev-pkg-test, reinstall-pkgs.

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
| `etc/sysctl.d/*`, `etc/systemd/{system,user,oomd,logind,resolved}.conf.d/*`, zram/zswap, udev, modprobe, NetworkManager, cups, sysusers, binfmt drop-ins, `environment.d` fcitx, `system-sleep/*` | layer 07 (system), each reviewed for TW |
