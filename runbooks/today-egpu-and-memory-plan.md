# Runbook: Today Plan - eGPU + Memory Optimization

Date anchor: 2026-02-16

Purpose: make immediate progress on compute reliability (`rb1-fedora` eGPU) and assistant context quality (memory structure redesign).

## Session Checkpoint (2026-02-16 20:11 EST)

Track A progress:

1. `DONE` Host baseline and updates applied.
2. `DONE` Internal NVIDIA stack validated (`nvidia-smi` pass, driver `580.119.02`, CUDA `13.0`).
3. `DONE` WoL persistence configured and revalidated after reboot.
4. `DONE` Fedora-side fallback VLAN99 restored and validated (`172.31.99.1/30` <-> `172.31.99.2/30`).
5. `DONE` External eGPU hot-attach detection validated (`0f:00.0`, GTX 1060 6GB).
6. `DONE` Reboot-survival validation passed for fallback+eGPU state (boot ID changed; fallback persisted; both GPUs still visible).
7. `DONE` Acceptance harness script created: `scripts/egpu_acceptance_matrix.sh`.
8. `DONE` Scripted matrix scenarios executed and logged:
   - `notes/egpu-acceptance-matrix-20260216.md`
   - `notes/egpu-acceptance-artifacts/egpu-reboot_attached_persistence-20260216-193959.log`
   - `notes/egpu-acceptance-artifacts/egpu-cold_boot_attached-20260216-194611.log`
   - `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle_soft_rescan_postcheck-20260216-194739.log`
   - `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle_physical_postcheck-20260216-200930.log`
9. `DONE` Non-AI workload benchmark on external GPU captured:
   - `notes/egpu-acceptance-artifacts/egpu-benchmark-hashcat-external-20260216-195036.log`
10. `ISSUE` Physical hot-attach cable cycle produced reattach instability (kernel ACPI/PCI hotplug warning/Oops) with recovery by reboot:
   - `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle-physical-20260216-195603.log`
11. `DONE` User-attended external-display-sink scenario completed:
   - sink detection artifact: `notes/egpu-acceptance-artifacts/egpu-display-sink-check-20260216-201756.log` (`card2-DP-3=connected`)
   - matrix scenario artifact: `notes/egpu-acceptance-artifacts/egpu-attached_with_external_display-20260216-201759.log` (`PASS`)
12. `DONE` Decision recorded to defer further hotplug tuning for now and operate recovery-first.
13. `OPEN` Next-phase planning runbook kickoff.

Track B progress:

1. `DONE` Memory structure and RAG phase-1 decision captured in `memory/decisions/dec-rag-phase1-lexical-first.md`.
2. `DONE` `memory/` scaffold created with linked index, templates, and starter notes.
3. `DONE` Lexical retrieval helper added: `scripts/memory_index.sh`.

Bootstrap progress:

1. `DONE` AI runtime/tooling rollback executed on `rb1` (`ollama` + `codex` removed, host-local `~/cheney` clone removed).
2. `DONE` Environment baseline retained after rollback (NVIDIA, fallback99, SSH/WoL).
3. `DEFERRED` AI bootstrap workflow until explicitly resumed.

## Track A: eGPU on `rb1-fedora`

Goal: stable NVIDIA/eGPU path on Fedora baremetal for agent workloads.

### A1. Baseline Capture

```bash
ssh rb1 'hostnamectl --static; uname -r; ip -4 -br addr'
ssh rb1 'lspci -nnk | grep -EA3 "VGA|3D|Display"'
ssh rb1 'lsusb'
```

Record whether the Razer Core + GTX 1060 are visible before driver work.

### A1.1 Matrix Harness (Saved Test Program)

Use the reusable harness:

```bash
scripts/egpu_acceptance_matrix.sh \
  --scenario reboot_attached_persistence \
  --reboot \
  --host rb1-admin \
  --peer rb2
```

Outputs:

- Matrix row file: `notes/egpu-acceptance-matrix-YYYYMMDD.md`
- Per-run artifact log: `notes/egpu-acceptance-artifacts/egpu-<scenario>-<timestamp>.log`

### A1.2 Benchmark Harness (Saved Test Program)

Use the reusable external-GPU benchmark harness:

```bash
scripts/egpu_hashcat_benchmark.sh \
  --host rb1-admin \
  --device-id 2 \
  --hash-mode 1400
```

Output:

- `notes/egpu-acceptance-artifacts/egpu-benchmark-hashcat-external-<timestamp>.log`

### A2. Fedora/NVIDIA Bring-Up

1. Update host packages.
2. Enable RPM Fusion repositories (free + nonfree).
3. Install NVIDIA stack (`xorg-x11-drv-nvidia`, CUDA libs, akmods/kernel headers as needed).
4. Reboot and validate:

```bash
ssh rb1 'nvidia-smi'
ssh rb1 'modinfo nvidia | head -n 10'
```

### A3. Acceptance

- `nvidia-smi` reports GTX 1060.
- External eGPU (Razer Core path) is detected consistently across reboot/reattach tests.
- Management SSH remains stable on non-eGPU NIC.

### A4. If Unstable

- Keep eGPU disconnected from management path.
- Record dmesg/journal evidence.
- Continue AI stack bring-up in CPU mode until GPU path is corrected.

## Track B: Memory Optimization (Markdown Graph)

Goal: create a durable, agent-friendly memory substrate using plain markdown files with structured metadata and links.

### B1. Principle

Use Obsidian-style data model without tool lock-in:

1. Markdown files as source of truth.
2. Frontmatter metadata (`id`, `tags`, `created`, `updated`, `scope`).
3. Explicit links (`[[note-id]]`) for graph traversal.
4. Git versioning + deterministic retrieval helpers.

### B2. Initial Scaffold

Create a `memory/` tree in repo:

- `memory/inbox/`
- `memory/projects/`
- `memory/entities/`
- `memory/rules/`
- `memory/decisions/`
- `memory/index.md`
- `memory/templates/`

Each note should include consistent frontmatter schema.

### B3. Retrieval Strategy (Phase 1)

1. Lexical retrieval first (`rg` + structured headers/tags).
2. Add simple index script (build note list + backlinks).
3. Keep optional semantic layer (embeddings/DB) as additive later phase.

### B4. Acceptance

- New instance can find active priorities in under 60 seconds.
- Decision history is linkable and auditable.
- No dependency on proprietary UI/app.

## End-of-Day Deliverables

1. `rb1` eGPU status documented as pass/fail with evidence (`notes/egpu-readiness-rb1-fedora-20260216.md`).
2. `memory/` scaffold committed.
3. One sample decision note and one sample project note linked from `memory/index.md`.
4. Updated `log.md` checkpoint for both tracks.
