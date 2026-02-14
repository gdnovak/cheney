# Hardware Inventory

| node_id | device_name | model_year | role | cpu | ram_gb | storage_summary | gpu_or_egpu | tb_version | power_risk | current_os_or_hypervisor | target_role | status | last_verified_at |
|---|---|---|---|---|---:|---|---|---|---|---|---|---|---|
| rb14-2017 | Razer Blade 14 (2017) | 2017 | Current Proxmox source host | Intel Core i7-7700HQ (4c/8t) | 16 | 476.9G NVMe (`pve-root` 96G, `local-lvm` ~347.9G, swap 8G) | Internal GTX 1060 (mobile) | TB3+ | Medium | Proxmox VE 9.1 node `rb1-pve` (`vmbr0` 192.168.5.98/22) | Transitional / backup node after migration | Active | 2026-02-13 23:45 EST |
| rb14-2015 | Razer Blade 14 (2015) | 2015 | Target Proxmox host | Unverified (host offline) | 0 | Unverified (host offline) | eGPU-capable via TB path as applicable | TB3 path required for Core + GTX 1060 setup | High (no battery, cable sensitivity) | Not connected during inventory pass | Primary Proxmox host for current VM set | Offline / pending physical setup | 2026-02-13 23:45 EST |
| mba-2011 | MacBook Air (~2011) | 2011 | Fallback continuity node | Unverified (no shell access yet) | 0 | Unverified (no shell access yet) | None | Mini DisplayPort-era adapter path | Medium (aging hardware, reboot reliability) | Legacy Proxmox usage reported; current state not shell-verified | Emergency fallback host | Booting/intermittent; pingable at `192.168.5.66` | 2026-02-13 23:45 EST |

## Notes

- `ram_gb=0` currently means unknown/unverified, not literal zero memory.
- `rb1-pve` currently reports no local corosync config, indicating standalone node mode on the active host.
- User-reported issue: legacy MacBook Air Proxmox state may still reference an old cluster peer and fail quorum until reconfigured.
