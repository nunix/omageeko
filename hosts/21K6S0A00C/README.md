# 21K6S0A00C — Lenovo ThinkPad P14s Gen 4 (AMD)

Machine-specific files that layers/05-hardware/install.sh copies into $HOME
when /sys/class/dmi/id/product_name is `21K6S0A00C` (existing files are backed up).

- `home/.config/hypr/monitors.lua`: desk layout DP-8 (C27G7) | DP-9 + HDMI-A-1
  (Odyssey G9 picture-by-picture halves), DP-9 at 0x0, laptop panel centred below
  (kept off by Omarchy's internal-monitor toggle).
- `home/.config/omageeko/monitor-wake-kick`: the Odyssey G9 (model `LS49AG95`, both
  picture-by-picture halves). After deep standby it drops and re-adds HDMI-A-1 and
  then keeps both halves dark although they report DPMS on.
  `omageeko-monitor-wake-kick.service` (omageeko-hardware) cycles their DPMS on that
  reconnect.
