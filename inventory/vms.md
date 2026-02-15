# VM Inventory and Migration Order

| vm_id | vm_name | current_host | target_host | criticality | backup_state | migration_method | network_dependencies | last_boot_verified | migration_order | notes |
|---|---|---|---|---|---|---|---|---|---:|---|
| 101 | tsDeb | `rb1-pve` (mapped to `rb14-2017`, verify mapping before cutover) | `rb2-pve` | Medium | VM backup status unverified; app-level recovery path exists via reprovision | Prefer Proxmox move/replicate, fallback backup+restore | `vmbr0` LAN (`192.168.5.102/22`) + Tailscale (`100.81.158.2`) | 2026-02-13 23:45 EST (running) | 1 | Keep reachable as remote-control anchor during migration |
| 201 | lchl-tsnode-rb2 | `rb2-pve` | n/a (local utility VM) | Medium | Reprovisionable from cloud image + runbook | Rebuild-in-place preferred over backup restore | `vmbr0` LAN (`192.168.5.112/22`) + Tailscale (`100.97.121.113`) | 2026-02-14 22:30 EST (running) | 1 | Lightweight dedicated tailscale node; host-level tailscale on `rb2` intentionally disabled |
| 301 | lchl-tsnode-mba | `mba` | n/a (local utility VM) | Low | Reprovisionable from cloud image + runbook | Rebuild-in-place preferred over backup restore | `vmbr0` LAN (`192.168.5.113/22`) + Tailscale (`100.115.224.15`) | 2026-02-14 22:30 EST (running) | 1 | Lightweight dedicated tailscale node for third-node continuity |
| 100 | truenas | `rb1-pve` | `rb2-pve` (pivot in progress) | High | Fresh backup + verified copy + restored clone staged on `rb2` (2026-02-14 HST) | Backup/restore complete; pending physical USB drive cutover + service validation | `vmbr0` LAN (`192.168.5.100/22`) + storage dependencies | 2026-02-14 21:53 HST (`rb1` active, `rb2` clone stopped) | 2 | Keep `rb1` VM as rollback until `rb2` burn-in passes |

## Ordering Guidance

- Migrate lowest-criticality services first.
- Keep at least one remote-access path online during all migration stages.
- Defer highest-criticality VM(s) until backup/restore confidence is verified.
- Reconfirm host mapping (`rb1-pve` -> physical node) before executing migration order.
- Migration over stable 1GbE is acceptable for this phase; >1GbE is optimization work, not a blocker.
- `truenas` migration is now part of phase-3 pivot and must complete before `rb1` baremetal conversion.
