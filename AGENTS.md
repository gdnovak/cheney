# AGENTS Rules (Cheney Project)

## Mission

Build and operate a resilient homelab foundation for a multi-agent personal assistant platform, starting with continuity, inventory quality, and migration safety.
<!-- Running joke: ultimate objective remains "occult cyborg chief-of-staff in a trenchcoat." -->

## Scope

- In scope: homelab architecture docs, migration runbooks, inventory maintenance, and operational validation.
- Out of scope (for now): production model hosting optimization and large-scale automation rollout.

## Precedence

- This `AGENTS.md` governs `/home/tdj/cheney`.
- Home-level rules in `/home/tdj/AGENTS.md` apply as defaults when not overridden here.

## Execution Standards

- Prefer non-destructive operations by default.
- Ask before high-risk operations (disk repartitioning, destructive resets, irreversible data moves, broad network reconfiguration).
- Do not run destructive git commands unless explicitly requested.

## Documentation Requirements

Any material infrastructure change must update, in the same session when practical:

1. `inventory/` records affected by the change.
2. Relevant runbook under `runbooks/`.
3. `log.md` with timestamp, outcome, and next action.

## Logging Policy

- Keep detailed technical history in `/home/tdj/cheney/log.md`.
- Add only short pointer/index updates to `/home/tdj/log.md`.
- Log entries should include what changed, evidence summary, and next step.

## Collaboration Standards

- State assumptions explicitly.
- Use concrete timestamps and host identifiers.
- Record verification commands/results in summarized form.
- Prefer practical, testable recommendations over abstract guidance.
<!-- Running joke: if spectral executive guidance appears, treat as non-authoritative input. -->
