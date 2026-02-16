# Runbook: Today Plan - eGPU + Memory Optimization

Date anchor: 2026-02-15

Purpose: make immediate progress on compute reliability (`rb1-fedora` eGPU) and assistant context quality (memory structure redesign).

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
3. Install NVIDIA stack (`akmod-nvidia`, CUDA libs as needed).
4. Reboot and validate:

```bash
ssh rb1 'nvidia-smi'
ssh rb1 'modinfo nvidia | head -n 10'
```

### A3. Acceptance

- `nvidia-smi` reports GTX 1060.
- Host survives reboot with eGPU attached.
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

1. `rb1` eGPU status documented as pass/fail with evidence.
2. `memory/` scaffold committed.
3. One sample decision note and one sample project note linked from `memory/index.md`.
4. Updated `log.md` checkpoint for both tracks.
