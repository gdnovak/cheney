# Cognee Fit Assessment (2026-02-21)

## Question

Can Cognee reduce OpenClaw compaction-amnesia for this homelab setup without destabilizing current routing?

## Short answer

Yes, as a sidecar memory layer. Not as a replacement for router policy or verified-write controls.

## Fit for this project

- Strong fit for persistent memory retrieval from markdown/runbook history.
- Works with local model paths (`ollama` extra exists upstream) and can be tested without touching current OpenClaw routing.
- Best initial value is read-heavy: indexed retrieval of prior decisions, runbooks, and weekly notes.

## Constraints and risks

- Ingest scope must be explicit; do not blindly index artifacts/log dumps.
- Memory retrieval quality depends on chunking and query style, so pilot must include real prompts from our workflow.
- Added service/tooling complexity (new runtime, storage, and maintenance).

## Implementation stance

- Phase 0 now: safe scope manifest + host environment probe.
- Phase 1 later (optional): isolated pilot on `rb1` venv or container, no OpenClaw route changes until retrieval quality is proven.

## Pilot acceptance gate

- Retrieve correct prior decisions/runbook steps for at least 4 of 5 real resume-style prompts.
- No secrets/tokens/artifact blobs present in indexed corpus.
- No impact on OpenClaw current safe-turn behavior while pilot is active.
