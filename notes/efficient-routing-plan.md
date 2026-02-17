# Efficient Routing Plan

Date: 2026-02-17  
Scope: OpenClaw assistant routing on `rb1-fedora` (`tdj` profile)

## Goal

Keep assistant quality high while reducing cloud token burn.

## Current Constraints

- OAuth-backed `openai-codex/gpt-5.3-codex` is currently primary.
- Host hardware: `2x GTX 1060 6GB` + strong CPU.
- CLI-first operation is intentional for now; LAN URL access is deferred.

## Key Decision

Use a hybrid router, not a single-model strategy:

- Local primary for routine work: `ollama/qwen2.5:7b`
- Optional local coding bias path: `ollama/qwen2.5-coder:7b`
- Cloud escalation/fallback for hard tasks: `openai-codex/gpt-5.3-codex`

This keeps responsiveness and cost control without sacrificing quality for difficult tasks.

## Training Requirement

No custom training is required for phase 1.

- `qwen2.5` and `qwen2.5-coder` are already instruction-tuned models.
- We can run inference directly and tune routing policy, not model weights.

## Hardware Fit Assessment

- `2x GTX 1060 6GB` is sufficient for 7B-class local inference.
- 14B-class models may be possible with tradeoffs (latency/VRAM pressure).
- `vLLM` is not the first target on this host due compute capability requirements; `Ollama` is preferred for this phase.

## Routing Policy (Phase 1)

Default to local unless the task is clearly high-risk or high-complexity.

- Local (`qwen2.5:7b`): conversational assistant work, summaries, drafting, routine shell guidance, low-risk coding edits.
- Local coder (`qwen2.5-coder:7b`): code-heavy drafting/refactors that do not require deep architecture decisions.
- Cloud Codex (`gpt-5.3-codex`): architecture decisions, security-sensitive changes, production-impacting migration steps, ambiguous failure diagnosis, and final review for high-stakes outputs.

## Escalation Triggers

Escalate from local to Codex when any of the following occur:

- Local output is inconsistent or hallucinatory after one correction pass.
- Task requires long-chain reasoning across many files/systems.
- Security/compliance/infra-risk tradeoffs must be justified precisely.
- User explicitly requests highest-confidence reasoning.

## Implementation Plan

1. Install local runtime and model(s) on `rb1`:
   - Install `ollama`.
   - Pull `qwen2.5:7b` first.
   - Optionally pull `qwen2.5-coder:7b`.
2. Register local provider in OpenClaw and set model routing:
   - Local model as primary.
   - Codex as fallback/escalation.
3. Run A/B validation:
   - 10 representative assistant prompts.
   - Compare quality, latency, and cloud token use.
4. Keep policy simple:
   - Local-first for routine.
   - Codex for hard/high-risk.

## Acceptance Criteria

- Routine assistant tasks complete acceptably on local model.
- Hard tasks escalate cleanly to Codex.
- Cloud token usage drops materially from current baseline.
- User-perceived quality remains acceptable for everyday conversation.

## Notes

- This is a quality-first efficiency plan, not a pure cost-minimization plan.
- Full semantic memory/RAG expansion remains a separate decision track.

## Implementation Status (2026-02-17)

- Phase-1 implementation executed on `rb1-fedora`.
- Validation artifacts and outcomes: `notes/openclaw-routing-implementation-20260217.md`.
- Remediation pass completed: session-reset validation + manual Codex backstop path added for non-failover transport errors.
- Operational day-to-day wrapper implemented: `scripts/openclaw_agent_safe_turn.sh`.
- Benchmark harness implemented and executed: `scripts/openclaw_safe_turn_benchmark.sh`.
- Tuning applied: local-runtime precheck (default enabled) skips wasted local attempt when Ollama is unavailable.
- Real-prompt benchmark run completed (`notes/openclaw-safe-turn-benchmark-20260217-035520.md`).
- Threshold policy recorded: `notes/openclaw-safe-turn-thresholds-20260217.md`.
- Current open item: monitor rolling metrics and tune only on threshold breach.
