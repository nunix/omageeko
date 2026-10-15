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

## BLE mouse never reconnecting after sleep (2026-10-15): root cause and fix
- Symptom: the MX Master 3S paired and worked until its first disconnect (sleep or power-off). After that it stayed in "connecting" forever. The Jabra (BR/EDR) was unaffected. Re-pairing from pairing mode always worked.
- Investigation (btmon captures): after the disconnect the kernel correctly added the mouse to the controller's accept list (0x0011) and, because the mouse shared its IRK, to the resolving list (0x0027). It enabled address resolution (`ll-privacy` is on with this Qualcomm controller) and ran a filtered passive scan. The controller reported zero advertisements.
- Cause: a resolving-list peer defaults to **Network Privacy Mode**, so the controller drops advertisements that carry the peer's identity address. The MX Master reconnects from its static identity address, so every reconnect was silently discarded. Pairing mode uses an unfiltered scan, which is why pairing worked.
- Fix: device flag 0x02 (**Device Privacy Mode**) for bonded LE peers. The mouse reconnected within 1 s of setting it. `omageeko-hardware` ships `/usr/libexec/omageeko/bt-device-privacy` plus `omageeko-bt-device-privacy.{service,timer}` (at bluetooth start and every 60 s), enabled by layer 05.
- Not used: BlueZ `Privacy = device` in main.conf also turns on local privacy. Devices bonded without the local IRK (this capture showed a zero local IRK) could then fail to reconnect.
- Dead ends, for the record: a "missing LongTermKey" (normal for LE Secure Connections: BlueZ stores the single key as PeripheralLongTermKey), and turning address resolution off for the device (a fresh pairing resets flags; the accept/resolve state wasn't consistent at the time).
- Mistakes during debugging: a host-side `bluetoothctl disconnect` disables BlueZ auto-connect until the next Connect (invalid test), and `bluetoothctl --timeout 5 connect` cancels its own Connect call. Use `busctl --timeout=90 call org.bluez <dev> org.bluez.Device1 Connect`.

## Ported from nunix/omarchy-mac branches (2026-10-15)
- Workspace carousel (`feature/workspace-carousel`, `personal/mx2`): `omarchy-hyprland-workspace-carousel` in the overlay. Change from the branch: workspace ids are global in Hyprland, so the "next empty" slot skips ids that live on another monitor. Otherwise, with 2 on DP-8 and 3 on DP-9, scrolling on HDMI-A-1 jumped to another screen.
- MX thumb wheel binds and the Mac-like touchpad (natural scroll, disable while typing, reversed 3-finger swipes) are host files: `hosts/21K6S0A00C/home/.config/hypr/{bindings,input}.lua`. Gesture actions use `hl.exec_cmd`.
- iPhone tethering (`feature/iphone-tethering`): TW names are `usbmuxd` and `imobiledevice-tools` (there is no `libimobiledevice` package).
- Desk workspaces (2026-10-15): 1/4 on DP-8, 2/5 on DP-9, 3/6 on HDMI-A-1 as persistent workspace rules in the host `monitors.lua`. The bar lists ids 1-5 plus existing ones, so persistence alone makes it show six (no shell patch). The carousel cycles a screen's pinned pair. `Super + Ctrl + Left/Right` swaps columns (`omarchy-hyprland-window-swap-columns`). No column swap existed in the omarchy-mac branches.
- Offline config check: Omarchy's bootstrap loads modules from `$HOME/.config`, so validating staged host files needs a temporary HOME (symlinked ~/.config entries + copied hypr/ with the host files), not XDG_CONFIG_HOME.
