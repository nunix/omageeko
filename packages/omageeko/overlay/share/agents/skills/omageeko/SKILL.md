---
name: omageeko
description: >
  REQUIRED on omageeko systems (Omarchy's Hyprland desktop on openSUSE Tumbleweed) for anything
  touching packages, updates, boot, services, hardware or the omageeko source. Overrides the Arch
  parts of the omarchy skill: no pacman, yay, AUR, limine or mkinitcpio here. Triggers: install,
  remove or find software, zypper, rpm, flatpak, distrobox, update, upgrade, omarchy update,
  omageeko-update, omageeko-bump, upstream bump, snapshot, rollback, snapper, reboot needed, boot
  entries, kernel, SELinux, PAM, fingerprint, bluetooth, monitors waking, host files, migrations,
  "is this Arch or Tumbleweed", and changes meant to survive a reinstall.
---

# omageeko Skill

omageeko is [Omarchy](https://omarchy.org/) (upstream `omacom/omarchy`) running on **openSUSE Tumbleweed** instead of Arch. The desktop, the `omarchy` CLI, the shell, menus and themes are upstream Omarchy. The base OS, packages, boot and update path are Tumbleweed's.

Use this skill **together with the `omarchy` skill**: `omarchy` covers desktop customization (Hyprland, bar, themes, hooks), and this one wins wherever the two disagree.

## Topic Guides

Read the matching guide before acting:

- [`packages.md`](packages.md): installing and removing software (zypper, Flathub, the Arch box, the name map)
- [`updates.md`](updates.md): `omageeko-update`, snapshots and rollback, reboot detection, the upstream bump
- [`system.md`](system.md): Tumbleweed facts that differ from Arch: boot, PAM, SELinux, time, config paths
- [`hardware.md`](hardware.md): this machine's fixes (Bluetooth, monitors, audio, fingerprint) and host files
- [`source.md`](source.md): the omageeko checkout: layers, packages, patches, overlay; making changes durable

## Critical Rules

1. **Never use Arch tooling.** `pacman`, `yay`, `paru`, `makepkg`, `mkinitcpio`, `limine-*` and `ufw` don't exist or don't apply. Use `omarchy pkg add/drop` (they translate names) or `zypper`; `dracut`/`sdbootutil` for boot; `firewalld`.
2. **Never edit `/usr/share/omarchy/` or `/usr/share/omageeko/`.** They are owned by the omageeko RPMs and replaced on every rebuild. Reading is fine.
3. **Durable system changes go into the omageeko checkout** (`~/omageeko`, see `source.md`), not straight onto the system. Changes only to the running system are lost on reinstall. A hot fix is fine to unblock the user, but say so, and port it to the checkout.
4. **Leave these alone:**
   - `~/.claude/settings.json` holds the user's Vertex login settings;
   - `~/.local/bin/claude` is a native Claude Code install, not an Omarchy wrapper; never remove or replace it;
   - the google-cloud-sdk lines in `~/.bashrc`.
5. **Updates go through `omageeko-update`** (`omarchy update` calls it). Never `zypper dup` from inside an agent without asking. A Tumbleweed upgrade is the user's call, and `omageeko-update` also rebuilds and gates the Omarchy layer afterwards.
6. **Privilege:** `sudo` is passwordless for this user. Still describe privileged actions before running them, and prefer the omarchy/omageeko commands that wrap them.
7. **Don't kill processes by pattern** (`pkill -f`, `pgrep -f`): it matches the agent's own shell. Kill by exact PID (from `hyprctl clients -j` or `pidof`).

## System at a Glance

| Component | omageeko | (Arch Omarchy) |
|---|---|---|
| Base OS | openSUSE Tumbleweed, rolling snapshots | Arch |
| Packages | zypper/rpm; Flathub; Omarchy's Arch repo in the `omageeko-arch` distrobox | pacman, AUR |
| Omarchy itself | RPMs `omageeko`, `omageeko-settings`, `omageeko-session`, `omageeko-hardware`, built locally from a pinned upstream + patches | `omarchy` pacman package |
| Local repo | `/var/lib/omageeko/repo` (zypper alias `omageeko-local`) | pkgs.omarchy.org |
| Boot | systemd-boot + `sdbootutil` + dracut, btrfs snapshots as boot entries | limine + mkinitcpio |
| Snapshots | snapper (root on btrfs; `/home` is XFS, not snapshotted) | snapper/limine |
| Login | lightdm → "Omarchy" uwsm session | sddm |
| Security | SELinux enforcing; PAM stacks in `/usr/lib/pam.d` | no SELinux |
| Time | chrony | systemd-timesyncd |

## Quick Commands

```bash
omageeko-update --check        # what's pending (OS, omageeko, apps); changes nothing
omarchy pkg add <arch-name>    # install by Omarchy/Arch name; translated to TW/Flathub/box
omageeko-box list              # apps living in the Arch box
snapper list                   # snapshots; see updates.md for rollback
rpm -qf <file>                 # which package owns a file
less ~/omageeko/packages/omageeko/overlay/INDEX.md   # every omageeko change to upstream, and why
```
