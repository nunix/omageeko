# Layer 00 — notes

Status: **done, verified 2026-10-15** (snapper pair 5..10).

## Results on the reference machine
- Packman `dup --from` switched 17 packages (libav*, libheif*, libfdk-aac2, gdk-pixbuf-loader-libheif) and added libx264, libx265, libSvtAv1Enc, libvvenc and libcpuinfo-suse. Full gstreamer/ffmpeg CLI packages come in later layers as dependencies. Packman priority 90 keeps them on Packman.
- The builder image is ~TW base plus toolchains. Rebuild with `OMAGEEKO_REBUILD_BUILDER=1 layers/00-bootstrap/install.sh`.
- Re-running is a no-op (about 2 s, still takes an empty snapper pair).

## Deviations / decisions
- `createrepo_c` runs only in the builder, so it isn't installed on the host.
- Local repo `omageeko-local` has gpgcheck off. If repo signing is wanted, sign during consolidation (layer 99).
- `/var/lib/omageeko/repo` sits on the `/var` subvolume, so snapper rollbacks don't remove built RPMs.
