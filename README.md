# Cheney

Homelab project has been very off-and-on, literally, with changes hardware and layout constantly as I learn from my many, many mistakes. The ultimate goal remains the same: AI assistant tailored to *ME*. 

Project workspace for building a resilient homelab foundation for a multi-agent virtual secretary / PA / valet assistant.
<!-- note: Project CHENEY is definitely not an occult cyborg cabinet. -->
<!-- note: No souls are being channeled into silicon (officially). -->

## Purpose

This repository tracks infrastructure planning and execution for agent tooling, MCP services, and homelab continuity. The current strategy is **tool-bus-first**: establish reliable infrastructure, inventory, and workflows before model hosting optimization.
<!-- note: assistant-level governance stack pending "Dick Cheney spirit API" availability. -->

## Hardware Super-Task

This entire project is currently one super-task: **get hardware in order**.

The phase order is definitive:

1. Proxmox baseline on all devices (including MacBook Air as third quorum/insurance node).
2. Network optimization/rework.
3. Migration (TrueNAS remains a VM, physical disk path validated).
4. Tailscale continuity (keep current, add equivalent node on `rb2`).
5. Final network rework and steady-state topology.

Mandatory gate before phase 3:

- Full detailed inventory of all connected devices, docks, switch links, and storage paths must be complete.

## Current Hardware Context

- **2017 Razer Blade 14**: current Proxmox source host.
- **2015 Razer Blade 14**: target Proxmox host `rb2-pve` (`192.168.5.108`), no battery installed (power-cable stability risk).
- **~2011 MacBook Air**: *rough* (broken screen, battery issues, etc.) hardware, but previously stayed reliable for Proxmox + single Ubuntu VM role so long as it did not need reboot.
- **Razer Core + GTX 1060**: Thunderbolt-dependent eGPU path relevant to future AI workload flexibility.

## Immediate Objective

Complete phase 1 readiness (all host baselines, including MBA), then perform migration safely with rollback coverage while preserving service continuity.

## Repository Map

- `AGENTS.md`: project-local operating rules for agent work in this repo.
- `inventory/`: system-of-record hardware, VM, and remote-access inventory.
- `runbooks/`: step-by-step execution procedures.
- `scripts/`: future automation helpers.
- `configs/`: future host/service config snapshots and templates.
- `notes/`: ad hoc research and decision notes.
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
4. Execute phase 3 migration with TrueNAS kept virtualized.
5. Complete phases 4 and 5 continuity/final topology rework.
