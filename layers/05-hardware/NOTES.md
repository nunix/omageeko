# Layer 05 — notes

Status: **installed and verified 2026-10-15** (snapper pair 75..80). Waiting on manual tests (fingerprint enrollment, lock, Bluetooth pairing, headset).

## Hardware audit (P14s Gen 4 AMD)
| Device | Result |
|---|---|
| Headphone jack / headset mic | worked, but panel showed "ALC257 Analog". Fixed with the UCM label rule |
| Laptop microphone (ACP6.3 DMIC via UCM Mic1) | works; noise floor -46/-49 dBFS; large DC offset (+0.08/+0.35) |
| HDMI/DP outputs (dock, 2 monitors) | labelled by monitor name, fine |
| Bluetooth | bluez was missing entirely. Installed, controller up. After the reboot, pairing looped: `bt-agent` (bluez-tools) was missing, so there was no pairing agent. Built bluez-tools; MX Master 3S re-paired and is stable |
| Power profiles | ppd was missing. performance/balanced/power-saver available (amd-pstate active) |
| Fingerprint (Goodix 27c6:6594) | supported by TW libfprint 1.94.10; fprintd sees it. Scope: lock screen only (user decision); enrollment pending |
| Lock screen | was refusing to lock (no PAM stack). Fixed, pam_unix path verified |
| Input method (fcitx5) | omarchy-fcitx5.service was crash-looping (fcitx5 missing). Fixed in layer 04 |
| Keyboard backlight, mute/micmute LEDs, brightness, cameras, Wi-Fi, s2idle | present |

## Upstream hardware scripts on this machine
All ran; only bluetooth.sh, vulkan.sh (already satisfied), network.sh (masks systemd-networkd-wait-online; TW uses NetworkManager) and fix-fkeys.sh (writes `hid_apple.conf`, inert without Apple keyboards) changed anything. platform-setup.sh is a no-op on x86.

## Open / optional
- DMIC DC offset: cosmetic for voice apps (they high-pass). A PipeWire filter-chain DC blocker could clean it if it causes pops.
- Battery charge thresholds (thinkpad_acpi supports start/end): Omarchy has no setting for it. Candidate omageeko addition.
- Bluetooth agent (`bt-agent.service`) only runs in the uwsm session (graphical-session.target).

## Displays (2026-10-15)
- Desk: DP-8 (Samsung C27G7, 2560x1440@240) | DP-9 + HDMI-A-1 (Odyssey G9 LS49AG95 in picture-by-picture: two 2560x1440@60 halves with the same serial). DP-9 sits at 0x0, DP-8 at `auto-center-left`, HDMI-A-1 at `auto-center-right`, and eDP-1 at `auto-center-down`, kept off by Omarchy's `internal-monitor-disable` toggle (toggles load after monitors.lua).
- Saved as a host file: `hosts/21K6S0A00C/home/.config/hypr/monitors.lua`.
- 2026-10-15: after the lock blanked the screens, the G9 went into deep standby, dropped HDMI-A-1, and on wake stayed dark on both halves. Hyprland and the kernel reported all outputs connected with DPMS on. A DPMS off/on cycle on DP-9 + HDMI-A-1 woke them. Automated: `omageeko-monitor-wake-kick` watches Hyprland's `monitoraddedv2` events and cycles DPMS on the monitors listed in `~/.config/omageeko/monitor-wake-kick` (host file: `LS49AG95`).
