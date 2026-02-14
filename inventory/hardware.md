# Hardware Inventory

| node_id | device_name | model_year | role | cpu | ram_gb | storage_summary | gpu_or_egpu | tb_version | power_risk | current_os_or_hypervisor | target_role | status | last_verified_at |
|---|---|---|---|---|---:|---|---|---|---|---|---|---|---|
| rb14-2017 | Razer Blade 14 (2017) | 2017 | Current Proxmox source host | Intel Core i7-7700HQ (4c/8t) | 16 | 476.9G NVMe (`pve-root` 96G, `local-lvm` ~347.9G, swap 8G) | Internal GTX 1060 (mobile) | TB3+ | Medium | Proxmox VE 9.1 node `rb1-pve` (`vmbr0` 192.168.5.98/22) | Transitional / backup node after migration | Active | 2026-02-13 23:45 EST |
| rb14-2015 | Razer Blade 14 (2015) | 2015 | Target Proxmox host | Unverified (detailed host audit pending) | 0 | Unverified (detailed host audit pending) | eGPU-capable via TB path as applicable | TB3 path required for Core + GTX 1060 setup | High (no battery, cable sensitivity) | Proxmox install complete as `rb2-pve.home.arpa` (`192.168.5.108`), SSH key auth working | Primary Proxmox host for current VM set | Active and reachable | 2026-02-14 03:13 EST |
| mba-2011 | MacBook Air (~2011) | 2011 | Fallback continuity node | Unverified (detailed host audit pending) | 0 | Unverified (detailed host audit pending) | None | Mini DisplayPort-era adapter path | Medium (aging hardware, reboot reliability) | Proxmox reachable at `kabbalah` (`192.168.5.66`), SSH key auth working, decoupled from old cluster | Emergency fallback host | Active and reachable | 2026-02-14 03:13 EST |

## Notes

- `ram_gb=0` currently means unknown/unverified, not literal zero memory.
- `rb1-pve` currently reports no local corosync config, indicating standalone node mode on the active host.
- Legacy MBA quorum issue was mitigated by forcing expected votes, then removing stale corosync config so node is standalone.
- Phase 1 is not complete until MBA is brought to a working, reachable Proxmox state for third-node quorum/insurance.
