# eGPU Passthrough Findings (Fedora VM on Proxmox)

Date: 2026-02-15
Node: `rb1-pve`
VM: `220` (`cheney-vessel-alpha`)

## Current Outcome

1. Host stability:
- `rb1` remains stable and reachable when management is pinned to USB NIC (`enxa0cec804fed7`).
- Fallback VLAN path (`rb1` <-> `rb2`) remains usable.
2. eGPU passthrough:
- Proxmox successfully binds eGPU to VFIO (`0f:00.0`, `0f:00.1`).
- VM start succeeds with warning:
  - `failed to reset PCI device ... Inappropriate ioctl for device`
3. Guest behavior:
- Fedora guest loses SSH/QGA availability after eGPU attach (GPU-only and GPU+audio both tested).
- Removing `hostpci*` restores guest access immediately.

## Test Variables Recorded

1. `dummy_hdmi=present` and `dummy_hdmi=absent` were both tested for `hostpci0=0f:00.0`.
2. Result in both states: guest SSH/QGA loss after passthrough attach; rollback restores guest.
3. eGPU Ethernet cable was unplugged to avoid management path coupling.

## Primary Documentation References

1. Proxmox PCI Passthrough:
- https://pve.proxmox.com/pve-docs/pve-admin-guide.html#qm_pci_passthrough
2. Proxmox Cloud-Init Support:
- https://pve.proxmox.com/wiki/Cloud-Init_Support
3. Linux VFIO framework:
- https://docs.kernel.org/driver-api/vfio.html
4. Fedora 42 release notes (interface naming/system behavior context):
- https://docs.fedoraproject.org/en-US/fedora/f42/release-notes/

## Practical Interpretation

1. Guest distro choice (Fedora vs Ubuntu) is secondary to the eGPU/TB reset and passthrough characteristics.
2. This GTX 1060 eGPU path likely needs additional tuning beyond baseline VFIO attach:
- ROM handling (`romfile`/`rombar=0`)
- BIOS/UEFI permutations
- possible vendor-reset support (if available for this device path)
- explicit guest-side NVIDIA driver stack post-attach

## Next Test Matrix

Run each test with management fixed to USB NIC and fallback VLAN verified:

1. `dummy_hdmi=present`, `hostpci0=0f:00.0` only
2. `dummy_hdmi=absent`, `hostpci0=0f:00.0` only
3. `dummy_hdmi=present`, `hostpci0=0f:00.0`, `hostpci1=0f:00.1`
4. same as #3 plus `rombar=0`
5. same as #3 plus UEFI/OVMF guest firmware path

After each case:

1. Verify `rb1` SSH + fallback VLAN.
2. Verify VM SSH + QGA.
3. If VM unavailable for >60s, roll back `hostpci*` and record outcome.
