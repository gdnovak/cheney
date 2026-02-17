# Runbook: Today Plan - eGPU + Memory Optimization

Date anchor: 2026-02-16

Purpose: make immediate progress on compute reliability (`rb1-fedora` eGPU) and assistant context quality (memory structure redesign).

## Session Checkpoint (2026-02-16 19:33 EST)

Track A progress:

1. `DONE` Host baseline and updates applied.
2. `DONE` Internal NVIDIA stack validated (`nvidia-smi` pass, driver `580.119.02`, CUDA `13.0`).
3. `DONE` WoL persistence configured and revalidated after reboot.
4. `DONE` Fedora-side fallback VLAN99 restored and validated (`172.31.99.1/30` <-> `172.31.99.2/30`).
5. `DONE` External eGPU hot-attach detection validated (`0f:00.0`, GTX 1060 6GB).
6. `DONE` Reboot-survival validation passed for fallback+eGPU state (boot ID changed; fallback persisted; both GPUs still visible).

Track B progress:

1. `OPEN` Memory structure and RAG decision still pending.
2. `OPEN` `memory/` scaffold not started.

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
