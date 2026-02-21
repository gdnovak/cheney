# OpenClaw Router Live Trial v2

Date: 2026-02-21
Scope: Live/manual evaluation of basic-local + low->high escalation routing.

## Policy Snapshot

- Route profile: `basic-local-v2`
- Local tier (basic/coding_basic):
  - general: `ollama/qwen2.5:7b`
  - coding: `ollama/qwen2.5-coder:7b`
- Cloud low tier: `openai-codex/gpt-5.3-codex` (`thinking=medium`)
- Cloud high tier: `openai-codex/gpt-5.3-codex` (`thinking=high`)
- Escalation chain: `local -> low -> high`
- Thinking policy defaults:
  - local: `off`
  - low/normal: `medium`
  - high: `high`
- Latency guards:
  - local: escalate above `10000ms`
  - low: escalate above `20000ms`

## Unified Telemetry

- Router JSONL: `notes/openclaw-artifacts/openclaw-router-decisions.jsonl`
- Per-turn artifact JSON: `notes/openclaw-artifacts/openclaw-safe-turn-<timestamp>.json`
- Summary command:

```bash
scripts/openclaw_router_live_summary.sh
```

## Live Usage Command

```bash
scripts/openclaw_agent_safe_turn.sh --message "<prompt>"
```

## Force-Tier Spot Checks

1. Force local:

```bash
scripts/openclaw_agent_safe_turn.sh --force-tier local --message "Extract only the IP from this line: host=rb1 ip=192.168.5.114"
```

2. Force low:

```bash
scripts/openclaw_agent_safe_turn.sh --force-tier low --message "Summarize this deployment risk in 5 bullets"
```

3. Force high:

```bash
scripts/openclaw_agent_safe_turn.sh --force-tier high --message "Review rollback strategy for a storage migration"
```

## JSON Output for Inspection

```bash
scripts/openclaw_agent_safe_turn.sh --json --message "<prompt>" | jq .
```

## Notes

- `--fallback-model` is retained as backward-compatible alias for high tier.
- If low-tier model key is unavailable in model catalog, wrapper collapses low to high and records alias notes in output/telemetry.
- If local runtime precheck fails and backstop is enabled, wrapper logs `local_precheck_unavailable` and skips directly to cloud low.
