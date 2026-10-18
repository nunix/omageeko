# The omageeko source (`~/omageeko`)

The checkout (GitHub `nunix/omageeko`, private) rebuilds the whole system on a fresh Tumbleweed install. Anything that should survive a reinstall belongs here.

## Layout

```
upstream.lock        pinned omacom/omarchy (commit, release, track=stable|edge) + omarchy-pkgs commit
packages.map         Arch name → Tumbleweed target, with the owning layer
layers/NN-*/         install.sh (human), verify.sh, AGENT.md (agent prompt), NOTES.md (findings)
packages/<name>/     RPM specs built in the builder container (lib/build-rpm.sh)
packages/omageeko/   the Omarchy RPMs: omageeko.spec, patches/, overlay/, menu-transform.py, migrations.tsv
  overlay/bin/       full replacements of upstream commands + omageeko-only commands
  overlay/share/     added files (units, uwsm env, wireplumber, this skill…)
  overlay/stubs.tsv  upstream commands stubbed as not applicable
  overlay/INDEX.md   every change to upstream, and why  ← read before changing anything
hosts/<model>/home/  per-machine user files (monitors, bindings, input…)
tools/omageeko-bump  upstream bump with gates; docs/bump-runbook.md resolves red reports
docs/                feature docs; PLAN.md, UPDATE-PLAN.md, TODO.md
```

Layers: 00 bootstrap/builder image · 01 base packages · 02 built RPMs · 03 Omarchy core (omageeko RPMs) · 04 session · 05 hardware + host files · 06 shell/menu apps. Each layer's `verify.sh` must pass.

## Making a change durable

| Change | Where |
|---|---|
| Fix an upstream command | a fuzz-0 patch in `packages/omageeko/patches/` (small change), or a full replacement in `overlay/bin/` (Tumbleweed rewrite); start it with a `# omageeko:` comment stating the intent; add a row to `overlay/INDEX.md` |
| Add a command | `overlay/bin/omarchy-*` or `omageeko-*` (the spec packages `omarchy*` from bin automatically) |
| Add a system file | `overlay/share/…` + an `install` line and a `%files` line in `omageeko.spec` (right subpackage) |
| Map a package | one line in `packages.map` |
| Per-machine user config | `hosts/<model>/home/…` |
| Menu change | `menu-transform.py` (SET / DROP / INSERT / I18N_LABELS) |

Patch format: `--- a/<upstream path>` / `+++ b/<upstream path>`, generated with `diff -u`, applied with `patch -p1 --fuzz=0` in `%prep`. A patch that needs fuzz is broken.

## Build and install

```bash
cd ~/omageeko
layers/03-omarchy-core/install.sh     # rebuild + install omageeko RPMs (stamps skip unchanged packages)
layers/03-omarchy-core/verify.sh
```

- The builder must not be on a newer Tumbleweed snapshot than the host. If the build refuses, the host needs `zypper dup` first, which is the user's call.
- Every rebuild gets a newer release (`%{?dist}` = a build timestamp), so zypper always takes it.
- Commit with a clear message; the user pushes or asks for a push. Commit trailers follow the session's instructions.

## Hot fixes

Copying a fixed file straight into `/usr/share/omarchy` unblocks the user, but the next RPM update overwrites it. Do it only together with the durable change above, and tell the user that a rebuild is pending. `rpm -V omageeko` lists files that differ from the package.
