# Network and Remote Access

## Objective

Ensure at least one reliable remote-control path remains available while away, even with single-node failure.

## Layer-2 Environment Snapshot

- Core switching includes a Netgear smart switch and a second faster unmanaged switch.
- Current node Ethernet may traverse docks/eGPU enclosures and should be treated as potential failure points.
- `rb1` management is intentionally on a dedicated USB Ethernet NIC, not on the Razer Core network path.

## Current Methods (Verified 2026-02-20 16:55 EST)

| node_id | primary_remote_method | secondary_remote_method | wake_capability | known_issues | last_tested |
|---|---|---|---|---|---|
| rb14-2017 (`rb1-fedora`) | SSH alias `rb1-admin` (`tdj@192.168.5.114`) | SSH alias `rb1` (`root`, break-glass key path) | No hardware WoL support on active NIC (`enp0s20f0u1c2`) | Active adapter uses `cdc_ncm` path; `ethtool -s enp0s20f0u1c2 wol g` is unsupported. Forcing USB config to `ax88179_178a` exposes WoL flags but loses carrier on this host (not production-usable). | 2026-02-20 17:13 EST |
| rb14-2015 (`rb2-pve`) | SSH alias `rb2` + Proxmox UI `https://192.168.5.108:8006` | VLAN99 fallback endpoint `172.31.99.2` | `Wake-on: g` on `enx00051bde7e6e` | No-battery power risk; no-power AC restore still requires manual button press | 2026-02-16 19:33 EST |
| mba-2011 (`kabbalah`) | SSH alias `mba` + Proxmox UI `https://192.168.5.66:8006` | utility VM path via `301` | `Wake-on: g` on `nic0` | Aging hardware and slower reboot profile | 2026-02-16 19:33 EST |
| truenas VM (`100` on `rb2`) | LAN service endpoint `192.168.5.100` | Proxmox console from `rb2` | n/a (VM) | VM guest agent unavailable; manage via LAN and host-level controls | 2026-02-16 19:33 EST |

## `rb1-fedora` Access Baseline (Applied 2026-02-16)

- Added admin user `tdj` with key auth and `wheel`/passwordless sudo for managed operations.
- Added local SSH alias `rb1-admin` to prefer non-root admin path.
- Added sshd hardening drop-in:
  - `PubkeyAuthentication yes`
  - `PasswordAuthentication no`
  - `PermitRootLogin prohibit-password`
  - `KbdInteractiveAuthentication no`
- Validation:
  - `ssh rb1-admin` works and `sudo -n true` passes.
  - Password-only SSH attempt fails (`Permission denied (publickey,...)`).
  - Root remains key-only reachable as break-glass (`rb1`) due installer file `/etc/ssh/sshd_config.d/01-permitrootlogin.conf`.
  - Current management path is now `enp0s20f0u1c2` at `192.168.5.114` (`Wired connection 2`), with fallback VLAN on `fb99` (`fallback99-new`).

## WoL / Wake Feasibility Matrix

| node_id | supports_wol | tested_result | blockers | fallback |
|---|---|---|---|---|
| rb14-2017 (`rb1-fedora`) | No (on current stable NIC path) | `nmcli` can set `wake-on-lan=magic`, but active adapter (`enp0s20f0u1c2`, `cdc_ncm`) does not expose WoL in `ethtool`; `ethtool -s ... wol g` returns `Operation not supported`. Magic packet traffic to new MAC was captured on-wire from `rb2`. Retest forcing USB config to vendor mode (`ax88179_178a`) exposes `Supports Wake-on: pg` and accepts `wol g`, but link/carrier drops (`Link status: 0`) with kernel register-read errors. | Hardware WoL regression versus prior Realtek path under stable mode; vendor-mode WoL not usable due no-link condition | Keep smart plug/manual wake path; if WoL is required, use a WoL-capable NIC/driver path (e.g., prior Realtek adapter) |
| rb14-2015 (`rb2-pve`) | Yes (limited by no-power behavior) | `ethtool` reports `Wake-on: g`; prior no-power recovery test showed manual power-on required | WoL does not recover node from fully unpowered state | Smart plug cycle + manual power contingency |
| mba-2011 (`kabbalah`) | Yes | `ethtool` reports `Wake-on: g` | True wake-from-off behavior should be periodically revalidated | Scheduled power window/manual recovery |

## Fallback Management Path Status

- Reserved subnet remains:
  - `rb1` target fallback: `172.31.99.1/30`
  - `rb2` active fallback: `172.31.99.2/30`
- Current state:
  - `rb2` side active: `vmbr0.99` -> `172.31.99.2/30`.
  - `rb1` side active: `fb99` (`fallback99-new`) on `enp0s20f0u1c2` -> `172.31.99.1/30`.
  - Bidirectional ping currently succeeds (`rb1 <-> rb2` over VLAN99).
  - Fallback SSH path validated through jump tests to both endpoints.
  - Post-reboot persistence validated on Fedora side (`rb1` boot ID changed; fallback remained up/reachable).

## Tailscale Continuity Rule

- Keep existing route-advertisement continuity path (`tsDeb`) available during network rework.
- Keep utility tailscale nodes on VMs (`201`, `301`) instead of Proxmox hosts.
- Do not decommission an existing path until at least one replacement path is verified end-to-end.

## Tailscale Staging Status (Current)

| node | install_state | tailscaled | tailnet_state | notes |
|---|---|---|---|---|
| tsDeb (`101`) | installed | active (verified via `qm guest exec 101 -- tailscale status`) | running | continuity anchor VM on `rb2`; currently appears as `tsdeb-rb1` on tailnet (`100.81.158.2`) |
| rb2 host | disabled by policy | inactive/disabled | n/a | host-level tailscale intentionally disabled |
| mba host | disabled by policy | inactive/disabled | n/a | host-level tailscale intentionally disabled |
| lchl-tsnode-rb2 (`201`) | installed | unknown in this session (`qga` unavailable) | last known running | utility tailscale node |
| lchl-tsnode-mba (`301`) | installed | unknown in this session (`qga` unavailable) | last known running | utility tailscale node |

Runbook:

- `runbooks/tailscale-node-staging-rb2-mba.md`

## Watcher Status

- Watcher node: `tsDeb` VM (`192.168.5.102`) on `rb2-pve`.
- VM boot behavior: running on `rb2` (`qm list`).
- `tsdeb-watchdog.timer` check from guest-exec reports `active`; `tsdeb-watchdog.service` idle between timer runs (`inactive`).
- Watcher policy expects ping checks for `rb1`, `rb2`, and `mba` with WoL attempt on failure.
- Current watcher host mapping (updated 2026-02-20): `rb1=192.168.5.114/6c:6e:07:21:02:3e`, `rb2=192.168.5.108/00:05:1b:de:7e:6e`, `mba=192.168.5.66/00:24:32:16:8e:d3`.

## Manual Backup Path (`rb1` -> TrueNAS HDD)

- Destination dataset: `oyPool/rb1AssistantBackups` (`/mnt/oyPool/rb1AssistantBackups`, quota `30G`).
- Backup mode: manual snapshots only (no timer/rotation automation).
- Script on `rb1`: `/home/tdj/bin/rb1_truenas_backup.sh`
- Core commands:
  - create: `/home/tdj/bin/rb1_truenas_backup.sh create <label>`
  - list: `/home/tdj/bin/rb1_truenas_backup.sh list`
  - prune: `/home/tdj/bin/rb1_truenas_backup.sh prune <keep_count>`
- Access method:
  - TrueNAS user `macmini_bu`
  - key `~/.ssh/id_ed25519_truenas_rb1`
  - alias `truenas-rb1`

## Away-Safe Validation Checklist

1. Confirm SSH paths work for `rb1-admin`, `rb1` (break-glass), `rb2`, and `mba` using current keys.
2. Confirm Proxmox UI access remains available on `rb2` and `mba`.
3. Re-validate VLAN99 fallback after each host reboot and before unattended windows.
4. Record test timestamps and failures before any migration/cutover work.
