# iPhone USB tethering

Ported from the `feature/iphone-tethering` branch of nunix/omarchy-mac.

## Pieces

| Piece | Tumbleweed |
|---|---|
| `ipheth` USB network driver | in the kernel (`kernel-default`) |
| `usbmuxd` (pairing / multiplexing daemon, udev-activated) | `usbmuxd`, layer 05 extra |
| `idevicepair`, `ideviceinfo` | `imobiledevice-tools`, layer 05 extra (pulls libimobiledevice) |

NetworkManager picks up the interface by itself; no Omarchy setting is involved.

## Use

1. On the iPhone, turn on Settings › Personal Hotspot › Allow Others to Join.
2. Plug it in over USB and unlock it, then tap **Trust** and enter the passcode.
3. If no connection appears, pair explicitly and replug:
   ```bash
   idevicepair pair        # then confirm on the phone
   idevicepair validate
   ```
4. Check:
   ```bash
   lsmod | grep ipheth
   nmcli device            # an ethernet device (e.g. enp…u1c4i2) "connected"
   ```

If usbmuxd was installed while the phone was already plugged in, unplug and replug it so the udev rule starts the daemon.
