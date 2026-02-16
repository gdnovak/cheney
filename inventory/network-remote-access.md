# Network and Remote Access

## Objective

Ensure at least one reliable remote-control path remains available while away, even with single-node failure.

## Layer-2 Environment Snapshot

- Core switching includes a Netgear smart switch and a second faster unmanaged switch.
- Current node Ethernet may traverse docks/eGPU enclosures and should be treated as potential failure points.
- `rb1` management is intentionally on a dedicated USB Ethernet NIC, not on the Razer Core network path.

## Current Methods (Verified 2026-02-16)

| node_id | primary_remote_method | secondary_remote_method | wake_capability | known_issues | last_tested |
|---|---|---|---|---|---|
| rb14-2017 (`rb1-fedora`) | SSH alias `rb1` (`192.168.5.107`) | none (no Proxmox UI on baremetal Fedora) | `Wake-on: g` on `enp0s20f0u6` | VLAN99 fallback path is not currently configured on Fedora side | 2026-02-16 18:05 EST |
| rb14-2015 (`rb2-pve`) | SSH alias `rb2` + Proxmox UI `https://192.168.5.108:8006` | VLAN99 fallback endpoint `172.31.99.2` | `Wake-on: g` on `enx00051bde7e6e` | No-battery power risk; no-power AC restore still requires manual button press | 2026-02-16 18:05 EST |
| mba-2011 (`kabbalah`) | SSH alias `mba` + Proxmox UI `https://192.168.5.66:8006` | utility VM path via `301` | `Wake-on: g` on `nic0` | Aging hardware and slower reboot profile | 2026-02-16 18:05 EST |
| truenas VM (`100` on `rb2`) | LAN service endpoint `192.168.5.100` | Proxmox console from `rb2` | n/a (VM) | VM guest agent unavailable; manage via LAN and host-level controls | 2026-02-16 18:05 EST |

## WoL / Wake Feasibility Matrix

| node_id | supports_wol | tested_result | blockers | fallback |
|---|---|---|---|---|
| rb14-2017 (`rb1-fedora`) | Yes | `ethtool` reports `Wake-on: g` | Still need unattended validation through full dock/adapter chain | Smart plug + BIOS power-on + watchdog path |
| rb14-2015 (`rb2-pve`) | Yes (limited by no-power behavior) | `ethtool` reports `Wake-on: g`; prior no-power recovery test showed manual power-on required | WoL does not recover node from fully unpowered state | Smart plug cycle + manual power contingency |
| mba-2011 (`kabbalah`) | Yes | `ethtool` reports `Wake-on: g` | True wake-from-off behavior should be periodically revalidated | Scheduled power window/manual recovery |

## Fallback Management Path Status

- Reserved subnet remains:
  - `rb1` target fallback: `172.31.99.1/30`
  - `rb2` active fallback: `172.31.99.2/30`
- Current state:
  - `rb2` side is active (`vmbr0.99`).
  - `rb1` side is currently absent post-Fedora reinstall.
  - Bidirectional fallback ping currently fails.

## Tailscale Continuity Rule

- Keep existing route-advertisement continuity path (`tsDeb`) available during network rework.
- Keep utility tailscale nodes on VMs (`201`, `301`) instead of Proxmox hosts.
- Do not decommission an existing path until at least one replacement path is verified end-to-end.

## Tailscale Staging Status (Current)

| node | install_state | tailscaled | tailnet_state | notes |
|---|---|---|---|---|
| tsDeb (`101`) | installed | active (verified via `qm guest exec 101 -- tailscale status`) | running | continuity anchor VM on `rb2` |
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
- Watcher policy still expects ping checks for `rb1`, `rb2`, and `mba` with WoL attempt on failure.

## Away-Safe Validation Checklist

1. Confirm SSH path works for `rb1`, `rb2`, `mba` using current keys.
2. Confirm Proxmox UI access remains available on `rb2` and `mba`.
3. Re-establish dual-sided VLAN99 fallback before unattended windows.
4. Record test timestamps and failures before any migration/cutover work.
