# omageeko

Omarchy (quattro) desktop on openSUSE Tumbleweed, built layer by layer. See `PLAN.md` for the analysis and roadmap.

## Layout

```
upstream.lock          pinned omacom/omarchy (quattro) and omacom/omarchy-pkgs commits
upstream/              fetched upstream tree (not edited, regenerated from the lock)
packages.map           every upstream package -> TW package / @build / @flatpak / skip, with owning layer
packages/<name>/       RPM spec (+ patches, rebuild-on) for software missing on Tumbleweed
packages/omageeko/     the Omarchy port itself: omageeko.spec, patches/, overlay/ (bin replacements,
                       stubs.tsv, INDEX.md = everything omageeko changes upstream)
hosts/<dmi-product>/   machine-specific files (home/ is copied into $HOME by layer 05)
docs/                  feature docs (touchpad-and-mouse.md, desk-workspaces.md, iphone-tethering.md)
archive/omaweed/       the retired omaweed branch (installers, diff) and what was ported from it
lib/common.sh          shared helpers for layer scripts
lib/build-rpm.sh       builds one spec inside the builder container
layers/NN-name/
  AGENT.md             prompt for an agent to (re)build this layer on a fresh TW install
  install.sh           human-runnable, idempotent install script
  verify.sh            checks the layer is working (exit 0 = good)
  NOTES.md             findings, deviations from upstream, open issues
  Containerfile        when the layer's work runs in a container (00: omageeko-builder)
```

Anything that can run in a container does (builds, repo metadata). The host only gets what it runs.

## Layer contract

- Run only after the previous layers verify.
- Idempotent: safe to re-run.
- Wraps system changes in a snapper pre/post pair named `omageeko: <layer>`.
- A layer is frozen (AGENT.md + install.sh final) only after it works in a real session.

## Reinstall procedure (target)

1. Install TW: generic desktop + podman, kvm, hyprland roles.
2. `git clone <this repo> ~/omageeko`
3. Run `layers/*/install.sh` in order, or `omageeko-install` once consolidated.
