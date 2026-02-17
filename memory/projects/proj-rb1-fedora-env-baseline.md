---
id: proj-rb1-fedora-env-baseline
title: RB1 Fedora Environment Baseline
type: project
tags: [project, rb1, fedora, egpu]
created: 2026-02-16
updated: 2026-02-16
scope: cheney
status: active
---

# RB1 Fedora Environment Baseline

## Objective

Stabilize `rb1-fedora` for reliable experimentation while keeping management continuity and rollback safety.

## Current State

1. SSH/WoL/fallback VLAN are operational.
2. Internal and external NVIDIA GPUs are visible.
3. Non-AI eGPU acceptance matrix has multiple passing scenarios.
4. Remaining manual gates are physical hot-attach and external-display-sink scenario.

## Next Actions

1. Run user-attended physical hot-attach and capture matrix evidence.
2. Run user-attended external-display-sink scenario and capture matrix evidence.
3. Keep AI runtime deferred until explicitly requested.

## Links

- Index: [[mem-index]]
- Decision: [[dec-rag-phase1-lexical-first]]
