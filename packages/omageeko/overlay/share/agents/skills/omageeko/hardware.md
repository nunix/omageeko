# Hardware on omageeko

Machine-specific user files live in the checkout under `hosts/<DMI product name>/home/`. Layer 05 copies them into `$HOME`, backing up anything that differs. Product name: `cat /sys/class/dmi/id/product_name`. Edit the host file in the checkout, then copy it (or rerun layer 05); editing only `~/.config` is lost on reinstall.

## Bluetooth (BLE mice that won't reconnect)

- With LL privacy on, a bonded device whose resolving-list entry is in *Network Privacy Mode* has its identity-address adverts dropped. MX mice advertise that way after a power cycle, so they never reconnect.
- Fix shipped in `omageeko-hardware`: `/usr/libexec/omageeko/bt-device-privacy` sets device flag 0x02 (*Device Privacy Mode*) on bonded BLE devices; `omageeko-bt-device-privacy.service` plus a 60 s timer reapply it.
- Testing pitfalls:
  - A host-side `bluetoothctl disconnect` disables auto-connect, so the test is invalid.
  - `bluetoothctl --timeout` cancels its own Connect. Use `busctl --timeout=90 call org.bluez /org/bluez/hci0/dev_XX_XX… org.bluez.Device1 Connect`.
- The pairing agent is `bt-agent` (bluez-tools, built by omageeko).

## Monitors

- The layout is in the host file `~/.config/hypr/monitors.lua`. Workspaces are per screen since Omarchy 4.5 (each its own 1-10), so it pins none; see `~/omageeko/docs/desk-workspaces.md`.
- Some monitors stay dark after deep standby (Samsung Odyssey G9). `omageeko-monitor-wake-kick` (user service) cycles DPMS on the monitors listed in `~/.config/omageeko/monitor-wake-kick` when Hyprland re-adds them. `omageeko-monitor-wake-kick --kick-now` runs a cycle by hand.
- Hyprland's Lua config rejects `hyprctl keyword`; use `hyprctl eval '…'` and `hl.dsp.*` dispatchers.
- Validate config changes: `hyprctl configerrors` (live), or `Hyprland --verify-config` through a wrapper that stubs `hl.timer` (it segfaults on it).

## Audio, fingerprint, input

- Laptop audio is UCM (SOF/ACP). Readable node names come from `/usr/share/wireplumber/wireplumber.conf.d/60-omageeko-ucm-labels.conf`.
- `Super+Shift+K` restarts the desktop shell (`omarchy-restart-shell`).
- `Super+Shift+S` takes a screenshot (`omarchy-capture-screenshot`, same as PRINT and Trigger › Capture › Screenshot).
- Fingerprint: lock screen only (the default of the patched `omarchy-setup-security-fingerprint`). `--all` adds sudo + polkit, but agents then can't use sudo unattended; don't enable it.
- The MX thumb wheel and 3-finger swipes run `omarchy-hyprland-workspace-carousel`; `Super+Ctrl+←/→` runs `omarchy-hyprland-window-swap-columns`, `Super+\` runs `omarchy-hyprland-window-equalize-splits` (host `bindings.lua` / `input.lua`).
- iPhone USB tethering: `usbmuxd` + `imobiledevice-tools`, the `ipheth` driver is in-kernel; trust the phone, replug if needed.
