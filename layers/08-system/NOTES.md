# Layer 08 — notes

Status: **memory and scheduling part installed and verified 2026-10-30** (snapper pairs 266..267, 268..269). The rest of layer 08 (printing, mDNS, podman, firewalld) is not ported.

## Why not linux-omarchy (decision 2026-10-30)

Compared Omarchy's `linux-omarchy` 7.2.8 (omarchy-pkgs a224259) with TW `kernel-default` 7.3.0 on the P14s Gen 4 AMD:
- **Same in both configs:** HZ=1000, full dynamic preemption, sched_ext, BFQ/Kyber, NTSYNC, THP always, SELinux built in.
- **Different, reproduced at runtime here:** MGLRU on by default (tmpfiles), zswap (Omarchy turns it off anyway, in favour of zram), Kyber via udev.
- **Not reproducible without building it:** BORE (scx_lavd stands in), `-O3`, lazy RCU, ADIOS, scheduler/TLB/mm micro-patches, and about 150 hardware quirks, mostly for other machines. AMD-relevant: HDMI 2.1 FRL/VRR, an IOMMU perf option, ACP sound suspend.
- **Cost of a local build:** about an hour per bump, loses openSUSE's kernel patches and the prebuilt KMPs, and follows its own update track. Secure Boot is off (setup mode), so signing wasn't the blocker.

**Result:** stay on the TW kernel. `omarchy-kernel` (a Limine default-kernel switcher) and `omarchy-apply-pacman` are stubbed as not applicable.

## Findings while installing
- `systemd-experimental` creates the `systemd-oom` user through a sysusers file trigger. dbus-broker had already reloaded and logged `Invalid user-name in .../org.freedesktop.oom1.conf: user="systemd-oom"`, so oomd never got its bus name and `oomctl` timed out. A `ReloadConfig` plus an oomd restart fixes it; the layer does both.
- `systemd-tmpfiles --create` skips `w!` lines without `--boot`; `%post` passes it.
- The running user manager didn't register `app.slice` with oomd after `daemon-reload` (it connects when it starts), so registration waits for the next login.
- `scx.service` has `StartLimitBurst=2` per 30 s; a second restart within that window leaves it failed. The layer runs `reset-failed` first.
- scx_lavd runs in `initrc_t` under SELinux enforcing with no denials. oomd has its own domain (`systemd_oomd_t`).
- The tcp_bbr module loads on demand when the sysctl is applied.

## Values before → after (this machine)
| Setting | Before | After |
|---|---|---|
| swap | 2 GiB partition only (prio -1) | + zram0 = RAM size, zstd, prio 100 |
| vm.swappiness / vfs_cache_pressure / page-cluster | 60 / 100 / 3 | 150 / 50 / 0 |
| watermark boost / scale | 15000 / 10 | 0 / 125 |
| dirty limits | 10% / 20% of 54 GiB | 64 MiB / 256 MiB; writeback 15 s |
| TCP | cubic, pfifo_fast | bbr, fq |
| nvme0n1 scheduler | none | kyber |
| MGLRU | off | 0x0007 |
| CPU scheduler | EEVDF | scx_lavd --autopower (falls back to EEVDF if it exits) |
| OOM handling | kernel OOM killer only | systemd-oomd on app.slice |

## Reverting
- **One setting:** override it in `/etc` (an `/etc/sysctl.d` file, `systemctl disable --now scx.service`, a later `scx.service.d` drop-in, …).
- **Everything:** `sudo zypper remove omageeko-system` (plus zram-generator, systemd-experimental, scx if unwanted), or roll back to the snapper pre-snapshot.
