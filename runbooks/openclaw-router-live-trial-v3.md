# OpenClaw Router Live Trial v3

Date: 2026-02-21
Scope: Simpler local-first routing with automatic Codex fallback (no manual escalation required).

## Policy Snapshot

- Route profile: `basic-local-v3`
- Tier chain: `local -> low -> high`
- Local tier (default start for basic/coding_basic/normal):
  - general: `ollama/qwen2.5:7b`
  - coding: `ollama/qwen2.5-coder:7b`
- Low tier (automatic second attempt):
  - `ollama/qwen2.5:14b`
- High tier (automatic last-resort fallback):
  - `openai-codex/gpt-5.3-codex`
- Thinking policy defaults:
  - local: `off`
  - low: `medium`
  - high: `high`
- Latency guards:
  - local: escalate above `30000ms`
  - low: escalate above `120000ms`

## Behavioral Intent

- Manual escalation should not be needed in normal usage.
- Wrapper escalates tiers automatically when it detects transport/sanity errors or latency threshold breaches.
- If low-tier model is unavailable, wrapper collapses low tier to local general model and records alias notes.

## Usage

```bash
scripts/openclaw_agent_safe_turn.sh --message "<prompt>"
```

## Force-Tier Spot Checks

1. Local:

```bash
scripts/openclaw_agent_safe_turn.sh --force-tier local --message "Extract only the IP from this line: host=rb1 ip=192.168.5.114"
```

2. Low:

```bash
scripts/openclaw_agent_safe_turn.sh --force-tier low --message "Summarize this deployment risk in 5 bullets"
```

3. High:

```bash
scripts/openclaw_agent_safe_turn.sh --force-tier high --message "Review rollback strategy for a storage migration"
```

## Telemetry and Artifacts

- Router JSONL: `notes/openclaw-artifacts/openclaw-router-decisions.jsonl`
- Per-turn JSON: `notes/openclaw-artifacts/openclaw-safe-turn-<timestamp>.json`
- Live summary:

```bash
scripts/openclaw_router_live_summary.sh
```
