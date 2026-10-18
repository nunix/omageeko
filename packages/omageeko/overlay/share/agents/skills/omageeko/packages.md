# Packages on omageeko

## Order of preference

1. **Tumbleweed repos**: `sudo zypper install --no-recommends <pkg>`
2. **A vendor repo** (Chrome, Edge, VS Code, Brave, 1Password, NordVPN, Cursor, Sublime, mise, Symfony): enabled on first use by `omarchy pkg add`, from `/usr/share/omageeko/repos.tsv`
3. **Flathub**: system install, `flatpak install --system flathub <app-id>`
4. **The Arch box**: `omageeko-box install <pkg>` installs from Omarchy's Arch repo into the `omageeko-arch` distrobox and exports its launcher/commands. Use it only for apps that exist nowhere else.
5. **Build an RPM** in the omageeko checkout (`packages/<name>/`, see `source.md`). Use this for anything that should survive a reinstall and isn't packaged.

## Omarchy names → Tumbleweed

Omarchy commands and menus use Arch package names. `omarchy pkg add|drop|present|missing <name>` translate them through `/usr/share/omageeko/pkgmap.tsv`, which is generated from `~/omageeko/packages.map`:

| Target in packages.map | Meaning |
|---|---|
| `tw-name[,tw-name2]` | Tumbleweed package(s) |
| `@build[:rpm]` | built by omageeko into `omageeko-local` |
| `@repo:<alias>:<rpm>` | vendor repo from `repos.tsv` |
| `@flatpak:<app-id>` | Flathub |
| `@box:<pkg>` | the Arch box |
| `@none` | nothing needed on Tumbleweed (counts as installed) |
| `-` | not available / not applicable (the note says why) |

Names not in the map are assumed to be the same on Tumbleweed. Look a name up with `awk -F'\t' '$1=="<name>"' /usr/share/omageeko/pkgmap.tsv`.

## Useful zypper equivalents

| pacman | zypper |
|---|---|
| `pacman -S x` | `sudo zypper install --no-recommends x` |
| `pacman -Rns x` | `sudo zypper remove --clean-deps x` |
| `pacman -Ss x` | `zypper search x` (`-s` for versions) |
| `pacman -Qi x` | `rpm -qi x` / `zypper info x` |
| `pacman -Qo /file` | `rpm -qf /file` |
| `pacman -Ql x` | `rpm -ql x` |
| `pacman -Syu` | **don't**: use `omageeko-update` |
| `pacman -Qqe` | `zypper --no-refresh search --installed-only --userinstalled` (approx.) |

Gotchas:
- `/run/zypp.pid` holding a live PID means a transaction is running; wait instead of breaking the lock.
- `/var/log/zypp/history` is root-only.
- `--no-recommends` matches Omarchy's lean installs; Tumbleweed's default pulls recommends.
- Flatpak apps resolve URL handlers through `XDG_DATA_DIRS`; the session gets the Flatpak export dirs from `/usr/share/uwsm/env.d/20-omageeko-flatpak`.

## Menus

Install › Package / Remove › Package use zypper; Install › "Flathub" (upstream's AUR slot) lists Flathub apps; Install › OPI searches OBS/Packman; Remove › Flatpak removes Flatpak apps.
