# Runbook: OpenClaw Overnight Probe (`rb1`)

Date anchor: 2026-02-17

Purpose: run a simple unattended reliability probe every 30 minutes overnight, from `rb1` itself, with resumable logs for morning review.

## Scope and Safety

1. Use simple prompt only (haiku + marker token).
2. Use existing safe-turn wrapper with controlled fallback behavior.
3. Keep process detached and easy to stop.
4. Do not run on laptop/client host; run on `rb1` so client sleep does not interrupt execution.

## Preconditions

1. `rb1-admin` SSH access works from operator machine.
2. Repo exists at `/home/tdj/cheney` on `rb1`.
3. `openclaw` CLI is operational on `rb1`.

## Start (Detached On `rb1`)

```bash
ssh rb1-admin '
  cd /home/tdj/cheney &&
  nohup scripts/openclaw_overnight_probe.sh \
    --host local \
    --interval-sec 1800 \
    --cycles 0 \
    --mode gateway \
    > notes/openclaw-artifacts/overnight-probe-launch-$(date +%Y%m%d-%H%M%S).out 2>&1 &
'
```

Notes:

1. `--host local` is required because the probe itself runs on `rb1`.
2. `--cycles 0` means run until manually stopped.

## Verify Running

```bash
ssh rb1-admin '
  cd /home/tdj/cheney &&
  test -f notes/openclaw-artifacts/overnight-probe.pid &&
  ps -fp "$(cat notes/openclaw-artifacts/overnight-probe.pid)" &&
  tail -n 5 "$(cat notes/openclaw-artifacts/overnight-probe.latest_jsonl)"
'
```

Expected:

1. PID exists and process is active.
2. JSONL rows appear every ~30 minutes.

## Stop

```bash
ssh rb1-admin '
  cd /home/tdj/cheney &&
  kill "$(cat notes/openclaw-artifacts/overnight-probe.pid)"
'
```

## Morning Summary

```bash
ssh rb1-admin '
  cd /home/tdj/cheney &&
  scripts/openclaw_overnight_probe_summary.sh
'
```

Expected summary fields:

1. `count`, `success_count`, `failure_count`
2. `backstop_count`, provider split
3. latency (`avg_wrapper_elapsed_ms`, `p95_wrapper_elapsed_ms`)
4. cloud usage (`cloud_tokens_total`, `cloud_tokens_avg`)
5. recent errors list

## Failure Handling

1. If process is not running, check latest launch log in `notes/openclaw-artifacts/overnight-probe-launch-*.out`.
2. If JSONL path pointer is missing, identify newest probe file:
   - `ls -1t notes/openclaw-artifacts/overnight-probe-*.jsonl | head -n1`
3. If `openclaw` path is failing repeatedly, stop probe and run one attended safe-turn:
   - `scripts/openclaw_agent_safe_turn.sh --host local --message "Respond exactly: PROBE_ATTENDED_OK"`
