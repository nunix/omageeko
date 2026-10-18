# omageeko bump runbook

For whoever resolves a red `omageeko-bump` report: you, or a local AI agent (see [Local AI](#local-ai)). Every report item links to one section below. Each section is self-contained: read only the sections your report names.

## Ground rules (read first)

1. Work only inside the omageeko checkout (`~/omageeko`). Never edit `/usr/share/omarchy`, `/usr/share/omageeko`, `~/.claude*` or anything outside the checkout.
2. Only touch the files a section names. Make one change per report item.
3. After each fix, rerun the gates: `tools/omageeko-bump run --to <target>` (target = `.target.ref` in `.bump/latest/report.json`). Done means the report is green.
4. Never run `--apply` or `--install` yourself. A human, or `omageeko-update`, applies a green bump.
5. **Stop and hand over to a human** when:
   - a section says so,
   - the same item is still red after two attempts,
   - a fix would delete an omageeko change you don't understand,
   - or a step asks for a judgement this runbook doesn't cover.

   Write what you found into `.bump/latest/handover.md` and stop.
6. Commit nothing. The human reviews `git diff` and commits.

Files you will meet:

| File | What it is |
|---|---|
| `.bump/latest/report.json` / `report.md` | gate results; each item has `kind`, `item`, `detail`, `playbook` |
| `.bump/latest/tree/` | the new upstream with the patches that applied (scratch, read-only for you) |
| `.bump/latest/patches/` | refreshed patches and `*.conflict` files |
| `.bump/latest/drift/` | upstream diffs of files omageeko replaces |
| `packages/omageeko/patches/*.patch` | omageeko's changes to upstream files (applied at fuzz 0) |
| `packages/omageeko/overlay/bin/` | omageeko's full replacements of upstream commands |
| `packages/omageeko/overlay/stubs.tsv` | upstream commands replaced by a "not applicable" stub |
| `packages/omageeko/migrations.tsv` | decisions on Arch-only migrations |
| `packages.map` | Arch package name → Tumbleweed package / `@flatpak:` / `@box:` / `-` (skip) |
| `packages/omageeko/overlay/INDEX.md` | why each change exists; update it when you change a patch or replacement |

Every omageeko change carries a `# omageeko:` comment stating its intent. That comment is the specification: keep the intent, adapt the code.

## patch-conflict

The patch no longer applies, and a 3-way merge with the new upstream conflicted. `.bump/latest/patches/<patch>.conflict` holds the merged file with conflict markers:

```
<<<<<<< .../theirs      the new upstream
=======
                        omageeko's version (from the old upstream + patch)
>>>>>>> .../mine
```

Steps:

1. Read the `# omageeko:` comment inside the `mine` block. That is what must survive.
2. Read the `theirs` block. List what upstream changed: new commands, renamed variables, added items.
3. Write the resolved file: **upstream's new behaviour plus the omageeko intent.** Never drop upstream additions, and never drop the omageeko guard.
4. Regenerate the patch from the new upstream file:
   ```bash
   t=.bump/latest/tree            # new upstream; the conflicting file is unpatched there
   f=bin/omarchy-remove-preinstalls
   cp "$t/$f" /tmp/orig && cp <your resolved file> /tmp/new
   diff -u --label "a/$f" --label "b/$f" /tmp/orig /tmp/new > packages/omageeko/patches/<patch>.patch
   ```
5. Rerun the gates. The item should now show `applies`.

**Worked example** (`omarchy-remove-preinstalls`, quattro 2026-10-18). Upstream replaced an unconditional `rm -f ~/.local/bin/{codex,claude,…}` with `omarchy-mise-default-tools disable` followed by the same `rm` list, and added `cf` to the list. The omageeko intent is to delete those files only when they are Omarchy mise wrappers, never a native install such as Claude Code's symlink. The resolution keeps `omarchy-mise-default-tools disable || exit 1`, replaces the `rm -f` line with omageeko's guarded `for stub in …` loop, and adds `cf` to the loop's list.

Stop and hand over if upstream removed the code the patch changes entirely. The patch may be obsolete, or the intent may need a new home; that's a judgement call.

## replaced-drift

Upstream changed a command that omageeko replaces completely (`overlay/bin/<name>`) or stubs (`stubs.tsv`). The upstream diff is in `.bump/latest/drift/bin_<name>.diff`.

1. Read the diff. Classify each hunk:
   - **Arch mechanics** (pacman, keyrings, limine, mkinitcpio, aarch64/N1x hardware): nothing to port.
   - **Behaviour or interface** (new arguments, new output format, new user-facing text, a new step callers rely on): port it to `overlay/bin/<name>` in Tumbleweed terms (zypper/rpm/flatpak/snapper).
   - **Comments or docs only**: nothing to port.
2. If you ported anything, keep the file's `# omageeko:` header accurate.
3. Acknowledge the review, which records that the replacement now matches this upstream revision:
   ```bash
   tools/omageeko-bump ack bin/<name>
   ```
4. Rerun the gates.

For stubs (`stubs.tsv`): if upstream turned a command into something useful on Tumbleweed, hand over. Porting a stub is a feature decision.

## replaced-collision

Upstream added a command with the same name as an omageeko-only command (`.bump/latest/drift/bin_<name>.new`). Hand over: someone has to decide whether to adopt upstream's version, keep omageeko's, or rename it.

## replaced-removed

Upstream deleted a command that omageeko replaces. This is a warning: the bump can still apply. Check with `grep -rn <name> packages/ docs/ layers/` whether anything of omageeko still calls it. If nothing does, delete `overlay/bin/<name>` (or its `stubs.tsv` line) and its row in `overlay/INDEX.md`.

## menu-drift

`menu-transform.py` failed: a menu id it edits, drops or inserts after no longer exists upstream. The error names the id.

1. Find the id's new name or position: `grep -n '<old id prefix>' .bump/latest/tree/default/omarchy/omarchy-menu.jsonc`.
2. Update the matching rule in `packages/omageeko/menu-transform.py`: `SET`, `DROP`, `INSERT` or `I18N_LABELS`.
3. If upstream removed the item entirely, delete the rule, and note it in `overlay/INDEX.md` under "Menu edits".
4. Rerun the gates.

## migration-arch

A new upstream migration mentions Arch tooling (`pacman`, `limine*`, `mkinitcpio`, `ufw`, …) and no hardware guard excludes this machine. Migrations run once per user during `omageeko-update`. Until each red one has a decision, `omageeko-update` holds **all** pending migrations.

Read the migration (`.bump/latest/tree/migrations/<name>`) and record one decision:

| The migration… | Decision |
|---|---|
| only touches Arch boot/package plumbing (limine entries, mkinitcpio, pacman.conf, pacman hooks, keyrings) | `skip` |
| only acts on hardware this machine lacks, behind a guard the classifier missed | `skip` |
| changes user config or the shell in a way that works on Tumbleweed (the Arch part is guarded with `command -v …` or `|| true`) | `run` |
| does something wanted but in an Arch way | hand over (needs a ported migration: `patched`) |

```bash
tools/omageeko-bump decide <name> skip "limine/mkinitcpio only; omageeko boots with systemd-boot + dracut"
```

Use a reason that states the fact you checked. Rerun the gates.

## package-unmapped

Upstream references a package that isn't in `packages.map` and doesn't exist on Tumbleweed under the same name. Find out what it is: read the `install/*.packages` line or the migration that adds it, and `zypper search <words>`. Then add one line to `packages.map` in the matching section:

| Situation | Line |
|---|---|
| Tumbleweed ships it under another name | `name  <layer> tw-name                # why` |
| hardware this machine family never has (NVIDIA, Qualcomm, Apple, ASUS/Dell model firmware), or an Arch kernel/keyring | `name  -  -                      # not applicable: <reason>` |
| an app only in Omarchy's Arch repo | `name  -  @box:name              # Omarchy repo, via omageeko-box` |
| an app on Flathub | `name  -  @flatpak:<app id>      # Flathub` |

Use layer `-` unless an existing layer should install it on every machine. Check with `grep -n '^<name> ' packages.map` that you didn't create a duplicate. Rerun the gates.

## pkgbuild-changed

This is a warning: omarchy-pkgs changed the recipe of a package omageeko builds itself (`packages/<name>/`). Compare `pkgver` / sources in the omarchy-pkgs diff with `packages/<name>/<name>.spec`. If upstream bumped the version, update `Version:` and the source URL/checksums in the spec. If you're unsure, hand over; the bump still applies without it.

## build-failed

The container build failed after the pin moved; `.bump/build.log` has the output. The pin and patches were restored automatically. Look for the first `error:` line:

- a patch hunk failing inside `%prep`: rerun the gates, the report is stale;
- a missing file in `%files` / `%install`: upstream moved or renamed a file. Update `packages/omageeko/omageeko.spec`, matching the new path in `.bump/latest/tree`;
- anything else: hand over.

## verify-config

The new upstream tree rejects the current Hyprland config (`Hyprland --verify-config` against the built tree). The detail shows Hyprland's error with file and line. If the error is in a host file (`hosts/<model>/home/.config/hypr/*.lua`), adapt that file to upstream's new API: look up the function in `.bump/latest/tree/default/hypr/`. If it's in upstream's own files, hand over. Usually that means Tumbleweed's Hyprland version differs from the one upstream targets.

## Local AI

The runbook is written so a local model can do it without cloud tokens. Each item is narrow, the files are small, and the gates verify every fix.

Tumbleweed has everything needed:

```bash
sudo zypper install ollama-vulkan opencode      # ollama with Vulkan (Radeon 780M), opencode agent
sudo systemctl enable --now ollama
ollama pull qwen3-coder:30b                     # MoE, ~19 GB; fits the 54 GB P14s, usable on CPU+iGPU
```

Run it on a red report:

```bash
cd ~/omageeko
opencode run --model ollama/qwen3-coder:30b \
  "Follow docs/bump-runbook.md to resolve every red item in .bump/latest/report.json. Ground rules first."
```

The `omageeko` agent skill (installed by the omageeko RPM, linked into `~/.agents/skills`) points agents here, so `opencode`, Codex or Claude Code find this runbook on their own. Review with `git diff`, rerun `tools/omageeko-bump run`, and commit when green.
