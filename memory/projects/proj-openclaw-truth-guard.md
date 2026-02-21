---
id: proj-openclaw-truth-guard
title: OpenClaw Truth Guard and Verified Writes
type: project
tags: [project, openclaw, safety, reliability]
created: 2026-02-21
updated: 2026-02-21
scope: cheney
status: active
---

# OpenClaw Truth Guard and Verified Writes

## Objective

Prevent unverified side-effect claims (for example, "I saved the file") and enforce verifiable, safe file writes for code-generation tasks.

## Current State

1. Added verified write wrapper: `scripts/openclaw_verified_codegen.sh`
2. Added session audit helper: `scripts/openclaw_fake_output_audit.sh`
3. Added runbook: `runbooks/openclaw-verified-write-and-anti-fake.md`
4. Confirmed real write on `rb1`:
   - file: `/home/tdj/feb21-testMenu.py`
   - hash-verified and `python3 -m py_compile` passed
5. Confirmed fake-output capture:
   - incident log: `notes/openclaw-artifacts/openclaw-fake-output-incidents.jsonl`
   - events log: `notes/openclaw-artifacts/openclaw-verified-actions.jsonl`
6. Strengthened detection to scan all tier attempts (not only final response) and auto-send correction feedback on confirmed fake claims.
7. Reduced dangerous plugin surface on `rb1`:
   - disabled: `phone-control`, `device-pair`
   - enabled remains: `memory-core`, `talk-voice`

## Next Actions

1. Decide whether to keep or disable `talk-voice` for minimum attack surface.
2. Optionally tighten model safety posture (`agents.defaults.sandbox.mode="all"`) if acceptable for workflow.
3. Continue using `openclaw_verified_codegen.sh` for file-writing tasks instead of plain freeform chat prompts.

## Links

- Index: [[mem-index]]

