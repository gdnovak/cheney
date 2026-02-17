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

## Operational Wrapper (Run #4)

Implemented a day-to-day safe-turn wrapper:

- Script: `scripts/openclaw_agent_safe_turn.sh`
- Purpose: run normal OpenClaw turns with automatic Codex backstop when local transport failures occur (for example `fetch failed` on Ollama path), then restore local-primary model state.

Validation evidence:

1. Normal path (Ollama healthy):
- Artifact: `notes/openclaw-artifacts/openclaw-safe-turn-20260217-033835.json`
- Result: `backstopUsed=0`, final provider/model `ollama/qwen2.5:7b`, response `SAFE_WRAPPER_OK_NORMAL`.
2. Forced outage path (Ollama stopped):
- Artifact: `notes/openclaw-artifacts/openclaw-safe-turn-20260217-033846.json`
- Result: `backstopUsed=1`, attempt1 `fetch failed` on `ollama`, attempt2 `SAFE_WRAPPER_OK_FALLBACK` on `openai-codex/gpt-5.3-codex`, then model restored to `ollama/qwen2.5:7b`.

Operational usage:

```bash
scripts/openclaw_agent_safe_turn.sh --message "Your prompt here"
```

Machine-readable output:

```bash
scripts/openclaw_agent_safe_turn.sh --message "Your prompt here" --json
```

## Benchmark + Tuning (Run #5)

Added benchmark runner:

- `scripts/openclaw_safe_turn_benchmark.sh`
- Runs a short case set and writes markdown + jsonl + log artifacts.

Baseline benchmark run:

- Markdown: `notes/openclaw-safe-turn-benchmark-20260217-034221.md`
- JSONL: `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-034221.jsonl`
- Result highlights:
  - `count=7`, `success=7`, `backstop=1`
  - `final_provider_ollama=6`, `final_provider_openai_codex=1`

Tuning applied to wrapper:

1. Added local-runtime precheck (default enabled):
- If default model is `ollama/*` and local runtime is unavailable, skip attempt-1 and go straight to Codex backstop.
2. Added opt-out flag:
- `--no-precheck`

Post-tuning benchmark run:

- Markdown: `notes/openclaw-safe-turn-benchmark-20260217-034700.md`
- JSONL: `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-034700.jsonl`
- Result highlights:
  - `count=7`, `success=7`, `backstop=1`
  - `avg_wrapper_elapsed_ms=11106`
  - forced-outage case `wrapper_elapsed_ms=12219`, with precheck marker `local_precheck_unavailable` and successful Codex final.

Real-profile benchmark run:

- Markdown: `notes/openclaw-safe-turn-benchmark-20260217-035520.md`
- JSONL: `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-035520.jsonl`
- Result highlights:
  - `count=7`, `success=7`, `backstop=1`
  - healthy backstop rate in sample: `0/6`
  - `forced_outage_wrapper_elapsed_ms=11635`
  - `cloud_final_tokens_total=9926` (single forced-outage backstop case)

Threshold policy recorded:

- `notes/openclaw-safe-turn-thresholds-20260217.md`

## Key Findings

1. Local-first routing is operational and stable for routine prompts.
2. Coder model path works when primary is switched to `qwen2.5-coder:7b`.
3. Fallback did not advance on forced Ollama outage in this scenario.
4. On-host OpenClaw docs indicate fallback advances on auth/rate-limit/timeout classes, while "other errors" do not advance fallback:
- `/usr/local/lib/node_modules/openclaw/docs/concepts/model-failover.md`
5. `tools.profile=coding` emits warning about unknown allowlist entries (`group:memory`, `image`) in this environment; execution still succeeds.
6. Practical mitigation is now codified in `scripts/openclaw_routing_validation.sh`: if native fallback does not advance for local provider transport errors, force a one-shot Codex backstop and restore local-first state.
7. Operational wrapper + benchmark tooling are in place; precheck tuning improves outage-path behavior by avoiding a wasted local transport attempt when Ollama is known unavailable.

## Current State

- `ollama` service: active/enabled
- OpenClaw default model: `ollama/qwen2.5:7b`
- OpenClaw fallback configured: `openai-codex/gpt-5.3-codex`
- Safe-turn wrapper: `scripts/openclaw_agent_safe_turn.sh` (precheck enabled by default)
- Benchmark runner: `scripts/openclaw_safe_turn_benchmark.sh`

## Next Action

Run additional real-prompt samples over time and tune wrapper trigger policy when measured metrics breach thresholds in `notes/openclaw-safe-turn-thresholds-20260217.md`.
