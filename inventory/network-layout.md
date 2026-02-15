# Network Layout Plan

## Current Physical Switching

- `switch-smart-netgear`: Netgear smart switch (management-capable control-plane anchor).
- `switch-fast-unmanaged`: higher-throughput unmanaged switch for bulk data paths.
- Rule: keep exactly one cable between switches unless loop protections are explicitly configured and validated.

## Current Known IP Anchors

| system | ip | role | source |
|---|---|---|---|
| rb1-pve host (`rb14-2017`) | 192.168.5.98/22 | active Proxmox host | live check |
| rb2-pve host (`rb14-2015`) | 192.168.5.108/22 | target Proxmox host | live check |
| truenas VM (100) | 192.168.5.100/22 | storage service VM (anchored on `rb1`) | guest agent check |
| tsDeb VM (101) | 192.168.5.102/22 | utility/remote-access VM | guest agent check |
| mba-2011 (`kabbalah`) | 192.168.5.66/22 | fallback node | live check |
| gateway | 192.168.4.1 | default route | host route table |

## Throughput Baseline (2026-02-14)

- Observed negotiated management-link speeds from live checks:
  - `rb1`: `enx90203a1be8d6` -> `1000/full`
  - `rb2`: `enx00051bde7e6e` -> `1000/full`
  - `mba`: `nic0` -> `1000/full`
- Current data confirms stable 1GbE baseline; CAT8 alone does not raise throughput when NIC/switch ports are 1Gb-limited.

## Temporary Fallback VLAN (Live Runtime)

- `VLAN 99` is staged on smart-switch ports for `rb1` and `rb2` as a logical fallback management path.
- Runtime host subinterfaces (non-persistent until explicitly written to host network config):
  - `rb1`: `vmbr0.99` -> `172.31.99.1/30`
  - `rb2`: `vmbr0.99` -> `172.31.99.2/30`
- Validation status:
  - `rb1 <-> rb2` ping over `172.31.99.0/30` is successful.
  - SSH to `rb2` over fallback path is validated via jump host (`ssh -J rb1-pve root@172.31.99.2 ...`).

## Fallback Persistence Status (2026-02-14)

- `rb2`: persistent config added in `/etc/network/interfaces`:
  - `auto vmbr0.99`
  - `iface vmbr0.99 inet static`
  - `address 172.31.99.2/30`
  - `vlan-raw-device vmbr0`
- Verified by reboot test: `vmbr0.99` returned automatically on `rb2`.
- `rb1`: fallback interface currently remains runtime-only (`vmbr0.99` on host uptime).

## Target Topology (Throughput-First, Medium Complexity)

1. Keep smart switch as control-plane anchor and management visibility point.
2. Place high-throughput endpoints (`rb1`, `rb2`, workstation/mac mini) on fast unmanaged switch when 2.5Gb-capable NICs are available.
3. Keep `mba` on known-stable 1Gb path for continuity/fallback, not bulk transfer.
4. Maintain a single LAN/subnet during initial optimization to reduce migration risk.
5. Add optional dual-NIC split later for learning and stronger isolation:
- NIC A on smart switch for management.
- NIC B on fast switch for migration/backup/storage traffic.
6. Keep storage-primary placement on `rb1` until a dedicated storage host or materially better `rb2` stability/performance exists.

## Host Path Targets

| host | current primary NIC path | current link | target near-term | target link | fallback path requirement |
|---|---|---|---|---|---|
| rb1-pve | `enx90203a1be8d6` (Razer Core path) | 1GbE | move bulk path to 2.5-capable adapter/switch port when added | 2.5GbE | keep at least one known-good management dongle profile documented |
| rb2-pve | `enx00051bde7e6e` | 1GbE | same as rb1; prioritize stable power and cable strain relief first | 2.5GbE | maintain emergency direct-management method for no-battery node |
| mba (`kabbalah`) | `nic0` | 1GbE | continuity node only | 1GbE | retain hub + direct TB/miniDP video fallback notes |
| workstation/mac mini | TBD (inventory detail pending) | TBD | add to fast-switch data path if 2.5-capable NIC path exists | 2.5GbE target | keep Wi-Fi as secondary out-of-band access |

## Phase-Oriented Direction

Phase 2 (pre-migration optimization):

1. Document exact switch port map and cable IDs.
2. Validate one-uplink inter-switch topology and no-loop behavior.
3. Run `iperf3` matrix baseline before any procurement.
4. Introduce 2.5Gb adapters to highest-impact nodes first (`rb1`, `rb2`, workstation/mac mini).

Phase 5 (final network rework):

1. Finalize steady-state uplink/internet path.
2. Optionally implement dual-NIC management/data split.
3. Finalize dock/eGPU Ethernet roles (`primary`, `fallback`, `do-not-use-for-primary`).

## Validation Checklist

1. Document exact port map for both switches.
2. Verify link speed and negotiated duplex on each host path after any cable/NIC change.
3. Run continuity test: unplug one non-critical path and verify SSH + `:8006` remain reachable.
4. Run throughput test matrix per `runbooks/network-throughput-benchmark.md`.
5. Confirm NIC error/drop counters do not show sustained growth under load.
