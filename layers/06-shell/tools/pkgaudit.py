import re, glob, os, subprocess, sys, json, shlex
names = {}
def add(n, src):
    n = n.strip().strip("'\"")
    if re.fullmatch(r"[a-z0-9][a-z0-9+._@-]*", n) and not n.startswith("-"):
        names.setdefault(n, set()).add(src)
# menu actions (omarchy-menu.jsonc, comments and trailing commas stripped)
def menu_entries(path="/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc"):
    txt = open(path).read()
    txt = re.sub(r"^\s*//.*$", "", txt, flags=re.M)
    txt = re.sub(r",(\s*[}\]])", r"\1", txt)
    out = []
    def walk(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if isinstance(v, dict) and "action" in v:
                    out.append((k, v.get("action", "")))
                walk(v)
        elif isinstance(o, list):
            for i in o: walk(i)
    walk(json.loads(txt))
    return out
for key, action in menu_entries():
    try: tok = shlex.split(action)
    except ValueError: continue
    for i, t in enumerate(tok):
        if t in ("omarchy-install-and-launch", "omarchy-install-app") and i + 2 < len(tok):
            for n in tok[i + 2].split(): add(n, key)
        if t == "omarchy-install-font" and i + 2 < len(tok): add(tok[i + 2], key)
# install/remove scripts
for f in glob.glob("/usr/bin/omarchy-install-*") + glob.glob("/usr/bin/omarchy-remove-*") + glob.glob("/usr/bin/omarchy-*-install"):
    try: src = open(f, errors="ignore").read()
    except Exception: continue
    if "# omageeko: stub" in src: continue
    for m in re.finditer(r"omarchy-pkg-(?:aur-)?(?:add|drop|present|missing)\s+([^\n;&|)]*)", src):
        for n in m.group(1).split():
            if n.startswith(("$", "\"$", "-")) or "=" in n: break
            add(n, os.path.basename(f))
for f in ("/usr/share/omageeko/pkgmap.tsv", "/usr/share/omageeko/repos.tsv"):
    if not os.path.exists(f):
        print(f"missing {f}: install the current omageeko first"); sys.exit(1)
pkgmap = {}
for line in open("/usr/share/omageeko/pkgmap.tsv"):
    a = line.rstrip("\n").split("\t"); pkgmap[a[0]] = (a[1], a[2] if len(a) > 2 else "")
repos = {l.split("\t")[0] for l in open("/usr/share/omageeko/repos.tsv") if l.strip() and not l.startswith("#")}
local_rpms = set(subprocess.run(["bash", "-c", "ls /var/lib/omageeko/repo/*/*.rpm 2>/dev/null | xargs -rn1 basename | sed -E 's/-[^-]+-[^-]+\\.[a-z0-9_]+\\.rpm$//'"], capture_output=True, text=True).stdout.split())
def in_repo(n):
    return subprocess.run(["zypper", "--no-refresh", "-q", "se", "-x", "-t", "package", n], capture_output=True).returncode == 0
def flathub(i):
    return subprocess.run(["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", f"https://flathub.org/api/v2/appstream/{i}"], capture_output=True, text=True).stdout == "200"
STOP = {"as", "each", "is", "quoted", "several", "so", "word"}  # words from code comments
bad, notyet, ok = [], [], 0
for n in sorted(names):
    if n in STOP: continue
    t, note = pkgmap.get(n, ("", ""))
    good = True
    if t == "": good = in_repo(n); why = "not on TW and not in packages.map"
    elif t == "-": notyet.append((n, note)); continue
    elif t == "@none": pass
    elif t.startswith("@repo:"):
        parts = t.split(":"); good = len(parts) == 3 and parts[1] in repos; why = f"repo alias {parts[1] if len(parts) > 1 else '?'} missing from repos.tsv"
    elif t.startswith("@flatpak:"): good = flathub(t.split(":", 1)[1]); why = f"{t} not on Flathub"
    elif t.startswith("@build"):
        rpm = t.split(":", 1)[1] if ":" in t else n; good = rpm in local_rpms; why = f"{rpm} not built in omageeko-local"
    else:
        missing = [x for x in t.split(",") if not in_repo(x)]; good = not missing; why = f"TW package(s) missing: {missing}"
    if good: ok += 1
    else: bad.append((n, why, ", ".join(sorted(names[n]))[:60]))
print(f"resolved={ok} not-yet-ported={len(notyet)} broken={len(bad)}")
for n, why, used in bad: print(f"  BROKEN {n:<30} {why}  (used by {used})")
for n, note in notyet: print(f"  later  {n:<30} {note}")
sys.exit(1 if bad else 0)
