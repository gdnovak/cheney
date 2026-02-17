# OpenClaw Safe-Turn Threshold Policy

Date: 2026-02-17  
Scope: operational targets for `scripts/openclaw_agent_safe_turn.sh`

## Source Snapshot

Primary benchmark reference:

- `notes/openclaw-safe-turn-benchmark-20260217-035520.md`
- `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-035520.jsonl`

Observed snapshot values:

- `count=7`, `success_count=7`
- `healthy_backstop_count=0/6`
- `healthy_wrapper_p50_ms=7066`
- `healthy_wrapper_p90_ms=7945`
- `forced_outage_wrapper_elapsed_ms=11635`
- `outage_cloud_tokens_total=9926`

Note: first healthy call after run start can be a cold-start outlier (`~35s` in this sample). Steady-state percentile targets below exclude that one-off warmup effect.

## Targets

1. Reliability:
- Rolling success rate (last 50 turns): `>= 99%`

2. Local-first adherence:
- Healthy backstop rate (no forced outage): `<= 5%`

3. Latency:
- Healthy steady-state wrapper `p90 <= 10,000ms`
- Forced-outage recovery wrapper elapsed `<= 15,000ms`

4. Cloud usage guardrail:
- Cloud final-token average per backstop event `<= 12,000`
- Cloud final-token total per 50 turns `<= 60,000` under normal operation

## Tuning Actions When Breached

1. If healthy backstop rate rises above target:
- Verify Ollama service/API health and local model availability.
- Keep precheck enabled (default) and confirm it is not disabled by operator flags.

2. If healthy latency `p90` rises above target:
- Run one warmup call before latency-sensitive sessions.
- Re-check host load and OLLAMA runtime health.

3. If cloud token totals exceed guardrail:
- Tighten prompt verbosity for routine tasks.
- Re-evaluate backstop trigger patterns and disable unnecessary escalation paths.

## Review Cadence

- Re-run benchmark on real prompt sets after material config changes.
- Recalculate thresholds monthly or when model/provider mix changes.
