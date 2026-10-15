# Layer 02 — notes

Status: **built and verified 2026-10-15** (snapper pair 29..32). Waiting on the manual plugin-load test in a live Hyprland session.

## Results
- All six specs build in the container. 25 new host packages (7 omageeko RPMs plus deps like libmpv2, qt6-multimedia, Quick3D).
- Re-running is about 12 s when nothing changed (stamp checks plus an empty zypper transaction).
- quickshell: all features on (Hyprland, Wayland, PAM, polkit, PipeWire, Bluetooth, networking, UPower, greetd, tray). CRASH_HANDLER is off (breakpad not packaged on TW).

## TW issues found
- `hyprland-devel` should require `glslang-devel` and `lua55-devel` (its headers include both). Candidate bug report for TW's hyprland package.

## Deferred
- Omarchy apps (omasnap, aether, gliff, herdr, ttfx, omacalc, omacut, omawrite, signed, hype, monologue, cliamp, disktree, try, tzupdate) are in `packages.map` as `08 @build` and use this same pipeline in layer 08.
- The pinned `omarchy-pkgs` commit is recorded, but the specs are hand-ported. When bumping, diff the PKGBUILDs between the old and new `pkgs_commit`.

## 2026-10-15: ttfx
- `ttfx` (omacom, Rust) added: the screensaver animates the branding text with it and failed without it. Moved from layer 08 to 02 in packages.map.
