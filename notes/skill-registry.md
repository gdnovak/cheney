# Skill Registry (Starter)

Purpose: list reusable skills with validation and rollback hooks.

## Columns

1. `skill_name`
2. `owner`
3. `inputs`
4. `outputs`
5. `validation`
6. `rollback`

## Starter Skills

| skill_name | owner | inputs | outputs | validation | rollback |
|---|---|---|---|---|---|
| `continuity-check-skill` | orchestrator | host aliases, expected services | pass/fail summary | run `runbooks/continuity-validation-suite.md` checks | no-op (read-only) |
| `assistant-node-health-skill` | vm-codex-rb1 | tailscale node IPs and VMIDs | status report | `tailscale status` + `qm status` checks | restart only affected service |
| `fallback-network-check-skill` | orchestrator | fallback IPs (`172.31.99.1/30`, `172.31.99.2/30`) | fallback path report | ping/ssh jump validation | restore known-good interface config |
| `egpu-gate-skill` | vm-codex-rb1 | host alias (`rb1-pve`) | `egpu_ready=true|false` | `scripts/assistant/check_egpu_ready.sh` | block unattended mode if fail |

## Skill Policy

1. Skills marked mutating require approval marker.
2. All skills must write report artifacts when run via subagent.
3. Any autonomous workflow must include `egpu-gate-skill` as mandatory precheck.
