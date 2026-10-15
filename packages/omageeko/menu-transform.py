#!/usr/bin/env python3
"""omageeko: build-time edits to Omarchy's menu (default/omarchy/omarchy-menu.jsonc)
and its translations (default/i18n/*/menu.json). Run from the spec's %prep inside
the upstream tree. Every rule must match, so upstream renames fail the build."""
import json, pathlib, re, sys

MENU = pathlib.Path("default/omarchy/omarchy-menu.jsonc")
I18N = pathlib.Path("default/i18n")

# (menu id, field, new value): set a field on a single-line menu entry
SET = [
    ("install.package", "icon", ""),      # openSUSE logo instead of Arch (nf-linux-opensuse)
    ("remove.package", "icon", ""),
    ("install.aur", "icon", "\U000f03d7"),       # package glyph: Flathub replaces the AUR
    ("install.aur", "label", "Flathub"),
]
# menu ids to drop (with their children): channels that don't exist on omageeko
DROP = ["update.channel.rc", "update.channel.edge"]
# translated labels to override in every language that defines them (brand names)
I18N_LABELS = {"install.aur": "Flathub"}

def entry_re(mid):
    return re.compile(r'^(\s*"' + re.escape(mid) + r'"\s*:\s*\{)(.*)(\},?\s*)$', re.M)

def main():
    text = MENU.read_text()
    for mid, field, value in SET:
        rx = entry_re(mid)
        m = rx.search(text)
        if not m:
            sys.exit(f"menu-transform: entry {mid} not found")
        body = m.group(2)
        fre = re.compile(r'("' + field + r'"\s*:\s*)"(?:[^"\\]|\\.)*"')
        if not fre.search(body):
            sys.exit(f"menu-transform: {mid} has no {field}")
        body = fre.sub(lambda f: f.group(1) + json.dumps(value, ensure_ascii=False), body, count=1)
        text = text[:m.start(2)] + body + text[m.end(2):]
    for mid in DROP:
        rx = re.compile(r'^\s*"' + re.escape(mid) + r'(\.[^"]*)?"\s*:.*\n', re.M)
        text, n = rx.subn("", text)
        if n == 0:
            sys.exit(f"menu-transform: entry {mid} not found to drop")
    MENU.write_text(text)

    changed = 0
    for f in sorted(I18N.glob("*/menu.json")):
        data = json.loads(f.read_text())
        touched = False
        for mid, label in I18N_LABELS.items():
            if isinstance(data.get(mid), dict) and "label" in data[mid]:
                data[mid]["label"] = label
                touched = True
        if touched:
            f.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
            changed += 1
    if changed == 0:
        sys.exit("menu-transform: no translation defines the overridden labels")
    print(f"menu-transform: {len(SET)} field edits, {len(DROP)} drops, {changed} translations")

if __name__ == "__main__":
    main()
