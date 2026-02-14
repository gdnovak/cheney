# Network and Remote Access

## Objective

Ensure at least one reliable remote-control path remains available while away, even with single-node failure.

## Layer-2 Environment Snapshot

- Core switching includes a Netgear smart switch and a second faster unmanaged switch.
- Current node Ethernet may traverse docks/eGPU enclosures, which must be treated as potential failure points.
- User reports all docks and the Razer Core can function as Ethernet paths; current active Razer host is using USB Ethernet.

## Current Methods (To Verify)

| node_id | primary_remote_method | secondary_remote_method | wake_capability | known_issues | last_tested |
|---|---|---|---|---|---|
| rb14-2017 | SSH alias `rb1-pve` + Proxmox host LAN (`192.168.5.98`) | Proxmox UI `https://192.168.5.98:8006` | Capability present (`Wake-on: g` on `nic0`) | Management bridge moved to Razer Core NIC (`enx90203a1be8d6`) during recable; verify stability overnight | 2026-02-14 04:03 EST |
| rb14-2015 (`rb2-pve`) | SSH alias `rb2` + LAN (`192.168.5.108`) | Proxmox UI `https://192.168.5.108:8006` | Capability present (`Wake-on: g` on `nic0`) | No battery; physical power stability risk | 2026-02-14 03:29 EST |
| mba-2011 | SSH alias `mba` + LAN (`192.168.5.66`) | Proxmox UI `https://192.168.5.66:8006` | Capability present (`Wake-on: g` on `nic0`) | Reboots are slower than Razers (~58s ping return observed) | 2026-02-14 03:29 EST |

## WoL / Wake Feasibility Matrix

| node_id | supports_wol | tested_result | blockers | fallback |
|---|---|---|---|---|
| rb14-2017 | Yes (interface capability reported) | Wake capability confirmed via `ethtool`; watchdog path active (no packet needed during recent reboot tests) | Must validate path through USB-Ethernet/dock chain | Smart plug + BIOS power-on + scheduled watchdog |
| rb14-2015 (`rb2-pve`) | Yes | Wake capability confirmed via `ethtool`; watchdog path active (no packet needed during recent reboot tests) | Must validate after planned dongle swap | Smart plug + BIOS auto power-on policy (if available) |
| mba-2011 | Yes | Wake capability confirmed via `ethtool`; watchdog sent WoL packet during reboot windows (`03:23` and `03:28` EST) | Must validate true wake-from-off behavior after recabling | Scheduled power window or manual recovery plan |

## Cluster State Notes

- Active host `rb1-pve` currently appears standalone (`/etc/pve/corosync.conf` absent).
- MacBook Air is reported to hold older Proxmox cluster assumptions and may block normal operation until cluster config is reconciled.

## Tailscale Continuity Rule

- Keep current Tailscale path online during hardware rework.
- Add equivalent Tailscale endpoint on `rb2` before final cutover.
- Do not remove existing route advertisement path until `rb2` path is verified.

## Watcher Status

- Watcher node: `tsDeb` VM (`192.168.5.102`) on `rb1-pve`.
- VM boot behavior: `onboot: 1` confirmed in Proxmox config.
- `tsdeb-watchdog.timer` is enabled and active on `tsDeb`.
- Watcher currently runs ping checks for `rb1`, `rb2`, `mba` and sends WoL packets on failure.

## Closed-Lid Reboot Validation

- `rb1`: PASS (2/2 sequential reboot cycles recovered with lid closed).
- `rb2`: PASS (2/2 sequential reboot cycles recovered with lid closed).
- `mba`: PASS (2/2 sequential reboot cycles recovered with lid closed; slower recovery profile).

## Away-Safe Validation Checklist

1. Confirm primary remote path works for every node with current credentials/keys.
2. Confirm at least one node can be remotely reached after simulated single-node outage.
3. Confirm wake or recovery strategy for each node is documented and tested.
4. Record test timestamps and failures before any migration cutover.
