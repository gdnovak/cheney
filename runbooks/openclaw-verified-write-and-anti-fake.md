# OpenClaw Verified Write + Anti-Fake Workflow

Date: 2026-02-21  
Scope: prevent unverified side-effect claims and safely permit non-dangerous code file writes on `rb1`.

## Problem This Solves

- Base OpenClaw chat responses can claim "I saved/ran" without any tool execution.
- We need file writes to be real, verifiable, and restricted.
- We need durable logging for fake-output incidents.

## Scripts

1. Verified write wrapper:
- `scripts/openclaw_verified_codegen.sh`

2. Forensic audit helper:
- `scripts/openclaw_fake_output_audit.sh`

## Verified Write Contract

`openclaw_verified_codegen.sh` enforces:

- Structured JSON response contract for file-generation tasks.
- Fallback extraction from first code block if JSON parse fails and target file is explicit.
- Allowlist path gate (default: `/home/tdj`) so writes outside allowed root are blocked.
- Static dangerous-content scan before write (e.g., root delete, raw disk write, remote pipe-to-shell).
- Optional Codex safety review for code-like files.
- On-host write verification via SHA-256 match.
- Incident logging if side effects are claimed without verification.
- Automatic correction feedback to agent session on confirmed fake behavior.

## Primary Usage

```bash
cd /home/tdj/cheney
scripts/openclaw_verified_codegen.sh \
  --host rb1-admin \
  --message "write a small CLI program that is a simple 3-option menu..." \
  --target-file /home/tdj/feb21-testMenu.py
```

Machine-readable result:

```bash
scripts/openclaw_verified_codegen.sh ... --json | jq .
```

## Incident and Event Logs

- Verified run events:
  - `notes/openclaw-artifacts/openclaw-verified-actions.jsonl`
- Confirmed fake-output incidents:
  - `notes/openclaw-artifacts/openclaw-fake-output-incidents.jsonl`
- Per-run artifacts:
  - `notes/openclaw-artifacts/openclaw-verified-codegen-<timestamp>.json`
  - `notes/openclaw-artifacts/openclaw-verified-codegen-<timestamp>.log`

## Session Forensics (Backfill / Audit)

Audit latest session and append suspicious historical claims to incident log:

```bash
cd /home/tdj/cheney
scripts/openclaw_fake_output_audit.sh --host rb1-admin
```

Print only:

```bash
scripts/openclaw_fake_output_audit.sh --host rb1-admin --no-append
```

## Operational Notes

- This workflow is intentionally conservative: if static scan fails, write is blocked.
- For stricter behavior, use `--strict-codex-review`.
- If Codex review is temporarily unavailable and strict mode is off, static scan still protects baseline safety.
- This mechanism does not depend on model honesty; writes and execution claims are verified externally.

