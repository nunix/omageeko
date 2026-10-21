# Layer 02 — notes

Status: **built and verified 2026-10-15** (snapper pair 29..32). Waiting on the manual plugin-load test in a live Hyprland session.

## Results
- All six specs build in the container. 25 new host packages (7 omageeko RPMs plus deps like libmpv2, qt6-multimedia, Quick3D).
- Re-running is about 12 s when nothing changed (stamp checks plus an empty zypper transaction).
- quickshell: all features on (Hyprland, Wayland, PAM, polkit, PipeWire, Bluetooth, networking, UPower, greetd, tray). CRASH_HANDLER is off (breakpad not packaged on TW).

## TW issues found
- `hyprland-devel` should require `glslang-devel` and `lua55-devel` (its headers include both). Candidate bug report for TW's hyprland package.

## Deferred
- Omarchy apps (omasnap, aether, gliff, herdr, omacalc, omacut, omawrite, signed, hype, monologue, cliamp, disktree, try, tzupdate) are in `packages.map` as `08 @build` and use this same pipeline in layer 08.
- The pinned `omarchy-pkgs` commit is recorded, but the specs are hand-ported. When bumping, diff the PKGBUILDs between the old and new `pkgs_commit`.

## 2026-10-15: ttfx
- `ttfx` (omacom, Rust) added: the screensaver animates the branding text with it and failed without it. Moved from layer 08 to 02 in packages.map.

## Packman lagging Tumbleweed (2026-10-21)
- Snapshot 20261020 dropped `liboapv1`; Packman's ffmpeg 9 (`libavcodec63`) still required `liboapv.so.1`, so it could not be installed in a fresh builder, and owe's BuildRequires failed. The host was unaffected (it keeps the orphaned `liboapv1`).
- `lib/build-rpm.sh` now retries BuildRequires once with Packman disabled inside the throwaway build container (Tumbleweed's own ffmpeg 9, same sonames). owe's `%check` skips its `media` test when the build ffmpeg lacks `libx264` (only Packman's has it); at runtime owe uses the host's Packman ffmpeg.
