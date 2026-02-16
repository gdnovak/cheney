# VM Inventory and Runtime Placement

| vm_id | vm_name | current_host | target_host | criticality | backup_state | migration_method | network_dependencies | last_boot_verified | migration_order | notes |
|---|---|---|---|---|---|---|---|---|---:|---|
| 100 | truenas | `rb2-pve` | `rb2-pve` (current storage-primary) | High | Backup + transfer + restore path verified (`2026-02-14`) | Backup/restore + physical USB move completed | `vmbr0` LAN (`192.168.5.100/22`) + storage dependencies | 2026-02-16 18:05 EST (running) | 1 | Storage service currently anchored on `rb2`; keep rollback artifact history until extended burn-in passes |
| 101 | tsDeb | `rb2-pve` | `rb2-pve` | Medium | Fresh backup + restore completed (`2026-02-14`) | Backup/restore migration completed (`rb1` -> `rb2`) | `vmbr0` LAN (`192.168.5.102/22`) + Tailscale path | 2026-02-16 18:05 EST (running) | 1 | Continuity anchor; watchdog timer check reports active |
| 220 | cheney-vessel-alpha | `rb2-pve` | n/a (temporary while `rb1` baremetal stack is validated) | Medium | Fresh backup + restore completed (`2026-02-14`) | Backup/restore migration completed (`rb1` -> `rb2`) | `vmbr0` LAN (`192.168.5.111/22`) | 2026-02-16 18:05 EST (running) | 2 | Keep on `rb2` until `rb1` eGPU + AI bootstrap acceptance passes |
| 201 | lchl-tsnode-rb2 | `rb2-pve` | `rb2-pve` | Medium | Reprovisionable from cloud image + runbook | Rebuild-in-place preferred over backup restore | `vmbr0` LAN (`192.168.5.112/22`) + tailnet | 2026-02-16 18:05 EST (running) | 2 | Utility tailscale node; host-level tailscale on `rb2` remains intentionally disabled |
| 301 | lchl-tsnode-mba | `mba` | `mba` | Low | Reprovisionable from cloud image + runbook | Rebuild-in-place preferred over backup restore | `vmbr0` LAN (`192.168.5.113/22`) + tailnet | 2026-02-16 18:05 EST (running) | 2 | Utility tailscale node for third-node continuity |

## Operating Guidance

- Keep at least one remote-access path online during all hardware/network changes.
- Treat `rb2` as the current VM/storage anchor while `rb1` Fedora is stabilized for direct GPU work.
- Do not schedule further VM relocations from `rb2` until fallback VLAN redundancy is restored on `rb1`.
- Migration over stable 1GbE is acceptable for current continuity work; >1GbE remains optimization.
