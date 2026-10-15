# Desk workspaces and column swap

Host configs in `hosts/21K6S0A00C/home/.config/hypr/`; layer 05 copies them into `~/.config/hypr/`.

## Workspaces pinned per screen (`monitors.lua`)

| Screen | Position | Workspaces |
|---|---|---|
| DP-8 | left | 1, 4 |
| DP-9 | center | 2, 5 |
| HDMI-A-1 | right | 3, 6 |

Each is a persistent workspace rule bound to its screen, so all six always exist and the bar shows 1-6. `Super + <n>` and window rules sending an app to workspace *n* always land on the same screen. Each screen starts on its lower number. With only the laptop panel on, Hyprland puts all six there.

Hyprland applies the rules on config reload too, so installing the file while working moves existing workspaces to their screens.

The workspace carousel (MX thumb wheel, 3-finger swipe; see `touchpad-and-mouse.md`) cycles the focused screen's pinned pair, e.g. 1 ↔ 4 on DP-8.

## Swap columns (`bindings.lua`)

`Super + Ctrl + Left/Right` runs `omarchy-hyprland-window-swap-columns left|right` (omageeko RPM):

- dwindle, one column split and the other a single window: the two columns trade sides in one step (the single window's parent is the root split, which is swapped);
- dwindle with both columns split (2x2): each left window swaps with its right neighbour;
- scrolling layout: the focused column swaps with its neighbour in the pressed direction.

Focus stays on the window that had it. These keys replaced Omarchy's "move grouped window focus"; `Super + Alt + Tab` and `Super + Alt + wheel` still cycle a group.
