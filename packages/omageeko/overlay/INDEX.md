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
| omarchy-update-pacman | `zypper` in a PID 1 scope (args are zypper args) |
| omarchy-update-system-pkgs | `zypper refresh` + `zypper dup`; interactive retry on solver questions |
| omarchy-update-system-pkgs-when-conflicted | re-runs update-system-pkgs |
| omarchy-update-pkg-prune | `zypper clean` (packages only) |
| omarchy-update-keyring | `zypper refresh` (repo keys are zypper's) |
| omarchy-update-pacman-guard | no-op (no pacman hooks) |
| omarchy-update-orphan-pkgs | zypper `--unneeded` set; reports only under `-y`, removal always asks (patterns can make packages look unneeded) |
| omarchy-update-aur-pkgs | `flatpak update` |
| omarchy-update-analyze-logs | warns on dracut/sdbootutil errors |
| omarchy-update-available | newer TW snapshot (`media.1/products`) + newer omageeko-local RPMs; feeds the bar's update widget |
| omarchy-version | omageeko RPM version-release |
| omarchy-version-pkgs | newest rpm install time |
| omarchy-version-channel | `tumbleweed / omageeko` |
| omarchy-channel-current | `stable` (pinned upstream) or `dev` (linked checkout) |
| omarchy-channel-set | explains omageeko follows `upstream.lock` |
| omarchy-install-and-launch | Flathub-resolved packages launch with `flatpak run <id>` |
| omarchy-snapshot | create: snapper (all configs). restore: guides through the systemd-boot snapshot entry, then `snapper rollback` |

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
| omarchy-mise-install | keep an existing `~/.local/bin/<cmd>` that isn't an Omarchy mise wrapper (e.g. a native Claude Code symlink) instead of replacing it |

## Added files (`overlay/share/`)

| File | Why |
|---|---|
| `/usr/share/applications/chromium.desktop` (hidden) | Omarchy uses the `chromium.desktop` ID (default browser, web apps, mimeapps.list); TW ships `chromium-browser.desktop` |
| `/usr/share/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf` (omageeko-hardware) | readable names for UCM laptop audio nodes (panel labels by node.nick) |
| `/usr/share/omarchy/logo.txt` and skel `branding/screensaver.txt` | omageeko wordmark (Omarchy's block font; O/M/A glyphs reused) replaces the Omarchy logo; the original is kept at `/usr/share/omageeko/omarchy-logo.txt` |
| `/usr/share/omageeko/lib/pkg.sh` | Arch-name translation for the pkg ports |

## Menu edits (`menu-transform.py`, run in %prep; fails on upstream drift)

| Id | Change |
|---|---|
| install.package, remove.package | openSUSE logo instead of Arch |
| install.aur | label "Flathub" (all translations), package icon |
| update.channel.rc, update.channel.edge | dropped (omageeko: Stable = pinned upstream, Dev = linked checkout) |

## Vendor repositories (`overlay/share/repos.tsv` → /usr/share/omageeko/repos.tsv)

Enabled on first use by `omarchy-pkg-add` for `@repo:<alias>:<rpm>` map targets: mise, google-chrome, microsoft-edge, vscode, brave, 1password, nordvpn, cursor, sublime-text.

## Path changes

| Upstream path | omageeko path | Why |
|---|---|---|
| `/usr/local/share/wayland-sessions/omarchy.desktop` | `/usr/share/wayland-sessions/omarchy.desktop` | lightdm reads /usr/share (upstream's location is for sddm) |

## Stubs (`stubs.tsv`, generated at build)

Not applicable: refresh-limine, refresh-pacman, upgrade-to-quattro, provision-owner, provision-hardware, dev-pkg-test, reinstall-pkgs.

Ported in later layers: system-factory-reset (06), plymouth-set (06), hibernation-* (07), setup/remove-security-sshd (07), install-gaming-steam/retroarch (08), install/remove-service-sunshine (08), install-openclaw-cli (08).

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
