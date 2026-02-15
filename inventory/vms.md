# VM Inventory and Migration Order

| vm_id | vm_name | current_host | target_host | criticality | backup_state | migration_method | network_dependencies | last_boot_verified | migration_order | notes |
|---|---|---|---|---|---|---|---|---|---:|---|
| 101 | tsDeb | `rb2-pve` | n/a (migrated) | Medium | Fresh backup + restore completed (`2026-02-14`) | Backup/restore migration completed (`rb1` -> `rb2`) | `vmbr0` LAN (`192.168.5.102/22`) + Tailscale (`100.81.158.2`) | 2026-02-14 22:08 HST (running on `rb2`) | 1 | Keep reachable as remote-control anchor; subnet-routing duty should remain on `rb2` path |
| 220 | cheney-vessel-alpha | `rb2-pve` (temporary host) | `rb1` Fedora baremetal (future move) | Medium | Fresh backup + restore completed (`2026-02-14`) | Backup/restore migration completed (`rb1` -> `rb2`) | `vmbr0` LAN (`192.168.5.111/22`) | 2026-02-14 22:08 HST (running on `rb2`) | 1 | Temporary relocation to clear `rb1` for Fedora install |
| 201 | lchl-tsnode-rb2 | `rb2-pve` | n/a (local utility VM) | Medium | Reprovisionable from cloud image + runbook | Rebuild-in-place preferred over backup restore | `vmbr0` LAN (`192.168.5.112/22`) + Tailscale (`100.97.121.113`) | 2026-02-14 22:30 EST (running) | 1 | Lightweight dedicated tailscale node; host-level tailscale on `rb2` intentionally disabled |
| 301 | lchl-tsnode-mba | `mba` | n/a (local utility VM) | Low | Reprovisionable from cloud image + runbook | Rebuild-in-place preferred over backup restore | `vmbr0` LAN (`192.168.5.113/22`) + Tailscale (`100.115.224.15`) | 2026-02-14 22:30 EST (running) | 1 | Lightweight dedicated tailscale node for third-node continuity |
| 100 | truenas | `rb2-pve` (pivot active) | n/a (post-pivot primary planned) | High | Fresh backup + verified copy + restore completed (`2026-02-14`) | Backup/restore + physical USB move executed; service validation still pending | `vmbr0` LAN (`192.168.5.100/22`) + storage dependencies | 2026-02-14 22:08 HST (running on `rb2`) | 2 | Keep original `rb1` definition only as rollback reference until burn-in passes |

## Ordering Guidance

- Migrate lowest-criticality services first.
- Keep at least one remote-access path online during all migration stages.
- Defer highest-criticality VM(s) until backup/restore confidence is verified.
- Reconfirm host mapping (`rb1-pve` -> physical node) before executing migration order.
- Migration over stable 1GbE is acceptable for this phase; >1GbE is optimization work, not a blocker.
- `truenas` migration is now part of phase-3 pivot and must complete before `rb1` baremetal conversion.
