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
9. Scripted acceptance harnesses are in-repo:
   - Matrix script: `scripts/egpu_acceptance_matrix.sh`
   - Benchmark script: `scripts/egpu_hashcat_benchmark.sh`
   - Matrix output: `notes/egpu-acceptance-matrix-20260216.md`
   - Matrix artifacts: `notes/egpu-acceptance-artifacts/egpu-*.log`
   - Benchmark artifact: `notes/egpu-acceptance-artifacts/egpu-benchmark-hashcat-external-20260216-195036.log`

## Why This Helps eGPU Work Later

1. Management path is isolated from eGPU Ethernet/TB chain, reducing lockout risk during attach tests.
2. NVIDIA/akmods toolchain is already proven on current kernel, so external detection failures can be treated as bus/device-path problems first.
3. WoL path is available for remote recovery during failed test cycles.
4. Root break-glass access remains available (`rb1`) while normal operations use `rb1-admin`.

## Known Constraints

1. `sshd -T` reports `PermitRootLogin yes` because installer file `/etc/ssh/sshd_config.d/01-permitrootlogin.conf` overrides hardening intent. Password auth remains disabled, so root is currently key-only.
2. Physical hot-attach with manual cable remove/reinsert was not rerun in this pass; current "hot attach" evidence is a software PCI remove/rescan proxy cycle with post-check pass.
3. External-display-sink scenario is still pending user-attended setup. Current state reports external GPU `display_active=Disabled`.
4. Kernel reports reduced external link speed (`PCIe Gen2 x4` observed in latest checks). Benchmark impact captured below.

## Matrix Coverage (Current)

`notes/egpu-acceptance-matrix-20260216.md` now records these passing scenarios:

1. `reboot_attached_persistence` (`PASS`, reboot `32s`)
2. `attached_no_external_display` (`PASS`)
3. `cold_boot_attached` (`PASS`, reboot `44s`)
4. `hot_attach_idle_soft_rescan_postcheck` (`PASS`)

All rows show pre/post success for:

1. External GPU presence (`lspci`, `nvidia-smi`)
2. Fallback reachability and interface persistence
3. Core Fedora service health

Supporting hot-attach proxy artifact:

- `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle-soft_rescan-20260216-194731.log`

## Non-AI Workload Benchmark (External GPU)

- Command class: `hashcat -b -m 1400 -d 2` (external GPU only)
- Artifact: `notes/egpu-acceptance-artifacts/egpu-benchmark-hashcat-external-20260216-195036.log`
- Observed speed: `1608.6 MH/s` (`SHA2-256`)
- Post-run `nvidia-smi` for external GPU (`0F:00.0`): `utilization=61%`, `pstate=P0`, link `Gen3 x4` during workload window

## Deferred Phase-5 eGPU Gates

Run these in order:

1. User-attended physical hot-attach cycle (cable remove/reinsert on idle host), then rerun:
   - `scripts/egpu_acceptance_matrix.sh --scenario hot_attach_idle_physical_postcheck --host rb1-admin --peer rb2`
2. User-attended external-display-sink cycle, then rerun:
   - `scripts/egpu_acceptance_matrix.sh --scenario attached_with_external_display --host rb1-admin --peer rb2`
3. Capture for each user-attended test:
   - `boltctl list`
   - `lspci -nnk | grep -EA3 'VGA|3D|Display'`
   - `nvidia-smi --query-gpu=index,pci.bus_id,name,display_active,pcie.link.gen.current,pcie.link.width.current --format=csv`
   - `journalctl -k --since "<test-start-time>"`
4. Validate management SSH, fallback VLAN99, and WoL remain unaffected after each attempt.

## Pass/Fail Definition

- Pass: external eGPU appears reliably across attach/reboot scenarios, fallback path remains intact, and at least one workload runs without GPU reset/drop events.
- Fail: unstable external enumeration, management instability, or reproducible GPU errors; keep internal NVIDIA as baseline and continue CPU-safe AI bootstrap tasks.
