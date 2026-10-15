#!/usr/bin/env python3
"""omageeko: audit Omarchy menu sections for Tumbleweed readiness.
For each menu action: commands it runs (and omarchy-* commands they call, 2 levels),
external programs referenced, whether they exist here, stubs, Arch references."""
import json, os, re, shlex, shutil, sys
MENU = "/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc"
SECTIONS = sys.argv[1:] or ["apps", "learn", "trigger", "style", "setup", "about", "system"]
txt = re.sub(r"^\s*//.*$", "", open(MENU).read(), flags=re.M)
txt = re.sub(r",(\s*[}\]])", r"\1", txt)
menu = json.loads(txt)
entries = []
def walk(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if isinstance(v, dict) and ("label" in v or "action" in v or "target" in v):
                entries.append((k, v))
            walk(v)
walk(menu)

SHELL_WORDS = set("""if then else elif fi for do done while case esac in function return exit local
export set unset source echo printf read test true false shift break continue eval exec cd pwd
declare readonly trap wait sleep command type hash kill let mapfile select time until
cat grep sed awk cut tr sort uniq head tail wc xargs find mkdir rm cp mv ln touch chmod chown
basename dirname date env tee stat readlink realpath mktemp sh bash timeout pgrep pkill seq
printf true false id whoami tput stty""".split())
def script_path(cmd):
    p = shutil.which(cmd)
    return p if p and os.path.isfile(p) else None
def is_stub(path):
    try: return "# omageeko: stub" in open(path, errors="ignore").read()
    except Exception: return False
FUNCS = set()
def commands_in_script(path):
    """external commands invoked in code lines (rough heuristic)"""
    found = set()
    try: lines = open(path, errors="ignore").read().splitlines()
    except Exception: return found
    if not lines or not lines[0].startswith("#!") or "bash" not in lines[0] and "sh" not in lines[0]:
        return found
    heredoc = None
    for line in lines:
        fm = re.match(r"\s*(?:function\s+)?([A-Za-z_][A-Za-z0-9_-]*)\s*\(\)", line)
        if fm: FUNCS.add(fm.group(1))
        s = line.strip()
        if heredoc:
            if s == heredoc: heredoc = None
            continue
        m = re.search(r"<<-?\s*['\"]?([A-Za-z_]+)['\"]?", s)
        if m: heredoc = m.group(1)
        if not s or s.startswith("#"): continue
        s = re.sub(r"(['\"]).*?\1", " ", s)            # drop quoted strings
        for seg in re.split(r"\|\||&&|[;|&(){}`]|\$\(|\bthen\b|\bdo\b|\belse\b", s):
            w = seg.strip().split()
            while w and ("=" in w[0] and not w[0].startswith("=")):
                w = w[1:]                                # VAR=x cmd
            if w and w[0] in ("sudo", "setsid", "exec", "uwsm-app", "nohup", "command", "--"):
                w = w[1:] if w[0] != "uwsm-app" else [x for x in w[1:] if x != "--"]
            if not w: continue
            c = w[0]
            if re.fullmatch(r"[a-z][a-z0-9._+-]*", c) and c not in SHELL_WORDS:
                found.add(c)
    return found
def expand(cmds, depth=2):
    seen, frontier = set(cmds), set(cmds)
    for _ in range(depth):
        nxt = set()
        for c in frontier:
            if c.startswith("omarchy-"):
                p = script_path(c)
                if p:
                    for x in commands_in_script(p):
                        if x not in seen: nxt.add(x)
        seen |= nxt; frontier = nxt
    return seen
import subprocess
_real = {}
def is_real_command(c):
    if c.startswith("omarchy-"): return True
    if c not in _real:
        r = subprocess.run(["zypper", "--no-refresh", "-q", "se", "--provides", f"/usr/bin/{c}"], capture_output=True, text=True)
        _real[c] = r.returncode == 0 and "|" in r.stdout
    return _real[c]
ARCH = re.compile(r"\b(pacman|yay|makepkg|mkinitcpio|limine[a-z-]*|ufw|systemd-boot|archlinux|wiki\.archlinux)\b")
report = {}
for key, v in entries:
    sec = key.split(".")[0]
    if sec not in SECTIONS: continue
    action = v.get("action") or ""
    target = v.get("target") or ""
    if not action and not target: continue
    if target:
        report[key] = {"label": v.get("label"), "kind": "link", "target": target,
                       "arch": bool(ARCH.search(target))}
        continue
    try: toks = shlex.split(action)
    except ValueError: toks = action.split()
    first = set()
    for t in toks:
        t = t.strip("'\"")
        for part in re.split(r"[;&|]+", t):
            part = part.strip().split()
            if part and re.fullmatch(r"[a-z][a-z0-9._+-]*", part[0]) and part[0] not in SHELL_WORDS:
                first.add(part[0])
    allc = expand(first)
    missing = sorted(c for c in allc if not shutil.which(c) and c not in FUNCS and is_real_command(c))
    stubs = sorted(c for c in allc if c.startswith("omarchy-") and script_path(c) and is_stub(script_path(c)))
    arch = sorted({c for c in allc if c.startswith("omarchy-") and script_path(c)
                   and ARCH.search("\n".join(l for l in open(script_path(c), errors="ignore") if not l.lstrip().startswith("#")))})
    report[key] = {"label": v.get("label"), "kind": "action", "missing": missing, "stubs": stubs, "arch": arch}
json.dump(report, sys.stdout, indent=1)
