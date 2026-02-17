# OpenClaw Routing Implementation Checkpoint

Date: 2026-02-17  
Host: `rb1-fedora` (`tdj`)  
Scope: Execute `notes/efficient-routing-plan.md` phase-1 implementation and validation.

## What Was Implemented

1. Installed and enabled Ollama as system service on `rb1`.
2. Pulled local models:
- `qwen2.5:7b`
- `qwen2.5-coder:7b`
3. Configured OpenClaw routing:
- Primary: `ollama/qwen2.5:7b`
- Fallback: `openai-codex/gpt-5.3-codex` (OAuth profile already present)
4. Applied moderate token controls:
- `bootstrapMaxChars=8000`
- `bootstrapTotalMaxChars=24000`
- `contextPruning.mode=cache-ttl`, `ttl=1h`, `keepLastAssistants=12`
- `tools.profile=coding`
5. Added reusable validation harness:
- `scripts/openclaw_routing_validation.sh`

## Validation Artifacts

- Baseline (pre-change):  
  `notes/openclaw-artifacts/openclaw-routing-baseline-20260217-023746.log`
- Validation run #1 (parser bug in gateway shape):  
  `notes/openclaw-artifacts/openclaw-routing-validation-20260217-025502.log`  
  `notes/openclaw-artifacts/openclaw-routing-validation-20260217-025502.jsonl`
- Validation run #2 (clean parser):  
  `notes/openclaw-artifacts/openclaw-routing-validation-20260217-030356.log`  
  `notes/openclaw-artifacts/openclaw-routing-validation-20260217-030356.jsonl`
- Matrix file (appended runs):  
  `notes/openclaw-routing-validation-20260217.md`

## Results (Run #2)

- Route matrix: `8/10 PASS`
- Coder-path check: `PASS` (`provider=ollama`, `model=qwen2.5-coder:7b`)
- Forced fallback check (Ollama stopped): `FAIL` (`provider=ollama`, response `fetch failed`)
- Overall checks: `9/12 PASS`
- Mean duration (all 12 checks): `~22.1s`

## Key Findings

1. Local-first routing is operational and stable for routine prompts.
2. Coder model path works when primary is switched to `qwen2.5-coder:7b`.
3. Fallback did not advance on forced Ollama outage in this scenario.
4. On-host OpenClaw docs indicate fallback advances on auth/rate-limit/timeout classes, while "other errors" do not advance fallback:
- `/usr/local/lib/node_modules/openclaw/docs/concepts/model-failover.md`
5. `tools.profile=coding` emits warning about unknown allowlist entries (`group:memory`, `image`) in this environment; execution still succeeds.

## Current State

- `ollama` service: active/enabled
- OpenClaw default model: `ollama/qwen2.5:7b`
- OpenClaw fallback configured: `openai-codex/gpt-5.3-codex`

## Next Action

Run a focused fallback remediation pass (error-class handling + session reset strategy), then rerun `scripts/openclaw_routing_validation.sh` and compare against this checkpoint.
