# Layer 03 — notes

Status: **installed and verified 2026-10-15** (snapper pairs 37..40, 41..42). No visible change to the running desktop.

## Results
- `omageeko` + `omageeko-settings` 4.0.4+git20261014.84cfb93. They pulled in `uwsm` (+ python313-pyxdg).
- 519 `/usr/bin/omarchy*` commands: all of upstream's `bin/` (the `omarchy` router + 518 `omarchy-*`).
- 24 overlay replacements, 6 patches, 20 stubs. No remaining command invokes pacman/yay/limine/mkinitcpio/ufw.
- Tested by hand: `omarchy-version`, `omarchy-channel-current`, `omarchy-version-pkgs`, the pkg-present/missing translations, `omarchy-update-available` ("up to date": TW 20261013 is current), and a stub message.

## Not yet exercised (needs a session or a real update)
- `omarchy update` end to end (snapshot → zypper dup → migrations → shell restart). Planned once the session runs (layer 04/05), ideally when a new TW snapshot lands.
- The fzf pickers (`omarchy-pkg-install/remove/aur-install`) were checked for parsing only.

## Decisions
- The bar's update indicator reports newer **Tumbleweed snapshots** and newer omageeko-local RPMs.
- `omarchy update` still takes its own snapper snapshot, on top of the snapper-zypp-plugin pre/post pair. Slightly redundant, but it keeps upstream's flow.
- `omarchy-update-orphan-pkgs -y` (used by the update flow) only *reports* zypper's unneeded packages and never removes them unattended.
