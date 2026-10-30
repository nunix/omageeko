# Agent prompt — omageeko layer 08: system (memory and scheduling part)

You are rebuilding the memory and scheduling part of layer 08 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00–05 must verify. The rest of layer 08 (printing, mDNS, podman, firewalld, the `08` entries in `packages.map`) is not ported yet: don't install `map_packages 08` here.

## Goal

Give the stock Tumbleweed kernel Omarchy's memory and scheduling behaviour, using Omarchy's own files wherever they exist and only Tumbleweed packages (no kernel build):

1. Build and install the `omageeko-system` RPM (subpackage of `packages/omageeko/omageeko.spec`). Its Requires pull in `zram-generator`, `systemd-experimental` (TW ships systemd-oomd there) and `scx`.
2. Start swap on zram now: `systemctl daemon-reload`, then `systemctl start dev-zram0.swap` (as Omarchy's migration 1790984500 does).
3. Reload dbus-broker's policy (`busctl call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig`), then enable and restart `systemd-oomd.service`. **Why:** dbus-broker reloads as soon as systemd-experimental's files land, before sysusers creates `systemd-oom`, and then rejects oomd's bus name (`Invalid user-name ... systemd-oom`) until the next reload; `oomctl` times out.
4. `systemctl --user daemon-reload` so the user manager reads `app.slice.d/10-oomd.conf`. The user manager registers `app.slice` with oomd when it starts, so a session older than oomd only shows up after the next login.
5. Enable `scx.service`, `reset-failed` it (the unit allows 2 starts per 30 s), restart it and wait for `/sys/kernel/sched_ext/state` to read `enabled` (scx_lavd takes about 3 s).

## What omageeko-system ships

From the pinned upstream tree, at TW's vendor paths (so `/etc` stays the admin's):

| Upstream file | Installed as |
|---|---|
| `default/systemd/zram-generator.conf.d/90-omarchy.conf` | `/usr/lib/systemd/zram-generator.conf.d/` (zram = RAM size, zstd, priority 100) |
| `etc/sysctl.d/99-omarchy-sysctl.conf`, `90-omarchy-file-watchers.conf` | `/usr/lib/sysctl.d/` (reclaim tuned for zram, 64M/256M dirty caps, BBR + fq, MTU probing, inotify) |
| `etc/systemd/oomd.conf.d/10-omarchy.conf` | `/usr/lib/systemd/oomd.conf.d/` (50% pressure for 20 s) |
| `default/systemd/user/app.slice.d/10-oomd.conf` | `/usr/lib/systemd/user/app.slice.d/` (only user apps are kill candidates) |
| `etc/tmpfiles.d/omarchy-zswap.conf` | `/usr/lib/tmpfiles.d/` (zswap off in front of zram; TW's default is already off) |
| `etc/udev/rules.d/60-omarchy-io-scheduler.rules` | `/usr/lib/udev/rules.d/` (Kyber on whole disks) |

omageeko additions (`overlay/share/system/`):
- `omageeko-mglru.conf` (tmpfiles, boot-only `w!`): multi-gen LRU on. Omarchy's kernel enables it at build time; TW's builds it in but leaves it off.
- `scx-lavd.conf`, a `scx.service` drop-in: `SCX_SCHEDULER_OVERRIDE=scx_lavd`, `SCX_FLAGS_OVERRIDE=--autopower`. This stands in for the BORE patch in Omarchy's kernel. `--autopower` follows power-profiles-daemon (layer 05).

`%post system` applies sysctl, the boot-only tmpfiles (`--boot`) and the udev rule right away, and try-restarts oomd and scx. Enabling units stays in this layer.

Left out on purpose: `etc/modprobe.d/omarchy-usb-autosuspend.conf`. It isn't a performance setting, and it costs battery.

## Verification

`layers/08-system/verify.sh` must exit 0. It checks:
- zram0 active, zstd, priority 100; zswap off; MGLRU 0x0007
- every key in Omarchy's two sysctl files live, unless `/etc` overrides it
- Kyber on each whole disk
- oomd active with Omarchy's pressure limit, and `app.slice` registered (info only until the next login)
- scx.service enabled and active, sched_ext running lavd
- no SELinux denials for oomd/zram/scx this boot
