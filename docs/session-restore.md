# Session restore

Status: built and installed (2026-11-04); waiting on the first real reboot
(test plan steps 2-7). Pieces:

- `omageeko-session-restore` (Python, `overlay/bin/`; the name avoids the
  `omageeko-session-restore` RPM): `save | restore | offer | status | dismiss | auto`;
- `omarchy-system` patch (`patches/omarchy-system-session-save.patch`);
- user units `omageeko-session-restore-offer.service` and
  `omageeko-session-restore-save.{service,timer}` (omageeko-session RPM,
  enabled by layer 04);
- bar widget `omageeko.session-restore` (`overlay/shell/plugins/omageeko-session-restore/`);
- menu entry System › Session (`menu-transform.py`).

The sections below are the original plan; where the build differs, it says so.

Decided (2026-11-04):
- Restore runs on a click. A slider toggle in the widget's popup turns on
  automatic restore at login. It is off by default.
- Terminal windows are not saved or restored.
- Brave's "Continue where you left off" is already on (set in
  `brave://settings`), so part 3.2 needs no install step.

Goal: save which apps are open and the workspace each one sits on, and put them
back on the same workspaces after a reboot. If the monitors are exactly the same
as when the session was saved, every window goes back to its own monitor and
workspace. If not, everything opens on the main monitor, on the same workspace
number (1-10) it had.

A bar widget in `centerEnd`, after `omarchy.weather` and before
`omarchy.system-update`, shows when there is a session to restore and runs the
restore.

## What the desk looks like today

Captured with `hyprctl clients/monitors/workspaces -j` while writing this plan:

| Monitor | Connector | Identity (state file) | Block | Windows |
|---|---|---|---|---|
| C27G7, left | DP-8 | `Samsung … LC27G7xT H4ZN902129` | 1 (ws 11-20) | ws 11: Slack, Gmail webapp, Calendar webapp |
| G9 left half | DP-9 | `Samsung … LS49AG95 HNTW500105` | 2 (ws 21-30) | ws 21: Brave (YouTube) |
| G9 right half | HDMI-A-1 | `Samsung … LS49AG95 HNTW500105 #2` | 0 (ws 1-10) | ws 1: Brave (new tab), ws 2: agent terminal |

What this means for the design:

- **The two G9 halves report the same make, model and serial.** The only
  difference between them is the connector. So the "same monitors" check has to
  compare connectors as well as identities, and it can't treat the
  `#2` suffix from `monitor-workspaces.lua` as stable on its own.
- **Workspaces are saved as (monitor identity, slot 1-10), and also as the raw
  id.** Blocks belong to the physical monitor (in
  `~/.local/state/omarchy/monitor-workspaces`), so on the same desk the raw id
  is enough. On a different desk, the slot is what carries over.
- **Every Brave window runs in a single process (pid 7224)**: normal browser
  windows and webapps alike. The pid and `/proc/<pid>/cmdline` can't tell them
  apart. Only the window class can:
  - `brave-browser`: a normal browser window. There can be several, each on its
    own workspace, all with the same class. The title (the active tab) is what
    tells them apart.
  - `brave-<host><path with / → _>-Default`: a webapp launched with
    `omarchy-launch-webapp <url>` (Chromium builds the class from `--app=URL`;
    it drops the query and fragment). Today:
    - `brave-mail.google.com__mail_u_1_-Default` ← `GMail.desktop`
      (`https://mail.google.com/mail/u/1/#inbox`)
    - `brave-calendar.google.com__calendar_u_1_r-Default` ←
      `Google Calendar.desktop` (`https://calendar.google.com/calendar/u/1/r?pli=1`)
- **Slack is a Flatpak** (`com.slack.Slack`). Its pid is inside the sandbox, so
  it has to be launched with `flatpak run`, not from its cmdline.
- **Some apps live in the Arch box** (`omageeko-arch-*.desktop`: Claude, Zed,
  gliff, localsend). They have to be launched through their desktop entry so
  they go through distrobox.
- **Brave's last exit is recorded as `Crashed`** and `session.restore_on_startup`
  isn't set. Today Brave neither restores windows nor shuts down cleanly. See
  part 3.

## Part 1: capture (`omageeko-session-restore save`)

A new command, `overlay/bin/omageeko-session-restore` (Python 3, like
`omarchy-hyprland-window-equalize-splits`: the matching and the event listener
are easier to get right there than in bash + jq), with subcommands `save | restore | status | discard`.

`save` writes `~/.local/state/omageeko/session.json`, using a temp file and a
rename so a crash can't leave a half-written file:

```json
{
  "version": 1,
  "saved": "2026-11-04T18:02:11+01:00",
  "monitors": [
    { "connector": "DP-8", "identity": "Samsung … LC27G7xT H4ZN902129", "block": 1,
      "mode": "2560x1440", "position": "-2560x0", "scale": 1 }
  ],
  "main": "DP-9",
  "windows": [
    { "kind": "webapp", "class": "brave-mail.google.com__mail_u_1_-Default",
      "launch": { "desktop": "GMail.desktop" },
      "title": "Inbox - …", "workspace": 11, "slot": 1,
      "monitor": "Samsung … LC27G7xT H4ZN902129", "connector": "DP-8",
      "floating": false, "at": [-1273, 36], "size": [1261, 689] }
  ]
}
```

Steps:

1. Monitors: from `hyprctl monitors -j` plus the block file (connector →
   identity → block). The **fingerprint** is the sorted list of
   `connector|identity|mode|position|scale`.
2. Windows: from `hyprctl clients -j`. Skip special workspaces, and
   `mapped=false` and `hidden` windows. Sort by workspace and then by
   position, so restoring in that order rebuilds the tiling layout roughly as
   it was.
3. Classify each window. This is the part the browsers depend on:

   | Kind | How it's recognised | Launch recorded |
   |---|---|---|
   | `brave` | class `brave-browser` (more generally, the class of the default browser's desktop entry) | none per window. One browser launch covers them all (part 3) |
   | `webapp` | class `^brave-.+-Default$`, or any Chromium-family prefix | the desktop entry whose `omarchy-launch-webapp "<url>"` produces this class; else the URL rebuilt from the class |
   | `flatpak` | `/proc/<pid>/root/.flatpak-info`, or class = a Flatpak app id | `flatpak run <app-id>` |
   | `box` | desktop entry `omageeko-arch-*` whose `StartupWMClass` or name matches | that desktop entry |
   | `desktop` | desktop entry with `StartupWMClass` = class, or file name = class | `gtk-launch <entry>` / `uwsm-app -- <entry>` |
   | `cmdline` | anything left | `/proc/<pid>/cmdline`, marked as best effort |
   | skip | terminals (Alacritty, foot, kitty, ghostty, and any class whose desktop entry has `Categories=…TerminalEmulator`), `org.omarchy.agent`, pickers, OSD and polkit dialogs, pinned floating helpers (autoclicker), anything listed in an exclude file | — |

   The webapp lookup: read every `*.desktop` file in
   `~/.local/share/applications`, take the URL from
   `Exec=omarchy-launch-webapp "<url>"`, build
   `brave-<host><path with / → _>-Default` from it, and keep a table from
   class to desktop entry. A webapp class that doesn't match any entry is
   rebuilt as `https://<host>/<path>` (the query is lost) and flagged in the
   status output.
4. **Never save an empty or nearly empty session over a good one.** If there
   are fewer than 2 windows and a saved session exists, keep the old one, so
   a save during logout, after some windows have closed, can't wipe it.

When it saves:

- **On reboot, shutdown and logout, before windows are closed.** That means a
  fuzz-0 patch to upstream `bin/omarchy-system`: run
  `omageeko-session-restore save || true` in `exit_session` before
  `omarchy-hyprland-window-close-all`. This is a small patch, so it goes in
  `patches/`, with a row in `overlay/INDEX.md`.
- **Autosave every 5 minutes** (a user systemd timer
  `omageeko-session-save.timer`), so a power cut or hard reset still leaves a
  recent session. Skip the write if nothing changed.
- **Manually**, from the widget menu or `omageeko-session-restore save`.

## Part 2: monitors (same desk or a different one)

At restore time, build the fingerprint again from the live monitors.

- **Exact match**: same connectors, identities, modes, positions and scales.
  Every window goes back to its saved `workspace` id, which is its own
  monitor's block. Floating windows also get back their `at`/`size`.
- **Anything else** (laptop only, a different dock, a G9 half missing, a
  connector renamed): every window goes to slot `slot` of the **main
  monitor**, i.e. workspace `block(main) * 10 + slot`. Windows from different
  monitors that had the same slot end up together on that workspace, which is
  what was asked for. Floating windows are centred instead of positioned.

  The main monitor is chosen in this order: the saved `main` connector if it
  is present, then the monitor at `0x0`, then the internal panel (`eDP-*`),
  then the monitor with focus. On this desk that's DP-9 (G9 left half, at
  0x0). It can be set in `~/.config/omageeko/session.conf`
  (`main=DP-9`).

The workspace ids come from the block file, so restore never has to call
`o.workspaces.focus()`. A window sent to workspace 23 lands on DP-9 because
Hyprland and `monitor-workspaces.lua` already agree that block 2 is DP-9.
Moving windows with `movetoworkspacesilent` keeps the focused screen from
changing.

## Part 3: browsers and webapps

This is the hard part. Brave runs one process with one session file for every
window.

1. **Shut Brave down cleanly.** `omarchy-hyprland-window-close-all` closes
   windows one at a time with a 2 s limit. Chromium records each window as it
   closes, so it only remembers the last one, and the timeout is why the exit
   shows up as `Crashed`. In the same `omarchy-system` patch, after the save,
   send `SIGTERM` to the browser's main process. Its exact pid comes from
   `hyprctl clients -j` (per rule 7: never by pattern). Wait up to 5 s for it
   to exit before `close-all`. Chromium handles SIGTERM like Quit, so it
   saves the whole session and records a clean exit.
2. **Brave's "Continue where you left off"** is already on (set by the user in
   `brave://settings`). Brave brings back every window and its tabs. We don't
   need the URLs, and we can't read them from outside Brave anyway. On a
   reinstall, set it again in Brave settings; it's mentioned in the layer 05
   NOTES.
3. **Restore**: launch the browser once (`omarchy-launch-browser`). Brave
   brings back N `brave-browser` windows. Match each one to a saved entry by
   title (the saved active tab). Titles show up late, so also listen for
   `windowtitlev2` events, not only `openwindow`, for up to 20 s. Exact title
   first, then the longest common prefix. Windows left unmatched after that
   are paired with the remaining saved entries in creation order. Anything
   still unmatched stays where Brave put it.
4. **Webapps**: Chromium may or may not bring back `--app` windows itself (the
   `Apps_*` files in `Default/Sessions` suggest it might). So don't decide
   ahead of time. After the browser launch, wait until no new Brave windows
   have appeared for about 3 s, then launch only the saved webapps whose class
   isn't already on screen. That avoids duplicate Gmail and Calendar windows
   whichever way Brave behaves. To be confirmed in test step 3.
5. **One webapp open twice** (two windows with the same class): launch it once
   per missing window and assign windows in order.

Other browsers: the same logic is keyed on the default browser's class
(`omarchy-cmd-default-browser`). Firefox-family browsers have their own
session restore and no webapps; same title matching.

## Part 4: restore (`omageeko-session-restore restore`)

1. Load `session.json`. Stop if it's missing, if its `version` is unknown, or
   if a restore has already run in this Hyprland instance (marker
   `$XDG_RUNTIME_DIR/omageeko-session-restore.restored`).
2. Work out the target workspace for every window (part 2).
3. Start a listener on Hyprland's event socket
   (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`, read
   directly from Python; no `socat`). On `openwindow` / `windowtitlev2`, match the new window against
   the pending list: class first, then title for browser windows, then launch
   order. Then run
   `hyprctl dispatch movetoworkspacesilent <ws>,address:0x…`, and set
   floating/position where needed. Windows that don't match anything aren't
   touched.
4. Launch, in this order: the browser first (part 3), then the webapps it
   didn't bring back, then everything else, in saved workspace order, with a
   short gap between launches so the tiling order holds. Each app is launched
   **once per saved window** of that class, except browsers.
5. Stop the listener after everything is placed, or after 60 s. Write a short
   report to `~/.local/state/omageeko/session-restore.log` (placed / launched
   but not matched / couldn't launch). Notify only if something failed.
6. Tell the bar widget to refresh (`omarchy-shell` IPC, see part 5).

**At login** (`omageeko-session-restore offer`, run once per login):

- **Auto-restore off (the default)**: a notification ("Restore 6 windows
  from 18:02? Restore / Dismiss") and the bar icon. Restore runs on a click.
- **Auto-restore on**: `restore` runs straight away, with no prompt.

The setting is `auto=true|false` in `~/.config/omageeko/session.conf`. The
slider in the widget popup writes it (part 5), and
`omageeko-session-restore auto on|off|status` does the same from the CLI. Built:
`offer` runs from the `omageeko-session-restore-offer.service` user unit
(`WantedBy=graphical-session.target`), so it ships in the RPM rather than in
`~/.config` hooks.

## Part 5: bar widget (`omageeko.session-restore`)

A shell plugin modelled on `bar/widgets/SystemUpdate.qml`. It stays hidden
when there's nothing to do, the same way the update icon does.

- Placement in the host `shell.json` (`hosts/21K6S0A00C/home/.config/omarchy/shell.json`):

  ```json
  "centerEnd": [
    { "id": "omarchy.elsewhen", … },
    { "id": "omarchy.weather" },
    { "id": "omageeko.session-restore" },
    { "id": "omarchy.system-update" }
  ]
  ```

- States, from `omageeko-session-restore status --json`:
  - **hidden**: nothing saved, or this login's restore has already run or
    been dismissed;
  - **pending** (restore icon, e.g. `󰑓`): a saved session exists that hasn't
    been restored since login. The tooltip shows "6 windows · saved 18:02 ·
    same monitors" or "… · monitors changed: all on DP-9";
  - **restoring** (spinner): while the listener is running;
  - **partial** (warning tint): the last restore left something unmatched.
    The tooltip says what.
- Left click: restore. Right click: a small `PopupCard` with:
  - a **"Restore at login" slider** (`ToggleSwitch` from `qs.Ui`), bound to
    `omageeko-session-restore auto status`. Flipping it runs
    `omageeko-session-restore auto on|off`;
  - buttons: Restore, Save now, Dismiss, Open log.
- The slider has to be reachable even when there's nothing to restore. So
  the popup also opens from a "Session restore" entry in the Omarchy menu
  (`menu-transform.py` INSERT), next to Save now. The bar icon itself stays
  hidden when there's nothing to restore.
- `ShellIpc { target: "omageeko.session-restore" }` with `refresh()`, called by the
  command after save, restore and dismiss. Also a slow timer (5 min) as a
  backup.
- Plugin rules from `plugins.md`: `Text.PlainText` for window titles (they
  are untrusted), `Style.duration()` for the spinner, strings in
  `i18n/en.json` (plural entry for "%1 windows").
- Durable home: a built-in plugin in the omageeko RPM (`overlay/share/` →
  `/usr/share/omarchy/shell/plugins/omageeko.session/`, plus `%files`),
  so it works like the other bar widgets and survives a reinstall. A user
  plugin under `~/.config/omarchy/plugins/` is the fallback if the shell
  won't load extra plugins from the packaged dir.

## Part 6: packaging (omageeko checkout)

| Piece | Where |
|---|---|
| `omageeko-session-restore` | `packages/omageeko/overlay/bin/` (packaged automatically) |
| save before close + Brave SIGTERM | `packages/omageeko/patches/NNNN-omarchy-system-session-save.patch` (fuzz 0) |
| autosave timer + service | `overlay/share/systemd/user/omageeko-session-save.{service,timer}`, `install` + `%files` lines in `omageeko.spec`, enabled in layer 04 |
| bar widget | `overlay/share/shell/plugins/omageeko.session/` + `%files` |
| widget placement | `hosts/21K6S0A00C/home/.config/omarchy/shell.json` |
| Brave startup setting | already set by the user; a line in layer 05 NOTES for reinstalls |
| menu entry for the popup | `menu-transform.py` INSERT |
| why each change exists | `overlay/INDEX.md` rows |
| user doc | this file, rewritten from plan to doc once built |
| checks | layer 03 `verify.sh`: the command is on PATH, `omageeko-session-restore status --json` parses, the patch is applied (`grep omageeko-session-restore $(which omarchy-system)`) |

## Part 7: test plan

1. `save` on the current desk. Check that `session.json` lists Slack (flatpak),
   Gmail and Calendar (webapp, mapped to their desktop entries), the 2
   `brave-browser` windows with their titles, and leaves out the agent
   terminal.
2. `omarchy reboot`. Check that Brave's `exit_type` is `Normal` afterwards, and
   that the widget shows "pending · same monitors".
3. Click restore. Check that Slack, Gmail and Calendar land on DP-8 ws 11
   (slot 1), YouTube Brave on DP-9 ws 21 and the new-tab Brave on HDMI-A-1
   ws 1, with no duplicate webapps. Note whether Brave brought back the `--app`
   windows itself (this decides how much of part 3.4 matters).
4. Different monitors: unplug the dock and reboot on the laptop panel alone.
   Everything should land on eDP-1's block, slots 1/1/1/1/1 (all of them are
   slot 1 today). Repeat with only DP-8 connected.
5. Pull the power during a session. The autosaved session (at most 5 min
   old) should be offered at the next login.
6. Turn on the "Restore at login" slider and reboot. The windows should come
   back with no prompt. Turn it off, reboot, and check that the prompt is
   back.
7. Log out with only one window open. The previous good session must be kept
   (the rule in part 1, step 4).

## Open points

- Does Chromium bring back `--app` windows with "Continue where you left
  off"? Settled by test step 3; part 3.4 works either way.
- Terminals: settled, they are skipped.
- Login trigger: settled, a systemd user unit on `graphical-session.target`.
