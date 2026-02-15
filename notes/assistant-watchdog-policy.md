# Assistant Watchdog Policy (Starter)

Purpose: prevent runaway behavior, cost spikes, and unsafe unattended actions.

## Hard Constraints

1. Unattended mode is blocked unless eGPU gate passes.
2. Destructive action classes are blocked without approval token.
3. Max one active task at a time.
4. Max task runtime 45 minutes.
5. Max retries 2 with backoff.

## Cost/Token Controls

1. Daily token cap: `250000`.
2. Hourly token cap: `35000`.
3. Per-task cap: `12000`.
4. On threshold:
   - emit critical event
   - downgrade to small model
   - pause queue pending manual ack

## Required Event Emissions

1. `task_started`
2. `task_done` or `task_failed`
3. `watchdog_kill` when timeout/guard triggers
4. `rebooting` before/after reboot sequences

## Manual Acknowledgment Conditions

1. Any `watchdog_kill`.
2. Any failed eGPU gate in unattended mode.
3. Any attempted high-risk mutation without approval token.
