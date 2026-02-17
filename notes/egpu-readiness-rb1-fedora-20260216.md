# eGPU Readiness Findings - `rb1-fedora` (2026-02-16)

Purpose: record what is already in place for external eGPU work, what is still missing, and what to run next so phase-5 eGPU work resumes cleanly.

## Baseline Completed

1. `rb1-fedora` is stable on management NIC `enp0s20f0u6` (`192.168.5.107/22`) and reachable via `rb1-admin`.
2. Fedora host updated and rebooted on kernel `6.18.9-200.fc43.x86_64`.
3. Core services are active: `sshd`, `firewalld`, `chronyd`, `cockpit.socket`.
4. Wake-on-LAN persistence is configured:
   - NM profile `enp0s20f0u6` => `wake-on-lan=magic`
   - `ethtool` reports `Wake-on: g` after reboot
5. Internal NVIDIA stack is operational:
   - Driver `580.119.02`
   - CUDA `13.0`
   - GPU detected by `nvidia-smi`: `NVIDIA GeForce GTX 1060`

## Why This Helps eGPU Work Later

1. Management path is isolated from eGPU Ethernet/TB chain, reducing lockout risk during attach tests.
2. NVIDIA/akmods toolchain is already proven on current kernel, so external detection failures can be treated as bus/device-path problems first.
3. WoL path is available for remote recovery during failed test cycles.
4. Root break-glass access remains available (`rb1`) while normal operations use `rb1-admin`.

## Known Constraints

1. Fedora-side VLAN99 fallback (`172.31.99.1/30`) is still missing; current fallback ping between `rb1` and `rb2` fails.
2. `sshd -T` reports `PermitRootLogin yes` because installer file `/etc/ssh/sshd_config.d/01-permitrootlogin.conf` overrides hardening intent. Password auth remains disabled, so root is currently key-only.
3. No external eGPU attach matrix has been run in this session.

## Deferred Phase-5 eGPU Gates

Run these in order:

1. Restore dual-sided fallback first (`rb1` + `rb2`) to reduce recovery risk.
2. Attach-test matrix on `rb1-fedora`:
   - cold boot with Core attached
   - hot attach on idle host
   - attach with/without external display sink
3. Capture for each test:
   - `boltctl list`
   - `lspci -nnk | grep -EA3 'VGA|3D|Display'`
   - `nvidia-smi`
   - `journalctl -k --since "<test-start-time>"`
4. Validate that management SSH and WoL remain unaffected after each attempt.

## Pass/Fail Definition

- Pass: external eGPU device appears reliably in PCI enumeration and remains stable across reboot/reattach without losing management access.
- Fail: no stable external enumeration or management instability; keep internal NVIDIA as baseline and continue CPU-safe AI bootstrap tasks.
