# Network Layout Plan (Draft)

## Current Physical Switching

- `switch-smart-netgear`: Netgear smart switch (management-capable).
- `switch-fast-unmanaged`: Higher-throughput unmanaged switch.
- Dock/enclosure Ethernet paths are actively used and must be included in failure analysis.

## Current Known IP Anchors

| system | ip | role | source |
|---|---|---|---|
| rb1-pve host (`rb14-2017` mapping assumed) | 192.168.5.98/22 | active Proxmox host | live check |
| rb2-pve host (`rb14-2015`) | 192.168.5.108/22 | target Proxmox host | live ping + ssh port check |
| truenas VM (100) | 192.168.5.100/22 | storage service VM | guest agent check |
| tsDeb VM (101) | 192.168.5.102/22 | utility/remote-access VM | guest agent check |
| mba-2011 | 192.168.5.66 | fallback node (ping reachable) | user + live ping |
| gateway | 192.168.4.1 | default route | host route table |

## Phase-Oriented Network Direction

Phase 2 (pre-migration optimization):

1. Keep the smart Netgear switch as the control-plane anchor (Proxmox management and critical remote access).
2. Use the faster unmanaged switch for bulk/data paths where management features are not required.
3. Normalize cable runs and document any temporary IP changes.
4. Keep at least one host with direct/known-good Ethernet path not dependent on dock/eGPU chain during migration windows.

Phase 5 (final network rework):

1. Finalize long-term internet in/out path and switch uplink structure.
2. Lock Mac mini steady-state mode (wired primary + Wi-Fi secondary/fallback).
3. Finalize long-term placement of dock/Razer Core Ethernet paths (primary vs fallback).

## Performance Constraint (Current Default)

- Migration is allowed on stable 1GbE.
- Any >1GbE inter-Razer path is a later optimization and does not block migration execution.

## Validation Checklist

1. Document exact port map for both switches.
2. Verify link speed and negotiated duplex on each host path.
3. Run continuity test: unplug one switch/uplink and verify remote control remains available.
4. Confirm post-failover path for Proxmox management (`:8006`) and SSH.
