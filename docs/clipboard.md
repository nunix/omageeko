# Clipboard history

omageeko uses Omarchy's own clipboard manager (shell plugin `omarchy.clipboard`): a themed Quickshell panel with search, fed by two `wl-paste --watch` watchers (text and PNG images).

| Open it | |
|---|---|
| `Super + Shift + V` | host `bindings.lua` (omageeko) |
| `Super + Ctrl + V` | Omarchy default |
| bar clipboard icon | host `~/.config/omarchy/shell.json`: a `command` module before the tray, click runs `omarchy-shell shell toggle omarchy.clipboard` |

Stored: text, images and screenshots (deduplicated by content, files in `~/.local/state/omarchy/clipboard-images`), copied files. History: `~/.local/state/omarchy/clipboard-history.json`. Password-manager copies (`x-kde-passwordManagerHint`) are skipped.

Rich objects copied inside apps (a Google Slides shape, a spreadsheet range) are kept as the image or the plain text the app also offers, not as the live object. Restoring them would need the clipboard to offer several formats at once, which `wl-copy` can't do.
