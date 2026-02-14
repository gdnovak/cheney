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
| rb14-2017 | SSH alias `rb1-pve` + Proxmox host LAN (`192.168.5.98`) | Proxmox UI `https://192.168.5.98:8006` (verify browser path) | Capability present (`Wake-on: g` on `nic0`) | USB-Ethernet dependency on current setup | 2026-02-13 23:45 EST |
| rb14-2015 (`rb2-pve`) | Host ping + SSH port reachable at `192.168.5.108` | Proxmox UI `https://192.168.5.108:8006` (auth pending validation) | Unknown (login not yet validated) | No battery; physical power stability risk | 2026-02-14 01:53 EST |
| mba-2011 | ICMP reachable (`192.168.5.66`) | SSH port 22 open but key/auth not available yet | Unknown | Reboot hit-or-miss; legacy Proxmox state reportedly expects missing cluster peer/quorum | 2026-02-13 23:45 EST |

## WoL / Wake Feasibility Matrix

| node_id | supports_wol | tested_result | blockers | fallback |
|---|---|---|---|---|
| rb14-2017 | Yes (interface capability reported) | Wake capability confirmed via `ethtool`; remote wake event not yet end-to-end tested | Must validate path through USB-Ethernet/dock chain | Smart plug + BIOS power-on + scheduled watchdog |
| rb14-2015 (`rb2-pve`) | Unknown | Not tested (installed, auth pending) | Must confirm once host login is validated | Smart plug + BIOS auto power-on policy (if available) |
| mba-2011 | Unknown | Not tested | No authenticated shell access yet; legacy Proxmox quorum issue likely requires local fix | Scheduled power window or manual recovery plan |

## Cluster State Notes

- Active host `rb1-pve` currently appears standalone (`/etc/pve/corosync.conf` absent).
- MacBook Air is reported to hold older Proxmox cluster assumptions and may block normal operation until cluster config is reconciled.

## Tailscale Continuity Rule

- Keep current Tailscale path online during hardware rework.
- Add equivalent Tailscale endpoint on `rb2` before final cutover.
- Do not remove existing route advertisement path until `rb2` path is verified.

## Away-Safe Validation Checklist

1. Confirm primary remote path works for every node with current credentials/keys.
2. Confirm at least one node can be remotely reached after simulated single-node outage.
3. Confirm wake or recovery strategy for each node is documented and tested.
4. Record test timestamps and failures before any migration cutover.
