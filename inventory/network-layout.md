# Network Layout Plan

## Current Physical Switching

- `switch-smart-netgear`: Netgear smart switch (management-capable control-plane anchor).
- `switch-fast-unmanaged`: higher-throughput unmanaged switch for bulk data paths.
- Rule: keep exactly one cable between switches unless loop protections are explicitly configured and validated.

## Current Known IP Anchors (2026-02-16)

| system | ip | role | source |
|---|---|---|---|
| rb1-fedora host (`rb14-2017`) | 192.168.5.107/22 | Fedora baremetal agent host | live SSH check |
| rb2-pve host (`rb14-2015`) | 192.168.5.108/22 | primary Proxmox host | live SSH check |
| rb2 fallback VLAN | 172.31.99.2/30 | fallback management endpoint (single-sided currently) | live host route/addr check |
| truenas VM (100) | 192.168.5.100/22 | storage service VM on `rb2` | live guest service check |
| tsDeb VM (101) | 192.168.5.102/22 | utility/remote-access VM on `rb2` | `qm list` |
| cheney-vessel-alpha VM (220) | 192.168.5.111/22 | sandbox workload VM on `rb2` | `qm list` |
| lchl-tsnode-rb2 VM (201) | 192.168.5.112/22 | utility tailscale node on `rb2` | `qm list` |
| lchl-tsnode-mba VM (301) | 192.168.5.113/22 | utility tailscale node on `mba` | `qm list` |
| mba-2011 (`kabbalah`) | 192.168.5.66/22 | fallback Proxmox node | live SSH check |
| gateway | 192.168.4.1 | default route | host route table |

## Throughput Baseline

Historical baseline (2026-02-14):

- `rb1 <-> rb2`: healthy ~1Gb class throughput.
- `* <-> mba`: bottlenecked (~300 Mbps class) due MBA USB2 Ethernet path.

Current link checks (2026-02-16):

- `rb1-fedora` `enp0s20f0u6` -> `1000/full`
- `rb2-pve` `enx00051bde7e6e` -> `1000/full`
- `mba` `nic0` -> `1000/full`

## Fallback VLAN (Management-Only)

- `VLAN 99` remains staged on the smart-switch path for `rb1`/`rb2` fallback management.
- Current host interface state:
  - `rb2`: `vmbr0.99` -> `172.31.99.2/30` (present and routed)
  - `rb1-fedora`: no active `.99` fallback interface at this time
- Validation status (2026-02-16):
  - `rb1 -> 172.31.99.2` ping fails (`100%` loss).
  - `rb2 -> 172.31.99.1` ping fails (`100%` loss).

## Fallback Persistence Status (Current)

- `rb2`: persistent fallback config is present in `/etc/network/interfaces` and active after reboot.
- `rb1-fedora`: previous Proxmox `vmbr0.99` persistence no longer applies post-reinstall; Fedora-side fallback reimplementation is pending.

## Security Controls (VLAN99)

1. VLAN99 is host-management only; no VM transit on this path.
2. Do not configure a gateway on fallback interfaces.
3. Do not use fallback subnet for forwarding/NAT/routing policies.
4. Keep scope constrained to `172.31.99.0/30` between `rb1` and `rb2` only.
5. Revalidate controls after any interface or host-role changes.

## Target Topology (Throughput-First)

1. Keep smart switch as control-plane anchor and management visibility point.
2. Place high-throughput endpoints (`rb1`, `rb2`, workstation/mac mini) on fast unmanaged switch when 2.5Gb-capable NICs are available.
3. Keep `mba` on stable 1Gb path for continuity/fallback, not bulk transfer.
4. Maintain a single LAN/subnet during early optimization to reduce migration risk.
5. Add optional dual-NIC split later:
- NIC A on smart switch for management.
- NIC B on fast switch for migration/backup/storage traffic.

## Host Path Targets

| host | current primary NIC path | current link | target near-term | target link | fallback path requirement |
|---|---|---|---|---|---|
| rb1-fedora | `enp0s20f0u6` (USB NIC) | 1GbE | keep management isolated from eGPU Ethernet; add 2.5Gb data path later | 2.5GbE target | reintroduce Fedora-side VLAN99 interface and validate reachability |
| rb2-pve | `enx00051bde7e6e` | 1GbE | prioritize power/cable strain relief, then 2.5Gb upgrade path | 2.5GbE target | keep `vmbr0.99` active and documented |
| mba (`kabbalah`) | `nic0` | 1GbE | continuity node only | 1GbE | retain hub + direct TB/miniDP fallback notes |
| workstation/mac mini | TBD | TBD | add to fast-switch data path if 2.5-capable NIC path exists | 2.5GbE target | keep Wi-Fi as secondary out-of-band access |

## Validation Checklist

1. Document exact port map for both switches.
2. Verify link speed and duplex after any cable/NIC change.
3. Rebuild dual-sided fallback (`rb1` + `rb2`) and confirm bidirectional ping/SSH.
4. Run throughput matrix per `runbooks/network-throughput-benchmark.md`.
5. Confirm NIC error/drop counters do not show sustained growth under load.
