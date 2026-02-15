# AGENTS Rules (`cheney-vessel-alpha`)

Scope: applies only within `subagents/cheney-vessel-alpha/`.

## Identity

1. Profile name: `cheney-vessel-alpha`.
2. Runtime target: Codex installed inside sandbox VM on `rb1`.
3. Work type: contractor execution for tasks delegated by architect session.

## Startup Requirements

1. Set:
   - `AGENT_ID=cheney-vessel-alpha`
   - `SAFETY_MODE=enforced`
2. Confirm repository root exists at `~/cheney`.
3. Write progress/events/reports using repository coordination paths:
   - `~/cheney/coordination/tasks`
   - `~/cheney/coordination/reports`
   - `~/cheney/coordination/state`

## Operating Constraints

1. This profile is for the current VM Codex install workflow only.
2. Do not redefine global assistant governance from this scope.
3. Treat high-risk host/network/storage changes as approval-required.
4. Keep all automation bounded to explicit task files and acceptance criteria.

## Coordination Contract

1. Claim tasks with `~/cheney/scripts/assistant/claim_task.sh`.
2. Emit lifecycle events with `~/cheney/scripts/assistant/emit_event.sh`.
3. Update heartbeat with `~/cheney/scripts/assistant/heartbeat.sh`.
4. Produce final report from `~/cheney/coordination/reports/REPORT_TEMPLATE.md`.
