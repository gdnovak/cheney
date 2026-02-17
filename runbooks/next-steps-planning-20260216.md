# Runbook: Next Steps Planning (Post eGPU Acceptance)

Date anchor: 2026-02-16

Purpose: move from eGPU validation work into practical next-phase setup planning without spending extra cycles on known-temperamental hotplug behavior.

## Planning Baseline

1. eGPU acceptance gates are complete for current scope (including external-display scenario pass).
2. Physical hot-unplug/replug is known temperamental; recovery path exists and is documented.
3. AI runtime/tooling remains intentionally deferred on `rb1`.
4. Memory scaffold + phase-1 RAG decision are already in repo.

## Operating Decision

Use recovery-first policy for eGPU operations:

1. Prefer stable attached mode.
2. Avoid unnecessary hotplug cycles.
3. If reattach fails, recover via controlled reboot and continuity checks.

## Next-Phase Planning Tracks

### Track 1: Fedora Host Operational Polish

1. Resolve SSH root-login override behavior (`PermitRootLogin yes` from installer include) and decide final policy.
2. Capture a clean post-acceptance baseline snapshot (`ip`, `nvidia-smi`, `boltctl`, fallback VLAN status).
3. Confirm service/autostart posture remains minimal and intentional.

### Track 2: Continuity and Recovery Hardening

1. Convert ad hoc recovery commands into one reusable validation/recovery script for `rb1`.
2. Add an explicit “post-incident checklist” runbook section for eGPU/TB faults.
3. Schedule a controlled maintenance reboot verification after any major package/kernel update.

### Track 3: Assistant Bootstrap Readiness (Still Deferred)

1. Keep AI runtime disabled until explicitly resumed.
2. Define exact preconditions to resume (auth readiness, model/storage budget, rollback path).
3. When resumed, bring up in attended mode first with strict rollback checkpoints.

### Track 4: Memory/RAG Workflow Maturation

1. Start logging each major decision in `memory/decisions/`.
2. Add weekly summary note pattern in `memory/projects/` for fast resume.
3. Keep lexical retrieval as default; revisit vector layer only on trigger conditions from `dec-rag-phase1-lexical-first`.

## Suggested Immediate Order

1. Track 1 (host polish)
2. Track 2 (recovery hardening)
3. Track 4 (memory workflow habits)
4. Track 3 (AI bootstrap), only when explicitly requested

## Acceptance for This Planning Stage

1. Repo documents clearly state hotplug defer decision and recovery-first posture.
2. Next-phase planning runbook exists and is linked in logs.
3. Resume sessions can start from this file without re-deriving priorities.
