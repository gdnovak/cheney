# VM Inventory and Migration Order

| vm_id | vm_name | current_host | target_host | criticality | backup_state | migration_method | network_dependencies | last_boot_verified | migration_order | notes |
|---|---|---|---|---|---|---|---|---|---:|---|
| 101 | tsDeb | `rb1-pve` (mapped to `rb14-2017`, verify mapping before cutover) | `rb2-pve` | Medium | VM backup status unverified; app-level recovery path exists via reprovision | Prefer Proxmox move/replicate, fallback backup+restore | `vmbr0` LAN (`192.168.5.102/22`) + Tailscale (`100.81.158.2`) | 2026-02-13 23:45 EST (running) | 1 | Keep reachable as remote-control anchor during migration |
| 100 | truenas | `rb1-pve` (mapped to `rb14-2017`, verify mapping before cutover) | `rb2-pve` | High | Backup workflows recently healthy (2026-02-13), but VM-level rollback artifact check still required | Move/restore VM while keeping TrueNAS virtualized | `vmbr0` LAN (`192.168.5.100/22`) + storage dependencies | 2026-02-13 23:45 EST (running) | 2 | Keep as VM; physically attach required disks on target host and validate pool import |

## Ordering Guidance

- Migrate lowest-criticality services first.
- Keep at least one remote-access path online during all migration stages.
- Defer highest-criticality VM(s) until backup/restore confidence is verified.
- Reconfirm host mapping (`rb1-pve` -> physical node) before executing migration order.
- Migration over stable 1GbE is acceptable for this phase; >1GbE is optimization work, not a blocker.
