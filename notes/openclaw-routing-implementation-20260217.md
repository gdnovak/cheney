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

## Remediation Pass (Run #3)

Targeted remediation was applied after run #2:

1. Session hygiene:
- Validation harness now resets OpenClaw session store before each run (backup + clean start).
2. Error-class handling:
- Harness now performs a controlled manual backstop if forced fallback does not auto-advance:
  - Detect `fallback_forced_check` fail
  - Temporarily switch primary model to Codex
  - Re-run fallback prompt as `fallback_manual_backstop`
  - Restore local primary model and restart Ollama

Artifacts:

- `notes/openclaw-artifacts/openclaw-routing-validation-20260217-032014.log`
- `notes/openclaw-artifacts/openclaw-routing-validation-20260217-032014.jsonl`
- `notes/openclaw-routing-validation-20260217.md`

Run #3 outcomes:

- Route matrix: `8/10 PASS`
- Coder-path check: `PASS`
- Native forced fallback (Ollama down): `FAIL` (`fetch failed`, provider stayed `ollama`)
- Manual backstop case: `PASS` (`provider=openai-codex`, model `gpt-5.3-codex`)
- Overall checks: `10/13 PASS`

## Key Findings

1. Local-first routing is operational and stable for routine prompts.
2. Coder model path works when primary is switched to `qwen2.5-coder:7b`.
3. Fallback did not advance on forced Ollama outage in this scenario.
4. On-host OpenClaw docs indicate fallback advances on auth/rate-limit/timeout classes, while "other errors" do not advance fallback:
- `/usr/local/lib/node_modules/openclaw/docs/concepts/model-failover.md`
5. `tools.profile=coding` emits warning about unknown allowlist entries (`group:memory`, `image`) in this environment; execution still succeeds.
6. Practical mitigation is now codified in `scripts/openclaw_routing_validation.sh`: if native fallback does not advance for local provider transport errors, force a one-shot Codex backstop and restore local-first state.

## Current State

- `ollama` service: active/enabled
- OpenClaw default model: `ollama/qwen2.5:7b`
- OpenClaw fallback configured: `openai-codex/gpt-5.3-codex`

## Next Action

Implement a dedicated operational wrapper for day-to-day agent turns (same backstop logic as the validator), then benchmark token/cost deltas across a short real-task sample.
