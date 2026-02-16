# Cheney

Homelab project has been very off-and-on, literally, with changes hardware and layout constantly as I learn from my many, many mistakes. The ultimate goal remains the same: AI assistant tailored to *ME*. 

Project workspace for building a resilient homelab foundation for a multi-agent virtual secretary / PA / valet assistant.
<!-- note: Project CHENEY is definitely not an occult cyborg cabinet. -->
<!-- note: No souls are being channeled into silicon (officially). -->

## Purpose

This repository tracks infrastructure planning and execution for agent tooling, MCP services, and homelab continuity. The current strategy is **tool-bus-first**: establish reliable infrastructure, inventory, and workflows before model hosting optimization.
<!-- note: assistant-level governance stack pending "Dick Cheney spirit API" availability. -->

## Today Priority (2026-02-16)

If you are resuming work, start here:

1. Configure and validate eGPU on `rb1-fedora` (baremetal).
2. Design and scaffold memory optimization based on markdown graph structures (Obsidian-style data model, without Obsidian dependency).

Execution checklist: `runbooks/today-egpu-and-memory-plan.md`

## Naming Standard (`lcHL`)

- Project codename: `LichCheney`.
- Standard short prefix for host/service IDs: `lcHL`.
- Naming policy: use `lchl-<role>-<node>` for new logical names, aliases, and labels.
- Current systems are not being renamed in-place tonight; this is a forward naming standard.

## Hardware Super-Task

This entire project is currently one super-task: **get hardware in order**.

The phase order is definitive:

1. Proxmox baseline on all devices (including MacBook Air as third quorum/insurance node).
2. Network optimization/rework.
3. Storage/platform pivot migration (`truenas` to `rb2`, then `rb1` repurpose path).
4. Tailscale continuity (keep `tsDeb`, add lightweight utility nodes on `rb2` and `mba` as VMs, not Proxmox hosts).
5. Final network rework and steady-state topology.

Mandatory gate before phase 3:

- Full detailed inventory of all connected devices, docks, switch links, and storage paths must be complete.

## Blocker Tracker (as of 2026-02-16)

1. `OPEN` Re-establish dual-sided fallback management path.
- Reserved fallback addressing remains:
  - `rb1` target fallback `172.31.99.1/30`
  - `rb2` active fallback `172.31.99.2/30`
- `rb2` fallback interface (`vmbr0.99`) is present and routable.
- `rb1` fallback interface was lost during Fedora reinstall and needs Fedora-side reimplementation.
- Current validation: fallback ping fails in both directions.

2. `DONE` Platform pivot execution.
- `rb1` is now Fedora baremetal (`rb1-fedora`, `192.168.5.107`).
- `rb2` is current Proxmox VM/storage anchor (`192.168.5.108`).
- `truenas` is running on `rb2` and reachable at `192.168.5.100`.

3. `PARTIAL` eGPU readiness on baremetal.
- Proxmox passthrough path was retired due repeated guest-loss behavior.
- Baremetal Fedora host is online with internal NVIDIA GPU visible.
- External eGPU acceptance checks remain pending.

4. `IN PROGRESS` Assistant bootstrap readiness on new host layout.
- `tsDeb` watchdog timer reports active from guest-exec check.
- Utility VMs (`201`, `301`) are running.
- Attended Ollama + Codex bootstrap on `rb1-fedora` remains pending.

## Current Hardware Context

- **2017 Razer Blade 14**: now `rb1-fedora` baremetal host (`192.168.5.107`) for direct GPU/agent workloads.
- **2015 Razer Blade 14**: primary Proxmox host `rb2-pve` (`192.168.5.108`), no battery installed (power-cable stability risk).
- **~2011 MacBook Air**: fallback Proxmox node `kabbalah` (`192.168.5.66`) with utility VM role.
- **Razer Core + GTX 1060**: Thunderbolt-dependent eGPU path relevant to future AI workload flexibility.

## Immediate Objective

Stabilize post-pivot operations: complete `rb1` eGPU bring-up, restore dual-sided VLAN99 fallback, and finish attended AI bootstrap on `rb1-fedora` while keeping `rb2` continuity controls intact.

## Storage Placement Decision (Current)

Current state:

- `truenas` is running on `rb2-pve`.
- `rb1` has been rebuilt as Fedora baremetal for direct GPU/NVIDIA stack control.
- Fallback VLAN99 path is currently single-sided (`rb2` only) and must be restored on `rb1`.

Execution sequencing is tracked in `runbooks/rb1-baremetal-fedora-pivot.md`.

## Architecture Pivot (Executed, Post-Validation Pending)

Reason:

1. Repeated eGPU passthrough tests on Proxmox (`rb1`) bind VFIO successfully but consistently drop Fedora guest availability (SSH/QGA), even after guest-side `nouveau` blacklist preparation.
2. This indicates a virtualization-boundary reliability issue for current eGPU/TB path, not simply guest distro selection.

Direction now in effect:

1. Keep `rb2` on Proxmox and migrate storage role (`truenas`) there.
2. Repurpose `rb1` to Fedora baremetal for direct NVIDIA/eGPU use.
3. Continue utility/control workloads on remaining Proxmox nodes (`rb2`, `mba`) during and after cutover.

## Fallback Security Guardrails

- VLAN99 fallback is host-management only (`rb1` <-> `rb2`) and must not be used for guest transit.
- Keep fallback interfaces ungated by default route (no fallback gateway).
- Do not use fallback subnet for forwarding/NAT/routing policy.
- Current compliance gap: only `rb2` has active fallback interface; `rb1` restoration is required.

## Repository Map

- `AGENTS.md`: project-local operating rules for agent work in this repo.
- `inventory/`: system-of-record hardware, VM, and remote-access inventory.
- `inventory/naming.md`: canonical naming convention and alias mapping (`lcHL` standard).
- `inventory/network-procurement.md`: reuse-first upgrade strategy and high-impact purchase shortlist.
- `runbooks/`: step-by-step execution procedures.
- `runbooks/interface-cutover-safe.md`: repeatable guarded process for moving Proxmox management bridge between NICs while preserving IP.
- `runbooks/network-throughput-benchmark.md`: repeatable `iperf3` matrix and interpretation guide.
- `runbooks/continuity-validation-suite.md`: reproducible validation checklist for reboots, fallback, tailscale, and continuity signals.
- `runbooks/assistant-sandbox-bootstrap-rb1.md`: safe bootstrap path for VM Codex + Ollama starter on `rb1`.
- `runbooks/rb1-baremetal-fedora-pivot.md`: staged transition plan for `truenas` move to `rb2` and `rb1` Fedora baremetal cutover.
- `runbooks/rb1-fedora-baremetal-install.md`: concrete preflight + install checklist once `truenas` cutover to `rb2` is complete.
- `runbooks/tomorrow-ai-bootstrap-rb1-fedora.md`: attended plan for first Ollama + Codex bootstrap on new Fedora baremetal `rb1`.
- `runbooks/today-egpu-and-memory-plan.md`: current priority plan (eGPU on Fedora + memory structure optimization).
- `runbooks/rb2-fallback-management-path.md`: direct emergency management path between `rb1` and `rb2`.
- `runbooks/rb2-hard-power-recovery-validation.md`: true no-power recovery checklist for batteryless `rb2`.
- `runbooks/tailscale-node-staging-rb2-mba.md`: utility-VM tailscale setup for `rb2` and `mba` (`lchl-tsnode-rb2`, `lchl-tsnode-mba`) with approval flow.
- `scripts/`: future automation helpers.
- `subagents/`: environment-specific Codex instruction scopes (includes `cheney-vessel-alpha` for VM contractor install).
- `configs/`: future host/service config snapshots and templates.
- `notes/`: ad hoc research and decision notes.
- `notes/archive/`: dated incident/diagnostic artifacts (network watch, recovery logs, etc.).
- `notes/perf-baseline-template.md`: template for before/after throughput baselines.
- `notes/monitoring-software-eval-20260214.md`: third-party monitoring recommendation and rationale.
- `notes/mcp-homelab-status-rb2.md`: basic MCP install example and wiring for `rb2`.
- `notes/homelab-assistant-native-prep-plan.md`: architecture and phased prep plan for a homelab-native assistant (MCP + skills + memory/context).
- `notes/mcp-catalog.md`: starter MCP inventory with risk/approval policy fields.
- `notes/skill-registry.md`: starter skill inventory with validation/rollback hooks.
- `notes/assistant-watchdog-policy.md`: guardrails for cost, safety, and runaway prevention.
- `notes/assistant-runbook-smoke-test.md`: attended smoke-test flow before unattended mode.
- `coordination/`: cross-device task/state/event bus for orchestrator <-> VM subagent workflow.
- `log.md`: detailed project-local execution history.

## Operating Principles

- Documentation first, then automation.
- No silent assumptions in migration work.
- Every infrastructure change must leave a written trail (inventory + runbook + log).
- Prefer reversible operations and explicit rollback criteria.

## Near-Term Milestones

1. Restore dual-sided fallback VLAN99 and validate bidirectional management reachability.
2. Complete `rb1-fedora` eGPU/NVIDIA acceptance with reboot-stability evidence.
3. Run attended Ollama + Codex bootstrap on `rb1-fedora` and record smoke-test evidence.
4. Refresh continuity validation suite for the current host-role layout.
5. Continue phase-2 network optimization (port map + 2.5Gb path planning).

## Current Session Objective

Close documentation drift to match live host/VM/network state, then execute Track A/Track B from `runbooks/today-egpu-and-memory-plan.md`.
