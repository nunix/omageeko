# omageeko-update — plan and feasibility

Drafted 2026-10-18. Goal: one `omageeko-update` that replaces `omarchy update` and runs three stages in order. A stage with nothing to do, or one that fails, never stops the next.

1. **Base OS**: Tumbleweed snapshot (`zypper dup`)
2. **Omageeko layer**: Omarchy upstream + the omageeko RPMs (rebuild, bump, migrations)
3. **Apps**: Flatpak, the Arch box, mise

The long-term target is two stages: the omageeko RPMs come from a repo that `zypper dup` updates together with Tumbleweed, leaving only **system** and **apps**.

## Measured upstream churn (pin 84cfb93 of 2026-10-14 → quattro a6dcc31 of 2026-10-18)

| Measure | Result |
|---|---|
| Commits | 35 in 4 days; 484 in the last 30 days |
| Diff | 304 files, +12.7k / −1.5k lines |
| Release tags | v4.0.0 08-14, .1 08-25, .2 08-30, .3 09-08, .4 09-14, .5 10-16 (every 1–4 weeks) |
| omageeko patches (`--fuzz=0`) | 17/18 apply; `omarchy-remove-preinstalls` conflicts (upstream moved CLI tools to mise lazy shims, #9596) |
| Files omageeko replaces (overlay/stubs) changed upstream | 6: pkg-drop, update-keyring, refresh-pacman, reinstall-pkgs, system-factory-reset, hibernation-setup. These are silent drift: nothing fails, the port just falls behind |
| Menu transform | still applies (menu changed: "Reboot to Boot Menu" removed) |
| New migrations | 29; the audit flags 13 as Arch-coupled, but most exit early on hardware guards (N1x/aarch64, ASUS). About 2–3 need a real look |
| New package names | 27; ~8 have the same name on TW (pciutils, rtkit, zram-generator, rdma-core, systemd-ukify…), the rest are Arch kernels/firmware/NVIDIA → `@none`/`-` |
| Relevant to this desk | #15655 "Give each monitor its own workspaces" (Workspaces.qml, hotkeys) overlaps the host workspace pinning; review at the next bump |

**Verdict:** feasible. **Track release tags, not quattro HEAD:** that's one merge every 1–4 weeks instead of ~16 commits a day. A merge is mostly mechanical when gates do the checking. Expected cost per release: 30–90 min of review, most of it on migrations and replaced files.

## What already exists

`omarchy update` already runs on TW through the overlay ports: keyring → `zypper refresh`, system-pkgs → `zypper dup`, orphans, analyze-logs, aur-pkgs → `flatpak update` + `omageeko-box update`, update-available → TW snapshot + local repo. Missing pieces:

- the omageeko layer itself: upstream bump + rebuild after a TW snapshot,
- migrations gated by the audit,
- a TW boot check (`omarchy-update-boot` is a no-op on x86),
- a per-stage report.

## Stage design

```
omageeko-update [-y] [--check]
  preflight   free space, zypper lock, snapper pre (one snapshot pair for the whole run)
  1 base      zypper ref → dup available? → zypper dup
              → note "reboot needed" (zypper needs-rebooting) → sdbootutil/bootctl check
  2 omageeko  a) rebuild: packages whose stamp changed (rebuild-on: hyprland → titlebars,
                 Qt → quickshell…) — needs stage 1 first (builder snapshot == host)
              b) upstream: newer release tag of omarchy / omarchy-pkgs?
                 → omageeko-bump --gate (below). All gates green → build + install;
                 any red → keep the pin, report "v4.0.6 available, needs porting: …"
              c) omarchy-migrate, only after migration-audit passes
  3 apps      flatpak update (system + user), omageeko-box update (pacman -Syu + re-export),
              omarchy-update-mise, fwupd (optional)
  finish      snapper post, restart services, summary table, reboot prompt if needed
```

- **Order:** 1 → 2 → 3 is fixed. Stage 2a needs stage 1's snapshot, because the builder must not be newer than the host. Stage 3 always runs.
- **Bar and menu:** `omarchy-update-available` reports per stage (OS / omageeko / apps) so the bar widget can show what's pending. The Update menu entry and `omarchy update` call `omageeko-update` (overlay replacement of `omarchy-update`). Upstream's sudo-hardening wrapper is reused, not rewritten.
- **`--check`:** dry run that prints the three stage states without changing anything.

## `omageeko-bump` (the part that keeps the source in sync)

Run per upstream release, on demand, or by stage 2b:

1. Fetch the tag into a scratch tree. Resolve the matching omarchy-pkgs commit.
2. Apply patches with fuzz 0. A conflict is red, with the hunk shown.
3. Replaced-file drift: diff every upstream file that `overlay/bin` and `stubs.tsv` replace, old pin → new tag. Any change is red until reviewed. This turns silent drift into a loud gate.
4. Run `menu-transform.py`. Upstream drift is red (it already fails on unknown ids).
5. Migration audit, improved: classify migrations that exit early on hardware guards (`omarchy-hw-*`, `omarchy-hw-match`) as portable. Arch-coupled and unguarded is red.
6. Package audit: every new name is checked with `zypper search` (same name exists → green) or must be added to `packages.map`.
7. Build in the builder container. Run `Hyprland --verify-config` on the staged tree (temp HOME).
8. Write `upstream.lock`, a report, and a git branch `bump/v4.0.6`. Merge to main on green, or after a review.

## The two-stage end state (OS + omageeko in one zypper dup)

Move the builds off the laptop:

| Option | Pros | Cons |
|---|---|---|
| **OBS project** (`home:nunix:omageeko`) | rebuilds automatically against every TW snapshot (fixes titlebars/quickshell ABI breaks for free), signed repo, `opi`/zypper native, reinstall = add repo + install | home projects are **public** (the packaging becomes visible); spec must build without network (vendor sources as tarballs) |
| GitHub Actions + signed repo (Pages/release assets) | can stay private | you maintain the TW-snapshot rebuild trigger and signing yourself |
| keep the local builder | works today | stays a 3-stage update; builds take minutes on the laptop |

With a remote repo, a CI job runs `omageeko-bump` on each upstream tag and opens a PR when a gate is red. The client update becomes: `zypper dup` (TW + omageeko, one transaction, one snapper pair) → migrations → apps.

## Where complexity could get too big

- **Upstream's Arch coupling is growing:** linux-omarchy kernels, limine/UKI, pacman hooks, the omarchy-pkgs repo. Each new feature of that kind costs a stub or a port. The stub list (21) and replaced commands (33) are the cost meter: if they keep growing faster than releases, the approach is losing.
- **Hyprland/Quickshell version coupling:** upstream writes its Lua config against Arch's Hyprland. If TW lags or leads (both on 0.56.2 today), the Lua API can break. This is the biggest technical risk. A bump gate catches it via verify-config, but a fix may need a local Hyprland build.
- **Owning the update entrypoint:** upstream's `omarchy-update` carries privileged-bash hardening. Replacing it means following its changes, which is one more replaced file in the drift gate.

## Phases

| Phase | Scope | Size |
|---|---|---|
| A | `omageeko-update` orchestrator (3 stages, report, `--check`), TW boot check, update-available per stage; stage 2 = rebuild-if-stale + "upstream available" notice | small |
| B | `omageeko-bump` with gates 1–8, improved migration and package audits; first real bump: v4.0.4 → v4.0.5 (fix remove-preinstalls, review 6 replaced files, #15655 vs host workspaces) | medium |
| C | remote repo (OBS or GH Actions) + CI bump bot → two-stage update | medium, needs a hosting decision |

## Repos by stage (2026-10-18)

Stage 1 `zypper dup --from` the Tumbleweed repos (openSUSE distribution repos, codecs, Packman, classified by URL). Stage 2 updates `omageeko-local` and `mise`, then `mise up`: mise is Omarchy's installer for its default tools and runtimes, so it belongs to the Omarchy layer (layer 03 installs it with `base-devel` and the `-devel` headers mise builds against). Stage 3 updates every other repo (vendor apps, OBS add-ons), Flatpak and the box.

## Decisions (2026-10-18)

1. **Track releases, never downgrade.** Omarchy cuts releases on maintenance branches (`v4-0-5` forked from quattro on 2026-08-14), so the Oct 14 quattro pin is ~945 commits ahead of v4.0.5. Moving to v4.0.5 would mean 7 of 18 patches failing, the menu transform failing and 51 already-run migrations missing. `track=stable` therefore takes only a release tag that *contains* the pin. It holds until the next release is cut from quattro (expected v4.1.0), then follows that line. `track=edge` follows quattro with the same gates.
2. **Apply automatically, Aeon style.** `omageeko-update` applies all three stages and ends with "Updates applied", plus "Reboot to use them" when the kernel or core libraries changed. Snapper keeps the pre-update state. A green bump auto-installs; a red one is held and reported.
3. **Local-AI friendly bump.** `tools/omageeko-bump` is deterministic and writes `.bump/<target>/report.{json,md}`. Every red item names a section of `docs/bump-runbook.md`, written so a local model (ollama-vulkan + opencode, both packaged in TW) can resolve it, with explicit hand-over rules.
4. **Agent skill.** No openSUSE/Tumbleweed system skill exists (searched GitHub: only project-specific zypper/OBS skills). omageeko ships its own (`/usr/share/omageeko/agents/skills/omageeko`), linked next to Omarchy's skills.
5. Phase C hosting: not decided; builds stay local for now.

### Original questions

1. Track release tags (recommended) or quattro HEAD.
2. Stage 2b: auto-install a fully green bump, or always just notify and let you run it.
3. Phase C hosting: OBS (public packaging) vs GitHub Actions (private) vs stay local.
