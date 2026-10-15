# Touchpad and MX thumb wheel

Ported from the `feature/workspace-carousel` and `personal/mx2` branches of nunix/omarchy-mac. The host configs live in `hosts/21K6S0A00C/home/.config/hypr/`; layer 05 copies them into `~/.config/hypr/`.

## Workspace carousel

`omarchy-hyprland-workspace-carousel <left|right>` (in the omageeko RPM) cycles the focused monitor's workspaces:

- the occupied workspaces 1-5 on that monitor,
- plus the first free one after them (ids already living on another monitor are skipped, so focus never jumps to another screen),
- wrapping around at both ends.

With windows on 1 and 3, `right` goes 1 → 3 → 4 → 1.

When the screen has pinned workspaces (persistent rules, see `desk-workspaces.md`), it cycles exactly those (plus occupied 1-5 there) and adds no free slot.

## MX thumb wheel (`bindings.lua`)

```lua
o.bind("mouse_left", "Previous workspace (carousel)", "omarchy-hyprland-workspace-carousel left")
o.bind("mouse_right", "Next workspace (carousel)", "omarchy-hyprland-workspace-carousel right")
```

`mouse_left`/`mouse_right` are Hyprland's horizontal wheel events. Any horizontal scroll (the thumb wheel, a tilt wheel, or a sideways two-finger swipe on the touchpad) switches workspaces, and apps no longer get horizontal scrolling. Use `SUPER + mouse_left` / `SUPER + mouse_right` as the keys to keep it.

## Touchpad (`input.lua`)

- `natural_scroll = true`: content follows the fingers.
- `disable_while_typing = true`.
- 3-finger swipe left → carousel `right`, swipe right → carousel `left`. Reversed on purpose, as on macOS: the next workspace slides in from the right.

## Check

```bash
hyprctl configerrors                         # empty
hyprctl getoption input:touchpad:natural_scroll
omarchy-hyprland-workspace-carousel right    # moves within the focused monitor
```
