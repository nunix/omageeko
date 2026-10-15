# Agent prompt — omageeko layer 05: hardware

You are rebuilding layer 05 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00–04 must verify. Reference machine: Lenovo ThinkPad P14s Gen 4 AMD (Ryzen 7 PRO 7840U, Radeon 780M, ALC257 codec + ACP6.3 digital mics, Goodix 27c6:6594 fingerprint reader).

## Goal

Make the laptop hardware work the Omarchy way:

1. Build and install `bluez-tools` (packages/bluez-tools, port of Arch extra/bluez-tools). It provides `bt-agent`, which Omarchy's `bt-agent.service` runs as the auto-accept pairing agent. **It is not part of bluez and not packaged by TW.** Without it bluetoothd logs `No agent available` and devices loop between connecting and pairing.
2. Install `map_packages 05` (bluez, power-profiles-daemon, libfprint-2-2, fprintd, fprintd-pam, usbutils, libvulkan_radeon) and the `omageeko-hardware` RPM.
3. Run **Omarchy's own** `install/hardware/all.sh` as root. Each script gates itself on a hardware match. Provide `run_logged` and skip the Arch-only `pacman.sh`. Env: `OMARCHY_PATH`, `OMARCHY_INSTALL`, PATH with `/usr/share/omarchy/bin`. Leaf scripts use `omarchy-pkg-add`, so Arch names they pass need `packages.map` entries (`vulkan-radeon`, `libfprint-git`, …).
4. Enable and start `bluetooth.service` and `power-profiles-daemon.service`.
5. Run `omarchy-apply-lock`. The Quickshell lock screen **refuses to lock** while `/etc/pam.d/omarchy-lock-password` is missing.
6. Copy machine-specific user files from `hosts/<DMI product_name>/home/` into `$HOME` (backing up files that differ). For example, `hosts/21K6S0A00C/home/.config/hypr/monitors.lua` is the desk layout.
7. Remove any user-level copy of the audio label rule and restart wireplumber.

## Tumbleweed deltas (in packages/omageeko)

- **Patch `omarchy-apply-lock`:** `account include system-local-login` becomes `common-account`. TW has no `system-local-login`, and an include of a missing stack breaks authentication.
- **Patch `omarchy-setup-security-fingerprint`:**
  - Copy `/usr/lib/pam.d/{sudo,polkit-1}` to `/etc/pam.d` before editing (TW ships vendor stacks in `/usr/lib/pam.d`).
  - The created polkit stack includes `common-{auth,account,password,session}`.
  - Packages go through `omarchy-pkg-add` (`libfprint-git` maps to `libfprint-2-2`), plus `fprintd-pam`, which TW splits out.
  - **Scope (user decision 2026-10-15): the fingerprint unlocks the lock screen only.** By default the command enrolls, verifies and runs `omarchy-apply-lock` (creating `/etc/pam.d/omarchy-lock-fingerprint`), but skips the sudo/polkit PAM edits. `--all` restores upstream's sudo + polkit + lock setup. lightdm's first login stays password-only, which is also what unlocks the GNOME keyring.
  - The user's sudo is `NOPASSWD`, so sudo never runs PAM auth either way. The scope keeps polkit prompts and any non-NOPASSWD use password-only.
  - Removed from `stubs.tsv`.
- **Patch `omarchy-remove-security-fingerprint`:** guard the `/etc/pam.d/sudo` grep (the file exists on TW only after `--all`).
- **`omageeko-hardware`** ships `/usr/share/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf`. UCM laptop nodes otherwise take `node.nick` from the codec PCM name ("ALC257 Analog") for both the headphone jack and the headset mic, and Omarchy's audio panel labels rows by `node.nick`. The rule names `HiFi__Headphones/Speaker/Mic1/Mic2` nodes "Headphones (jack)", "Laptop speakers", "Laptop microphone" and "Headset mic (jack)".
- TW's alsa-ucm-conf exposes Speaker and Headphones as **separate card profiles**. While the jack is plugged, only the Headphones sink exists, and unplugging switches back to the speaker. That's expected UCM behaviour, not a bug.

## Verification

`layers/05-hardware/verify.sh` must exit 0. It checks:
- the hardware RPM
- bt-agent installed, and `bt-agent.service` running in the uwsm session
- bluetooth active with a controller visible
- ppd active with performance/balanced/power-saver profiles
- the audio node nicks (no codec names)
- that the lock PAM file exists and its includes resolve on TW, and that fprintd sees the reader
- that sudo/polkit/common-auth don't use pam_fprintd (lock-screen-only policy)
- the AMD Vulkan driver

Fingerprint enrollment is reported as info until done.

Extra lock-stack check without a real password: `/tmp/omageeko-tools/pamcheck.py`, a ctypes PAM client (TW has no pamtester). Run a wrong-password attempt against `omarchy-lock-password` and confirm the journal shows `pam_unix(omarchy-lock-password:auth): authentication failure`. Then run `faillock --user $USER --reset`.

**Manual:** `omarchy-setup-security-fingerprint` (interactive enrollment), the lock screen (Super+Ctrl+L), Bluetooth pairing in the panel, and switching to the headset in the audio panel.

A device stuck from pairing attempts without an agent stays half-connected: `bluetoothctl remove <mac>`, then pair again (panel, or `bluetoothctl pair <mac>` + `trust`).
