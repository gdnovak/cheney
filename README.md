# Cheney

Homelab project has been very off-and-on, literally, with changes hardware and layout constantly as I learn from my many, many mistakes. The ultimate goal remains the same: AI assistant tailored to *ME*. 

Project workspace for building a resilient homelab foundation for a multi-agent virtual secretary / PA / valet assistant.
<!-- note: Project CHENEY is definitely not an occult cyborg cabinet. -->
<!-- note: No souls are being channeled into silicon (officially). -->

## Purpose

This repository tracks infrastructure planning and execution for agent tooling, MCP services, and homelab continuity. The current strategy is **tool-bus-first**: establish reliable infrastructure, inventory, and workflows before model hosting optimization.
<!-- note: assistant-level governance stack pending "Dick Cheney spirit API" availability. -->

## Today Priority (2026-02-17)

If you are resuming work, start here:

1. Keep eGPU in stable attached mode and avoid unnecessary hotplug cycles; use recovery-first posture if disconnect issues recur.
2. Continue Fedora operational polish and continuity hardening from `runbooks/next-steps-planning-20260216.md`.
3. Expand memory workflow usage (`memory/` notes + decisions) for resumable sessions.
4. Complete OpenClaw routing hardening on `rb1` (local-first stable path is up; fallback/error handling needs follow-up).

Execution checklists:

- `runbooks/today-egpu-and-memory-plan.md`
- `runbooks/next-steps-planning-20260216.md`

## Latest Implementation Checkpoint (2026-02-17 03:09 EST)

- `DONE` Implemented phase-1 efficient routing stack on `rb1-fedora` (`tdj`):
  - Ollama installed as system service and enabled.
  - Local models pulled: `qwen2.5:7b`, `qwen2.5-coder:7b`.
  - OpenClaw routing set to local-first (`ollama/qwen2.5:7b`) with Codex fallback (`openai-codex/gpt-5.3-codex`).
- `DONE` Added reusable routing validation harness: `scripts/openclaw_routing_validation.sh`.
- `DONE` Captured baseline + validation artifacts:
  - `notes/openclaw-artifacts/openclaw-routing-baseline-20260217-023746.log`
  - `notes/openclaw-routing-validation-20260217.md`
  - `notes/openclaw-artifacts/openclaw-routing-validation-20260217-030356.{log,jsonl}`
- `DONE` Verified coder-path routing (`qwen2.5-coder:7b`) under controlled primary-model switch.
- `OPEN` Forced fallback test currently fails with `fetch failed` when Ollama is unavailable; remediation tracked in `notes/openclaw-routing-implementation-20260217.md`.

## Prior Implementation Checkpoint (2026-02-16 22:30 EST)

- `DONE` Added hardened admin access path `rb1-admin` (`tdj`) with key-only SSH and validated `sudo -n` access.
- `DONE` Applied Fedora baseline updates on `rb1` (package refresh, core services active, reboot validated).
- `DONE` Set Wake-on-LAN persistence on `rb1` (`nmcli ... wake-on-lan=magic`, `ethtool Wake-on: g`) and validated packet-send path from `tsDeb`.
- `DONE` Installed/validated NVIDIA stack on `rb1` internal GPU (`nvidia-smi` shows GTX 1060, driver `580.119.02`, CUDA `13.0`).
- `DONE` Reintroduced Fedora-side fallback VLAN99 (`fallback99`, `172.31.99.1/30`) with bidirectional ping success and fallback SSH path verification (`rb1 <-> rb2` over `172.31.99.0/30`).
- `DONE` External eGPU is hot-attach detected and driver-bound (`0f:00.0` / `10de:1c03`), with both GPUs visible in `nvidia-smi`.
- `DONE` Rolled back AI bootstrap artifacts from `rb1` per scope request:
  - Ollama service/binary/data removed
  - Codex CLI removed
  - host-local `~/cheney` clone removed
- `DONE` Kept environment baseline intact (Node/npm retained; NVIDIA + fallback VLAN unchanged and verified).
- `DONE` Reboot-survival validation passed with eGPU attached:
  - `rb1` boot ID changed after reboot
  - `fallback99` auto-returned (`172.31.99.1/30`)
  - bidirectional fallback ping/SSH checks succeeded post-reboot
  - internal+external NVIDIA GPUs remained visible.
- `DONE` Completed attended OpenClaw evaluation attempts and captured artifacts for API-path validation.
- `DONE` Removed OpenClaw and related host state from `rb1` on request (`npm uninstall -g openclaw`; removed `/root/.openclaw*`).
- `DONE` Returned AI stack posture to deferred/manual bootstrap.

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

1. `DONE` Re-establish dual-sided fallback management path.
- Reserved fallback addressing remains:
  - `rb1` target fallback `172.31.99.1/30`
  - `rb2` active fallback `172.31.99.2/30`
- `rb2` fallback interface (`vmbr0.99`) is present and routable.
- `rb1` fallback interface is restored on Fedora (`enp0s20f0u6.99` / connection `fallback99`).
- Current validation: bidirectional fallback ping succeeds; fallback SSH path validates.
- Reboot-survival validation passed on Fedora side (fallback interface persisted and remained reachable).

2. `DONE` Platform pivot execution.
- `rb1` is now Fedora baremetal (`rb1-fedora`, `192.168.5.107`).
- `rb2` is current Proxmox VM/storage anchor (`192.168.5.108`).
- `truenas` is running on `rb2` and reachable at `192.168.5.100`.

3. `DONE` eGPU readiness baseline on baremetal (with hotplug caveat).
- Proxmox passthrough path was retired due repeated guest-loss behavior.
- Baremetal Fedora host now has validated NVIDIA driver stack (`nvidia-smi` pass, driver `580.119.02`).
- External eGPU acceptance matrix includes display-attached scenario pass; findings + caveats are tracked in `notes/egpu-readiness-rb1-fedora-20260216.md`.
- Known caveat: physical hot-unplug/replug remains temperamental; operate recovery-first and defer active hotplug tuning for now.

4. `DEFERRED` Assistant bootstrap readiness on new host layout.
- `tsDeb` watchdog timer reports active from guest-exec check.
- Utility VMs (`201`, `301`) are running.
- AI runtime/tooling on `rb1` is currently removed; manual re-bootstrap will happen later.

## Current Hardware Context

- **2017 Razer Blade 14**: now `rb1-fedora` baremetal host (`192.168.5.107`) for direct GPU/agent workloads.
- **2015 Razer Blade 14**: primary Proxmox host `rb2-pve` (`192.168.5.108`), no battery installed (power-cable stability risk).
- **~2011 MacBook Air**: fallback Proxmox node `kabbalah` (`192.168.5.66`) with utility VM role.
- **Razer Core + GTX 1060**: Thunderbolt-dependent eGPU path relevant to future AI workload flexibility.

## Immediate Objective

Stabilize post-pivot operations: complete `rb1` eGPU bring-up and confirm dual-sided VLAN99 reboot persistence while keeping `rb2` continuity controls intact.

## Storage Placement Decision (Current)

Current state:

- `truenas` is running on `rb2-pve`.
- `rb1` has been rebuilt as Fedora baremetal for direct GPU/NVIDIA stack control.
- Fallback VLAN99 path is active on both `rb1` and `rb2`; reboot-survival validation has passed on Fedora side.

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
- Current compliance check: both fallback interfaces are active and unrouted; reboot persistence is validated on both sides.

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
- `runbooks/next-steps-planning-20260216.md`: post-eGPU-acceptance planning tracks and execution order.
- `runbooks/openclaw-api-key-smoke-rb1-fedora.md`: attended OpenClaw API-key validation flow on `rb1`.
- `runbooks/rb1-egpu-incident-recovery.md`: primary incident-response workflow for `rb1` eGPU/TB faults.
- `runbooks/memory-workflow-weekly.md`: weekly memory/decision cadence for fast resume and context continuity.
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
- `notes/egpu-readiness-rb1-fedora-20260216.md`: current eGPU readiness findings and deferred phase-5 test gates.
- `notes/openclaw-cli-feature-findings-20260216.md`: OpenClaw CLI reconnaissance findings and headless caveats.
- `coordination/`: cross-device task/state/event bus for orchestrator <-> VM subagent workflow.
- `log.md`: detailed project-local execution history.

## Operating Principles

- Documentation first, then automation.
- No silent assumptions in migration work.
- Every infrastructure change must leave a written trail (inventory + runbook + log).
- Prefer reversible operations and explicit rollback criteria.

## Near-Term Milestones

1. Execute next-phase planning tracks from `runbooks/next-steps-planning-20260216.md`.
2. Keep eGPU in stable operating mode and document recovery-first handling for disconnect incidents.
3. Fix OpenClaw fallback-path behavior and session hygiene, then re-run routing validation matrix.
4. Refresh continuity validation suite for the current host-role layout.
5. Continue phase-2 network optimization (port map + 2.5Gb path planning).

## Current Session Objective

Resume from the 2026-02-17 03:09 checkpoint: keep recovery-first eGPU operations, maintain weekly memory workflow discipline, and complete OpenClaw fallback remediation + rerun.
