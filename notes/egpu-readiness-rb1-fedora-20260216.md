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
6. External eGPU is currently detected and driver-bound:
   - PCI endpoint present: `0000:0f:00.0` (`10de:1c03`, GTX 1060 6GB)
   - Thunderbolt path visible (`Razer Core` in kernel log and `boltctl list`)
   - `nvidia-smi` shows both GPUs concurrently
7. Fallback VLAN99 is restored:
   - `rb1`: `enp0s20f0u6.99` (`fallback99`) -> `172.31.99.1/30`
   - `rb2`: `vmbr0.99` -> `172.31.99.2/30`
   - Bidirectional ping and fallback SSH path checks succeed
8. AI runtime artifacts were intentionally removed after initial smoke validation:
   - `ollama` removed from host
   - `codex` removed from host
   - host-local `~/cheney` clone removed
   - environment baseline left intact for deferred AI bring-up later
9. Scripted acceptance harness is now in-repo:
   - Script: `scripts/egpu_acceptance_matrix.sh`
   - Matrix output: `notes/egpu-acceptance-matrix-20260216.md`
   - Artifact log (first scripted run): `notes/egpu-acceptance-artifacts/egpu-reboot_attached_persistence-20260216-193959.log`

## Why This Helps eGPU Work Later

1. Management path is isolated from eGPU Ethernet/TB chain, reducing lockout risk during attach tests.
2. NVIDIA/akmods toolchain is already proven on current kernel, so external detection failures can be treated as bus/device-path problems first.
3. WoL path is available for remote recovery during failed test cycles.
4. Root break-glass access remains available (`rb1`) while normal operations use `rb1-admin`.

## Known Constraints

1. `sshd -T` reports `PermitRootLogin yes` because installer file `/etc/ssh/sshd_config.d/01-permitrootlogin.conf` overrides hardening intent. Password auth remains disabled, so root is currently key-only.
2. One reboot-survival pass (with eGPU attached and fallback active) succeeded; full multi-scenario matrix is not yet completed.
3. Kernel reports external GPU link limitation at `2.5 GT/s PCIe x4` on current path; practical workload impact still needs benchmarking.
4. External-GPU pinning behavior under real workloads has not yet been validated (AI runtime currently deferred).

## Latest Scripted Matrix Result

- Scenario: `reboot_attached_persistence`
- Result: `PASS`
- Reboot elapsed: `32s`
- Pre/post external GPU checks:
  - `lspci` external endpoint: pass
  - `nvidia-smi` external BDF visibility: pass
  - fallback ping and fallback interface persistence: pass

## Deferred Phase-5 eGPU Gates

Run these in order:

1. Attach-test matrix on `rb1-fedora`:
   - cold boot with Core attached
   - hot attach on idle host
   - attach with/without external display sink
2. Capture for each test:
   - `boltctl list`
   - `lspci -nnk | grep -EA3 'VGA|3D|Display'`
   - `nvidia-smi`
   - `journalctl -k --since "<test-start-time>"`
3. Validate that management SSH, fallback VLAN99, and WoL remain unaffected after each attempt.
4. Run one short GPU workload benchmark to estimate impact of current link speed limits.

## Pass/Fail Definition

- Pass: external eGPU appears reliably across attach/reboot scenarios, fallback path remains intact, and at least one workload runs without GPU reset/drop events.
- Fail: unstable external enumeration, management instability, or reproducible GPU errors; keep internal NVIDIA as baseline and continue CPU-safe AI bootstrap tasks.
