# Homelab-Native Assistant Prep Plan (`lcHL`)

Goal: prepare a local-first assistant platform that can coordinate multiple agents with durable memory/context, tool execution, web/page access, and MCP/skills governance.

## Design Principles

1. Keep control-plane reliability separate from heavy compute.
2. Treat memory/context as first-class infrastructure, not ad-hoc files.
3. Standardize tool interfaces through MCP.
4. Keep skill definitions versioned and testable.
5. Default to least privilege for automation and remote actions.

## Target Capability Layers

1. Orchestration layer:
   - routes tasks to one or many agents
   - maintains job state, retries, and resumability
2. Context and memory layer:
   - session memory
   - durable long-term memory (semantic + structured)
   - project/router logs
3. Tool layer:
   - MCP servers for host status, VM control, storage checks, network checks, web retrieval, and page processing
4. Skill layer:
   - reusable execution playbooks with guardrails
   - explicit inputs/outputs and prerequisites
5. Observability and security layer:
   - health, traces, alerts
   - access controls and audit trails

## Proposed Homelab Role Split

1. `rb1` (`lchl-pve-rb1`):
   - control-plane anchor
   - storage-backed assistant state
   - TrueNAS remains local storage anchor
2. `rb2` (`lchl-pve-rb2`):
   - compute/worker node for heavier agent tasks
   - optional MCP execution workers
3. `mba` (`lchl-pve-mba`):
   - continuity/fallback agent endpoint
   - lightweight monitoring/notification backup

## MCP Requirements and Additions

## Required MCP classes

1. Infra MCP:
   - read-only host/VM/network status
   - controlled action endpoints (reboot/start/stop) with explicit allowlist
2. Storage MCP:
   - TrueNAS status, pool health, share health, space metrics
3. Web MCP:
   - URL fetch, HTML extraction, and normalized page summary
   - deterministic handling of redirects/timeouts
4. Workspace MCP:
   - repo/search/log context retrieval
   - scoped write operations only through approved workflows

## MCP hardening requirements

1. Separate read-only and mutating tools.
2. Require explicit approval gates for high-impact mutating tools.
3. Emit structured logs for every mutating call.
4. Keep host credentials out of MCP source; use mounted secrets/env.

## Skills Requirements and Additions

## Skill model

1. Skill = reproducible operating recipe with:
   - prerequisites
   - command templates
   - expected outputs
   - failure and rollback paths
2. Skills must be deterministic and script-first where possible.
3. Skills are versioned in repo and referenced by stable names.

## Initial skill set to add

1. `continuity-check-skill`
   - wraps `runbooks/continuity-validation-suite.md`
2. `fallback-network-skill`
   - wraps VLAN99 persistence/verification workflow
3. `storage-health-skill`
   - TrueNAS VM + pool + service checks
4. `assistant-node-health-skill`
   - tailscale nodes + watchdog + core services

## Memory and Context Architecture

1. Short-term memory:
   - per-session memory with TTL
2. Long-term semantic memory:
   - vector index for notes/runbooks/log snippets and outcomes
3. Structured operational memory:
   - key-value records for node status, last-known-good config, and rollback points
4. Context router:
   - always consult `/home/tdj/log.md` -> project `AGENTS.md` -> project `log.md`

## Processing and Runtime Prerequisites

1. Queue/scheduler for asynchronous tasks (retry + dead-letter behavior).
2. Persistent database for metadata/state.
3. Vector store for retrieval.
4. Object/file store for artifacts (logs, reports, snapshots).
5. A lightweight API/front-door service for task submission and status.

## Security Baseline

1. Keep management fallback VLAN99 host-only and non-routed.
2. Separate high-risk tools behind approval and audit.
3. Enforce named identities/tags for remote access (Tailscale ACL discipline).
4. Document risk/mitigation/rollback before risky automations.
5. Keep secrets externalized and rotated.

## Observability Baseline

1. Uptime and service checks for all nodes and critical VMs.
2. Centralized logs for agent actions and MCP calls.
3. Alert rules for:
   - node unreachable
   - tailscale disconnect
   - storage pool health failures
   - fallback path failures

## Phased Delivery Plan

## Phase A - Foundations

1. Lock topology and continuity runbooks.
2. Stand up basic observability.
3. Establish MCP read-only baseline.

## Phase B - Controlled Automation

1. Add action MCP endpoints with approvals.
2. Add first four skills and test each on sandbox-safe tasks.
3. Add memory stores and context router integration.

## Phase C - Multi-Agent Coordination

1. Add task queue + orchestration policies.
2. Define planner/worker/reviewer patterns.
3. Add failure isolation and automatic rollback for known operations.

## Phase D - Operator UX

1. Add a single command/status dashboard view.
2. Add replayable run reports for each automation.
3. Add policy audit summaries (who did what, where, and why).

## Immediate Backlog (Next Adds)

1. Add a dedicated runbook to bootstrap assistant core services on `rb1`.
2. Add a minimal MCP catalog document (`tool`, `risk_level`, `approval_required`).
3. Add a skill registry file with owner + validation command per skill.
4. Add an acceptance checklist for "assistant can operate unattended for 24h".
