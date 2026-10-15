# Agent prompt — omageeko layer 02: build RPMs

You are rebuilding layer 02 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00 and 01 must already verify. Read `PLAN.md`, `packages.map` (the entries marked `02 @build`) and `upstream.lock` (`pkgs_commit` pins `omacom/omarchy-pkgs`, which the specs port from).

## Goal

Build the desktop-critical software that Tumbleweed doesn't ship as local RPMs, inside the `omageeko-builder` container. Publish them to the local repo `/var/lib/omageeko/repo` (zypper alias `omageeko-local`) and install them on the host:

| Spec (`packages/<name>/`) | RPMs | Why |
|---|---|---|
| quickshell | quickshell | Omarchy's whole desktop shell (bar, notifications, OSD, lock, launcher, polkit) |
| owe | owe, owe-lockfeed | video/still wallpaper engine plus the lock screen frame feed (the 4.5 feature) |
| omarchy-hyprland-titlebars | same | Hyprland plugin for floating-workspace titlebars, loaded from `/usr/lib/omarchy-hyprland-titlebars/titlebars.so` |
| hyprland-preview-share-picker | same | screen share picker set in `xdph.conf` |
| jetbrains-mono-nerd-fonts | same | Omarchy configs use the family `JetBrainsMono Nerd Font` |
| ia-writer-fonts | same | iA Writer Mono/Duo/Quattro/Duospace |

## Pipeline

- `lib/build-rpm.sh <spec>` runs **inside** the builder. It syncs the builder (`zypper dup`), copies files next to the spec into SOURCES and installs `rpmspec -q --buildrequires`. It then downloads remote `SourceN` URLs from `rpmspec -P` (TW has no spectool; a `#/name` fragment renames the file), runs `rpmbuild -ba`, copies the RPMs to `/repo/<arch>` and `/repo/src`, and runs `createrepo_c --update`.
- `layers/02-build-rpms/install.sh` runs on the host:
  1. Refuses to continue if the builder's TW snapshot is newer than the host's. Built RPMs must not need newer libraries; run `sudo zypper dup` first.
  2. Builds each package only when its **stamp** changed. The stamp is the sha256 of `packages/<name>/` plus the repo candidate versions (`zypper info`) of the packages listed in `packages/<name>/rebuild-on`. This mirrors Omarchy's `rebuild_on`: quickshell → `libQt6Core6` (Qt private API), titlebars → `hyprland` (plugin ABI), owe → libmpv2/libavcodec/Qt, share-picker → gtk4. Force with `OMAGEEKO_REBUILD=all` or `OMAGEEKO_REBUILD="quickshell owe"`. Build logs go to `/var/lib/omageeko/repo/.logs/<name>.log`.
  3. Inside a snapper pair, runs `zypper install --from omageeko-local` for the RPM set, then `fc-cache -f`.

## Porting rules (Arch PKGBUILD → TW spec)

- Release is `<pkgrel>.omageeko`. Add a header comment naming the PKGBUILD and version being ported.
- Prefer `cmake(Qt6Foo)` / `pkgconfig(foo)` BuildRequires. Qt private APIs need `qt6-*-private-devel`.
- Use TW macros: `%cmake` (Ninja via `%define __builder ninja`), `%meson`, `%{_userunitdir}`, `%{_ttfontsdir}`, `%reconfigure_fonts_scriptlets`.
- Pacman hooks become RPM scriptlets (owe's restart hook becomes `%posttrans`). quickshell's Qt-upgrade compat hook is replaced by the `rebuild-on` stamp plus a `verify.sh` check (`quickshell --private-check-compat`).

## Gotchas hit (and the fixes in the specs)

- `%meson` already passes `--buildtype=plain`. Adding `-Dbuildtype=…` makes meson fail.
- owe-lockfeed's CMake builds tests by default and needs `cmake(Qt6Test)`. owe's tests shell out to the `ffmpeg` CLI, so `BuildRequires: ffmpeg`. The `transition` test is skipped because containers have no real GL timing.
- The builder carries Packman (layer 00 Containerfile), so owe links against the same ffmpeg the host runs.
- **Hyprland plugins on TW:**
  - `hyprland-devel` lacks `glslang-devel` and `lua55-devel` requirements (packaging gap, worth reporting).
  - `lua.h` lives in `/usr/include/lua5.5`, so add `pkg-config --cflags lua5.5` to CXXFLAGS.
  - SUSE's `%cmake` adds `-Wl,--no-undefined` to shared links. Plugins need undefined symbols resolved by the compositor, so override `CMAKE_SHARED_LINKER_FLAGS`.
  - The plugin's Release embeds the Hyprland version (`.h0.56.2`), and the RPM `Requires: hyprland = <that version>`.
- TW has no `qt6-svg-imports`. `libQt6Svg6` ships the qsvg image/icon plugins.

## Verification

`layers/02-build-rpms/verify.sh` must exit 0. It checks that every RPM is installed from omageeko-local, that quickshell runs and passes its Qt compat check, the titlebars path and that its Hyprland version matches the installed one, the owe commands, unit and QML module, and the font families.

**Manual test (live session):** `hyprctl plugin load /usr/lib/omarchy-hyprland-titlebars/titlebars.so`, then `hyprctl plugin list`, then `hyprctl plugin unload …`. Also `quickshell --version`.
