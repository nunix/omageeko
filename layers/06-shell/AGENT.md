# Agent prompt — omageeko layer 06: Omarchy shell & menu

You are rebuilding layer 06 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00–05 must verify. The layer aligns the Omarchy menu (Super+Space, 10 sections, 398 entries) with Tumbleweed, one part at a time (`PLAN.md` §6). Read `packages/omageeko/overlay/INDEX.md` first.

## 06a — Install / Remove / Update (done)

**Package-name resolution.** Omarchy's menus and `omarchy-install-*` commands pass Arch/AUR names to `omarchy-pkg-add`. `packages.map` translates every one; `layers/06-shell/tools/pkgaudit.py` extracts them from the menu and the installed commands and checks the targets for real. Target kinds (see `/usr/share/omageeko/lib/pkg.sh`):

| Target | Meaning |
|---|---|
| plain names | Tumbleweed packages (`firefox` → `MozillaFirefox`, `php` → `php8`, …) |
| `@repo:<alias>:<rpm>` | vendor RPM repo from `packages/omageeko/overlay/share/repos.tsv`. `omarchy-pkg-add` imports the key, then adds the repo with GPG checking on (first use only). Chrome, Edge, Brave (+Origin), VSCode, Cursor, Sublime Text, 1Password (+CLI), NordVPN, mise. |
| `@flatpak:<id>` | Flathub, system-wide (Spotify, Signal, Slack, Zen, Dropbox, Heroic, Minecraft, Zed) |
| `@build:<rpm>` | local RPM: the six menu Nerd fonts come from `packages/nerd-fonts-extra` (published, installed on demand) |
| `@none` | nothing to install on TW (e.g. `umu-launcher`; Lutris fetches its own) |
| `@box:<pkg>` | Omarchy's own Arch package inside the `omageeko-arch` distrobox (`omageeko-box`) |
| `-` + note | not ported yet. The install prints the reason instead of failing inside zypper |

User decisions (2026-10-15): proprietary apps come from the vendor repo where one exists, else Flathub. Nerd fonts are one local RPM each.

On-demand entries use the `-` layer, so `map_packages 06` installs nothing up front.

**Apps without a TW, vendor or Flathub source (user decision 2026-10-15: hybrid):**
- **Box** (`omageeko-box`, overlay bin; `omageeko` requires distrobox + podman): claude-desktop, openai-codex-desktop, perplexity, grok-bot, t3code-bin, hermes-desktop, lmstudio-bin, plus zed and omazed (Zed moves from Flathub so omazed and Zed share `~/.config/zed`).
  - One Arch distrobox `omageeko-arch` (archlinux:latest) with Omarchy's repo `https://pkgs.omarchy.org/stable/$arch`. The Omarchy key 40DFB630… is received and locally signed. Arch's default `SigLevel = Required DatabaseOptional` applies: the database is unsigned (its `.sig` is a 404), every package signature is required. Don't set `SigLevel = Required` on the section, or sync fails.
  - `omageeko-box install`: `pacman -S --needed`, export each package `.desktop` (`distrobox-export --app`), and add a hidden alias under the original desktop id for Omarchy's `gtk-launch <id>` calls. `/usr/bin` commands are exported to `~/.local/bin` **only when the host has no command of that name**: claude-desktop's Arch package ships `claude`, which must never shadow a native Claude Code.
  - State lives in `~/.local/state/omageeko/box-{packages,exports}`. `has` reads it (fast menu "installed" checks), `remove` unexports and runs `pacman -Rns`, and `update` runs `pacman -Syu` and re-exports. `omarchy-update-aur-pkgs` calls `omageeko-box update`, so `omarchy update` covers the box.
  - `# omageeko: pacman-inside-box` opts the helper out of the spec's no-pacman `%check` and layer 03's verify.
  - Layer 06 adopts an existing box: any `@box` package already installed gets recorded and re-exported.
- **Native local packages** (published, installed on demand):
  - `packages/voxtype/vendor.conf`: the **vendor's signed RPM**. `fetch_vendor_rpm` in lib/common.sh verifies the detached signature with a throwaway keyring (key by fingerprint), then publishes. `build_packages` handles `vendor.conf` packages.
  - `packages/once` (binary + system service; `Requires: podman-docker`. An OR with docker made libsolv pick real Docker).
  - `packages/openclaw` (npm global install into the package, plus a `/usr/share/openclaw` seed so `omarchy-install-openclaw-cli` works; that command is no longer a stub).
  - `packages/omarchy-emacs` (noarch; requires `emacs-x11`, TW's GUI Emacs).
- **Vendor repo:** symfony-cli (Cloudsmith) in `repos.tsv`.

**Supporting changes:**
- `omageeko` requires `flatpak`. Its `/etc/profile.d` snippet adds Flatpak exports to `XDG_DATA_DIRS` from the next login.
- Overlay `omarchy-install-and-launch`: when a package resolves to Flathub, launch with `flatpak run <id>`. The desktop id differs from Arch's, and a session started before the install lacks Flatpak's data dirs.
- Patch `omarchy-update-time`: restart chronyd plus `chronyc makestep`. TW uses chrony, not systemd-timesyncd.
- `omarchy-update-firmware` works unchanged. Its Arch-only EFI copy is skipped because TW keeps fwupd's EFI binary elsewhere.
- `packages/omageeko/menu-transform.py` runs in `%prep`, with declarative rules that fail the build if an id disappears upstream:
  - openSUSE logo instead of Arch on Install/Remove › Package
  - "AUR" → "Flathub" (all translations) with a package icon
  - drop the RC/Edge channels (omageeko: Stable = pinned upstream, Dev = linked checkout)

**Script:** `layers/06-shell/install.sh`:
1. `build_packages omageeko nerd-fonts-extra`
2. Install the omageeko RPMs.
3. Add Flathub system-wide.
4. Restart the shell (`omarchy-restart-shell`) to reload the menu.

**Verify:** natives published, distrobox/omageeko-box present, the box on Omarchy's repo, flatpak and Flathub, `repos.tsv`, the font RPMs published, the menu edits, update-time on chrony, and `pkgaudit.py` reporting `broken=0`.

## 06b — Omarchy base applications (done)

Menu audit first: `layers/06-shell/tools/menuaudit.py <sections>`. It follows each menu action two levels into `omarchy-*` and flags stubs, Arch references and absent programs. It's noisy (strings and functions); confirm each finding by hand. The real gaps were apps Omarchy installs as base: the Print key needs **omasnap**, Share needs the **localsend** CLI, plus the file manager (**nautilus**) and media (**mpv**, **imv**).

Install set = every `packages.map` entry with layer `06`, passed to `omarchy-pkg-add` so it resolves like the menus do:
- **Tumbleweed:** nautilus, sushi, python313-nautilus, mpv, mpv-mpris, imv, evince, gnome-disk-utility; extra `v4l-utils` (webcam overlay in screen recording).
- **Native local RPMs** (user decision: mixed):
  - `packages/omasnap` (cmake/Qt6 + layer-shell-qt6)
  - `packages/herdr` (cargo + zig 0.16 tarball; TW has 0.15)
  - `packages/disktree` (upstream binary; native so it sees the host's disks)
  - `packages/tzupdate` (cargo; must run the host's timedatectl)
  - `packages/aether` (upstream Go binary; a preinstall)
  - `packages/omarchy-nvim` (LazyVim starter + Omarchy config, plugins synced headless in the builder and slimmed with Omarchy's verbatim functions, seeded to /etc/skel; arch-specific because plugins carry native libs; the dependency generator is excluded from those trees). Layer 06 then runs `omarchy-nvim-setup`.
- **Box:** localsend (Omarchy's build gives the `localsend` CLI that Share needs; Flathub has none), gliff, tobi-try, plus the preinstalls omacalc, omacut, omawrite, signed, hype, monologue, cliamp.
- **Preinstalls:** the list is parsed from upstream's `omarchy-remove-preinstalls` drop list. It's skipped while `~/.local/state/omarchy/preinstalls-removed` exists; `Install › Preinstalls` brings them back through the same mapping.

Gotchas: `localsend --help` launches the GUI (don't use it as a smoke test). Never kill with `pgrep -f`/`pkill -f` patterns that also appear in your own command line.

## Next parts
06c Trigger details, 06d Setup details (language/locale-gen, DNS, direct boot, sudoless docker), 06e Learn, then bar/panels: reviewed with the user in the running session.
