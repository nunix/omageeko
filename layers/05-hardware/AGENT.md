# Agent prompt — omageeko layer 05: hardware

You are rebuilding layer 05 of **omageeko** (Omarchy `quattro` on openSUSE Tumbleweed). Layers 00–04 must verify. Reference machine: Lenovo ThinkPad P14s Gen 4 AMD (Ryzen 7 PRO 7840U, Radeon 780M, ALC257 codec + ACP6.3 digital mics, Goodix 27c6:6594 fingerprint reader).

## Goal

Make the laptop hardware work the Omarchy way:

1. Install `map_packages 05` (bluez, power-profiles-daemon, libfprint-2-2, fprintd, fprintd-pam, usbutils, libvulkan_radeon) and the `omageeko-hardware` RPM.
2. Run **Omarchy's own** `install/hardware/all.sh` as root. Each script gates itself on a hardware match. Provide `run_logged` and skip the Arch-only `pacman.sh`. Env: `OMARCHY_PATH`, `OMARCHY_INSTALL`, PATH with `/usr/share/omarchy/bin`. Leaf scripts use `omarchy-pkg-add`, so Arch names they pass need `packages.map` entries (`vulkan-radeon`, `libfprint-git`, …).
3. Enable and start `bluetooth.service` and `power-profiles-daemon.service`.
4. Run `omarchy-apply-lock`. The Quickshell lock screen **refuses to lock** while `/etc/pam.d/omarchy-lock-password` is missing.
5. Remove any user-level copy of the audio label rule and restart wireplumber.

## Tumbleweed deltas (in packages/omageeko)

- **Patch `omarchy-apply-lock`:** `account include system-local-login` becomes `common-account`. TW has no `system-local-login`, and an include of a missing stack breaks authentication.
- **Patch `omarchy-setup-security-fingerprint`:**
  - Copy `/usr/lib/pam.d/{sudo,polkit-1}` to `/etc/pam.d` before editing (TW ships vendor stacks in `/usr/lib/pam.d`).
  - The created polkit stack includes `common-{auth,account,password,session}`.
  - Packages go through `omarchy-pkg-add` (`libfprint-git` maps to `libfprint-2-2`), plus `fprintd-pam`, which TW splits out.
  - Removed from `stubs.tsv`.
- **`omageeko-hardware`** ships `/usr/share/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf`. UCM laptop nodes otherwise take `node.nick` from the codec PCM name ("ALC257 Analog") for both the headphone jack and the headset mic, and Omarchy's audio panel labels rows by `node.nick`. The rule names `HiFi__Headphones/Speaker/Mic1/Mic2` nodes "Headphones (jack)", "Laptop speakers", "Laptop microphone" and "Headset mic (jack)".
- TW's alsa-ucm-conf exposes Speaker and Headphones as **separate card profiles**. While the jack is plugged, only the Headphones sink exists, and unplugging switches back to the speaker. That's expected UCM behaviour, not a bug.

## Verification

`layers/05-hardware/verify.sh` must exit 0. It checks:
- the hardware RPM
- bluetooth active with a controller visible
- ppd active with performance/balanced/power-saver profiles
- the audio node nicks (no codec names)
- that the lock PAM file exists and its includes resolve on TW, and that fprintd sees the reader
- the AMD Vulkan driver

Fingerprint enrollment is reported as info until done.

Extra lock-stack check without a real password: `/tmp/omageeko-tools/pamcheck.py`, a ctypes PAM client (TW has no pamtester). Run a wrong-password attempt against `omarchy-lock-password` and confirm the journal shows `pam_unix(omarchy-lock-password:auth): authentication failure`. Then run `faillock --user $USER --reset`.

**Manual:** `omarchy-setup-security-fingerprint` (interactive enrollment), the lock screen (Super+Ctrl+L), Bluetooth pairing in the panel, and switching to the headset in the audio panel.
