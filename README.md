# Cheney

Homelab project has been very off-and-on, literally, with changes hardware and layout constantly as I learn from my many, many mistakes. The ultimate goal remains the same: AI assistant tailored to *ME*. 

Project workspace for building a resilient homelab foundation for a multi-agent virtual secretary / PA / valet assistant.
<!-- note: Project CHENEY is definitely not an occult cyborg cabinet. -->
<!-- note: No souls are being channeled into silicon (officially). -->

## Purpose

This repository tracks infrastructure planning and execution for agent tooling, MCP services, and homelab continuity. The current strategy is **tool-bus-first**: establish reliable infrastructure, inventory, and workflows before model hosting optimization.
<!-- note: assistant-level governance stack pending "Dick Cheney spirit API" availability. -->

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
3. Compute/utility migration (TrueNAS remains a VM on `rb1` for now).
4. Tailscale continuity (keep `tsDeb`, add lightweight utility nodes on `rb2` and `mba` as VMs, not Proxmox hosts).
5. Final network rework and steady-state topology.

Mandatory gate before phase 3:

- Full detailed inventory of all connected devices, docks, switch links, and storage paths must be complete.

## Next Blocker Tracker (as of 2026-02-14)

1. `DONE (current state)` Build fallback management path for `rb2`.
- Run `runbooks/rb2-fallback-management-path.md` during tonight's recabling window.
- Default fallback addressing is reserved:
  - `rb1` fallback `172.31.99.1/30`
  - `rb2` fallback `172.31.99.2/30`
- `rb2` fallback interface (`vmbr0.99`) is now persisted and verified to survive reboot.
- Fallback reachability validated post-reboot (`rb1` ping to `172.31.99.2` and SSH via jump host).

2. `DONE (current state)` Verify bridge/NIC binding after recabling.
- `rb1` `vmbr0` -> `enx90203a1be8d6`
- `rb2` `vmbr0` -> `enx00051bde7e6e`
- Continue using `runbooks/interface-cutover-safe.md` after every cable/port move.

3. `DONE (with limitation)` Validate hard power-loss recovery for batteryless `rb2`.
- Executed true no-power test with live watcher log (`notes/rb2-recovery-watch-20260214-215107.log`).
- Observed: AC restore did not auto-boot; manual power button was required.
- Recovery timing: first down at `21:51:22 EST`, healthy return at `21:54:25 EST` (~`183s` downtime).
- WoL packet was sent from `tsDeb` during outage and did not power on `rb2` from no-power state.
- Optional next improvement: smart-plug cycle tests for unattended hard-reset repeatability.

4. `DONE (current state)` Reconfirm post-change acceptance.
- `ping` + SSH + `pveproxy/pvedaemon/pve-cluster` currently healthy on `rb1`, `rb2`, and `mba`.
- `tsDeb` watchdog timer remains required acceptance criterion after any future power-recovery test.

## Current Hardware Context

- **2017 Razer Blade 14**: current Proxmox source host.
- **2015 Razer Blade 14**: target Proxmox host `rb2-pve` (`192.168.5.108`), no battery installed (power-cable stability risk).
- **~2011 MacBook Air**: *rough* (broken screen, battery issues, etc.) hardware, but previously stayed reliable for Proxmox + single Ubuntu VM role so long as it did not need reboot.
- **Razer Core + GTX 1060**: Thunderbolt-dependent eGPU path relevant to future AI workload flexibility.

## Immediate Objective

Complete phase 1 readiness (all host baselines, including MBA), then perform migration safely with rollback coverage while preserving service continuity.

## Storage Placement Decision (Current)

- `truenas` stays on `rb1-pve` in the current phase.
- `rb2` is treated as compute/agent capacity, not storage-primary.
- Do not move TrueNAS to `rb2` until power stability and storage-path performance materially improve or a dedicated storage host is introduced.

## Repository Map

- `AGENTS.md`: project-local operating rules for agent work in this repo.
- `inventory/`: system-of-record hardware, VM, and remote-access inventory.
- `inventory/naming.md`: canonical naming convention and alias mapping (`lcHL` standard).
- `inventory/network-procurement.md`: reuse-first upgrade strategy and high-impact purchase shortlist.
- `runbooks/`: step-by-step execution procedures.
- `runbooks/interface-cutover-safe.md`: repeatable guarded process for moving Proxmox management bridge between NICs while preserving IP.
- `runbooks/network-throughput-benchmark.md`: repeatable `iperf3` matrix and interpretation guide.
- `runbooks/rb2-fallback-management-path.md`: direct emergency management path between `rb1` and `rb2`.
- `runbooks/rb2-hard-power-recovery-validation.md`: true no-power recovery checklist for batteryless `rb2`.
- `runbooks/tailscale-node-staging-rb2-mba.md`: utility-VM tailscale setup for `rb2` and `mba` (`lchl-tsnode-rb2`, `lchl-tsnode-mba`) with approval flow.
- `scripts/`: future automation helpers.
- `configs/`: future host/service config snapshots and templates.
- `notes/`: ad hoc research and decision notes.
- `notes/perf-baseline-template.md`: template for before/after throughput baselines.
- `notes/monitoring-software-eval-20260214.md`: third-party monitoring recommendation and rationale.
- `notes/mcp-homelab-status-rb2.md`: basic MCP install example and wiring for `rb2`.
- `log.md`: detailed project-local execution history.

## Operating Principles

- Documentation first, then automation.
- No silent assumptions in migration work.
- Every infrastructure change must leave a written trail (inventory + runbook + log).
- Prefer reversible operations and explicit rollback criteria.

## Near-Term Milestones

1. Finish phase 1 host verification for `rb1`, `rb2`, and MBA.
2. Complete phase 2 network optimization plan and port/cable map.
3. Pass detailed inventory gate before migration.
4. Execute phase 3 compute/utility migration while TrueNAS stays virtualized on `rb1`.
5. Complete phases 4 and 5 continuity/final topology rework.

## Tonight Objective (Planning Anchor)

After blocker items `1` and `3` are validated during recabling/power tests, target a first-pass agent bootstrap on one or two nodes to begin automation workflows.
