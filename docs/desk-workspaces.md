# Desk workspaces and column swap

Host configs in `hosts/21K6S0A00C/home/.config/hypr/`; layer 05 copies them into `~/.config/hypr/`.

## Workspaces per screen (Omarchy 4.5)

Since Omarchy 4.5 every screen has workspaces 1-10 of its own (`default/hypr/monitor-workspaces.lua`). Hyprland numbers them in a block of ten per screen, assigned once per physical monitor in `~/.local/state/omarchy/monitor-workspaces`: HDMI-A-1 got 1-10, DP-8 11-20, DP-9 21-30. Each bar shows its screen's block as 1-10 (the `count` setting on `omarchy.workspaces` in the host `shell.json`, an omageeko patch; upstream lists 1-5 plus any higher ones in use), and `Super + <n>` goes to workspace *n* of the focused screen.

The host `monitors.lua` used to pin 1/4 to DP-8, 2/5 to DP-9 and 3/6 to HDMI-A-1 as persistent workspace rules. Under 4.5 that showed workspaces twice in the bars (ids 1-6 all belong to HDMI-A-1's block, so its bar listed them, and the other bars listed theirs as visitors), so the rules are gone (2026-10-29). Upstream has no switch to turn per-screen workspaces off.

The workspace carousel (MX thumb wheel, 3-finger swipe; see `touchpad-and-mouse.md`) cycles the focused screen's own workspaces.

## Swap columns (`bindings.lua`)

`Super + Ctrl + Left/Right` runs `omarchy-hyprland-window-swap-columns left|right` (omageeko RPM):

- dwindle, one column split and the other a single window: the two columns trade sides in one step (the single window's parent is the root split, which is swapped);
- dwindle with both columns split (2x2): each left window swaps with its right neighbour;
- scrolling layout: the focused column swaps with its neighbour in the pressed direction.

Focus stays on the window that had it. These keys replaced Omarchy's "move grouped window focus"; `Super + Alt + Tab` and `Super + Alt + wheel` still cycle a group.

## Even out splits (`bindings.lua`)

`Super + \` runs `omarchy-hyprland-window-equalize-splits`: after resizing, the workspace's tiling splits go back to even halves, first the columns, then the rows inside each column (a 2×2 grid becomes four equal quarters). Hyprland 0.56's `splitratio` only takes a relative change, so the command reads the splits from the window geometry and resizes a window on each split line by half the difference. Only the tiling (dwindle) layout has splits; focus stays on the window that had it.
