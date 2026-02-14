# Network Layout Plan (Draft)

## Current Physical Switching

- `switch-smart-netgear`: Netgear smart switch (management-capable).
- `switch-fast-unmanaged`: Higher-throughput unmanaged switch.
- Dock/enclosure Ethernet paths are actively used and must be included in failure analysis.

## Current Known IP Anchors

| system | ip | role | source |
|---|---|---|---|
| rb1-pve host (`rb14-2017` mapping assumed) | 192.168.5.98/22 | active Proxmox host | live check |
| truenas VM (100) | 192.168.5.100/22 | storage service VM | guest agent check |
| tsDeb VM (101) | 192.168.5.102/22 | utility/remote-access VM | guest agent check |
| mba-2011 | 192.168.5.66 | fallback node (ping reachable) | user + live ping |
| gateway | 192.168.4.1 | default route | host route table |

## Draft Topology Direction

1. Keep the smart Netgear switch as the control-plane anchor (management and stability-critical paths).
2. Use the faster unmanaged switch for high-throughput data-plane paths where management features are not required.
3. Keep at least one host with direct/known-good Ethernet path not dependent on dock/eGPU chain during migration windows.

## Open Decisions (To Resolve Before Cutover)

- Decide which nodes must stay on the smart switch at all times.
- Define whether VM migration traffic should stay isolated from general LAN traffic.
- Verify whether USB-Ethernet path on active Razer introduces stability/performance limits.
- Decide long-term placement of Razer Core Ethernet in the topology (primary vs fallback).

## Validation Checklist

1. Document exact port map for both switches.
2. Verify link speed and negotiated duplex on each host path.
3. Run continuity test: unplug one switch/uplink and verify remote control remains available.
4. Confirm post-failover path for Proxmox management (`:8006`) and SSH.
