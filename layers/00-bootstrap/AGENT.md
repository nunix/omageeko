# Agent prompt — omageeko layer 00: bootstrap

You are rebuilding layer 00 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed) on a fresh Tumbleweed install. The install used the generic desktop role plus the podman, kvm and hyprland roles. The project repo is checked out at `~/omageeko`. Read `~/omageeko/PLAN.md` (sections 3 and 4) first.

## Goal

Prepare the host so later layers can build and install omageeko without putting toolchains on the host:

1. Host packages: `git-core` and `podman`. Nothing else. Compilers belong in the builder image.
2. Packman Essentials repo (`https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/`, alias `packman-essentials`, priority 90, autorefresh). Import its key, then `zypper dup --from packman-essentials --allow-vendor-change` so the codec stack (libav*, ffmpeg, gstreamer plugins) comes from Packman.
3. Local RPM repo at `/var/lib/omageeko/repo`, owned by the user (on `/var`, so it's outside root snapshots). Initialise it with `createrepo_c`, run *inside the builder*. Register it in zypper as `omageeko-local`: `dir:` URL, priority 80, `--no-gpgcheck` (local, self-built).
4. Builder image `localhost/omageeko-builder:tw` from `layers/00-bootstrap/Containerfile`. It's based on `registry.opensuse.org/opensuse/tumbleweed` with rpm-build, rpmdevtools, createrepo_c, gcc/g++, cmake, ninja, meson, pkgconf, go, rust/cargo and git. Per-package BuildRequires are *not* baked in. They're installed at build time from each spec, with a persistent `omageeko-zypp-cache` volume.
5. Fetch upstream Omarchy at the commit in `upstream.lock` into `~/omageeko/upstream`: `git init` + shallow fetch of the exact commit + detached checkout. Never edit this tree.

## Rules

- Run as the normal user. Use `sudo` only for zypper and repo directories (passwordless sudo is expected).
- Idempotent: every step checks state first. Re-running must be a no-op apart from refreshes.
- Wrap the run in a snapper pre/post pair described as `omageeko: 00-bootstrap` (`lib/common.sh` `snap_begin`/`snap_end`).
- Rootless podman maps container root to the invoking user. Run the builder as container root (no `--userns=keep-id`) so it can zypper-install BuildRequires, while outputs on the host stay user-owned. Use `--security-opt label=disable` for the bind mounts (SELinux is enforcing on the host).
- Don't change the bootloader, the display manager, or any desktop config in this layer.

## Implementation

- Shared helpers: `lib/common.sh` (`require_user`, `zypper_install`, `snap_begin`/`snap_end`, `fetch_upstream`, `in_builder`).
- Script: `layers/00-bootstrap/install.sh`. Rebuild the builder image with `OMAGEEKO_REBUILD_BUILDER=1`.

## Verification

`layers/00-bootstrap/verify.sh` must exit 0. It checks git, rootless podman, the Packman repo, a Packman-vendored libavcodec, the local repo (repodata, registered), the builder image and its toolchains, that builder writes come out user-owned, and that upstream is at the pinned commit with the quattro layout (`default/hypr/bootstrap.lua`).
