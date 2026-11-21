-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Monitor scale is Hyprland's scale for the output. It sizes everything
-- Wayland-native, accepts fractions (1.6, 1.75), and applies immediately.
-- "auto" lets Hyprland pick per display.
local omarchy_monitor_scale = "auto"
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Desk layout, left to right: DP-8 (C27G7) | DP-9 + HDMI-A-1 (Odyssey G9 halves,
-- picture-by-picture), laptop panel centered below DP-9. Positions are explicit:
-- eDP-1 connects before the dock's DP MST outputs, so relative positions
-- (auto-center-*) placed it at 0x0 and shoved DP-9 aside. Omarchy's internal-
-- monitor toggle (SUPER+CTRL+Delete, persistent) still decides whether eDP-1 is on.
hl.monitor({ output = "DP-8", mode = "preferred", position = "-2560x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "DP-9", mode = "preferred", position = "0x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "2560x0", scale = omarchy_monitor_scale })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "320x1440", scale = 1 })

-- Workspaces are per screen since Omarchy 4.5: each one has its own 1-10
-- (default/hypr/monitor-workspaces.lua), so none are pinned here.

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- GDK scale is GDK_SCALE, the factor GTK draws its own UI at. It's what
-- sizes X11/XWayland windows, which Omarchy leaves unscaled so they stay
-- crisp instead of being stretched by the compositor. GTK only honors whole
-- numbers, so use the nearest integer to the monitor scale, and restart an
-- app for a change to reach it.
local omarchy_gdk_scale = 1
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
