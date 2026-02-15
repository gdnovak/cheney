# Coordination Bus (`lcHL`)

Purpose: durable cross-device task/state channel between:

1. Orchestrator session (this workstation/session).
2. VM subagent on `rb1` sandbox VM.

This directory is the source of truth for assignment, status, and completion records.

## Layout

- `tasks/`: task specs (queued/in-progress/done metadata in-file).
- `reports/`: execution reports linked to task IDs.
- `state/heartbeat.json`: latest liveness/status snapshot.
- `state/events.log`: append-only event stream.
- `claims/`: lock/claim markers to avoid multi-agent double execution.
- `policies/`: safety, budget, and approval policy files.
- `schemas/`: format references for task/heartbeat/event records.

## Conventions

1. Task IDs are lowercase and timestamp-prefixed: `t-YYYYMMDD-HHMM-<slug>`.
2. Every task must include:
   - `risk_class`
   - `success_criteria`
   - `rollback`
3. Every report must include:
   - task ID
   - result (`done`/`failed`/`blocked`)
   - command evidence summary
4. Any reboot or high-impact transition must emit an event line.

## Event Types

- `heartbeat`
- `task_claimed`
- `task_started`
- `task_done`
- `task_failed`
- `task_blocked`
- `rebooting`
- `watchdog_kill`

## Safety

Policies in `policies/` are mandatory. If a command class is not explicitly allowed for unattended execution, it is treated as blocked by default.
