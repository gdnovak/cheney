# Phase Gate: Full Device Inventory (Required Before Migration)

This gate must pass before phase 3 migration begins.

## Gate Objective

Produce a complete, high-detail inventory of all connected infrastructure that can affect migration or continuity outcomes.

## Required Coverage

1. Hosts
- `rb1-pve`
- `rb2-pve`
- `mba-2011`
- any additional active host that provides quorum, routing, storage, or management

2. Switching and links
- Netgear smart switch ports and connected endpoints
- faster unmanaged switch ports and connected endpoints
- uplink relationships between switches/router
- link speed/duplex observations for each host path

3. Dock/enclosure paths
- Dell WD19 usage and attached host(s)
- K-series dock usage and attached host(s)
- Razer Core Ethernet usage mode
- USB-Ethernet dependencies and fallback paths

4. Storage paths
- TrueNAS VM disk mapping (virtual + physically attached devices)
- host-level attachment path for each required physical drive
- recovery/rollback path for any disk move action

5. Remote access and continuity
- reachable SSH/UI paths per node
- WoL/power-recovery method per node
- Tailscale continuity plan (`current + rb2`)

## Acceptance Checklist

- [ ] `inventory/hardware.md` has no unknowns that block migration decisions.
- [ ] `inventory/vms.md` has migration method and rollback notes for each VM.
- [ ] `inventory/network-layout.md` contains exact switch/port map and uplink plan.
- [ ] `inventory/network-remote-access.md` has tested primary/secondary access methods.
- [ ] `inventory/peripherals.md` reflects active dock/enclosure wiring.
- [ ] `log.md` contains timestamped evidence summary for this gate.

## Failure Policy

If any item above is incomplete, migration is postponed until the gate is passed and logged.
