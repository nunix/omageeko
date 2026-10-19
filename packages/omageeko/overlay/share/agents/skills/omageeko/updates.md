# Updates, snapshots, rollback

## omageeko-update

`omarchy update` (menu Update › Omageeko, the bar's update widget) runs `omageeko-update`. It applies updates right away, the way Aeon does, and ends with "Updates applied", plus "Reboot to use them" when the kernel or core libraries changed. Three stages; each one runs even if an earlier one had nothing to do or failed:

| Stage | Does |
|---|---|
| 1 base | `zypper dup --from` the Tumbleweed repos only (openSUSE distribution repos, codecs, Packman; classified by URL). Non-interactive; a solver question fails the stage and tells the user to run `sudo zypper dup` in a terminal |
| 2 omageeko | newer Omarchy release → `omageeko-bump run --apply --install` (only if every gate is green); rebuild stale omageeko RPMs; `zypper update` from `omageeko-local` + `mise`; `mise up` for the tools Omarchy installs with mise (listed in the summary); then migrations, gated |
| 3 apps | `zypper update` from vendor/add-on repos (Brave, Chrome, OBS home projects…), `flatpak update` (system + user), `omageeko-box update` |

- `omageeko-update --check` lists what's pending and changes nothing.
- The log is in `~/.local/state/omageeko/update.log`; the last result is in `~/.local/state/omageeko/last-update.json`.
- Stage 2 needs the checkout at `~/omageeko` (or `source=` in `~/.config/omageeko/update.conf`). Without it, stage 2 skips the bump and rebuild but still updates mise, its tools and runs migrations.

## Migrations

Omarchy ships one-shot migrations, run per user by `omarchy-migrate` and recorded in `~/.local/state/omarchy/migrations/`. omageeko classifies pending ones (`/usr/share/omageeko/tools/omageeko-bump classify`):

- `portable`: runs;
- `hw-noop`: its hardware guard excludes this machine; marked done without running;
- `skip` / `run` / `patched`: a recorded decision in `packages/omageeko/migrations.tsv`;
- `arch:<tools>`: Arch-only and undecided. **All** pending migrations are held until it gets a decision (`docs/bump-runbook.md#migration-arch`).

## Snapshots and rollback

- `omageeko-update` works like Aeon's `transactional-update --drop-if-no-change`:
  - one `pre` snapshot ("omageeko-update") before stage 1;
  - the snapper zypp plugin's per-transaction pairs are disabled for the run (`DISABLE_SNAPPER_ZYPP_PLUGIN=1`, passed through sudo by `omarchy-update-pacman` and `zyp`);
  - at the end: no package changed → the snapshot is deleted (no new boot entries); otherwise a `post` ("omageeko-update: N packages") closes the pair, marked `important=yes` when a kernel changed.
- Layer scripts take one pair per layer (`snap_begin`/`snap_end`); zypper calls inside them skip the plugin's nested pair (`layer_zypper`).
- Pruning is left to `snapper-cleanup.timer` (daily; layer 03 sets NUMBER_LIMIT=5 and NUMBER_LIMIT_IMPORTANT=5, snapshots younger than an hour are kept). Running `snapper cleanup` inline waits on btrfs quota accounting, which is why it was taken out of the update path.
- Every snapshot gets a systemd-boot entry per installed kernel (sdbootutil's snapper plugin), so fewer snapshots means a shorter boot menu.
- `/home` (XFS) and `/var` (Flatpak, containers) are not in root snapshots.
- To roll back the OS:
  1. reboot and pick the pre-update snapshot entry in the systemd-boot menu;
  2. once it works, make it permanent with `sudo snapper rollback`, then reboot.
- `omarchy snapshot restore` walks through the same steps.
- Inspect what changed: `snapper list`, `snapper status <pre>..<post>`, `snapper diff <pre>..<post> <file>`.

## Is a reboot needed?

```bash
zypper needs-rebooting; echo $?                              # 102 = core libraries/services updated
[[ $(ls /usr/lib/modules | sort -V | tail -1) == $(uname -r) ]] || echo "new kernel installed"
sudo bootctl list --no-pager | grep -A3 default              # default entry after an update
```

## The upstream bump (Omarchy layer)

omageeko pins upstream in `~/omageeko/upstream.lock` and follows **Omarchy releases** (`track=stable`). It only takes a release tag that contains the current pin, so it never downgrades; `track=edge` follows the `quattro` branch instead.

```bash
cd ~/omageeko
tools/omageeko-bump check            # newer release? (exit 10 = yes)
tools/omageeko-bump run              # every gate, report in .bump/latest/report.md, changes nothing
tools/omageeko-bump run --apply      # green only: new pin + refreshed patches, build, verify, commit
```

The gates are: patches (fuzz 0, else a 3-way merge), replaced files (upstream drift of commands omageeko replaces), the menu transform, migrations, new package names, recipe changes in omarchy-pkgs, then build plus `Hyprland --verify-config`. A red report links each item to `docs/bump-runbook.md`. **Follow that runbook exactly**: it is written for agents, including local models, and says when to stop and hand over to a human.
