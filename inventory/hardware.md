# Hardware Inventory

| node_id | device_name | model_year | role | cpu | ram_gb | storage_summary | gpu_or_egpu | tb_version | power_risk | current_os_or_hypervisor | target_role | status | last_verified_at |
|---|---|---|---|---|---:|---|---|---|---|---|---|---|---|
| rb14-2017 | Razer Blade 14 (2017) | 2017 | Primary baremetal agent host (`rb1-fedora`) | Intel Core i7-7700HQ (4c/8t) | 16 | 476.9G NVMe (`SAMSUNG MZVLW512HMJP-00000`) | Internal Intel HD 630 + NVIDIA GTX 1060 Mobile (`10de:1c20`) + external GTX 1060 6GB via TB (`10de:1c03`) | TB3+ | Medium | Fedora Linux 43 Server (`192.168.5.107/22`, `enp0s20f0u6`) | Stable eGPU-ready AI/agent runtime host | Active; `rb1-admin` key SSH verified; WoL persistent (`magic`/`g`); internal+external NVIDIA GPUs visible in `nvidia-smi`; Ollama active | 2026-02-16 19:06 EST |
| rb14-2015 | Razer Blade 14 (2015) | 2015 | Primary Proxmox host (`rb2-pve`) | Intel Core i7-4720HQ (4c/8t) | 16 | 238.5G SSD (`LITEON IT L8T-256L9G`) | eGPU-capable TB path (not primary management path) | TB3 path available | High (no battery, cable sensitivity) | Proxmox VE 9.1.1 (`192.168.5.108/22`, `vmbr0`) + fallback VLAN (`172.31.99.2/30`, `vmbr0.99`) | Primary VM/storage host during `rb1` Fedora phase | Active and reachable; VMs `100/101/201/220` running; fallback endpoint active | 2026-02-16 19:06 EST |
| mba-2011 | MacBook Air (~2011) | 2011 | Fallback continuity Proxmox node (`kabbalah`) | Intel Core i5-2467M (2c/4t) | 2 | 56.5G SSD (`APPLE SSD TS064C`) | None | Mini DisplayPort-era adapter path | Medium (aging hardware, reboot reliability) | Proxmox VE 9.1.1 (`192.168.5.66/22`, `vmbr0`) | Emergency utility/fallback host | Active and reachable; VM `301` running | 2026-02-16 19:06 EST |

## Notes

- Legacy `rb1-pve` management address (`192.168.5.98`) is no longer active after Fedora baremetal conversion; `rb1` now resolves to `192.168.5.107`.
- `truenas` VM (`100`) is running on `rb2` and reachable at `192.168.5.100`; `zpool status -x` reports healthy.
- VLAN99 fallback is now active on both hosts (`rb1`: `enp0s20f0u6.99` / `172.31.99.1`; `rb2`: `vmbr0.99` / `172.31.99.2`) with successful bidirectional ping/SSH-path checks.
- `rb1` internal NVIDIA path is validated on Fedora (`nvidia`, `nvidia_uvm`, `nvidia_modeset`, `nvidia_drm` loaded; CUDA `13.0` reported).
- `rb1` external eGPU path is now detected and driver-bound in baremetal Fedora (`0f:00.0` / GTX 1060 6GB).
- eGPU readiness findings and deferred acceptance gates are tracked in `notes/egpu-readiness-rb1-fedora-20260216.md`.
