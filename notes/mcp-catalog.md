# MCP Catalog (Starter)

Purpose: enumerate MCP tools/services for starter phase with risk classification.

## Columns

1. `tool_id`
2. `host`
3. `capability`
4. `risk_level`
5. `approval_required`
6. `notes`

## Starter Catalog

| tool_id | host | capability | risk_level | approval_required | notes |
|---|---|---|---|---|---|
| `homelab-status-rb2` | `rb2` | host/vm/tailscale read-only health | low | no | existing MCP example |
| `continuity-suite-reader` | orchestrator | reads continuity runbook + parses pass/fail outputs | low | no | no mutation |
| `pve-action-gate` | `rb1` | controlled VM reboot/start/stop wrapper | medium | yes | approval token required |
| `network-fallback-check` | `rb1` | verify `vmbr0.99` state and reachability | low | no | management-only validation |
| `taskbus-control` | sandbox VM | claim tasks, update heartbeat, emit events | medium | yes | core automation bus |

## Policy Rules

1. No high-risk MCP tool may run unattended without explicit approval marker.
2. All mutating MCP calls must emit event + report record.
3. Unattended mode remains disabled unless eGPU gate passes.
