# Assistant Starter Smoke Test (Attended)

Purpose: validate starter coordination stack in attended mode before any overnight autonomy.

## Preconditions

1. Sandbox VM is bootstrapped (`runbooks/assistant-sandbox-bootstrap-rb1.md`).
2. Coordination files exist in repo.
3. eGPU gate status known.

## Steps

1. Emit initial heartbeat:
   - `scripts/assistant/heartbeat.sh idle "" false "attended smoke start"`
2. Emit start event:
   - `scripts/assistant/emit_event.sh heartbeat - info "smoke test start"`
3. Claim template task (copy to real task ID first).
4. Run example guarded task:
   - `scripts/assistant/run_task_example.sh <task-file>`
5. Check outputs:
   - `coordination/state/heartbeat.json`
   - `coordination/state/events.log`
   - report artifact path in task file

## Expected Result

1. Task claim recorded.
2. Events appended in correct order.
3. Heartbeat updated.
4. If eGPU gate fails, unattended path remains blocked (expected).

## Promotion Gate to Unattended Trial

All must be true:

1. Two attended smoke runs succeed.
2. No watchdog false-positive in attended runs.
3. Push notifications deliver reliably.
4. eGPU gate passes.
