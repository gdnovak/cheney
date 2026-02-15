# Inventory Contract

The `inventory/` directory is the source of truth for node, VM, and remote-access state used by migration and continuity runbooks.

## Required Files

- `hardware.md`: physical node and host capability inventory.
- `vms.md`: VM placement, criticality, and migration ordering.
- `network-remote-access.md`: remote-control paths, wake strategy, and away-safe checks.
- `network-layout.md`: L2/L3 layout plan, switch roles, VLAN/IP plan, and uplink decisions.
- `peripherals.md`: docks, hubs, and adapter dependencies that affect node operability.

## Additional Planning Files

- `network-procurement.md`: value-first network upgrade shortlist and purchase order.

## Update Triggers

Update relevant inventory files when any of the following changes:

- Host hardware role or availability.
- Hypervisor placement or VM assignments.
- Network topology, remote access method, or wake capability.
- Risk profile (power reliability, thermal limits, etc.).

## Pre-Migration Validation Checklist

1. Hardware entries are current and timestamped.
2. VM table contains source host, target host, and migration order.
3. Remote access doc includes tested path for each active node.
4. Known risks and mitigations are documented before execution.
