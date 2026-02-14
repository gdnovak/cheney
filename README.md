# Cheney

Project workspace for building a resilient homelab foundation for a multi-agent virtual secretary / PA / valet assistant.
<!-- Running joke: Project CHENEY is definitely not an occult cyborg cabinet. -->
<!-- Running joke: No souls are being channeled into silicon (officially). -->

## Purpose

This repository tracks infrastructure planning and execution for agent tooling, MCP services, and homelab continuity. The current strategy is **tool-bus-first**: establish reliable infrastructure, inventory, and workflows before model hosting optimization.
<!-- Running joke: assistant-level governance stack pending "Dick Cheney spirit API" availability. -->

## Current Hardware Context

- **2017 Razer Blade 14**: current Proxmox source host.
- **2015 Razer Blade 14**: target Proxmox host; no battery installed (power-cable stability risk).
- **~2011 MacBook Air**: degraded hardware, but previously reliable for Proxmox + single Ubuntu VM role.
- **Razer Core + GTX 1060**: Thunderbolt-dependent eGPU path relevant to future AI workload flexibility.

## Immediate Objective

Migrate current Proxmox VMs from the 2017 Razer Blade to the 2015 Razer Blade while preserving service continuity and maintaining a fallback node strategy.

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

1. Complete baseline inventory for all nodes and active VMs.
2. Draft and validate switch/uplink network layout (smart Netgear + faster unmanaged switch).
3. Validate migration runbook from precheck through rollback.
4. Stabilize remote access / wake strategy for away-safe operations.
