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
| `-` + note | not ported yet. The install prints the reason instead of failing inside zypper |

User decisions (2026-10-15): proprietary apps come from the vendor repo where one exists, else Flathub. Nerd fonts are one local RPM each.

On-demand entries use the `-` layer, so `map_packages 06` installs nothing up front.

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

**Verify:** flatpak and Flathub, `repos.tsv`, the font RPMs published, the menu edits, update-time on chrony, and `pkgaudit.py` reporting `broken=0`.

## Next parts
06b Setup, 06c Trigger, 06d Style, 06e System, 06f Learn, 06g bar/panels: reviewed with the user in the running session.
