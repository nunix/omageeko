# Tumbleweed facts that differ from Arch

## Boot

- systemd-boot, managed by **`sdbootutil`**: kernels and initrds (dracut) are installed per btrfs snapshot. `sudo bootctl list --no-pager` shows the entries; `sudo sdbootutil list-entries` shows the snapshot mapping.
- Kernel command line: `/etc/kernel/cmdline`, then `sudo sdbootutil update-all-entries`. Don't edit the files under `/boot/efi/loader/entries` by hand.
- initramfs: `sudo dracut -f` for the running kernel; drop-ins in `/etc/dracut.conf.d/`. There's no mkinitcpio.
- Omarchy's limine, UKI and "direct boot" commands are stubs on omageeko.

## Config locations

| Thing | Tumbleweed |
|---|---|
| Vendor defaults | `/usr/etc/` (e.g. `/usr/etc/nsswitch.conf`); copy to `/etc/` to override |
| PAM | vendor stacks in `/usr/lib/pam.d/`; `common-auth`, `common-account`, `common-password`, `common-session` (no `system-auth` / `system-local-login`). To change a service, copy it to `/etc/pam.d/` first |
| Sysctl, modprobe, udev | `/usr/lib/…` vendor, `/etc/…` local, as on Arch |
| Time sync | `chronyd` (`chronyc tracking`, `chronyc makestep`) |
| Firewall | `firewalld` (`firewall-cmd`) |
| Display manager | lightdm (`/etc/lightdm/`); sessions in `/usr/share/wayland-sessions/` |
| Session env | uwsm: `/usr/share/uwsm/env.d/*` (omageeko), `~/.config/uwsm/env.d/*` (user) |

## SELinux (enforcing)

- `getenforce`; denials: `sudo ausearch -m avc -ts recent` or `journalctl -t audit`.
- Files copied into system paths keep the wrong label. Run `sudo restorecon -Rv <path>` after placing them.
- Don't switch to permissive to "fix" something; find the denial.

## Containers

- Podman, rootless. `podman-docker` provides `docker`; sudoless Docker means the user's rootless podman.
- The `omageeko-arch` distrobox holds Omarchy's Arch repo (key `40DFB630…71`, lsigned).
- The omageeko builder image `localhost/omageeko-builder:tw` builds the RPMs (`~/omageeko/layers/00-*`).

## Logs

`journalctl -b` (system), `journalctl --user -b` (session), `journalctl --user -u 'wayland-wm*'` (Hyprland via uwsm).
