# omageeko — open work

Parked on 2026-10-15 after layer 06b. Ordered as the Omarchy menu reads, top-down.

## Layer 06 — Omarchy shell & menu
- [ ] **06c Trigger details**
  - disk and network speed tests (shell plugins `omarchy.disk-speedtest` / `omarchy.speedtest`): check the tools they call
  - hardware toggles (touchpad, touchscreen, haptics)
  - a real screen recording run (gpu-screen-recorder, desktop audio / mic / webcam overlay)
- [ ] **06d Setup details**
  - Language: `omarchy-locale-generate` uses Arch's `locale-gen` + `/etc/locale.gen`; TW ships precompiled locales (glibc-locale)
  - Direct boot: `omarchy-setup-direct-boot` creates a limine/UKI EFI entry, meaningless with systemd-boot + sdbootutil (stub or adapt)
  - Sudoless Docker: `omarchy-setup-security-sudoless-docker` / `omarchy-sudo-docker` assume a docker group; omageeko uses rootless podman
  - DNS: `omarchy-dns` (NetworkManager + nmcli) needs a live test
  - FIDO2: on-demand install path (`libfido2` → libfido2-1, libfido2-utils)
- [ ] **06e Learn**: "Arch wiki" link → openSUSE docs; herdr keybindings now that herdr is installed
- [ ] **Bar, panels, notifications**: update indicator, power, network/Bluetooth/audio panels

## Layer 07 — login & boot
- [ ] Plymouth Omarchy theme via dracut (Style › Unlock → `omarchy-plymouth-set` is a stub)
- [ ] Factory reset on snapper (`omarchy-system-factory-reset` stub)
- [ ] lightdm: optional greeter theming

## Layer 08 — system services
- [ ] avahi + nss-mdns (hosts line in TW's /usr/etc nsswitch)
- [ ] bolt (Thunderbolt), wireless-regdb, qemu binfmt
- [ ] podman-docker + docker-compose against podman.socket
- [ ] firewalld instead of ufw: `omarchy-setup-security-sshd` / `remove-security-sshd` stubs
- [ ] hibernation on dracut + sdbootutil (`omarchy-hibernation-*` stubs)
- [ ] sysctl / zram / oomd / logind / udev / modprobe drop-ins from upstream `etc/`, each reviewed for TW
- [ ] `omarchy update` end-to-end test on a real Tumbleweed snapshot bump

## omaweed follow-ups
- [ ] Visually check: monitor panel disable survives a theme switch; Remove › Flatpak and Install › OPI entries
- [ ] Delete the `omaweed` branch in nunix/omarchy-mac once happy (archived in `archive/omaweed/`)

## Later / optional
- [ ] superwhisper-bin (proprietary dictation)
- [ ] Battery charge thresholds (ThinkPad start/stop) — no Omarchy setting exists
- [ ] Laptop mic DC offset filter (AMD ACP DMIC), only if it causes pops
- [ ] Report upstream: TW `hyprland-devel` missing glslang-devel + lua55-devel requires; Hyprland `--verify-config` segfault on `hl.timer`; omazed one-time theme selection vs Zed onboarding
- [ ] First run of the installed `omageeko-update` (Update › Omageeko); the 2026-10-18 menu run still used the old chain
- [ ] Local AI: install ollama-vulkan + opencode + a model, then do a dry run of the runbook on a red report (`omageeko-bump run --to quattro`)
- [ ] 99 consolidate: single `omageeko-install`, signing the local repo, upstream bump procedure
