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
3. Non-AI eGPU acceptance matrix is complete for current scope, including display-attached scenario.
4. Physical hot-attach cable cycle is confirmed temperamental; recovery-by-reboot path is known and documented.

## Next Actions

1. Preserve current stable operating mode (avoid unnecessary hot-unplug/replug).
2. Keep AI runtime deferred until explicitly requested.
3. Shift to next-phase planning in `runbooks/next-steps-planning-20260216.md`.

## Links

- Index: [[mem-index]]
- Decision: [[dec-rag-phase1-lexical-first]]
- Decision: [[dec-egpu-hotplug-defer-recovery-first]]
