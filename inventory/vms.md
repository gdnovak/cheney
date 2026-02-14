# VM Inventory and Migration Order

| vm_id | vm_name | current_host | target_host | criticality | backup_state | network_dependencies | last_boot_verified | migration_order | notes |
|---|---|---|---|---|---|---|---|---:|---|
| 101 | tsDeb | `rb1-pve` (mapped to `rb14-2017`, verify mapping before cutover) | rb14-2015 | Medium | VM backup status unverified; app-level recovery path exists via reprovision | `vmbr0` LAN (`192.168.5.102/22`) + Tailscale (`100.81.158.2`) | 2026-02-13 23:45 EST (running) | 1 | Keep reachable as remote-control anchor during migration |
| 100 | truenas | `rb1-pve` (mapped to `rb14-2017`, verify mapping before cutover) | rb14-2015 | High | Backup workflows recently healthy (2026-02-13), but VM-level rollback artifact check still required | `vmbr0` LAN (`192.168.5.100/22`) + storage dependencies | 2026-02-13 23:45 EST (running) | 2 | Defer until network and rollback checks are fully validated |

## Ordering Guidance

- Migrate lowest-criticality services first.
- Keep at least one remote-access path online during all migration stages.
- Defer highest-criticality VM(s) until backup/restore confidence is verified.
- Reconfirm host mapping (`rb1-pve` -> physical node) before executing migration order.
