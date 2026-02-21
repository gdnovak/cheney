---
id: dec-openclaw-tui-live-blurb-cognee-phase0
title: Add OpenClaw TUI Live Footer and Keep Cognee at Phase-0 Prep
type: decision
tags: [decision, openclaw, cognee, memory, reliability]
created: 2026-02-21
updated: 2026-02-21
scope: cheney
status: accepted
---

# Add OpenClaw TUI Live Footer and Keep Cognee at Phase-0 Prep

## Decision

1. Patch OpenClaw TUI bundles on `rb1` with a reversible workflow to show live footer fields for:
   - action status
   - current model
   - inferred tier
2. Keep Cognee integration at phase-0 only for now:
   - safe ingest-scope manifest
   - host environment probe
   - no routing changes yet

## Why

1. Live status visibility in TUI improves operator trust during long/uncertain runs.
2. Cognee may help compaction-amnesia, but full integration should be gated by retrieval quality and safety checks.
3. Current OpenClaw router behavior is stable enough that memory-sidecar work should remain isolated until pilot results are measured.

## Evidence

1. TUI patch scripts and runbook added and validated with smoke checks on `rb1`.
2. Cognee prep artifacts generated under `notes/cognee/`.
3. OpenClaw routing defaults remained unchanged during this pass.

## Links

- Index: [[mem-index]]
- Project: [[proj-openclaw-truth-guard]]
