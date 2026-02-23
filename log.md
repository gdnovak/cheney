# Cheney Project Log

Purpose: detailed technical history for `/home/tdj/cheney`.

## Entry Template

```
## YYYY-MM-DD HH:MM TZ (Codex)
- Area: <topic>
- Status: <1-3 lines>
- Evidence: <commands/observations summary>
- Next action: <single next step>
```

## Log

## 2026-02-13 23:43 EST (Codex)
- Area: project bootstrap
- Status: Initialized Cheney project documentation scaffold with README, repo AGENTS policy, inventory contract/files, and first migration runbook.
- Evidence: Created directories `inventory/`, `runbooks/`, `scripts/`, `configs/`, `notes/` and authored core markdown files per bootstrap plan.
- Next action: Populate hardware/VM/network `TBD` fields from live host and Proxmox data.

## 2026-02-14 00:11 EST (Codex)
- Area: inventory pass from live systems
- Status: Replaced major `TBD` fields using live Proxmox data from `rb1-pve`, added VM inventory rows, added dock/peripheral inventory, and drafted network layout file with switch-role planning.
- Evidence: Collected `qm list`, `qm config 100/101`, guest-agent IPs, host CPU/RAM/storage, `ethtool` Wake-on capability, and verified MBA `192.168.5.66` ping + TCP/22 reachability; SSH auth to MBA failed in batch mode.
- Next action: Gain shell access on MBA and bring `rb14-2015` online to replace remaining unverified hardware/network fields and resolve legacy quorum state.

## 2026-02-14 01:53 EST (Codex)
- Area: hardware super-task plan lock + rb2 key bootstrap
- Status: Updated project docs to make "Hardware" the super-task with fixed 1-5 phase order, required full-device-inventory gate before migration, MBA requirement in phase 1, and TrueNAS-as-VM migration path. Added dedicated inventory gate runbook.
- Evidence: Updated `README.md`, inventory docs, and migration runbook; added `runbooks/phase-gate-full-device-inventory.md`. Created dedicated SSH keypair `~/.ssh/id_ed25519_rb2-pve` and isolated SSH config stanza for `rb2-pve` without modifying existing key entries.
- Next action: Complete `ssh-copy-id -i ~/.ssh/id_ed25519_rb2-pve.pub rb2-pve` with root password once available, then verify key-only SSH and continue phase-1 host verification (including MBA).

## 2026-02-14 03:14 EST (Codex)
- Area: phase-1 stability tooling + watcher bootstrap
- Status: Confirmed key SSH access to `rb1-pve`, `rb2-pve`, and `mba`; deployed `tsDeb` watchdog with systemd timer and WoL support; updated inventory docs with MBA dummy-plug-in-hub note and direct TB->HDMI fallback path.
- Evidence: Installed `wakeonlan` on `tsDeb`; created `/usr/local/sbin/tsdeb-watchdog.sh` plus `tsdeb-watchdog.service` and `tsdeb-watchdog.timer`; verified timer is `enabled`/`active`; journal entries show successful checks for `rb1/rb2/mba` at `03:12:57 EST`.
- Next action: Run closed-lid reboot validation cycles per `runbooks/closed-lid-reboot-validation.md` before recabling dongles/adapters.

## 2026-02-14 03:29 EST (Codex)
- Area: closed-lid reboot validation execution
- Status: Completed sequential closed-lid reboot validation for `rb1`, `rb2`, and `mba`; all three hosts passed 2/2 reboot cycles with SSH and Proxmox services recovered.
- Evidence: Cycle logs captured in `/tmp/closed_lid_validation_20260214_0319.log` and `/tmp/closed_lid_validation_20260214_0325_cycle2.log`; post-checks show `pveproxy/pvedaemon/pve-cluster` active on all hosts and watcher timer still `enabled`/`active` on `tsDeb`.
- Next action: Proceed with adapter/dongle recabling one host at a time while keeping management reachability checks between each swap.

## 2026-02-14 03:59 EST (Codex)
- Area: tomorrow blocker reminder hardening
- Status: Added a high-visibility `TOMORROW BLOCKER (Do Not Skip)` section to README focused on rb2 fallback management path, post-recable IP/interface verification, and deferred hard power-loss validation.
- Evidence: Updated `README.md` and added cross-reference note in `runbooks/closed-lid-reboot-validation.md`.
- Next action: Bring rb2 back online after recable and complete tonight's non-hard-power checks; run hard-power recovery checklist tomorrow.

## 2026-02-14 04:03 EST (Codex)
- Area: rb1 management interface cutover to Razer Core NIC
- Status: Switched `rb1` `vmbr0` bridge port from `nic0` to `enx90203a1be8d6` (Razer Core Ethernet path) while preserving IP `192.168.5.98/22`.
- Evidence: `/etc/network/interfaces` now uses `bridge-ports enx90203a1be8d6`; post-cutover checks show ping/SSH OK, `pveproxy/pvedaemon/pve-cluster` active, VMs `100/101` running, and `tsDeb` watchdog timer still `active/enabled`.
- Next action: Continue cable rearrangement one hop at a time with reachability checks after each change.

## 2026-02-14 04:21 EST (Codex)
- Area: rb2 management interface cutover + reusable runbook
- Status: Added dedicated cutover runbook and switched `rb2` `vmbr0` bridge port from `nic0` to `enx00051bde7e6e` while preserving IP `192.168.5.108/22`.
- Evidence: New file `runbooks/interface-cutover-safe.md`; `/etc/network/interfaces` on `rb2` now contains `bridge-ports enx00051bde7e6e`; post-checks show ping/SSH OK and `pveproxy/pvedaemon/pve-cluster` active; `tsDeb` watcher remained `active/enabled`.
- Next action: Continue recabling with one-change-at-a-time policy and run post-change reachability checks after each cable move.

## 2026-02-14 04:41 EST (Codex)
- Area: proxmox repo normalization + upgrade baseline
- Status: Normalized APT source configuration on `rb1`, `rb2`, and `mba` to no-subscription Proxmox/CEPH channels with enterprise channels explicitly disabled, then refreshed package indexes on all hosts.
- Evidence: `proxmox.sources` set to `pve-no-subscription`; `pve-enterprise.sources` has `Enabled: false`; `ceph.sources` enterprise stanza disabled and no-subscription stanza enabled on all three nodes. `apt-get update` succeeded on each host. Upgradable package counts: `rb1=40`, `rb2=83`, `mba=82`.
- Next action: Defer full package upgrade/reboots to a controlled maintenance window tomorrow after final recable state is stable.

## 2026-02-14 05:05 EST (Codex)
- Area: overnight network weak-spot telemetry
- Status: Added and launched passive overnight network watcher script to log ping/loss/latency plus per-host NIC link state, speed, duplex, and error/drop counters.
- Evidence: New script `scripts/overnight_net_watch.sh`; active process started with PID `182085`; output log `/home/tdj/cheney/notes/netwatch-20260214-050430.log` showing current link speeds and counters for `rb1/rb2/mba`.
- Next action: Review overnight log deltas tomorrow to identify packet loss, rising drops/errors, or link-speed renegotiation events.

## 2026-02-14 18:59 EST (Codex)
- Area: throughput-first implementation docs and tooling
- Status: Implemented the throughput-first network plan in repo docs with execution-ready benchmark instructions, a procurement shortlist, and a reusable performance baseline template.
- Evidence: Updated `inventory/network-layout.md` with target topology and host link goals; added `runbooks/network-throughput-benchmark.md`; added `inventory/network-procurement.md`; added `notes/perf-baseline-template.md`; added executable helper `scripts/iperf3_client_suite.sh`; updated README/inventory index references.
- Next action: Install `iperf3` on target nodes and run first full matrix baseline using new runbook/template before any new adapter/switch purchases.

## 2026-02-14 19:34 EST (Codex)
- Area: first throughput baseline execution (`iperf3`)
- Status: Ran quick matrix across `rb1`, `rb2`, and `mba`; identified expected healthy 1Gb behavior on `rb1<->rb2` and a major MBA path bottleneck around ~300 Mbps.
- Evidence: `notes/iperf3-matrix-20260214-193115.log` + summary file show `rb1<->rb2` ~`868-878 Mbps` with zero retransmits, while all `*<->mba` tests were ~`278-317 Mbps` with high retransmits. `lsusb -t` confirms MBA Ethernet (`r8152`) on `480M` USB2 path.
- Next action: Treat MBA as continuity-only, then add workstation/mac mini to the matrix and prioritize 2.5Gb-capable paths on `rb1/rb2/workstation`.

## 2026-02-14 19:42 EST (Codex)
- Area: blocker operationalization + peripheral inventory update
- Status: Added KVM switch details to peripheral inventory and replaced static TOMORROW block with live status tracker (`done/pending`) plus explicit hard-power validation runbook for `rb2`.
- Evidence: Updated `inventory/peripherals.md`; updated `README.md` blocker section and repository map; added `runbooks/rb2-hard-power-recovery-validation.md`. Verified current `vmbr0` bindings and health on `rb1/rb2/mba` before marking current-state items done.
- Next action: Execute the new hard-power recovery runbook on `rb2` and resolve the pending fallback direct-management path item.

## 2026-02-14 19:49 EST (Codex)
- Area: blocker 1+3 execution prep for recabling window
- Status: Advanced blocker item 1 to in-progress by adding a dedicated fallback direct-management runbook with fixed emergency addressing and added a recovery-watch script for power-loss testing. Expanded hard-power runbook to include optional smart-plug hard-reset validation.
- Evidence: Added `runbooks/rb2-fallback-management-path.md`; added executable `scripts/rb2_recovery_watch.sh`; updated `runbooks/rb2-hard-power-recovery-validation.md` with optional smart-plug section and watcher usage; updated `README.md` blocker statuses and runbook map.
- Next action: During physical recabling, execute fallback-link runtime IP test (`172.31.99.1/30 <-> 172.31.99.2/30`) and then run hard no-power recovery validation on `rb2`.

## 2026-02-14 20:21 EST (Codex)
- Area: recovery watcher smoke test + tonight objective anchor
- Status: Smoke-tested `rb2` recovery watcher script successfully and added a README planning anchor tying blocker completion to initial agent bootstrap on 1-2 nodes.
- Evidence: Ran `scripts/rb2_recovery_watch.sh 192.168.5.108 rb2 20 5` with successful ping/SSH/service polling; added `Tonight Objective (Planning Anchor)` section to `README.md`.
- Next action: Execute physical recable/power events and run the same watcher during hard power-loss validation.

## 2026-02-14 20:33 EST (Codex)
- Area: blocker 1 runtime VLAN fallback activation
- Status: Activated non-persistent fallback management IPs on `rb1`/`rb2` using `vmbr0.99` over `VLAN 99` and validated inter-host reachability.
- Evidence: `rb1 vmbr0.99=172.31.99.1/30`, `rb2 vmbr0.99=172.31.99.2/30`; successful bidirectional ping; successful SSH to `rb2` over fallback path via jump host (`ssh -J rb1-pve root@172.31.99.2`).
- Next action: During power-loss drill, keep fallback path available and monitor recovery via `scripts/rb2_recovery_watch.sh`; decide later whether to persist VLAN interface config in host network files.

## 2026-02-14 21:40 EST (Codex)
- Area: unattended continuity prep bundle (tailscale + mcp + monitoring + truenas pre-move)
- Status: Staged tailscale on `rb2` and `mba` without account binding, installed a basic read-only MCP server on `rb2`, evaluated third-party monitoring options, and began TrueNAS move with backup artifact creation/copy (no cutover).
- Evidence: `tailscaled` active/enabled on `rb2` and `mba` with `BackendState=NeedsLogin`; MCP server installed at `/opt/mcp-homelab-status/server.py` with launcher `/usr/local/bin/mcp-homelab-status`; backup `vzdump-qemu-100-2026_02_14-16_35_48.vma.zst` created on `rb1` and copied to `rb2` with matching SHA256 `939c022044d49fd2106c3b5f21331dfff248043cfae615df49ad6407b57d5365`.
- Next action: When present, finalize tailscale login only under confirmed account, decide monitoring deployment target (recommended start: Uptime Kuma), then proceed with physical-disk move before any TrueNAS cutover.

## 2026-02-14 21:56 EST (Codex)
- Area: rb2 hard power-loss validation execution
- Status: Completed true no-power recovery test for `rb2`; host did not auto-boot on AC restore and required manual power-on; services recovered cleanly after boot.
- Evidence: `notes/rb2-recovery-watch-20260214-215107.log` shows first `down` at `21:51:22 EST` and first healthy `up` at `21:54:25 EST` (183s). Sent WoL packet from `tsDeb` during outage; node remained off until manual button press. Post-recovery checks show `pveproxy/pvedaemon/pve-cluster` active and management IP restored.
- Next action: Keep blocker #1 in progress by deciding whether to persist `rb2` fallback VLAN interface (`vmbr0.99`), since runtime-only config dropped during reboot.

## 2026-02-14 22:01 EST (Codex)
- Area: blocker #1 closure (`rb2` fallback persistence)
- Status: Persisted `rb2` fallback VLAN interface config (`vmbr0.99`) and verified it survives reboot; fallback path now remains available after node restart.
- Evidence: Added `vmbr0.99` stanza to `/etc/network/interfaces` on `rb2`; rebooted `rb2`; post-reboot checks show `vmbr0=192.168.5.108/22`, `vmbr0.99=172.31.99.2/30`, and `pveproxy/pvedaemon/pve-cluster` all active. `rb1` ping to `172.31.99.2` successful post-reboot; SSH via jump host to `172.31.99.2` successful.
- Next action: Optional hardening: persist matching fallback interface config on `rb1` so VLAN99 path also survives `rb1` reboot.

## 2026-02-14 22:14 EST (Codex)
- Area: tailscale architecture shift to utility VMs (`rb2` + `mba`)
- Status: Disabled host-level `tailscaled` on `rb2` and `mba`, finalized utility VMs `tsnode-rb2` (`201`) and `tsnode-mba` (`301`), installed tailscale in both, and generated admin approval URLs.
- Evidence: Host checks show `tailscaled=disabled/inactive` on `rb2` and `mba`; VM checks show both nodes reachable (`192.168.5.112`, `192.168.5.113`) with `tailscale status` in `NeedsLogin` and auth URLs (`c7cba0f016792`, `c8bf33201fbaa`).
- Next action: Approve both nodes in Tailscale admin, then apply tailnet tags/routes policy and verify `tailscale ping` from existing `tsDeb` path.

## 2026-02-14 22:27 EST (Codex)
- Area: naming standard adoption (`LichCheney` / `lcHL`)
- Status: Added a lightweight naming standard to documentation so future nodes/services use the `lcHL` convention without renaming active infrastructure tonight.
- Evidence: Updated `README.md` with naming policy section and added `inventory/naming.md` with canonical `lchl-<role>-<node>` pattern plus current-to-canonical mapping.
- Next action: Apply `lchl-*` names consistently in future docs/tags; schedule live hostname/VM renames only in a maintenance window if desired.

## 2026-02-14 22:30 EST (Codex)
- Area: tailscale utility-node live rename (`lcHL`)
- Status: Renamed utility VMs and Tailscale hostnames to `lchl-tsnode-rb2` and `lchl-tsnode-mba` without reapproval; both remained online with unchanged tailnet IPs.
- Evidence: Proxmox VM names updated via `qm set --name`; node checks show `BackendState=Running` and DNS names `lchl-tsnode-rb2.tailde8dbc.ts.net` and `lchl-tsnode-mba.tailde8dbc.ts.net`; Tailscale IPs remain `100.97.121.113` and `100.115.224.15`.
- Next action: Optionally align `tsDeb-rb1` name to `lchl-tsdeb-rb1` in a later low-risk pass.

## 2026-02-14 23:02 EST (Codex)
- Area: tailscale reboot validation before recabling
- Status: Completed full reboot validation: utility VMs (`201`, `301`) plus hosts (`rb2`, `rb1`, `mba`) with post-boot Tailscale reconnect checks. All targeted systems recovered and utility nodes remained `BackendState=Running`.
- Evidence: VM reboot checks passed for `lchl-tsnode-rb2` and `lchl-tsnode-mba` (`tailscaled=active`, `BackendState=Running`). Host reboot checks confirmed boot ID changes on `rb2`, `rb1`, and `mba`; Proxmox core services returned `active` on all three; utility VMs came back with `onboot: 1` and Tailscale online (`100.97.121.113`, `100.115.224.15`). `tsDeb` watchdog validated after `rb1` reboot (`timer=active`, service transiently `activating` then `inactive` as expected).
- Next action: Proceed with cable management as cable-only swaps (no interface rebinding), performing ping+SSH checks after each physical move.

## 2026-02-14 23:16 EST (Codex)
- Area: storage strategy pivot (`truenas` pinned to `rb1`)
- Status: Updated planning/docs to keep `truenas` on `rb1` for current phase and limit migration scope to compute/utility VMs.
- Evidence: Updated `README.md`, `inventory/vms.md`, `runbooks/proxmox-migration-2017-to-2015.md`, and `inventory/network-layout.md` to remove `truenas -> rb2` migration assumption and explicitly mark storage-primary on `rb1`.
- Next action: Continue compute/agent-focused work on `rb1/rb2` while deferring storage relocation until stability/performance conditions materially improve.

## 2026-02-14 23:16 EST (Codex)
- Area: `truenas` RAM right-sizing
- Status: Reduced VM `100` memory from `8192` to fixed `4096` (`balloon: 0`), rebooted, and verified service health.
- Evidence: Post-change Proxmox status reports `maxmem=4.00 GiB`, VM running; guest checks show `Mem total ~3921 MiB`, `zpool status -x` => `all pools are healthy`, and `midclt call system.state` => `READY`. Boot ID changed across reboot (`b343dfa9...` -> `d312e1f0...`).
- Next action: Monitor during normal workload windows; if storage instability appears, roll back VM `100` memory to `8192`.

## 2026-02-14 23:28 EST (Codex)
- Area: fallback persistence policy hardening + risk-governance rule
- Status: Updated docs to make fallback persistence a required redundancy condition on both `rb1` and `rb2`, added VLAN99 management-only security controls, and codified that agent work should explicitly challenge risky requests with safer alternatives.
- Evidence: Updated `AGENTS.md`, `runbooks/rb2-fallback-management-path.md`, `inventory/network-layout.md`, and `README.md` to replace optional language and add security constraints (`no gateway`, `no forwarding/NAT/routing`, host-only path).
- Next action: Implement persistent `rb1` `vmbr0.99` config and verify reboot survival so dual-node fallback requirement is fully satisfied.

## 2026-02-14 23:31 EST (Codex)
- Area: `rb1` fallback persistence implementation
- Status: Applied persistent `vmbr0.99` configuration on `rb1`, brought interface up, and validated fallback reachability to `rb2`.
- Evidence: Added `vmbr0.99` stanza to `/etc/network/interfaces` on `rb1` (`172.31.99.1/30`, `vlan-raw-device vmbr0`); `ip -4 addr show vmbr0.99` confirms interface up; `ping 172.31.99.2` succeeded; fallback SSH via control-host jump remains functional (`ssh -J rb1-pve -i ~/.ssh/id_ed25519_rb2-pve root@172.31.99.2 ...`).
- Next action: Reboot `rb1` during a maintenance window and verify `vmbr0.99` auto-returns to fully close dual-node reboot-survival criteria.

## 2026-02-14 23:43 EST (Codex)
- Area: `rb1` fallback reboot-survival validation
- Status: Confirmed `rb1` reboot completed and `vmbr0.99` returned automatically; dual-node fallback persistence target is now satisfied.
- Evidence: `rb1` uptime start shows fresh boot (`2026-02-14 18:40:56` local host time), `ip -4 -br addr show dev vmbr0.99` on `rb1` shows `172.31.99.1/30` post-boot, and fallback path checks succeed (`rb1` ping `172.31.99.2`, SSH jump to `rb2` fallback IP using `~/.ssh/id_ed25519_rb2-pve`).
- Next action: Continue cable-only recabling with one-change-at-a-time validation while keeping VLAN99 management-only controls intact.

## 2026-02-15 00:56 EST (Codex)
- Area: assistant starter foundation artifacts (`ollama + codex`, OpenClaw deferred)
- Status: Implemented phase-A coordination and governance scaffolding for cross-device orchestrator <-> VM subagent workflow, including task bus contracts, policy files, helper scripts, bootstrap runbook, and starter MCP/skills/watchdog docs.
- Evidence: Added `coordination/` structure with templates/schemas/policies (`safety`, `budget`, `approvals`), added executable helper scripts under `scripts/assistant/`, added `runbooks/assistant-sandbox-bootstrap-rb1.md`, and added `notes/mcp-catalog.md`, `notes/skill-registry.md`, `notes/assistant-watchdog-policy.md`, `notes/assistant-runbook-smoke-test.md`. `bash -n` syntax check passed on all new shell scripts.
- Next action: Provision temporary sandbox VM on `rb1`, install Codex + Ollama there, then run attended smoke test; keep unattended mode blocked until eGPU gate passes.

## 2026-02-14 23:52 EST (Codex)
- Area: reproducible continuity test documentation
- Status: Added a dedicated no-execution validation suite runbook so future agents/sessions can reproduce continuity checks deterministically.
- Evidence: New file `runbooks/continuity-validation-suite.md` includes baseline capture, VM/host reboot validation flow, fallback VLAN checks, security checks, pass/fail criteria, and failure handling guidance.
- Next action: Use this runbook as the single source of truth after recabling and before major infrastructure changes.

## 2026-02-14 23:52 EST (Codex)
- Area: homelab-native assistant prep planning (`lcHL`)
- Status: Added a phased architecture plan for local assistant foundations covering MCP, skills, memory/context, processing/runtime, security, and observability requirements.
- Evidence: New file `notes/homelab-assistant-native-prep-plan.md` defines required MCP classes/hardening, initial skill set, node role split, context/memory model, and immediate backlog items.
- Next action: Implement Phase A foundations (observability baseline + MCP read-only catalog + assistant bootstrap runbook on `rb1`).

## 2026-02-15 01:04 EST (Codex)
- Area: VM Codex contractor identity scoping (`cheney-vessel-alpha`)
- Status: Added VM-specific subagent instruction scope so cloned-repo Codex instance can identify itself deterministically without imposing global governance on future autonomous assistant design.
- Evidence: Added `subagents/cheney-vessel-alpha/AGENTS.md` and `subagents/README.md`; updated `runbooks/assistant-sandbox-bootstrap-rb1.md` to enter `~/cheney/subagents/cheney-vessel-alpha` and set `AGENT_ID=cheney-vessel-alpha`; updated `README.md` repo map and deferred sanitized memory/log profile as backlog item in `notes/homelab-assistant-native-prep-plan.md`.
- Next action: Clone repo into sandbox VM, run Codex from `subagents/cheney-vessel-alpha`, and execute first attended task/report loop.

## 2026-02-15 02:38 EST (Codex)
- Area: Fedora VM rebuild + eGPU passthrough isolation on `rb1`
- Status: Rebuilt `cheney-vessel-alpha` as Fedora 42 cloud VM, stabilized `rb1` management on USB NIC (`enxa0cec804fed7`), and validated baseline VM SSH (`192.168.5.111`) with repo clone and pre-GPU snapshot (`fedora-base`). eGPU passthrough (`0f:00.*`) binds to VFIO and VM starts, but guest loses SSH/QGA until `hostpci*` is removed.
- Evidence: `qm` config/status checks show `hostpci` attach succeeds with reset warning (`Inappropriate ioctl for device`); host and fallback VLAN remain reachable; guest access returns immediately after passthrough rollback. Added test note with sources and next matrix in `notes/egpu-passthrough-fedora-proxmox-20260215.md`.
- Next action: Run controlled matrix with explicit `dummy_hdmi` state (`present`/`absent`) and passthrough parameter variants (`audio`, `rombar=0`, firmware mode), rolling back immediately on guest-loss events.

## 2026-02-15 02:48 EST (Codex)
- Area: eGPU test matrix update + architecture pivot plan lock
- Status: Completed controlled `dummy_hdmi=absent` eGPU passthrough test (`0f:00.0` only). Result remained fail (guest SSH/QGA loss) with clean automatic rollback; host/fallback continuity remained intact. Updated planning docs to pivot toward `truenas -> rb2` and `rb1` Fedora baremetal conversion.
- Evidence: Test loop showed `ssh=0 qga=0` through full window; rollback restored VM `220` SSH at `192.168.5.111`. `rb2` fallback ping to `172.31.99.1` remained healthy post-test. Added `runbooks/rb1-baremetal-fedora-pivot.md`; updated `README.md`, `inventory/vms.md`, `inventory/network-layout.md`, and marked legacy scope in `runbooks/proxmox-migration-2017-to-2015.md`.
- Next action: Execute pivot Phase A/B (`truenas` safety prep + migration to `rb2`) before any `rb1` baremetal reinstall.

## 2026-02-15 02:59 EST (Codex)
- Area: `truenas` copy/paste migration checkpoint (`rb1` -> `rb2`)
- Status: Completed the closest safe copy/paste path: fresh backup on `rb1`, verified transfer to `rb2`, and full restore on `rb2` as VM `100` kept powered off for physical cutover.
- Evidence: SHA256 matched on both hosts (`d2f1b02dbd7352f2b0c02d1ccf812dbcdc20b800355e13468102a99b789f987c`); `rb2` now has `qm config 100` with boot disk on `local-lvm:vm-100-disk-0` plus original USB passthrough IDs (`1058:2647`, `174c:55aa`); `rb1` `truenas` remains running for zero-downtime staging.
- Next action: During cutover window, stop `rb1` VM `100`, move physical USB storage drives from `rb1` to `rb2`, then start `rb2` VM `100` and validate pool + shares before any Fedora reinstall work.

## 2026-02-15 03:03 EST (Codex)
- Area: Fedora baremetal phase readiness (`rb1`)
- Status: Added concrete baremetal install runbook so Fedora conversion can begin immediately after `truenas` drive cutover validation.
- Evidence: New `runbooks/rb1-fedora-baremetal-install.md` with pre-wipe capture, installer guidance, first-boot baseline, and rollback.
- Next action: Complete physical drive move (`rb1` -> `rb2`), start/validate `rb2` TrueNAS VM, then execute Fedora preflight capture on `rb1`.

## 2026-02-15 03:07 EST (Codex)
- Area: Fedora pre-wipe safety execution + tailscale role correction
- Status: Executed `rb1` pre-wipe capture, copied capture to `rb2`, produced fresh backups for VMs `101` and `220`, and copied both backup artifacts to `rb2` dump storage. Updated Fedora runbook to keep subnet-router Tailscale role on `rb2` during/after `rb1` wipe.
- Evidence: `/var/lib/vz/dump/rb1-pre-fedora-capture-20260215-0303.tar.gz` exists on `rb2`; `/var/lib/vz/dump/vzdump-qemu-101-2026_02_14-22_03_39.vma.zst` and `/var/lib/vz/dump/vzdump-qemu-220-2026_02_14-22_04_04.vma.zst` exist on `rb2`; `runbooks/rb1-fedora-baremetal-install.md` preconditions now pin subnet routing to `rb2`.
- Next action: If requested, restore/migrate `101`/`220` onto `rb2` before Fedora wipe; otherwise proceed directly to Fedora installer on `rb1` with rollback artifacts already secured.

## 2026-02-15 03:10 EST (Codex)
- Area: `rb1` workload evacuation for Fedora wipe
- Status: Restored VM backups `101` and `220` onto `rb2`, then cut over live execution by stopping both on `rb1` and starting them on `rb2`.
- Evidence: `rb2` `qm list` now shows running `100`, `101`, `201`, `220`; `rb1` `qm list` shows `100`, `101`, `220` all stopped; network checks from workstation show `192.168.5.102` and `192.168.5.111` reachable with SSH port open.
- Next action: Proceed with Fedora installation on `rb1` when ready; keep `rb2` as temporary host for migrated VMs during burn-in.

## 2026-02-15 04:40 EST (Codex)
- Area: `rb1` Fedora install completion + SSH key bootstrap
- Status: Fedora Server install completed on `rb1`; host is now reachable as `rb1-fedora` at `192.168.5.107` over management USB NIC. Added dedicated SSH key auth without modifying existing node keys.
- Evidence: Keypair created at `~/.ssh/id_ed25519_rb1-fedora*`; login verified with `ssh -o BatchMode=yes rb1 'hostnamectl --static; whoami'` => `rb1-fedora` / `root`; interface check shows `enp0s20f0u6` on `192.168.5.107/22`.
- Next action: Execute tomorrow runbook `runbooks/tomorrow-ai-bootstrap-rb1-fedora.md` for attended Ollama + Codex bring-up.

## 2026-02-15 04:43 EST (Codex)
- Area: diagnostics artifact organization pre-reboot
- Status: Organized previously untracked network/power watch logs into dated archive folders under `notes/archive/` and added an index file.
- Evidence: Moved `netwatch-20260214-*.log` to `notes/archive/2026-02-14/network-watch/`, moved `rb2-recovery-watch-20260214-202059.log` to `notes/archive/2026-02-14/power-recovery/`, created `notes/archive/2026-02-14/README.md`.
- Next action: Continue capturing future incidents into new dated archive folders for trend comparison.

## 2026-02-15 04:47 EST (Codex)
- Area: next-session priority pinning
- Status: Promoted immediate priorities so resume sessions land on two explicit tracks: (1) eGPU configuration on `rb1-fedora`, (2) memory structure optimization using markdown graph patterns.
- Evidence: Added high-visibility section `Today Priority (2026-02-15)` in `README.md` and created `runbooks/today-egpu-and-memory-plan.md` with actionable checklist and acceptance criteria.
- Next action: Execute Track A (eGPU bring-up) after reboot, then start Track B memory scaffold in-repo.

## 2026-02-16 18:05 EST (Codex)
- Area: inventory reconciliation against live post-pivot network state
- Status: Revalidated current host/VM/network state over SSH and updated stale inventory/readme records to match the live layout (`rb1` Fedora baremetal, `rb2` Proxmox anchor, `truenas` on `rb2`). Captured an active continuity gap: VLAN99 fallback is currently single-sided on `rb2` and not active on `rb1` post-reinstall.
- Evidence: Live checks from `rb1`, `rb2`, `mba`, and `truenas` (`hostnamectl`, `ip -4 -br addr`, `lscpu`, `free -h`, `lsblk`, `ethtool`, `qm list`, `zpool status -x`) plus fallback validation (`rb1 -> 172.31.99.2` and `rb2 -> 172.31.99.1` both failed). Updated `README.md`, `inventory/hardware.md`, `inventory/network-layout.md`, `inventory/network-remote-access.md`, and `inventory/vms.md`.
- Next action: Reintroduce Fedora-side VLAN99 fallback interface on `rb1` and rerun continuity validation before unattended bootstrap work.

## 2026-02-16 18:55 EST (Codex)
- Area: `rb1-fedora` hardening/baseline implementation + eGPU readiness checkpoint
- Status: Implemented phase-1/2 baseline hardening on `rb1-fedora` (admin access model, SSH hardening, package/service baseline, WoL persistence) and completed phase-3 internal NVIDIA validation. Updated repo inventory/runbooks with resumable state and added dedicated eGPU-readiness findings note for deferred phase-5 execution.
- Evidence: `ssh rb1-admin` succeeds and `sudo -n` works; password-only SSH test fails with `Permission denied (publickey,...)`; `systemctl is-active sshd firewalld chronyd cockpit.socket` => all `active`; `nmcli ... wake-on-lan` => `magic`; `ethtool enp0s20f0u6` => `Wake-on: g`; `nvidia-smi` => `NVIDIA GeForce GTX 1060`, driver `580.119.02`, CUDA `13.0`; NVIDIA modules loaded (`nvidia*`). Confirmed `rb2` fallback endpoint remains `172.31.99.2/30`, but fallback ping still fails both directions because `rb1` `.99` interface is absent. `qm guest exec 101 -- tailscale status` shows continuity node as `tsdeb-rb1` (`100.81.158.2`).
- Next action: Restore Fedora-side VLAN99 fallback on `rb1` (`172.31.99.1/30`), verify bidirectional fallback ping/SSH, then run external eGPU attach matrix from `notes/egpu-readiness-rb1-fedora-20260216.md`.

## 2026-02-16 19:06 EST (Codex)
- Area: fallback restoration + external eGPU detection + Ollama baseline on `rb1-fedora`
- Status: Restored Fedora-side fallback VLAN99 on `rb1` (`fallback99` on `enp0s20f0u6.99`, `172.31.99.1/30`), validated bidirectional fallback connectivity with `rb2`, verified external GTX 1060 eGPU (`0f:00.0`) is detected/driver-bound alongside internal GPU, and installed/enabled Ollama with successful local API response and dual-GPU runtime discovery.
- Evidence: `rb1` and `rb2` fallback pings now succeed (`0%` loss); fallback SSH-path checks to `172.31.99.1` and `172.31.99.2` succeeded via jump tests; `lspci` shows external GPU `10de:1c03`; `nvidia-smi` lists two GPUs (`01:00.0`, `0f:00.0`); kernel log includes `thunderbolt ... Razer Core` and NVIDIA bind for `0f:00.0`; `boltctl list` shows authorized Razer Core devices; `systemctl is-active/is-enabled ollama` => `active`/`enabled`; `curl 127.0.0.1:11434/api/tags` returned JSON; Ollama journal reports both CUDA devices as inference compute.
- Next action: Run reboot-survival validation with eGPU attached (`fallback99` + NVIDIA + Ollama), then proceed with attended Codex CLI bootstrap on `rb1`.

## 2026-02-16 19:10 EST (Codex)
- Area: unattended bootstrap advancement on `rb1-fedora` (Ollama model + Codex CLI prep)
- Status: Completed unattended bootstrap tasks that did not require user interaction: pulled `llama3.2:1b`, verified local inference success, confirmed live GPU utilization during run, installed Node/npm and Codex CLI on `rb1`, and cloned Cheney repo to `~/cheney` with subagent scope files present.
- Evidence: `ollama pull llama3.2:1b` success; `ollama run llama3.2:1b "Respond with exactly: GPU_OK"` => `GPU_OK`; GPU process sample captured during run (`/usr/local/bin/ollama`, bus `0000:01:00.0`, ~`1728 MiB`); `node --version` => `v22.22.0`; `npm --version` => `10.9.4`; `codex --version` => `codex-cli 0.101.0`; `codex login status` => `Not logged in`; `~/cheney` clone on `rb1` at commit `1b1dcf3` with `subagents/cheney-vessel-alpha/AGENTS.md` present.
- Next action: When user is back, complete interactive Codex login on `rb1`, then run reboot-survival validation (eGPU attached + fallback99 + Ollama) and record results.

## 2026-02-16 19:29 EST (Codex)
- Area: AI bootstrap rollback on `rb1-fedora` (environment-only scope)
- Status: Rolled back host-side AI tooling per request: removed Ollama service/binary/data, removed global Codex CLI, and removed host-local `~/cheney` clone on `rb1`. Preserved environment baseline (NVIDIA, fallback VLAN99, WoL, SSH hardening) and updated repo docs to mark AI work deferred.
- Evidence: On `rb1`, `systemctl is-active ollama` => `inactive`, `systemctl is-enabled ollama` => `not-found`, `command -v ollama` => absent, `command -v codex` => absent, `node --version` => `v22.22.0`, `npm --version` => `10.9.4`, no `~/.ollama` or `/usr/share/ollama` present. Baseline rechecks passed: `nvidia-smi` still shows internal+external GTX 1060 (`01:00.0`, `0f:00.0`), `enp0s20f0u6.99` remains `172.31.99.1/30`, and fallback pings `rb1 <-> rb2` succeed.
- Next action: Run reboot-survival validation on `rb1` with eGPU attached to confirm fallback99/NVIDIA persistence, then continue non-AI environment setup tasks.

## 2026-02-16 19:33 EST (Codex)
- Area: `rb1-fedora` reboot-survival validation (environment-only, eGPU attached)
- Status: Completed controlled reboot validation after AI rollback. `rb1` rebooted successfully with external eGPU attached, fallback VLAN99 persisted automatically, management access restored on both primary and fallback paths, and NVIDIA visibility remained intact for both internal and external GPUs.
- Evidence: Pre-boot ID `0bc5f921-616c-46cd-a126-a122423ab1ba`; post-boot ID `a66d1f72-dca6-4273-b07b-89ca59654a5d` (confirmed reboot). Poll loop observed host down then up (`REBOOT_CONFIRMED_ELAPSED=26s`). Post-boot checks: `enp0s20f0u6.99=172.31.99.1/30`, `nmcli fallback99 autoconnect=yes`, `rb1<->rb2` fallback pings `0%` loss, TCP/22 open on `172.31.99.1` from `rb2`, `nvidia-smi` shows GPUs `01:00.0` and `0f:00.0`, and AI rollback state preserved (`ollama`/`codex` absent, Node/npm present).
- Next action: Continue external eGPU acceptance matrix (cold/hot attach scenarios + workload benchmark), keeping AI bootstrap deferred until explicitly requested.

## 2026-02-16 19:41 EST (Codex)
- Area: scripted eGPU acceptance matrix harness + first automated scenario
- Status: Added reusable eGPU acceptance script `scripts/egpu_acceptance_matrix.sh` and executed the first scripted scenario (`reboot_attached_persistence`) with a passing result. Script output is now preserved in matrix + artifact logs for repeatable/resumable testing.
- Evidence: `notes/egpu-acceptance-matrix-20260216.md` now contains a `PASS` row for `reboot_attached_persistence` (`reboot=1`, elapsed `32s`, pre/post `lspci` + `nvidia-smi` external checks pass, fallback ping/interface checks pass). Artifact log saved at `notes/egpu-acceptance-artifacts/egpu-reboot_attached_persistence-20260216-193959.log`. Post-run spot checks confirm AI rollback state is still preserved (`ollama`/`codex` absent) with NVIDIA + fallback intact.
- Next action: Run next matrix scenarios (hot-attach and display/no-display variants), then add short non-AI workload benchmark evidence for external GPU path characterization.

## 2026-02-16 19:49 EST (Codex)
- Area: eGPU acceptance continuation + benchmark harness
- Status: Completed additional non-interactive acceptance coverage on `rb1-fedora` (cold-boot-attached pass, no-display attached pass, hot-attach software-rescan postcheck pass), added reusable benchmark script `scripts/egpu_hashcat_benchmark.sh`, and captured a short non-AI external GPU workload benchmark artifact. Updated runbook/readiness docs with current state and explicit user-attended remaining gates.
- Evidence: `notes/egpu-acceptance-matrix-20260216.md` now includes `PASS` rows for `cold_boot_attached` (reboot `44s`) and `hot_attach_idle_soft_rescan_postcheck`; artifacts at `notes/egpu-acceptance-artifacts/egpu-cold_boot_attached-20260216-194611.log`, `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle-soft_rescan-20260216-194731.log`, and `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle_soft_rescan_postcheck-20260216-194739.log`. Benchmark artifact `notes/egpu-acceptance-artifacts/egpu-benchmark-hashcat-external-20260216-194816.log` shows external GPU-only hashcat speed `1615.5 MH/s` with post-run utilization observed on bus `0F:00.0`.
- Next action: Run user-attended physical hot-attach (cable remove/reinsert) and external-display-sink scenarios, then continue Track B (`memory/` scaffold and RAG-decision notes).

## 2026-02-16 19:50 EST (Codex)
- Area: benchmark script validation
- Status: Executed the new reusable benchmark script end-to-end and confirmed it correctly enumerates devices, runs external-GPU-only hashcat benchmark, and writes timestamped artifacts for resumable comparisons.
- Evidence: `scripts/egpu_hashcat_benchmark.sh` executed with `--device-id 2 --hash-mode 1400`; artifact `notes/egpu-acceptance-artifacts/egpu-benchmark-hashcat-external-20260216-195036.log` shows speed `1608.6 MH/s` and post-run external GPU activity (`0F:00.0`, `utilization=61%`, `pstate=P0`).
- Next action: Complete user-attended physical hot-attach/external-display scenarios, then move to Track B memory scaffolding.

## 2026-02-16 19:51 EST (Codex)
- Area: memory scaffold + phase-1 RAG decision implementation
- Status: Implemented Track B baseline memory substrate under `memory/` with frontmatter templates, linked index, starter project/entity/rule notes, and a concrete RAG strategy decision note. Added lightweight lexical index helper script for resumable retrieval.
- Evidence: Created `memory/index.md`, `memory/templates/*.md`, `memory/projects/proj-rb1-fedora-env-baseline.md`, `memory/decisions/dec-rag-phase1-lexical-first.md`, `memory/entities/entity-rb1-fedora.md`, and `memory/rules/rule-memory-frontmatter-schema.md`. Added `scripts/memory_index.sh`; test run produced expected table output with ids/types/links across all memory notes.
- Next action: After user-attended eGPU physical tests, continue expanding memory with session summaries and decision notes using the new schema.

## 2026-02-16 20:11 EST (Codex)
- Area: user-attended eGPU physical cycle + sink-path gate
- Status: Executed user-attended physical detach/reattach cycle and captured a hotplug instability event (external GPU did not immediately re-enumerate; kernel ACPI/PCI hotplug warning/Oops observed). Recovered by reboot; post-recovery dual-GPU state and fallback path returned healthy. Ran matrix postcheck (`hot_attach_idle_physical_postcheck`) as `PASS`. Added display-sink detection helper and verified eGPU connectors are all disconnected in current hardware setup.
- Evidence: Failure artifact `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle-physical-20260216-195603.log`; post-recovery matrix artifact `notes/egpu-acceptance-artifacts/egpu-hot_attach_idle_physical_postcheck-20260216-200930.log`; display check artifact `notes/egpu-acceptance-artifacts/egpu-display-sink-check-20260216-201014.log` (`result=not_connected` on all eGPU connectors).
- Next action: Keep external-display scenario blocked until a real sink is connected to eGPU outputs; investigate repeatability/mitigation path for physical hot-attach kernel warnings before treating hot-attach as stable.

## 2026-02-16 20:18 EST (Codex)
- Area: external-display-sink gate completion
- Status: User connected a real display sink to eGPU output; sink-check now reports connected (`card2-DP-3`). Executed `attached_with_external_display` matrix scenario and recorded `PASS` while preserving management/fallback continuity checks.
- Evidence: Sink artifact `notes/egpu-acceptance-artifacts/egpu-display-sink-check-20260216-201756.log` (`result=connected`); matrix artifact `notes/egpu-acceptance-artifacts/egpu-attached_with_external_display-20260216-201759.log` (`PASS`); matrix row appended in `notes/egpu-acceptance-matrix-20260216.md`.
- Next action: Keep focus on physical hot-attach instability mitigation (ACPI/PCI warning path), then decide whether to run repeatability matrix across additional cable/device permutations.

## 2026-02-16 20:41 EST (Codex)
- Area: eGPU operating decision lock + next-phase planning kickoff
- Status: Recorded operator decision to defer additional hotplug tuning for now and proceed with recovery-first operations, given known temperamental behavior and validated recovery path. Updated memory graph, readiness notes, and top-level README priorities to shift from eGPU acceptance execution to next-phase planning tracks.
- Evidence: Added memory decision note `memory/decisions/dec-egpu-hotplug-defer-recovery-first.md`; updated project memory note `memory/projects/proj-rb1-fedora-env-baseline.md`; added planning runbook `runbooks/next-steps-planning-20260216.md`; updated `notes/egpu-readiness-rb1-fedora-20260216.md` with operating decision + recovery playbook; updated `README.md` routing/priorities.
- Next action: Execute Track 1 + Track 2 from `runbooks/next-steps-planning-20260216.md` (Fedora operational polish and continuity/recovery hardening), while keeping AI bootstrap deferred.

## 2026-02-16 20:49 EST (Codex)
- Area: Track 1 operational polish execution (`rb1-fedora`)
- Status: Implemented Track 1 host polish: resolved SSH root-login precedence issue with explicit early access-policy include, captured clean post-acceptance baseline snapshot, and reduced nonessential service surface by disabling `bluetooth` and `ModemManager`.
- Evidence: On host, `sshd -T` now reports `permitrootlogin without-password` + `passwordauthentication no`; baseline snapshot saved at `notes/rb1-operational-baseline-20260216-204915.md`; `systemctl is-enabled/is-active bluetooth ModemManager` now returns `disabled`/`inactive`.
- Next action: Execute Track 2 continuity/recovery hardening (reusable recovery script + post-incident checklist runbook section).

## 2026-02-16 20:55 EST (Codex)
- Area: Track 2 continuity/recovery hardening implementation
- Status: Added reusable `rb1` recovery validator script and dedicated incident-recovery runbook, then executed a live smoke validation. Initial strict service policy produced one expected FAIL row (`nvidia-powerd inactive`), validator policy was corrected to accept expected inactive state on this hardware, and rerun passed.
- Evidence: Added `scripts/rb1_recovery_validate.sh`; added `runbooks/rb1-egpu-incident-recovery.md`; matrix `notes/rb1-recovery-matrix-20260216.md` now includes `track2_smoketest` (`FAIL`, policy tuning) and `track2_smoketest_rerun` (`PASS`); PASS artifact at `notes/rb1-recovery-artifacts/rb1-recovery-track2_smoketest_rerun-20260216-205545.log`.
- Next action: Continue Track 4 memory workflow maturation while keeping this recovery validator as the standard post-incident/post-maintenance gate.

## 2026-02-16 20:58 EST (Codex)
- Area: Track 2 reboot-mode validation
- Status: Executed reboot-mode recovery validation (`--reboot`) to confirm post-reboot continuity against the new standard validator. Run completed `PASS` with boot-id change and full policy/network/GPU checks intact.
- Evidence: Matrix row `track2_reboot_validation` in `notes/rb1-recovery-matrix-20260216.md` (`reboot_elapsed=32s`, result `PASS`); artifact `notes/rb1-recovery-artifacts/rb1-recovery-track2_reboot_validation-20260216-205806.log`.
- Next action: Proceed with Track 4 memory workflow maturation.

## 2026-02-16 21:04 EST (Codex)
- Area: Track 4 memory workflow maturation implementation
- Status: Implemented weekly memory workflow pattern for fast session resume: added weekly-summary template, created first weekly summary note, added weekly memory operations runbook, and linked these in memory index/project notes. Verified lexical index output includes all new notes and link graph references.
- Evidence: Added `memory/templates/weekly-summary-template.md`, `memory/projects/week-2026-W08-summary.md`, `runbooks/memory-workflow-weekly.md`; updated `memory/index.md`, `memory/projects/proj-rb1-fedora-env-baseline.md`, `README.md`, and `runbooks/next-steps-planning-20260216.md`. `scripts/memory_index.sh memory` reports the new weekly summary/template entries with link counts.
- Next action: Maintain weekly summary + decision-note cadence; keep semantic/RAG layer deferred until trigger criteria in `memory/decisions/dec-rag-phase1-lexical-first.md` are met.

## 2026-02-16 21:52 EST (Codex)
- Area: OpenClaw headless API-key evaluation bootstrap on `rb1-fedora`
- Status: Implemented attended OpenClaw evaluation baseline on `rb1` without enabling unattended services. Installed OpenClaw CLI (`2026.2.15`), created isolated profile `rb1eval`, inspected major CLI capability surfaces (models/gateway/cron/plugins/approvals/memory/nodes/docs), and captured pre-key smoke artifact. Validated API-key wiring path with an intentional invalid key and confirmed provider reached OpenAI (`401` response), proving headless API-key mode is functional once real key is supplied.
- Evidence: `ssh rb1-fedora 'openclaw --version'` => `2026.2.15`; profile status + model baseline captured in `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-prekey-20260216-215225.log`; new runbook `runbooks/openclaw-api-key-smoke-rb1-fedora.md`; feature reconnaissance note `notes/openclaw-cli-feature-findings-20260216.md`; inventory/README checkpoints updated for resumability.
- Next action: Run one attended real-key smoke command from `runbooks/openclaw-api-key-smoke-rb1-fedora.md` and save `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-realkey-<timestamp>.log`, then decide whether to keep API-key mode or pivot back to OAuth for steady-state.

## 2026-02-16 22:30 EST (Codex)
- Area: OpenClaw attended real-key smoke execution + ephemeral cleanup
- Status: Ran attended real-key smoke on `rb1-fedora` using ephemeral stdin key transfer. Provider/model path executed successfully, but both attempts returned OpenAI rate-limit responses before completion (`gpt-5-mini`, then `gpt-4.1-nano`). Performed full key cleanup and verified no residual local/remote temp key files or active auth env state.
- Evidence: Artifacts `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-realkey-20260216-222828.log` and `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-realkey-retry-20260216-222853.log`; local staged key file removed (`/home/tdj/.openai_key_once` absent); remote temp file removed (`/tmp/openai_key_once` absent); post-cleanup agent probe on `rb1` returns `No API key found for provider "openai"`.
- Next action: Re-run the same attended smoke command after OpenAI rate-limit window resets (or with a higher-quota key) to capture `OPENCLAW_SMOKE_OK` artifact, then close this track.

## 2026-02-16 22:52 EST (Codex)
- Area: OpenClaw rollback and host cleanup on `rb1-fedora`
- Status: Removed OpenClaw tooling and related host state on request to reset AI bootstrap scope. Uninstalled global OpenClaw package and removed OpenClaw state directories; verified command/module/service absence and preserved non-AI baseline.
- Evidence: `ssh rb1-fedora 'npm uninstall -g openclaw; rm -rf /root/.openclaw /root/.openclaw-*'`; post-checks show `command -v openclaw` absent, no `/usr/local/lib/node_modules/openclaw`, and no `openclaw` systemd unit installed/enabled.
- Next action: Hold AI/bootstrap changes until explicit user restart; user will perform manual setup when ready.

## 2026-02-16 22:52 EST (Codex)
- Area: `rb1-fedora` root filesystem capacity correction
- Status: Diagnosed Fedora installer default LVM sizing issue (`/` at `15G`, 100% full) and expanded root LV online to consume free VG space.
- Evidence: `pvs/vgs` showed `fedora` VG free `459.35g`; executed `lvextend -r -l +100%FREE /dev/fedora/root`; post-check `lvs` => `root 474.35g`; `df -h /` => `475G size`, `451G avail`, `6%` used.
- Next action: Continue normal host setup with adequate disk headroom; keep AI/bootstrap changes deferred until explicitly resumed.

## 2026-02-17 00:23 EST (Codex)
- Area: OpenClaw LAN gateway troubleshooting (`rb1-fedora`, user `tdj`)
- Status: Resolved primary gateway target misconfiguration and brought LAN listener online. Root cause for the initial failure was `gateway.port=22` (SSH) in `/home/tdj/.openclaw/openclaw.json`, which caused WebSocket handshake failures against SSH. Updated config to `gateway.port=18789`, `gateway.bind=lan`, and restarted user gateway service.
- Evidence: `openclaw status --json` now reports gateway URL `ws://192.168.5.107:18789`, `reachable=true`, `error=null`; listener present on `0.0.0.0:18789` (`openclaw-gateway`, pid `66817`).
- Note: A pending device scope-upgrade request was present (`operator.approvals`, `operator.pairing`) and was reconciled in local device state (`~/.openclaw/devices/{paired,pending}.json`) to clear pairing deadlock during CLI access.
- Next action: Continue manual OpenClaw setup on default profile; if remote clients still fail, re-validate client token/url and approve any new device pairing requests.

## 2026-02-17 00:58 EST (Codex)
- Area: OpenClaw token-usage optimization research (`rb1-fedora`, user `tdj`)
- Status: Completed docs + live-config audit to identify why setup consumed high tokens. Key findings: current profile is effectively `tools.profile=full` (unset), bootstrap/context caps are unset (defaults apply), and bootstrap workspace files total ~11.7k chars before any conversation/tool schemas. Produced a concrete low-token operating profile for setup mode (tight bootstrap caps, reduced tool profile, lower reasoning/output budget).
- Evidence: Read-only checks only (no runtime config edits): `~/.openclaw/openclaw.json` shows `bootstrapMaxChars=null`, `bootstrapTotalMaxChars=null`, `tools.profile=null`, `commands.native=auto`, internal hooks enabled including `bootstrap-extra-files`; workspace file sizes (`AGENTS.md=7869`, `SOUL.md=1673`, `TOOLS.md=860`, `IDENTITY.md=629`, `USER.md=460`, `HEARTBEAT.md=168`). Doc references: OpenClaw context/configuration/pruning pages (`docs.openclaw.ai`).
- Next action: When user confirms, apply a temporary "setup-low-token" config profile and validate with one controlled command + usage check, then keep that profile until AI bootstrap design is finalized.

## 2026-02-17 01:13 EST (Codex)
- Area: OpenClaw auth remediation checkpoint (`rb1-fedora`, user `tdj`)
- Status: Confirmed security items #1 and #2 remain fixed (`gateway.auth.rateLimit` present; ineffective `gateway.nodes.denyCommands` entries removed). Ran supported device-token rotation + gateway restarts for item #3 and validated CLI agent path works (`openclaw agent --local` -> `HEALTH_OK`). User decision: defer LAN URL/probe-path perfection for now and proceed in CLI-first mode.
- Evidence: `openclaw devices rotate` completed (`ok=true`), gateway service active on `0.0.0.0:18789`, `openclaw health --json` returns `ok=true`, `openclaw agent --local --agent main --message "Respond with exactly: HEALTH_OK"` returns `HEALTH_OK`. Local token secret synced to `/home/tdj/.config/openclaw/gateway.token` (`600` perms, 49 bytes).
- Next action: Keep OpenClaw in CLI-first mode while user finalizes preferred remote/LAN access method; avoid further gateway URL/probe churn unless requested.

## 2026-02-17 01:35 EST (Codex)
- Area: OpenClaw efficient routing plan documentation
- Status: Added a dedicated hybrid routing plan as requested: local-first assistant path using `qwen2.5` on `Ollama` with Codex escalation for high-complexity/high-risk tasks. Plan explicitly prioritizes assistant quality over pure efficiency and records hardware-fit assumptions for dual GTX 1060 cards.
- Evidence: Added `notes/efficient-routing-plan.md` with routing policy, escalation triggers, no-training requirement, hardware-fit notes, implementation steps, and acceptance criteria.
- Next action: User will perform additional research; when ready, execute phase-1 implementation (install `Ollama`, pull local model, wire OpenClaw primary+fallback routing, run A/B validation).

## 2026-02-17 03:09 EST (Codex)
- Area: OpenClaw phase-1 routing implementation + validation (`rb1-fedora`, user `tdj`)
- Status: Implemented the hybrid local-first routing plan on `rb1` (`ollama/qwen2.5:7b` primary, `openai-codex/gpt-5.3-codex` fallback), added reusable validation harness, and executed full validation matrix with artifacts. Local routing and coder-path checks pass; forced fallback test currently fails with `fetch failed` when Ollama is unavailable.
- Evidence: Added `scripts/openclaw_routing_validation.sh`; captured baseline `notes/openclaw-artifacts/openclaw-routing-baseline-20260217-023746.log`; captured clean validation artifacts `notes/openclaw-artifacts/openclaw-routing-validation-20260217-030356.log` + `.jsonl`; updated matrix `notes/openclaw-routing-validation-20260217.md`; implementation summary note `notes/openclaw-routing-implementation-20260217.md`. Post-run host checks: `systemctl is-active/is-enabled ollama` => `active/enabled`; `openclaw models status` shows default `ollama/qwen2.5:7b` and fallback `openai-codex/gpt-5.3-codex`.
- Next action: Run fallback remediation pass (error-class behavior + session hygiene), then rerun `scripts/openclaw_routing_validation.sh` and compare against the 2026-02-17 baseline.

## 2026-02-17 03:26 EST (Codex)
- Area: OpenClaw fallback remediation pass (`rb1-fedora`, user `tdj`)
- Status: Completed targeted remediation run: added session-store reset hygiene and explicit manual Codex backstop path to the routing validator. Reran matrix and confirmed mitigation works end-to-end: native forced fallback still fails on local provider transport error (`fetch failed`), but manual backstop succeeds and restores local-first state.
- Evidence: Updated `scripts/openclaw_routing_validation.sh`; new artifacts `notes/openclaw-artifacts/openclaw-routing-validation-20260217-032014.log` and `.jsonl`; matrix appended in `notes/openclaw-routing-validation-20260217.md` with `fallback_manual_backstop` => `PASS` (`provider=openai-codex`, `model=gpt-5.3-codex`, `FALLBACK_PATH_OK`). Post-run checks: `ollama` active, OpenClaw default model restored to `ollama/qwen2.5:7b`, fallback remains `openai-codex/gpt-5.3-codex`, session utilization reset to low (`3%`).
- Next action: Implement a dedicated operational wrapper for normal agent turns using the same manual backstop logic, then run short real-task benchmark to measure token/cost impact.

## 2026-02-17 03:39 EST (Codex)
- Area: OpenClaw operational safe-turn wrapper implementation (`rb1-fedora`, user `tdj`)
- Status: Implemented and validated routine-use wrapper `scripts/openclaw_agent_safe_turn.sh` that runs one agent turn and automatically backstops to Codex when local transport-class failures occur, then restores local-primary model state.
- Evidence: Added script `scripts/openclaw_agent_safe_turn.sh`; normal-path artifact `notes/openclaw-artifacts/openclaw-safe-turn-20260217-033835.json` shows `backstopUsed=0` and final `ollama/qwen2.5:7b`; forced-outage artifact `notes/openclaw-artifacts/openclaw-safe-turn-20260217-033846.json` shows attempt1 `fetch failed` on `ollama`, automatic backstop attempt2 `SAFE_WRAPPER_OK_FALLBACK` on `openai-codex/gpt-5.3-codex`, and cleanup restoring model to `ollama/qwen2.5:7b`. Post-check confirms `systemctl is-active ollama` => `active`.
- Next action: Run short real-task benchmark using `scripts/openclaw_agent_safe_turn.sh --json`, measure local vs backstop usage share/token impact, and refine trigger thresholds.

## 2026-02-17 03:48 EST (Codex)
- Area: OpenClaw safe-turn benchmark + threshold tuning (`rb1-fedora`, user `tdj`)
- Status: Added benchmark runner `scripts/openclaw_safe_turn_benchmark.sh`, executed short case-set benchmarks, and tuned wrapper policy by adding local-runtime precheck (default on) to skip wasted local attempts when Ollama is unavailable. Re-ran benchmark with tuned wrapper and verified stable success with expected provider split.
- Evidence: New benchmark artifacts: `notes/openclaw-safe-turn-benchmark-20260217-034221.md` + `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-034221.{jsonl,log}` (baseline), and `notes/openclaw-safe-turn-benchmark-20260217-034700.md` + `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-034700.{jsonl,log}` (post-tune). Post-tune summary: `count=7`, `success=7`, `backstop=1`, `final_provider_ollama=6`, `final_provider_openai_codex=1`, `avg_wrapper_elapsed_ms=11106`, forced-outage wrapper elapsed `12219ms`. Direct outage validation artifact `notes/openclaw-artifacts/openclaw-safe-turn-20260217-034446.json` shows precheck marker `local_precheck_unavailable` and successful Codex backstop with model restored to `ollama/qwen2.5:7b`.
- Next action: Run benchmark sets on real mixed prompts and tune backstop trigger policy to meet explicit token budget / backstop-rate targets.

## 2026-02-17 03:56 EST (Codex)
- Area: OpenClaw real-prompt benchmark + threshold policy lock (`rb1-fedora`, user `tdj`)
- Status: Ran real workload prompt profile through benchmark runner and recorded concrete operational thresholds for reliability, latency, and cloud-token guardrails. Wrapper precheck/backstop flow remained stable; host state restored cleanly after forced outage scenario.
- Evidence: Real-profile benchmark artifacts `notes/openclaw-safe-turn-benchmark-20260217-035520.md` + `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-035520.{jsonl,log}`; summary `count=7`, `success=7`, `backstop=1`, healthy backstop sample `0/6`, forced-outage wrapper elapsed `11635ms`, cloud final tokens total `9926`. Added policy note `notes/openclaw-safe-turn-thresholds-20260217.md` with targets and breach actions; updated `README.md`, `notes/openclaw-routing-implementation-20260217.md`, and `notes/efficient-routing-plan.md`.
- Next action: Keep periodic real-prompt benchmark cadence and adjust wrapper trigger policy only when thresholds in `notes/openclaw-safe-turn-thresholds-20260217.md` are breached.

## 2026-02-17 04:16 EST (Codex)
- Area: unattended overnight reliability probe tooling (`rb1`-targeted)
- Status: Implemented low-risk overnight probe runner and summary scripts for 30-minute unmanaged checks with JSONL/log artifacts, plus on-host execution support in the safe-turn wrapper via `--host local`.
- Evidence: Added `scripts/openclaw_overnight_probe.sh`, `scripts/openclaw_overnight_probe_summary.sh`, `runbooks/openclaw-overnight-probe.md`; updated `scripts/openclaw_agent_safe_turn.sh` (`--host local` support), `README.md`, and `runbooks/next-steps-planning-20260216.md`. Smoke test pass artifact: `notes/openclaw-artifacts/overnight-probe-20260217-041312.{jsonl,log}` with summary `notes/openclaw-overnight-probe-summary-20260217-041416.md`.
- Next action: Sync updated repo to `rb1`, launch detached overnight probe on `rb1` with `--host local`, and verify active PID plus first cycle row.

## 2026-02-17 04:18 EST (Codex)
- Area: overnight unmanaged probe launch on `rb1`
- Status: Pushed commit `edf8d2b` and deployed repo to `/home/tdj/cheney` on `rb1`; started detached probe on-host (`--host local`, 30-minute interval) so local client sleep does not interrupt runs. Initial cycle completed successfully.
- Evidence: `rb1` process `pid=119319` (`bash scripts/openclaw_overnight_probe.sh --host local --interval-sec 1800 --cycles 0 --mode gateway`); launch log `notes/openclaw-artifacts/overnight-probe-launch-20260217-041629.out`; active artifact pointer `notes/openclaw-artifacts/overnight-probe.latest_jsonl` => `/home/tdj/cheney/notes/openclaw-artifacts/overnight-probe-20260217-041629.jsonl`; cycle-1 summary `ok=1 provider=ollama backstop=0 wrapper_elapsed_ms=7247`; summary command on rb1 passes.
- Next action: Leave probe unmanaged overnight, then run `scripts/openclaw_overnight_probe_summary.sh` on `rb1` in the morning and commit resulting artifact pointers/findings.

## 2026-02-17 14:55 EST (Codex)
- Area: overnight probe stop + human-readable report
- Status: Stopped unmanaged overnight probe on `rb1` and generated a detailed human-readable report with per-cycle metrics/excerpts, interval behavior, and outlier analysis.
- Evidence: Probe run artifact `notes/openclaw-artifacts/overnight-probe-20260217-041629.jsonl` (`21/21` success, no errors/backstops, all `ollama/qwen2.5:7b`); supporting logs `notes/openclaw-artifacts/overnight-probe-20260217-041629.log` and `notes/openclaw-artifacts/overnight-probe-launch-20260217-041629.out`; report `notes/openclaw-overnight-reliability-report-20260217.md`.
- Next action: Decide whether to keep persistent-session probe behavior (context growth) or add periodic agent/session reset for flatter latency/token usage in future unattended runs.

## 2026-02-17 15:08 EST (Codex)
- Area: `rb1` controlled reboot validation after eGPU enclosure noise report
- Status: Executed recovery validator with reboot to power-cycle `rb1` and verify post-boot continuity + GPU visibility. Validation passed end-to-end.
- Evidence: `scripts/rb1_recovery_validate.sh --scenario egpu_enclosure_noise_reboot_20260217 --reboot` => `PASS`; reboot elapsed `42s`; matrix row appended in `notes/rb1-recovery-matrix-20260217.md`; artifact `notes/rb1-recovery-artifacts/rb1-recovery-egpu_enclosure_noise_reboot_20260217-20260217-150602.log`; post-check `nvidia-smi` shows internal `00000000:01:00.0` and external `00000000:0F:00.0` both detected.
- Next action: Observe enclosure acoustics physically after cold restart; if noise persists, keep eGPU detached when idle and schedule hardware inspection/cleaning.

## 2026-02-17 16:08 EST (Codex)
- Area: Ollama-only dual-GPU stress execution + safety supervision (`rb1`)
- Status: Executed supervised local-only stress run on `rb1` with no Codex fallback path, using concurrent `qwen2.5:7b` and `qwen2.5-coder:7b` requests plus thermal/kernel watchdog. Run completed and was stopped on request.
- Evidence: Final artifact set synced to repo under `notes/ollama-stress-20260217-152444/` (`requests.jsonl`, `nvidia-monitor.csv`, `run.log`, `watchdog.log`); summary report `notes/ollama-stress-report-20260217.md`. Final metrics: `185/185` success, avg throughput `22 tok/s`, max observed GPU temp `76C`, watchdog stop events `0`, hard kernel fault detections `0`, both GPUs actively utilized.
- Next action: Decide whether to preserve this watchdog profile as default for unattended local stress/benchmark runs, and whether to bias workload routing toward the faster `qwen2.5:7b` path for routine assistant tasks.

## 2026-02-17 16:11 EST (Codex)
- Area: maintenance prep checkpoint (suspend AI services)
- Status: Collected current service/process state on `rb1` for requested suspension step; no stop/disable actions applied yet due checkpoint hold.
- Evidence: `ollama.service` is `enabled/active` (system); `openclaw-gateway.service` is `enabled/active` (user). No distinct `clawdbot` unit found in systemd listings. Live processes include `ollama serve` and `openclaw-gateway`.
- Next action: On instruction, stop+disable `ollama.service` and stop+disable user `openclaw-gateway.service` (or target explicit `clawdbot` unit name if provided), then verify zero running processes.

## 2026-02-17 16:56 EST (Codex)
- Area: external infra note (`rb2`/TrueNAS) impacting current lab continuity
- Status: Investigated temporary TrueNAS inaccessibility on `rb2` and restored VM `100` memory back to fixed `8192` (`balloon: 0`). Guest came back healthy after warm-up; this is recorded as an operational checkpoint only (no cheney project baseline/planning changes).
- Evidence: `qm config 100` shows `memory: 8192`; `kvm -id 100` launch arg includes `-m 8192`; post-boot probes on `192.168.5.100` show `80/443/22/445/2049` open; `curl -k -I https://192.168.5.100` returned `HTTP/2 302`; serial-console checks show `midclt call system.state => READY`, `middlewared` active, and `nginx` active.
- Next action: For future outages, allow a short middleware/web warm-up window after restart before declaring failure; if steady-state failures recur, capture service logs before tuning.

## 2026-02-20 14:50 EST (Codex)
- Area: OpenClaw + Ollama drift check rerun (`rb1-admin`)
- Status: Re-ran the prior routing validation and both safe-turn benchmark profiles (real + control) after several days. Setup remains operational with model state/service state restored post-run (`default=ollama/qwen2.5:7b`, fallback=`openai-codex/gpt-5.3-codex`, `ollama` and user `openclaw-gateway` active).
- Evidence: Routing artifacts `notes/openclaw-routing-validation-20260220.md` and `notes/openclaw-artifacts/openclaw-routing-validation-20260220-144405.{jsonl,log}`; real benchmark artifacts `notes/openclaw-safe-turn-benchmark-20260220-144657.md` and `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260220-144657.{jsonl,log}`; control benchmark artifacts `notes/openclaw-safe-turn-benchmark-20260220-144833.md` and `notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260220-144833.{jsonl,log}`. Key results: real and control both `7/7` success with `backstop_count=1`; native forced fallback still fails with `fetch failed` but manual/precheck backstop path passes; routing improved vs prior run (`route_05_transform` and `route_09_python` now pass), with one remaining routine prompt miss (`route_07_ping_cmd`).
- Next action: Keep current wrapper/backstop policy as primary reliability guard; if desired, tighten `route_07_ping_cmd` prompt assertion to avoid process-tool side responses.

## 2026-02-20 16:16 EST (Codex)
- Area: `rb1` manual backup infrastructure on TrueNAS HDD
- Status: Implemented manual-only backup path from `rb1` to a new TrueNAS HDD dataset, aligned to operator policy of keeping only `2-3` snapshots and avoiding timer-driven rotation.
- Evidence:
  - Created dataset `oyPool/rb1AssistantBackups` on TrueNAS (`/mnt/oyPool/rb1AssistantBackups`, `quota=30G`).
  - Added dedicated `rb1` SSH key and alias (`~/.ssh/id_ed25519_truenas_rb1`, host alias `truenas-rb1`) and authorized it for `macmini_bu`.
  - Installed script on host: `/home/tdj/bin/rb1_truenas_backup.sh` (`create/list/prune`).
  - Validation run: created snapshots `initial-rb1-assistant-3` and `baseline-2026-02-20`; prune test kept 2 snapshots and removed older test snapshots.
  - Repo docs/scripts updated: `scripts/rb1_truenas_backup.sh`, `runbooks/rb1-manual-truenas-backup.md`, `inventory/network-remote-access.md`.
- Next action: Keep manual cadence before risky changes; run `prune 2` or `prune 3` after each verified snapshot.

## 2026-02-20 16:56 EST (Codex)
- Area: `rb1-fedora` management NIC cutover (USB-C chain -> direct USB3 Ethernet) with before/after validation
- Status: Completed guarded cutover to the new direct USB3 adapter and validated post-cutover primary/fallback networking. Management moved from `192.168.5.107` (`enp0s20f0u6`) to `192.168.5.114` (`enp0s20f0u1c2`); fallback VLAN moved from `enp0s20f0u6.99` (`fallback99`) to `fb99` (`fallback99-new`) at `172.31.99.1/30`.
- Evidence: Full artifact set under `notes/rb1-nic-cutover-20260220-163353/` including pre/post state captures, pre/post `iperf3` matrix, and WoL packet tests; summary report `notes/rb1-nic-cutover-20260220-163353/summary.md`. Throughput delta is negligible (+1 to +2 Mbps in 1Gb class tests; UDP 500M unchanged, 0% loss). WoL capability regressed on the active adapter: `ethtool -s enp0s20f0u1c2 wol g` => `Operation not supported` (while old Realtek path supported `Wake-on: g`).
- Next action: If hardware WoL on `rb1` remains required, either (a) revert to a WoL-capable NIC path, or (b) replace the new USB3 adapter with a chipset/driver path that exposes hardware WoL.

## 2026-02-20 16:58 EST (Codex)
- Area: `tsDeb` watchdog mapping alignment after `rb1` NIC/IP cutover
- Status: Updated `/usr/local/sbin/tsdeb-watchdog.sh` in VM `101` to track current node mappings so watchdog checks and WoL sends target the correct endpoints.
- Evidence: `qm guest exec 101 -- ...` now shows `check_and_wake rb1 192.168.5.114 6c:6e:07:21:02:3e`, `rb2 192.168.5.108 00:05:1b:de:7e:6e`, `mba 192.168.5.66 00:24:32:16:8e:d3`; service logs show all three nodes `up`; timer remains `active/enabled`.
- Next action: If `rb1` remains on the current adapter, treat WoL for `rb1` as best-effort only due driver-level unsupported state.

## 2026-02-20 17:14 EST (Codex)
- Area: `rb1` AX88179A WoL retest (post-cutover)
- Status: Re-tested the new adapter for advertised WoL support by forcing USB config mode and driver binding. In forced vendor mode (`bConfigurationValue=1` -> `ax88179_178a`), WoL flags appear and `ethtool -s ... wol g` succeeds; however, carrier drops (`Link status: 0`) and the interface is not usable for active networking on this host. Stable mode remains USB config `2` with `cdc_ncm` (networking OK, no hardware WoL exposure).
- Evidence: `notes/rb1-nic-cutover-20260220-163353/wol-retest-ax88179-rebind.log` and `notes/rb1-nic-cutover-20260220-163353/wol-retest-current-state.txt`; kernel lines include `Failed to read reg index 0x0040: -32` in forced vendor mode.
- Next action: Treat current adapter WoL as non-usable on Linux/Fedora in stable mode; if WoL is mandatory, switch back to a WoL-capable adapter path (or test alternate kernel/driver package out-of-band).

## 2026-02-20 17:27 EST (Codex)
- Area: `rb1` eGPU-primary + USB-fallback network role swap and validation
- Status: Completed staged network role change with eGPU Ethernet (`enp20s0u1`) as preferred route (`egpu-primary`, metric `80`) and USB3 adapter (`enp0s20f0u1c2`, metric `103`) as fallback. Legacy Realtek adapter was physically removed per operator sequence.
- Evidence: Failover/run-state artifact `notes/rb1-nic-cutover-20260220-163353/egpu-primary-failover-validation.txt` shows default route on `192.168.5.115` when primary is up and automatic fallback to `192.168.5.114` when `egpu-primary` is brought down; `rb2` pings to fallback/VLAN99 remained `0%` loss. Throughput comparison artifact `notes/rb1-nic-cutover-20260220-163353/egpu-vs-fallback-throughput.txt`: eGPU path `929 Mbps` sender (P1, 20s) vs fallback path `933 Mbps` sender (P1, 20s), both 1Gb-class.
- Evidence: eGPU WoL capture artifacts `notes/rb1-nic-cutover-20260220-163353/egpu-primary-wol-send.txt` and `.../egpu-primary-wol-pcap.txt`; `enp20s0u1` reports `Supports Wake-on: pg`, `Wake-on: g`. Updated watcher mapping in VM `101` to ping stable IP `192.168.5.114` while sending WoL to eGPU MAC `90:20:3a:1b:e8:d6`.
- Next action: Optional reboot-survival validation with both NICs present to confirm route-metric preference and WoL setting persistence across boot.

## 2026-02-20 17:31 EST (Codex)
- Area: `rb1` eGPU-primary reboot-survival validation
- Status: Reboot validation passed for the new dual-path network design. `rb1` returned in ~`26s`, boot ID changed as expected, and route/WoL persistence matched design (`egpu-primary` metric `80`, USB fallback metric `300`, eGPU `Wake-on: g`).
- Evidence: `notes/rb1-nic-cutover-20260220-163353/reboot-validation-20260220-172904.log` and summary `notes/rb1-nic-cutover-20260220-163353/reboot-validation-summary-20260220.md`; `rb2` pings post-boot were `0%` loss to `192.168.5.115`, `192.168.5.114`, and `172.31.99.1`.
- Evidence: Post-reboot failover sanity also passed: disabling `egpu-primary` moved default route to `192.168.5.114` with `0%` loss to fallback IP/VLAN; restoring `egpu-primary` returned default route to `192.168.5.115`.
- Next action: Keep this topology and periodically re-check eGPU link stability; if TB/eGPU path destabilizes, fallback route remains immediate recovery path.

## 2026-02-20 20:20 EST (Codex)
- Area: Ollama overnight reliability/efficiency soak setup (`rb1-fedora`)
- Status: Added local-only soak runner + summary tooling and launched unattended soak on `rb1` at 30-minute intervals to run lightweight prompts against `qwen2.5:7b` and `qwen2.5-coder:7b` with thermal guard.
- Evidence: New scripts `scripts/ollama_overnight_soak.sh` and `scripts/ollama_overnight_soak_summary.sh`; detached process on `rb1` `pid=24701`; launch output `notes/ollama-artifacts/ollama-overnight-launch-20260220-202015.out`; active JSONL pointer `notes/ollama-artifacts/ollama-overnight-soak.latest_jsonl` => `/home/tdj/cheney/notes/ollama-artifacts/ollama-overnight-soak-20260220-202015.jsonl`; initial cycle produced 4/4 successful rows with max observed GPU temp `63C`.
- Next action: Let soak run overnight unmanaged, then execute `scripts/ollama_overnight_soak_summary.sh` in the morning and decide routing/threshold adjustments from results.

## 2026-02-21 12:38 EST (Codex)
- Area: Ollama overnight soak stop + results summary (`rb1-fedora`)
- Status: Stopped the unattended overnight Ollama soak and generated a human-readable summary report.
- Evidence: Run JSONL `notes/ollama-artifacts/ollama-overnight-soak-20260220-202015.jsonl` with `count=132`, `success=132`, `failure=0`, `avg_elapsed_ms=3286`, `p95_elapsed_ms=6341`, `max_gpu_temp_c=63`, window `2026-02-21T01:20:17Z -> 2026-02-21T17:27:48Z`; summary file `notes/ollama-overnight-soak-summary-20260221-123829.md`.
- Note: Process required force stop (`SIGKILL`) after `SIGTERM` did not terminate promptly; likely script-stop handling edge during sleep/trap cycle.
- Next action: Decide whether to patch stop behavior for graceful termination and whether to convert this soak into a reusable manual check profile.

## 2026-02-21 15:02 EST (Codex)
- Area: OpenClaw router trial v2 implementation (`rb1-fedora` live-test profile)
- Status: Implemented `basic-local-v2` routing in `scripts/openclaw_agent_safe_turn.sh` with tier policy (`local -> low -> high`), task classes (`basic`, `coding_basic`, `normal`, `high_risk`), force-tier overrides, latency escalation guards (`local>10000ms`, `low>20000ms`), and unified router telemetry logging.
- Evidence: Added `scripts/openclaw_router_live_summary.sh` and `runbooks/openclaw-router-live-trial-v2.md`; updated policy docs (`notes/efficient-routing-plan.md`, `notes/openclaw-safe-turn-thresholds-20260217.md`). Validation runs:
  - `basic`: target `local`, escalated `local -> low` on `local_latency_threshold`, final `openai-codex/gpt-5.3-codex-spark`, `rc=0`.
  - `normal`: target `low`, final `openai-codex/gpt-5.3-codex-spark`, `rc=0`.
  - `high_risk`: target `high`, final `openai-codex/gpt-5.3-codex`, `rc=0`.
  - force-tier check (`--force-tier high`) correctly pinned to high tier.
- Next action: Use normal live prompts and monitor `notes/openclaw-artifacts/openclaw-router-decisions.jsonl`; summarize periodically with `scripts/openclaw_router_live_summary.sh` and tune thresholds only on sustained breach.

## 2026-02-21 15:12 EST (Codex)
- Area: OpenClaw router tier semantics fix (`normal`/`high` cloud behavior)
- Status: Updated routing wrapper and docs so both cloud tiers use `openai-codex/gpt-5.3-codex`, with tiered thinking defaults: `normal/low=medium`, `high/high_risk=high` (local remains `off`). Removed Spark from automatic high-tier resolution candidates for this profile.
- Evidence:
  - Script changes: `scripts/openclaw_agent_safe_turn.sh` (`--thinking` now acts as optional override; per-tier thinking defaults; low-tier default model set to `openai-codex/gpt-5.3-codex`; attempt telemetry now records `thinking`).
  - Doc sync: `runbooks/openclaw-router-live-trial-v2.md`, `notes/efficient-routing-plan.md`, `notes/openclaw-safe-turn-thresholds-20260217.md`.
  - Validation run artifacts: `notes/openclaw-artifacts/openclaw-safe-turn-20260221-151138.json` (`taskClass=normal`, `chosenTier=low`, `final.model=gpt-5.3-codex`, `final.thinking=medium`) and `notes/openclaw-artifacts/openclaw-safe-turn-20260221-151201.json` (`taskClass=high_risk`, `chosenTier=high`, `final.model=gpt-5.3-codex`, `final.thinking=high`).
- Next action: Continue live usage and monitor `notes/openclaw-artifacts/openclaw-router-decisions.jsonl` for latency/escalation drift before any further routing-policy changes.

## 2026-02-21 15:54 EST (Codex)
- Area: OpenClaw truth-guard hardening + fake-output forensics (`rb1-fedora`)
- Status: Implemented verified write and anti-fake guardrails, validated on `rb1`, and reduced dangerous plugin surface by disabling unused high-risk plugins.
- Changes:
  - Added `scripts/openclaw_verified_codegen.sh` (structured output contract, allowlisted writes, static safety scan, optional Codex safety gate, SHA-256 write verification, fake-claim detection, incident/event logs, automatic correction feedback to agent session).
  - Added `scripts/openclaw_fake_output_audit.sh` (session-history forensic scanner for side-effect claims; optional append to incident log).
  - Added runbook `runbooks/openclaw-verified-write-and-anti-fake.md`.
  - Added memory checkpoint note `memory/projects/proj-openclaw-truth-guard.md` and linked it in `memory/index.md`.
- RB1 validation evidence:
  - Verified write run: `notes/openclaw-artifacts/openclaw-verified-codegen-20260221-154818.json` (`writeVerified=true`, `codexAllow=true`, target `/home/tdj/feb21-testMenu.py`).
  - On-host checks: `/home/tdj/feb21-testMenu.py` exists; `sha256` matches wrapper record; `python3 -m py_compile` passed.
  - Historical fake-claim backfill: `scripts/openclaw_fake_output_audit.sh --session-file /home/tdj/.openclaw/agents/main/sessions/5d8fdc27-8366-4624-b85c-c39bc1cd09ad.jsonl` appended incidents to `notes/openclaw-artifacts/openclaw-fake-output-incidents.jsonl`.
  - Negative test (forced fake claim): `notes/openclaw-artifacts/openclaw-verified-codegen-20260221-155326.json` (`fakeDetected=true`, `correctionSent=true`), confirming detection now scans all attempts and final output.
- Plugin risk reduction on rb1:
  - Disabled: `phone-control`, `device-pair`.
  - Remaining enabled plugins: `memory-core`, `talk-voice`.
- Next action: Keep using `scripts/openclaw_verified_codegen.sh` for any file-writing tasks; periodically audit session claims and review whether to disable `talk-voice` for tighter minimal surface.

## 2026-02-21 16:21 EST (Codex)
- Area: OpenClaw TUI live-status blurb + Cognee phase-0 pilot scaffold (`rb1-fedora`)
- Status: Implemented reversible host patch workflow to add live footer action/model/tier blurb in OpenClaw TUI, applied patch on `rb1`, and passed syntax/health smoke checks. Added Cognee phase-0 prep artifacts (safe ingest scope manifest + rb1 env probe) without changing active OpenClaw routing.
- Evidence:
  - New TUI tooling: `scripts/openclaw_tui_live_blurb_transform.mjs`, `scripts/rb1_openclaw_tui_live_blurb_patch.sh`, `scripts/rb1_openclaw_tui_live_blurb_smoke.sh`, `scripts/rb1_openclaw_tui_live_blurb_restore.sh`, runbook `runbooks/openclaw-tui-live-blurb-rb1.md`.
  - Host patch applied with backups:
    - `/usr/local/lib/node_modules/openclaw/dist/tui-DW-D2_SI.js` (`3a0119... -> d8c1be...`)
    - `/usr/local/lib/node_modules/openclaw/dist/tui-CRTpgJsf.js` (`5bd88b... -> ec832e...`)
    - backups: `*.cheney-live-blurb-v1.bak`
  - Marker check on rb1: both files include `CHENEY_TUI_LIVE_BLURB_V1`, `inferFooterTier`, and ``action ${activityStatus}``.
  - Smoke checks passed: `scripts/rb1_openclaw_tui_live_blurb_smoke.sh rb1-admin` (`openclaw --version`, `openclaw status --json`, `openclaw health --json` all pass).
  - Additional agent sanity passed: `openclaw agent --local --agent main --message "Respond with exactly: TUI_PATCH_AGENT_OK"` returned `TUIPATCH_AGENT_OK`.
  - Cognee prep artifacts:
    - `scripts/cognee_memory_scope_build.sh` generated `notes/cognee/cognee-scope-manifest.txt` (`88` markdown files).
    - `scripts/cognee_env_probe.sh rb1-admin` generated `notes/cognee/cognee-env-probe-20260221-162022.md`.
    - fit/pilot docs added: `notes/cognee-fit-assessment-20260221.md`, `runbooks/cognee-memory-pilot-rb1.md`.
- Next action: User can run an attended visual TUI check for live footer behavior; if approved, execute Cognee phase-1 isolated pilot from `runbooks/cognee-memory-pilot-rb1.md` with no router changes.

## 2026-02-21 19:19 EST (Codex)
- Area: Cognee phase-1 native-host validation + backup precheck (`rb1-fedora`)
- Status: Pivoted from container-only pilot to host-native Python 3.12 execution on `rb1` to test whether containerization caused `cognify` failures. Verified it does not: the same `sqlite3 OperationalError: database is locked` occurs during `cognee-cli cognify` on native path with default settings.
- Evidence:
  - Native runtime bootstrap on `rb1` using `uv` + Python `3.12.12`, environment under `/home/tdj/cognee-native`.
  - Failing native run artifacts: `notes/cognee/pilot-phase1-native-20260221-185316-rerun/pilot-run.log` (lock errors during `extract_graph_from_data`).
  - Backup precheck failure to TrueNAS destination: `/home/tdj/bin/rb1_truenas_backup.sh create ...` failed with `Input/output error`; direct remote write tests to `/mnt/oyPool/rb1AssistantBackups` also fail; TrueNAS reports `pool I/O is currently suspended` for `oyPool/rb1AssistantBackups`.
- Mitigation in progress:
  - Updated native runner `/home/tdj/cognee-native/run_phase1_native.sh` to reset Cognee storage each run and use `--chunks-per-batch 1` for `cognify` to reduce sqlite write contention.
  - Active run: `notes/cognee/pilot-phase1-native-20260221-190536-batch1` (still in `cognify` at log time, with `lock_count=0`, `success_count=40`, no search artifacts yet).
- Next action: Keep monitoring `batch1` run to completion; if stable, persist this as interim pilot profile. Separately, recover TrueNAS pool writeability before requiring new snapshots there.

## 2026-02-21 19:22 EST (Codex)
- Area: TrueNAS `oyPool` suspension root-cause evidence (`rb2-pve` VM100)
- Status: Identified likely root cause as USB passthrough storage disconnect/reset, not RAM allocation and not immediate media-failure signature.
- Evidence:
  - `zpool status -xv` inside TrueNAS: `oyPool state: SUSPENDED`, action points to I/O failures; single vdev shows `READ=3 WRITE=4.20K` errors.
  - TrueNAS guest kernel timeline (`2026-02-20 16:44:31 PST`): `usb 8-2: USB disconnect`, `sd ... DID_NO_CONNECT`, multiple `I/O error, dev sdb ... WRITE`, then `WARNING: Pool 'oyPool' has encountered an uncorrectable I/O failure and has been suspended`.
  - Same device re-attaches at `2026-02-20 16:44:32 PST` as ASMedia bridge `idVendor=174c,idProduct=55aa` and disk node changes (`sdb` -> `sdd`).
  - Proxmox host logs around same window show USB reset/cache-sync failure events on the 5TB device path (`sdb`), consistent with link instability.
  - SMART health on affected disk (`/dev/sdd`, Toshiba HDWE150) reports `PASSED` with `Reallocated=0`, `Pending=0`, `Offline_Uncorrectable=0`, `CRC=0`; this supports transient transport/passthrough fault as primary suspect.
- Additional context:
  - VM100 config uses USB passthrough (`usb0: 1058:2647`, `usb1: 174c:55aa`) for data disks.
  - New backup writes to `/mnt/oyPool/rb1AssistantBackups` remain blocked while pool is suspended.
- Next action: Recover pool (`zpool clear oyPool` + write validation + scrub) after confirming USB path stability; medium-term harden by reducing USB passthrough fragility.

## 2026-02-21 19:26 EST (Codex)
- Area: TrueNAS `oyPool` non-destructive recovery + backup path restore (`rb2` VM100)
- Status: Executed guarded recovery without deleting pool data; `oyPool` restored from `SUSPENDED` to `ONLINE` and backup writes resumed.
- Actions taken:
  - Ran `zpool clear oyPool` in VM100.
  - Verified post-clear pool health (`READ/WRITE/CKSUM` all `0`, `errors: No known data errors`).
  - Wrote a marker file (kept in place, not deleted):
    - `/mnt/oyPool/rb1AssistantBackups/.cheney-recovery-write-test-20260221-162404`
  - Started scrub: `zpool scrub oyPool`.
  - Re-tested from `rb1` via backup script: successful snapshot `post-clear-20260221-192451`.
- Evidence summary:
  - Pre-state: `oyPool state: SUSPENDED` with message `pool I/O is currently suspended`.
  - Post-clear: `all pools are healthy`; `oyPool state: ONLINE`; temporary resilver completed with `0 errors`.
  - Scrub state at `2026-02-21 16:25:01 PST`: in progress (`72.1G / 416G scanned`, `0B repaired`, no known data errors).
  - Backup verification: `/home/tdj/bin/rb1_truenas_backup.sh create post-clear-20260221-192451` returned `rc=0`.
- Root-cause assessment (most likely):
  - USB passthrough link reset/disconnect on VM100 data disk path (`ASMedia 174c:55aa`) during writes caused transient transport I/O failures (`DID_NO_CONNECT`) and forced ZFS pool suspension.
  - SMART on affected disk currently `PASSED` with no pending/reallocated/uncorrectable sectors, so immediate media failure is less likely than USB transport instability.
- Next action:
  - Let scrub finish and re-check `zpool status -xv`.
  - If clean, keep current data; then plan USB-path hardening (power/cable/bridge/controller stability) to avoid future suspend events.

## 2026-02-21 19:34 EST (Codex)
- Area: Cognee phase-1 compatibility/ROI reassessment (`rb1-fedora`, non-interrupt monitoring)
- Status: Kept active native run untouched. Low-batch mitigation (`--chunks-per-batch 1`) eliminated sqlite lock errors in this run, but `cognify` is still very slow and has not reached search artifact generation.
- Evidence:
  - Active chain remained running during checks: launcher `218554` -> runner `218573` -> `cognee-cli cognify` `223036`.
  - Current run (`notes/cognee/pilot-phase1-native-20260221-190536-batch1`) shows `pipeline_starts=60`, `lock_errors=0`, `search_files=0`; run log mtime stalled at `19:29:19` while internal Cognee log continues.
  - Internal Cognee log (`/home/tdj/cognee-native/.venv/lib/python3.12/site-packages/logs/2026-02-21_19-11-11.log`) shows repeated JSON/schema retry cycles against local `qwen2.5:7b`, including validation retries and very large responses (`total_tokens` up to `6725` in one call).
  - Ollama service logs show long `/v1/chat/completions` latencies during this phase (roughly `28s` to `3m29s` per call).
  - Storage artifacts exist (`.cognee_data` populated, sqlite + WAL present), but completion gate remains blocked at `cognify`.
- Interim reassessment:
  - Compatibility: partial/fragile (works in native mode with reduced lock contention, but extraction path remains brittle and slow on current local model/profile).
  - Worth right now: limited for always-on assistant memory; still potentially useful as a controlled offline/batch enrichment job if we add strict bounds.
- Next action: continue passive monitoring to run completion/failure, then decide keep/tune/disable based on (1) completion success, (2) search artifact quality, and (3) wall-clock cost per batch.

## 2026-02-21 19:45 EST (Codex)
- Area: Ollama GPU scheduling follow-up (`rb1-fedora`)
- Status: Confirmed current Ollama placement is single-GPU (internal GTX 1060 active, eGPU idle) while Cognify run remains active. User chose to defer dual-GPU change for later to avoid interruption.
- Planned deferred action: set `OLLAMA_SCHED_SPREAD=1` in the Ollama service environment and restart `ollama` after active Cognee run is complete.

## 2026-02-21 19:53 EST (Codex)
- Area: Cognee phase-1 native run health check (`rb1-fedora`)
- Status: Active `cognify` run has exited (no `cognee-cli` process remains).
- Failure evidence:
  - Run artifact: `notes/cognee/pilot-phase1-native-20260221-190536-batch1/pilot-run.log` ended with:
    - `RuntimeError: generator didn't stop after athrow()`
    - preceding asyncgen shutdown errors in `TextDocument.read` / `contextlib.__aexit__`
  - Internal log mtime stopped at `19:50:01 EST`:
    - `/home/tdj/cognee-native/.venv/lib/python3.12/site-packages/logs/2026-02-21_19-11-11.log`
  - No post-cognify search outputs were produced in the run dir (`search-*.json` absent).
- Notable: this run still had `lock_errors=0`, so sqlite lock mitigation helped, but run completion failed due to async generator shutdown/runtime error.
- Next action: decide whether to re-run with stricter batch/timeout guardrails and checkpointed partial-output handling, or pause Cognee pending upstream/version workaround.

## 2026-02-21 20:06 EST (Codex)
- Area: Pre-fastfail backup + Ollama dual-GPU + Qwen14B model-first smoke (`rb1-fedora`)
- Status: Completed requested pre-change backup and model-first validation; Cognee re-run intentionally paused pending user go-ahead.
- Backup checkpoint:
  - Snapshot label: `pre-fastfail-qwen14b-20260221-200028`
  - Backup log: `/home/tdj/backup-logs/rb1_truenas_backup_2026-02-21_20-00-28.log`
  - Verified in snapshot list on TrueNAS.
- Ollama changes:
  - Set systemd override `/etc/systemd/system/ollama.service.d/10-sched-spread.conf` with `Environment=OLLAMA_SCHED_SPREAD=1`.
  - Restarted `ollama`; service active with env confirmed.
  - Pulled model `qwen2.5:14b` (`9.0 GB`, id `7cdf5a0187d5`).
  - Runner logs confirm dual-GPU split for `qwen2.5:14b`:
    - `CUDA0 model buffer ~4065 MiB`, `CUDA1 model buffer ~4083 MiB`
    - layers split `26/23` across internal/eGPU.
- Model-first smoke artifacts:
  - Directory: `notes/ollama-q14b-smoke-20260221-200432`
  - `test1` (strict summary/description JSON): `FAIL` (`description` returned empty), `5.01s`, usage `87`.
  - `test2` (basic nodes/edges JSON shape): `PASS`, `36.36s`, usage `378`.
  - `test3` (exact token control): `PASS` (`ZX-4172`), `0.76s`, usage `51`.
  - `test4` (Cognee-like strict KG keys + non-empty strings): `PASS`, `42.05s`, usage `439`.
- Interpretation:
  - 14B is materially better for structured output than 7B, but still non-deterministic under strict field constraints (at least one empty-field miss observed).
  - Dual-GPU spread is working and ready for a fast-fail Cognee trial.
- Next action: on user confirmation, launch `cognify` fast-fail run with `LLM_MODEL=qwen2.5:14b` and minimal guards.

## 2026-02-21 20:17 EST (Codex)
- Area: Fast-fail `qwen2.5:14b` run status + OpenClaw/Cognee integration probe + 14B model scan
- Status: Fast-fail rerun is active on `rb1` and reached `cognify` (`extract_graph_from_data` stage) with `qwen2.5:14b`. In parallel, completed quick doc scrape and compatibility probe for routing Cognee through OpenClaw with Codex fallback.
- Evidence:
  - Active processes: launcher `run-fastfail.sh` pid `248728`; worker `/home/tdj/cognee-native/.venv/bin/cognee-cli cognify --datasets cheney_fastfail_q14b_20260221-201105 --chunker TextChunker --chunk-size 700`.
  - Run artifact path: `/home/tdj/cheney/notes/cognee/pilot-fastfail-q14b-20260221-201105/pilot-run.log` (latest stage enters `extract_graph_from_data` at `20:17 EST`).
  - OpenClaw probe on `rb1`:
    - `POST /v1/chat/completions` returned `405 Method Not Allowed`.
    - gateway config currently has no `gateway.http.endpoints.chatCompletions.enabled` block; OpenAI-compatible endpoint is therefore not usable yet for Cognee passthrough.
  - Doc scan shortlist (official sources):
    - `Qwen/Qwen3-14B` model card + Qwen3 blog indicate stronger general/coding/reasoning position than Qwen2.5 14B for many evals.
    - `deepseek-r1:14b` remains the strongest 14B-class reasoning-specialized candidate but with heavier response style/token cost.
    - `Phi-4-Reasoning` (14B) is viable for concise math/reasoning tasks; context/latency tradeoffs differ from Qwen family.
- Interim assessment:
  - Best near-term upgrade candidate in your range: `qwen3:14b` as new local default; keep `deepseek-r1:14b` as escalated local reasoning lane.
  - Cognee->OpenClaw->Codex fallback is feasible once OpenClaw OpenAI-compatible HTTP endpoints are explicitly enabled.
- Next action: let current fast-fail run finish, then A/B `qwen2.5:14b` vs `qwen3:14b` on the same Cognee scope before changing router defaults.

## 2026-02-21 20:34 EST (Codex)
- Area: 7B misroute fix + OpenClaw fallback path activation + 14B preflight (`rb1-fedora`)
- Status: Stopped the degraded fast-fail run, corrected model-routing so Cognee uses 14B, enabled OpenClaw OpenAI-compatible endpoints, and validated a minimal Cognee-through-OpenClaw run with Codex fallback configured (not forced). Paused before full rerun so user can test TUI independently.
- What changed:
  - Stopped active processes:
    - `/home/tdj/cheney/notes/cognee/pilot-fastfail-q14b-20260221-201105/run-fastfail.sh`
    - `cognee-cli cognify --datasets cheney_fastfail_q14b_20260221-201105 ...`
  - Root cause for 7B usage identified: runtime config still pinned `LLM_MODEL="qwen2.5:7b"` in `/home/tdj/cognee-native/.env`.
  - Updated `/home/tdj/cognee-native/.env`:
    - `LLM_MODEL="qwen2.5:14b"` (backup created with timestamp suffix).
  - Updated `/home/tdj/.openclaw/openclaw.json` (backup created with timestamp suffix):
    - `agents.defaults.model.primary` -> `ollama/qwen2.5:14b`
    - preserved fallback: `openai-codex/gpt-5.3-codex`
    - added `models.providers.ollama.models` entry for `qwen2.5:14b`
    - enabled `gateway.http.endpoints.chatCompletions.enabled=true`
    - enabled `gateway.http.endpoints.responses.enabled=true`
    - removed invalid key `gateway.http.port` after schema check.
  - Restarted active gateway process manually as `tdj` (systemd user bus unavailable from this root shell context) and re-probed endpoints.
- Evidence:
  - OpenClaw API probe on `rb1` now succeeds:
    - `POST /v1/chat/completions` -> `200` with `CHAT_OK`
    - `POST /v1/responses` -> `200` with `OPENCLAW_RESP_OK`
  - Minimal Cognee probe completed successfully through OpenClaw path:
    - dataset: `cheney_oc_probe_20260221_203257`
    - log: `/home/tdj/cognee-native/.venv/lib/python3.12/site-packages/logs/2026-02-21_20-33-28.log`
    - log entries show model calls as `qwen2.5:14b` (no 7B on this run).
  - Ollama active models after probe:
    - `qwen2.5:14b` (loaded, GPU)
    - `nomic-embed-text:latest` (embedding lane)
- Next action: wait for user TUI validation; after approval, launch full Cognee run with OpenClaw primary `qwen2.5:14b` + Codex fallback.

## 2026-02-21 20:45 EST (Codex)
- Area: OpenClaw TUI latency triage (`rb1-fedora`)
- Status: Diagnosed slow/aborted `hello glados` turns as model+context overhead in the long-lived `main` session with `qwen2.5:14b`; implemented a responsive interactive profile while preserving heavy-model fallback lanes.
- Findings:
  - `main` session showed repeated long waits and aborts (`This operation was aborted`, `fetch failed`) before eventual response, with `qwen2.5:14b` and large prompt context.
  - OpenClaw enforces a minimum context of `16000` for configured 14B/Codex path; lowering to `8192` hard-fails both lanes.
- Changes applied:
  - Kept gateway/fallback pipeline intact.
  - Set `agents.defaults.contextTokens=16000` (minimum valid floor for current route set).
  - Kept `hooks.internal.entries.boot-md.enabled=false` and `hooks.internal.entries.bootstrap-extra-files.enabled=false` for leaner bootstrap during TUI validation.
  - Switched interactive primary model to `ollama/qwen2.5:7b` with fallbacks:
    - `ollama/qwen2.5:14b`
    - `openai-codex/gpt-5.3-codex`
  - Updated active `main` session model snapshot in `/home/tdj/.openclaw/agents/main/sessions/sessions.json` to `qwen2.5:7b`.
  - Terminated stuck `openclaw`/`openclaw-tui` client processes; left `openclaw-gateway` running.
- Validation:
  - Probe command:
    - `openclaw agent --agent main --message "hello glados" --json`
  - Result: success in ~`3.5s` wall time (`durationMs ~1312`, model `qwen2.5:7b`, prompt tokens `7071`).
- Next action: user retry TUI interaction; if stable, keep this profile for interactive work and use 14B lane for heavier tasks/cognee runs.

## 2026-02-21 21:07 EST (Codex)
- Area: OpenClaw simpler-stack router switch (`rb1-fedora`) with automatic fallback
- Request intent: keep same router behavior but remove need for manual escalation when local Ollama cannot handle a turn.
- Changes made:
  - Updated `scripts/openclaw_agent_safe_turn.sh` defaults to `basic-local-v3` profile.
  - Set default tier chain/model intent to local-first: `ollama/qwen2.5:7b` -> `ollama/qwen2.5:14b` -> `openai-codex/gpt-5.3-codex`.
  - Changed automatic task targeting so `normal` starts at `local` and `high_risk` starts at `low` (14B), with `high` (Codex) reserved for fallback/forced tier.
  - Relaxed latency thresholds to reduce unnecessary cloud escalation:
    - local threshold `30000ms` (was `10000ms`)
    - low threshold `120000ms` (was `40000ms`)
  - Added policy snapshot runbook: `runbooks/openclaw-router-live-trial-v3.md`.
  - Updated `README.md` notes to reflect the new local-first chain and runbook pointer.
- Validation evidence (live on `rb1-admin`):
  - Default normal turn: stayed local (`qwen2.5:7b`), `backstopUsed=0`, `attemptChain=["local"]`, output `ROUTER_SIMPLE_OK`, `durationMs=27080`.
  - Forced low tier: used local 14B (`qwen2.5:14b`), `attemptChain=["low"]`, output `ROUTER_LOW_OK`, `durationMs=95000`.
  - Forced high tier: used Codex (`gpt-5.3-codex`), `attemptChain=["high"]`, output `ROUTER_HIGH_OK`, `durationMs=1496`.
  - Controlled outage test (Ollama stopped): auto-escalated without manual intervention, `attemptChain=["local","low","high"]`, final provider `openai-codex`, output `ROUTER_OUTAGE_OK`.
  - Post-test health: `systemctl is-active ollama` returned `active`; default model restored to `ollama/qwen2.5:7b`.
- Next action: if desired, tune local/low latency thresholds further for responsiveness vs cloud spend tradeoff and run a short real-prompt benchmark profile under `v3`.

## 2026-02-21 21:12 EST (Codex)
- Area: Cognify readiness gate check (`rb1-fedora`)
- Goal: determine whether stack is ready to start Cognify now after router simplification.
- Preflight status:
  - `ollama` active with required models present (`qwen2.5:14b`, `nomic-embed-text:latest`).
  - OpenClaw router config remains local-first (`7b -> 14b -> Codex`) and healthy.
  - Cognee runtime present at `/home/tdj/cognee-native/.venv` with `cognee-cli` available.
  - LLM/embedding HTTP probes to Ollama passed (`/v1/chat/completions` and `/v1/embeddings` status `200`).
- Blocking finding from live smoke:
  - One-item smoke run (`dataset=readiness_smoke_20260221_211130`) failed during `cognee-cli add` before `cognify`.
  - Fresh log `/home/tdj/cognee-native/.venv/lib/python3.12/site-packages/logs/2026-02-21_21-11-32.log` shows sqlite write failure:
    - `attempt to write a readonly database`
  - Current data dirs are root-owned from prior privileged runs (`/home/tdj/cognee-native/.cognee_system` and `/home/tdj/cognee-native/.cognee_data`), causing non-root write failure for `tdj`.
- Readiness decision:
  - `NOT READY` to start Cognify until ownership/permissions are corrected.
- Next action:
  - Fix ownership back to `tdj:tdj` for Cognee state dirs, then rerun the same one-item smoke (`add -> cognify -> search`) as gate before full job.

## 2026-02-21 21:13 EST (Codex)
- Area: Cognify blocker remediation + readiness gate rerun (`rb1-fedora`)
- Action taken:
  - Corrected ownership for Cognee state dirs on `rb1`:
    - `sudo chown -R tdj:tdj /home/tdj/cognee-native/.cognee_system /home/tdj/cognee-native/.cognee_data`
- Verification before rerun:
  - `.cognee_system` and `.cognee_data` now `tdj:tdj` (was `root:root`).
- Gate rerun (one-item end-to-end smoke):
  - Dataset: `readiness_smoke_20260221_211258`
  - Steps:
    1) `cognee-cli add --dataset-name readiness_smoke_20260221_211258 "rb1 cognify readiness smoke: local-first router with automatic fallback."`
    2) `cognee-cli cognify --datasets readiness_smoke_20260221_211258 --chunker TextChunker --chunk-size 256 --chunks-per-batch 1`
    3) `cognee-cli search --query-type CHUNKS --datasets readiness_smoke_20260221_211258 --top-k 1 --output-format simple "what is this smoke dataset about?"`
  - Outcome:
    - `add`: success
    - `cognify`: `Success: Cognification completed successfully!`
    - `search`: returned 1 chunk with expected smoke text
- Readiness decision:
  - `READY` to start Cognify jobs under current user context.
- Residual caveat:
  - Historical logs still contain earlier lock/runtime failures from prior runs; this gate confirms current write-path and minimal pipeline are now healthy.
- Next action:
  - proceed with intended Cognify workload, starting with bounded batch settings (`--chunks-per-batch 1`) then scale up if stable.

## 2026-02-21 21:33 EST (Codex)
- Area: Cognify overnight continuity handoff (`rb1-fedora`)
- Commit/push checkpoint completed before run:
  - commit `a112b9f` pushed to `origin/main` (`Switch safe-turn to local-first v3 and unblock cognify readiness`).
- Run status:
  - Active dataset run: `cheney_scope_20260221-211845`
  - Active command: `timeout 1800 ./.venv/bin/cognee-cli cognify --datasets cheney_scope_20260221-211845 --chunker TextChunker --chunk-size 700 --chunks-per-batch 1`
  - Observed behavior: slow but progressing; repeated long Ollama chat-completion calls (roughly ~1m to ~3m), logs and GPU utilization continue advancing.
- Continuity action (no-loss handoff):
  - Added detached continuation watcher script on `rb1`:
    - `/home/tdj/cheney/notes/cognee/cognify-attempt-20260221-211845/overnight-continuation.sh`
  - Started detached watcher PID:
    - `287697`
  - Watcher behavior:
    1) wait for existing dataset run to end,
    2) if existing run already succeeded, skip re-cognify and run search verification,
    3) otherwise launch same dataset `cognify` without timeout,
    4) run post-search check and log outputs.
  - Watcher logs/artifacts:
    - wait log: `/home/tdj/cheney/notes/cognee/cognify-attempt-20260221-211845/overnight-continuation.log`
    - launch out: `/home/tdj/cheney/notes/cognee/cognify-attempt-20260221-211845/overnight-continuation.launch.out`
    - pid file: `/home/tdj/cheney/notes/cognee/cognify-attempt-20260221-211845/overnight-continuation.pid`
    - continuation cognify/search logs will write to `cognify-continuation.log` and `search-continuation.log` in the same attempt dir.
- Next action:
  - Leave overnight; in next session check continuation logs + final dataset search output to confirm completion quality.

## 2026-02-21 21:56 EST (Codex)
- Area: Cognify overnight run bedtime checkpoint (`rb1-fedora`)
- Dataset: `cheney_scope_20260221-211845`
- Outcome:
  - Primary bounded run (`timeout 1800`) ended around `21:49 EST`.
  - Detached continuation watcher took over and ran a no-timeout continuation.
  - Continuation log reports success:
    - `Success: Cognification completed successfully!`
    - `[COGNIFY-CONT] end 2026-02-21 21:49:36 EST rc=0`
  - No active `cognee-cli cognify`/`search` processes remain.
- Verification evidence:
  - Runtime log closed cleanly (`/home/tdj/cognee-native/.venv/lib/python3.12/site-packages/logs/2026-02-21_21-49-29.log`).
  - Manual post-run retrieval check passed:
    - `cognee-cli search --query-type CHUNKS --datasets cheney_scope_20260221-211845 --top-k 3 ...`
    - returned 3 relevant chunks from indexed Cheney docs.
- Notes:
  - `search-continuation.log` was not produced by the watcher path; manual search validation was executed instead to confirm retrieval readiness.
- Next action:
  - Morning: run quality pass (spot-check retrieved chunk relevance and summarize any hallucination/coverage gaps before expanding scope).

## 2026-02-21 22:15 EST (Codex)
- Area: RB1 overnight diagnostics launch (local model + Codex stack viability)
- Scope implemented:
  - Added runner: `scripts/rb1_overnight_diagnostics.sh`
  - Added report generator: `scripts/rb1_overnight_diagnostics_report.sh`
  - Diagnostics lanes now include:
    1) host/network/GPU health sampling
    2) OpenClaw local assistant probe (`task-class basic`)
    3) raw Ollama local model probe (`qwen2.5:7b`)
    4) forced Codex high-tier probe (`--force-tier high`)
- Validation before launch:
  - Two bounded smoke runs on `rb1` passed (`overnight-diagnostics-smoke*`) with 100% success on assistant + codex + raw lanes.
- Active overnight run:
  - Run dir: `/home/tdj/cheney/notes/diagnostics/overnight-diagnostics-20260221-221321`
  - PID: `310392`
  - Launch out: `notes/diagnostics/overnight-diagnostics-launch-20260221-221321.out`
  - Settings: duration `8h`, health every `300s`, assistant every `1800s`, forced-codex every `5400s`, temp guard `82C`.
  - Early status: first cycle completed successfully on all lanes (`assistant_local`, `local_raw`, `codex_forced_high`).
- First report artifact created (interim):
  - `/home/tdj/cheney/notes/overnight-diagnostics-report-20260221-221442.md`
- Morning command:
  - `ssh rb1-admin 'cd /home/tdj/cheney && scripts/rb1_overnight_diagnostics_report.sh'`
- Next action:
  - Morning: stop/confirm completion, generate final report, then decide whether current local+codex stack is stable enough for assistant duty.

## 2026-02-22 08:32 EST (Codex)
- Area: overnight diagnostics final readout (`rb1-fedora`)
- Run analyzed:
  - `/home/tdj/cheney/notes/diagnostics/overnight-diagnostics-20260221-221321`
  - Start: `2026-02-21 22:13:21 EST`
  - End: `2026-02-22 06:13:25 EST` (`rc=0`)
- Final report artifact:
  - `/home/tdj/cheney/notes/overnight-diagnostics-report-20260222-133004.md`
- Key outcomes:
  - Verdict: `FUNCTIONAL_CANDIDATE`
  - Assistant lane (OpenClaw local path): `16/16` success, `0` failures, `avg=32580ms`, `p95=34579ms`, `backstop_count=0`.
  - Forced Codex lane: `6/6` success, `0` failures, `avg=12771ms`, `p95=13219ms`.
  - Raw Ollama lane: `16/16` success, `0` failures, `avg=9532ms`, `p95=9775ms`.
  - Health/network: `96` samples, `0` gateway/internet/DNS failures, `max_gpu_temp_c=59`, no NIC RX/TX errors.
- Caveat found:
  - `kernel_error_events` in report (`109`) overstates actual unique kernel error lines during the run window due per-sample counting overlap at timestamp boundaries.
  - Direct journal query over run window shows `19` lines, all same type:
    - `pcieport 0000:0e:01.0: AER: Error of this Agent is reported first`
- Readiness interpretation:
  - Stack is stable enough for assistant candidacy from a reliability perspective.
  - Remaining tradeoff is local response latency (~30-35s via safe-turn local lane).
- Next action:
  - Decide whether to tune local path latency thresholds/model mix for responsiveness and patch kernel-error aggregation to de-duplicate boundary overlap.

## 2026-02-22 13:36 EST (Codex)
- Area: rb1 toolchain baseline
- Action:
  - Installed `ripgrep` on `rb1-fedora` via `sudo dnf install -y ripgrep`.
- Verification:
  - `rg --version` => `ripgrep 14.1.1`
- Reason:
  - Enables fast repo/log search for ongoing diagnostics and assistant quality analysis.
- Next action:
  - Use `rg` in follow-up natural-prompt overnight evaluation scripts.

## 2026-02-22 13:41 EST (Codex)
- Area: router-backed interactive CLI (`rb1` + repo)
- Change:
  - Added `scripts/openclaw_router_repl.sh` to provide an interactive REPL that always routes through `scripts/openclaw_agent_safe_turn.sh`.
  - This avoids direct `openclaw tui` routing bypass and preserves local-first/fallback policy.
- Features:
  - REPL commands: `/help`, `/status`, `/task`, `/thinking`, `/force`, `/exit`
  - Per-turn metadata display (provider/model/latency/backstop/attempt chain)
  - JSONL turn log output under `notes/openclaw-artifacts/router-repl-*.jsonl`
- Verification:
  - Smoke run on `rb1` via piped input succeeded:
    - prompt: `ping from router repl`
    - response: `PONG`
    - meta: provider `ollama`, model `qwen2.5:7b`, chain `["local"]`
- Next action:
  - Use this REPL as the default terminal interface when you want policy-consistent assistant interaction.

## 2026-02-22 13:56 EST (Codex)
- Area: router REPL UX improvements (`scripts/openclaw_router_repl.sh`)
- Changes implemented:
  - Added visual separation between assistant output and diagnostics.
    - Assistant output remains plain/bright.
    - Diagnostics/meta/error use separate styling channels (dim/error coloring when TTY supports ANSI).
    - Wrapper stderr is now captured and emitted in a dedicated diagnostics block, avoiding interleaving.
  - Added multiline compose mode:
    - `/multi` enters compose mode
    - `/end` submits composed multiline prompt
    - `/cancel` aborts compose
    - line editing uses readline when attached to a TTY
  - Added REPL toggles:
    - `--hide-meta` / `--show-meta`
    - `--hide-diag` / `--show-diag`
    - `--no-color`
- Verification on `rb1`:
  - Single-turn smoke (`ping from styled repl`) returned `PONG` with separated meta + diagnostics block.
  - Multiline smoke (`/multi` + `Write exactly MULTI_OK`) returned `MULTI_OK` and cleanly exited.
- Next action:
  - use this REPL as default attended CLI; optionally trim diagnostics verbosity further if desired.

## 2026-02-22 14:03 EST (Codex)
- Area: router REPL input/output UX follow-up (`scripts/openclaw_router_repl.sh`)
- Requested behavior implemented:
  - Assistant output now starts with model identifier prefix: `[modelname] ...`.
  - Default input mode is multiline-capable without command mode switching:
    - Enter sends message
    - Ctrl+J inserts newline
  - Existing diagnostics separation retained (dedicated diagnostics block; no stderr interleave).
- Additional fixes:
  - Hardened input read return handling for interrupt/EOF paths under `set -e`.
- Validation:
  - `rb1` smoke test succeeded with prefix output:
    - `router> [qwen2.5:7b] PONG_model_prefix_test`
  - Script syntax checks pass locally and on `rb1`.
- Note:
  - Ctrl+J/newline behavior depends on terminal key mapping (the script differentiates CR vs LF in TTY raw mode).
- Next action:
  - if any terminal sends Enter as LF instead of CR, apply a per-terminal fallback binding strategy.

## 2026-02-22 14:12 EST (Codex)
- Area: router REPL input model revision (`scripts/openclaw_router_repl.sh`)
- Why:
  - Prior raw-input mode still produced poor wrapped-line editing behavior and diagnostics/readability issues in interactive use.
- Changes:
  - Replaced raw keystroke loop with readline-backed input path (interactive Bash re-exec on TTY).
  - Added readline keybinding intent:
    - Enter => send
    - Ctrl+J => insert newline (`bind "\C-j":"\C-q\C-j"`)
  - Kept diagnostics separation and model-prefix output:
    - assistant line now begins with `[model]`
    - diagnostics remain in dim block (when color enabled)
- Validation:
  - `rb1` smoke pass:
    - prompt: `ping model prefix retest`
    - output: `[gpt-5.3-codex] PONG_model_prefix_retest`
    - meta: provider `openai-codex`, `backstop=1`, chain `local->low->high`
- Note:
  - True Ctrl+J newline behavior is terminal-dependent and should be verified in attended TTY use.
  - If key mapping still misbehaves in your terminal, next step is to mirror OpenClaw TUI’s exact input widget behavior.

## 2026-02-22 14:24 EST (Codex)
- Area: router REPL rollback + baseline preservation
- Action requested:
  - rolled `scripts/openclaw_router_repl.sh` back to the first/original version.
  - saved that exact content as baseline at:
    - `scripts/baselines/openclaw_router_repl.v1.sh`
- Verification:
  - local syntax checks pass for both files.
  - exact match confirmed:
    - `cmp scripts/openclaw_router_repl.sh scripts/baselines/openclaw_router_repl.v1.sh` => match
  - synced rollback to `rb1` and smoke-tested:
    - prompt: `ping rollback baseline`
    - response: `PONG_rollback_baseline`
- Next action:
  - implement OpenClaw-TUI-mirrored input behavior from this baseline version.

## 2026-02-22 14:35 EST (Codex)
- Area: router REPL OpenClaw-TUI input mirroring from v1 baseline
- Changes implemented:
  - Added `scripts/openclaw_router_repl_input.py` (prompt-toolkit input helper) to provide editor-style input semantics.
  - Updated `scripts/openclaw_router_repl.sh` to prefer helper mode on TTY when `prompt_toolkit` is present:
    - Enter submits message
    - Ctrl+J inserts newline
    - multiline prompt continuation shown as `... `
  - Preserved non-TTY behavior and command handling (`/help`, `/status`, `/task`, `/thinking`, `/force`, `/exit`).
  - Added fallback path when `prompt_toolkit` is unavailable (readline mode with visible `\\n` token insertion via Ctrl+J).
- Validation/evidence summary:
  - `bash -n scripts/openclaw_router_repl.sh` passes.
  - `python3 -m py_compile scripts/openclaw_router_repl_input.py` passes.
  - PTY probe confirms helper captures Ctrl+J as real newline (`0a` byte) and Enter as submit.
  - REPL command smoke in PTY confirms `/status` and `/exit` are parsed locally (no wrapper turn required).
- Notes:
  - prompt-toolkit prompt drawing was redirected to stderr so captured message payload stays clean on stdout.
  - For this host session, installed `prompt_toolkit` user package for attended validation.
- Next action:
  - sync this commit to `rb1` and verify behavior in your normal terminal once you reconnect.

## 2026-02-22 14:51 EST (Codex)
- Area: rb1 router REPL deployment verification + keybind parity tweak
- Findings:
  - `rb1` (`/home/tdj/cheney`) was behind at `a112b9f`; `git pull` had been blocked by an untracked local `scripts/openclaw_router_repl.sh`.
  - Preserved pre-pull local copy at `notes/local-overrides/openclaw_router_repl.sh.prepull-<timestamp>`, then fast-forwarded to `58e39fd`.
  - Installed `prompt_toolkit` for `tdj` on `rb1` so TUI-style input path is active.
  - Verified interactive smoke over `rb1-admin`: `/status` handled locally; `hello` answered by `qwen2.5:7b` (`provider=ollama`, `backstop=0`).
- Code tweak:
  - `scripts/openclaw_router_repl_input.py` now accepts OpenClaw-style newline keying with `Alt+Enter` (in addition to `Ctrl+J`), while Enter/CR submit.
- Next action:
  - commit/push newline keybind tweak and pull to rb1.

## 2026-02-22 15:01 EST (Codex)
- Area: router REPL output clarity (model provenance + diagnostics styling)
- User-reported issues:
  - qwen capability appeared inconsistent between sessions.
  - diagnostic text visually blended with assistant output.
- Evidence summary:
  - Parsed `notes/openclaw-artifacts/router-repl-*.jsonl` on rb1 and confirmed mixed behavior across runs:
    - some turns stayed local (`chosenTier=local`, `final.model=qwen2.5:7b`)
    - other turns escalated (`chosenTier=high`, `final.model=gpt-5.3-codex`) after latency thresholds.
  - This mismatch was hard to see in terminal because output lacked model prefix and wrapper diagnostics interleaved in default color.
- Changes made:
  - `scripts/openclaw_router_repl.sh`
    - assistant reply now prefixed with `[model]`.
    - wrapper stderr diagnostics are captured and printed as `[diag] ...` lines (separate block).
    - `[meta]` line now includes tier summary and compact attempt timing chain.
    - diagnostics/meta use dim gray ANSI style on TTY (`NO_COLOR` respected); assistant output remains bright/default.
- Next action:
  - push and pull on rb1, then user-validate visual separation and model provenance in attended session.

## 2026-02-22 15:03 EST (Codex)
- Area: router REPL clarity patch deployed
- Commit/push:
  - `0ed27d0` (`Clarify REPL model provenance and style diagnostics`)
- Sync:
  - pulled on rb1 (`rb1-admin`) to `0ed27d0`.
- Verification:
  - forced high-tier smoke shows explicit codex provenance:
    - output prefix: `[gpt-5.3-codex] ...`
    - diagnostics: `[diag] ...`
    - meta shows tier/attempt chain (`chain=["high"]`).
- Note:
  - this removes ambiguity between local qwen turns and codex escalations.

## 2026-02-22 15:16 EST (Codex)
- Area: rb1-admin UI shortcut
- Added launcher scripts:
  - `scripts/glados-ui`: runs router REPL with attended defaults (`--mode gateway --host local --agent main`).
  - `scripts/install_glados_shortcut.sh`: installs `~/.local/bin/glados` and `~/.local/bin/glados-ui` symlinks.
- Validation:
  - both scripts pass `bash -n`.
  - launcher help path verified (`scripts/glados-ui --help`).
- Next action:
  - pull latest on `rb1` and run installer as `rb1-admin`, then confirm `glados` starts REPL from any directory.

## 2026-02-22 15:17 EST (Codex)
- Area: launcher symlink fix
- Issue:
  - `glados` symlink under `~/.local/bin` initially failed to locate repo script because launcher root path was derived from symlink directory.
- Fix:
  - `scripts/glados-ui` now resolves `BASH_SOURCE[0]` through `readlink -f` before computing `ROOT_DIR`.
- Validation:
  - direct launch and symlink launch both return REPL help successfully.
- Next action:
  - push fix and re-verify `glados --help` on `rb1-admin`.

## 2026-02-22 15:34 EST (Codex)
- Area: live unattended monitoring of first semi-real OpenClaw task (speed-test script request)
- Prompt observed (router REPL):
  - "Can you please write a short script for internet speed testing? you may save it in the home directory"
- Evidence captured:
  - Turn record: `notes/openclaw-artifacts/router-repl-20260222-151845.jsonl`
  - Safe-turn log/json: `notes/openclaw-artifacts/openclaw-safe-turn-20260222-152052.log` / `.json`
  - Generated file: `/home/tdj/speed_test.sh` (mtime `2026-02-22 15:31:15 EST`)
- Performance summary:
  - Start (`Host=` line): `15:20:52 EST`
  - Escalation event: `15:21:49 EST` (`local -> low`, reason `local_latency_threshold`)
  - Completion/cleanup: `15:31:58 EST`
  - Wall-clock to completion: ~11m06s
  - Attempt 1 (local `qwen2.5:7b`): `47.5s`, `outputTokens=210`, ended non-final due latency threshold.
  - Attempt 2 (tier=low but final provider/model reported as `openai-codex/gpt-5.3-codex`): `3.9s`, final success, file creation confirmed.
- Operational behavior during monitor window:
  - `ollama runner` stayed heavily loaded (`qwen2.5:14b`, ~`51%/49% CPU/GPU` split) for multiple minutes.
  - No active `openclaw_agent_safe_turn.sh` after completion; REPL stayed open (`openclaw_router_repl.sh`).
- Notes:
  - There is a tier/provenance oddity: attempt chain is `local->low`, but final low-tier provider/model logged as codex. Keep this as a follow-up consistency check.
- Next action:
  - On user return, deliver concise performance summary + recommend whether to adjust low-tier routing/thresholds for practical responsiveness.

## 2026-02-22 16:21 EST (Codex)
- Area: routing consistency fix + generated script QA
- Routing issue reproduced:
  - wrapper recorded `tier=low` while final provider/model was codex for some gateway-mode turns.
- Fix applied:
  - `scripts/openclaw_agent_safe_turn.sh`
    - updated `run_attempt()` to force `openclaw agent --local` for non-high tiers when selected route model is `ollama/*`.
    - preserves gateway path for high tier.
  - intent: prevent gateway-side router/model override from making low-tier attempts appear as codex.
- Validation (rb1):
  - forced local→low→high scenario (`--max-local-elapsed-ms 1`) produced:
    - local: `ollama/qwen2.5:7b` (`local_latency_threshold`)
    - low: `ollama/qwen2.5:14b` (`low_latency_threshold`)
    - high: `openai-codex/gpt-5.3-codex`
  - confirms low tier now reports/uses local ollama model consistently.
- Generated script QA (`/home/tdj/speed_test.sh` on rb1):
  - previous version relied on fragile HTML line scraping from fast.com.
  - replaced with robust CLI-first probe (`speedtest`/`speedtest-cli` when available) plus ping latency fallback.
  - script syntax validated and executed on host (throughput skipped when speedtest tools absent; ping succeeded).
- Next action:
  - commit/push wrapper fix and logs; pull latest on rb1.

## 2026-02-22 16:53 EST (Codex)
- Area: OpenClaw router REPL warm-state automation + 14B-first routing alignment (`rb1`)
- Status:
  - Implemented warm-state management in `scripts/openclaw_router_repl.sh`:
    - startup warm-state display (`cold|warming|warmed|unknown`)
    - startup auto-warm (`--warmup auto|off`)
    - background keepalive loop (`--keepwarm on|off`, `--keepwarm-interval-sec`)
    - warm commands (`/warm-status`, `/warm-now`, `/keepwarm on|off`)
    - host-aware warm checks/warm calls over SSH (with `ssh -n` so stdin is not consumed)
  - Added warm policy flags (`--warm-scope`, `--warm-timeout-sec`, `--warm-model-14b`, `--warm-model-7b`, `--warm-keepalive`) and included warm settings in REPL JSONL settings payload.
  - Added dual-warm compatibility path for constrained VRAM (when scope is `both`, `7b` warm requests are forced CPU via `num_gpu=0`).
  - Updated safe-turn default local lane to 14B:
    - `scripts/openclaw_agent_safe_turn.sh`: `LOCAL_GENERAL_MODEL=ollama/qwen2.5:14b`.
  - Per latest operator direction, default REPL warm scope is now `14b` (dual warm remains available with `--warm-scope both`).
- Evidence:
  - Script updates:
    - `scripts/openclaw_router_repl.sh`
    - `scripts/openclaw_agent_safe_turn.sh`
  - Cold-start warm test (dual scope) artifact:
    - `notes/openclaw-artifacts/router-repl-20260222-164723.jsonl`
    - output showed: `14b cold->warming->warmed`, then `7b cold->warming->warmed (placement=cpu)`.
  - 14B-only default warm test artifact:
    - `notes/openclaw-artifacts/router-repl-20260222-165332.jsonl`
    - output showed warm target only `qwen2.5:14b`, `qwen2.5:7b` remained cold.
  - Post-test runtime checks on `rb1`:
    - `curl 127.0.0.1:11434/api/ps` after 14B-only startup => only `qwen2.5:14b` loaded.
    - bounded safe-turn local check returned `provider=ollama`, `model=qwen2.5:14b`, `backstopUsed=0`, response `ROUTER_LOCAL_14B_OK`.
- Notes:
  - During active generation, GPU utilization can be imbalanced even with spread enabled; observed sample showed one GPU saturated while the other held memory with low compute at that moment.
- Next action:
  - If desired, tune keepwarm interval/TTL target to balance responsiveness vs idle power draw while staying 14B-only by default.

## 2026-02-22 17:06 EST (Codex)
- Area: 14B prewarm validation follow-up + benchmark blocker isolation
- Status:
  - Confirmed direction is applied in code/config path:
    - local tier default remains `ollama/qwen2.5:14b` (`scripts/openclaw_agent_safe_turn.sh`)
    - REPL warm default remains `--warm-scope 14b` (`scripts/openclaw_router_repl.sh`)
  - Investigated inconsistent benchmark output (unexpected codex on forced-local run).
  - Root cause isolated: stale lock file in OpenClaw session path caused lane errors and fallback behavior during probes.
    - stale lock: `/home/tdj/.openclaw/agents/main/sessions/lean-probe-204438.jsonl.lock`
    - lock PID in error logs was not alive.
  - Cleared stale lock and re-ran local probe:
    - forced-local run returned `provider=ollama`, `model=qwen2.5:14b`, `backstopUsed=0`, `durationMs=26423`, response `ROUTE_LOCK_FIX_TEST`.
- Evidence:
  - Problematic run logs:
    - `notes/openclaw-artifacts/openclaw-safe-turn-20260222-165743.log` (lane lock errors)
    - `notes/openclaw-artifacts/openclaw-safe-turn-20260222-165827.log` (unknown agent probe/cleanup timing)
  - Post-fix good run:
    - `notes/openclaw-artifacts/openclaw-safe-turn-20260222-170138.json`
- Next action:
  - Run a clean, isolated cold-vs-prewarmed 14B benchmark using the now-unlocked main session (or dedicated benchmark agent if created), then decide whether to keep 14B warm-only or retool warm policy to 7B.

## 2026-02-22 17:14 EST (Codex)
- Area: rb1 process stop + script sync to latest warm/routing behavior
- Status:
  - Synced updated scripts to rb1 clone:
    - `/home/tdj/cheney/scripts/openclaw_router_repl.sh`
    - `/home/tdj/cheney/scripts/openclaw_agent_safe_turn.sh`
  - Verified rb1 checksums match local for both files after copy.
  - Cleared active turn/runtime workload:
    - no running `openclaw_router_repl.sh`/`openclaw_agent_safe_turn.sh`/`openclaw agent` processes left.
    - stopped loaded Ollama models (`qwen2.5:14b`, `qwen2.5:7b`) and confirmed `api/ps` empty.
  - Verified shortcut path (`glados`) now resolves to updated defaults on rb1.
- Evidence:
  - remote script settings check:
    - `LOCAL_GENERAL_MODEL="ollama/qwen2.5:14b"`
    - `WARM_SCOPE="14b"`
  - `glados` smoke output (`/status` then `/exit`) shows:
    - `warm_scope=14b`
    - `warm_targets=qwen2.5:14b`
  - artifact from smoke:
    - `notes/openclaw-artifacts/router-repl-20260222-171419.jsonl`
- Notes:
  - An earlier SSH transport error occurred during a combined kill command; rerun checks confirmed host health and successful completion of all requested actions.
- Next action:
  - User can start fresh test from rb1 via `glados` (defaults now 14b-local + 14b warm scope).

## 2026-02-22 17:24 EST (Codex)
- Area: 7B-only rollback + runtime reset + dual-GPU utilization probe (`rb1`)
- Status:
  - Applied requested rollback away from 14B:
    - `scripts/openclaw_agent_safe_turn.sh`
      - `LOCAL_GENERAL_MODEL` set to `ollama/qwen2.5:7b`
      - default `CLOUD_LOW_MODEL` now follows local 7B
      - added guard to remap low/local away from `ollama/qwen2.5:14b` if encountered
    - `scripts/openclaw_router_repl.sh`
      - default `WARM_SCOPE` set to `7b`
      - 14B warm scopes (`both`, `14b`) remapped to `7b` for this profile
      - warm tracking reduced to active 7B lane; status now reports `warm_14b_excluded=true`
  - Synced updated scripts to rb1 and verified via `glados` smoke (`warm_scope=7b`, startup warm line visible).
  - Reset runtime state as requested:
    - killed active OpenClaw turn/repl processes
    - stopped loaded Ollama models (`qwen2.5:14b`, `qwen2.5:7b`)
  - Corrected OpenClaw default model on rb1 to align with policy:
    - `openclaw models set ollama/qwen2.5:7b`
- Dual-GPU probe findings (7B, `OLLAMA_SCHED_SPREAD=1`):
  - Single request window: both GPUs active over the sample (`gpu0_active_samples=12/20`, `gpu1_active_samples=13/20`).
  - Dual concurrent request window: both GPUs active more consistently (`gpu0_active_samples=16/20`, `gpu1_active_samples=18/20`).
  - Max instantaneous utilization remained asymmetric (`gpu1` often peaks higher), but both GPUs are participating over time.
- Evidence:
  - Probe dirs on rb1:
    - `/tmp/ollama_gpu_probe_single_172205`
    - `/tmp/ollama_gpu_probe_dual_172227`
  - 7B-only glados startup artifact:
    - `notes/openclaw-artifacts/router-repl-20260222-172434.jsonl`
  - Forced low-tier 7B confirmation:
    - `notes/openclaw-artifacts/openclaw-safe-turn-20260222-172312.json`
- Next action:
  - User-attended run in rb1 terminal with `glados` to validate perceived responsiveness on 7B-only path.

## 2026-02-22 18:06 EST (Codex)
- Area: travel remote-access hardening for workstation host (`fedora`, `192.168.5.81`)
- Status:
  - Implemented travel-window command suite:
    - `scripts/travel_ssh_window.sh` (commands: `enable|status|extend|disable|baseline|sshd-status|sshd-ensure|wol-status|wol-enable`)
    - wrappers: `scripts/travel-ssh-enable`, `scripts/travel-ssh-status`, `scripts/travel-ssh-extend`, `scripts/travel-ssh-disable`
    - installer: `scripts/install_travel_ssh_shortcuts.sh`
  - Installed local shortcuts to `~/.local/bin` (`travel-ssh*`).
  - Added automatic expiry plumbing via user systemd units (generated by script):
    - `cheney-travel-ssh-expire.service`
    - `cheney-travel-ssh-expire.timer`
  - Added robust state/event tracking:
    - state: `~/.local/state/cheney/travel-ssh/state.env`
    - event log: `~/.local/state/cheney/travel-ssh/events.log`
  - Set WoL intent for this host without firewall mutation:
    - `travel-ssh wol-enable --interface enp4s0 --connection "Wired connection 1"`
    - result: `nm_wol=magic`, `sysfs_wakeup=enabled`
  - Confirmed SSH daemon baseline:
    - `sshd_enabled=enabled`, `sshd_active=active`, `sshd_listen_22=yes`
  - Captured baseline artifacts:
    - `notes/remote-access/baselines/this-host-ssh-firewall-baseline-20260222-180417.txt`
    - `notes/remote-access/baselines/this-host-ssh-firewall-baseline-20260222-180531.txt`
  - Added documentation:
    - `runbooks/travel-ssh-window-this-host.md`
    - `inventory/network-remote-access.md` (new workstation row + temporary travel policy section)
- Notes:
  - Deferred live firewall allowlist activation while user was away to avoid desktop auth prompts.
  - Dry-run timer lifecycle was validated using `--skip-firewall` (`enable -> extend -> disable`) and is functioning.
- Next action:
  - With user present, run `travel-ssh-enable --hours 72`, verify `policy_firewall_applied=1`, then execute off-LAN MBP validation.

## 2026-02-22 18:08 EST (Codex)
- Area: travel-SSH shortcut hardening
- Status:
  - Fixed wrapper resolution bug for symlinked shortcuts (`~/.local/bin/travel-ssh-*`) by switching wrappers to `readlink -f` path resolution.
  - Revalidated wrapper lifecycle with timer dry-run:
    - `travel-ssh-enable --hours 1 --skip-firewall`
    - `travel-ssh-extend --hours 1`
    - `travel-ssh-disable`
  - Captured additional baseline artifact during dry-run:
    - `notes/remote-access/baselines/this-host-ssh-firewall-baseline-20260222-180820.txt`
- Next action:
  - Activate real firewall allowlist with user present (`travel-ssh-enable --hours 72`) and run MBP off-LAN validation.

## 2026-02-22 18:09 EST (Codex)
- Area: travel-ssh path hygiene
- Status:
  - Removed accidental non-repo baseline directory created during early symlink-resolution bug:
    - removed `/home/tdj/.local/notes/remote-access/`
  - Canonical baseline path for this workflow remains:
    - `/home/tdj/cheney/notes/remote-access/baselines/`
- Next action:
  - Keep all future travel-SSH artifacts under `~/cheney/notes/remote-access/`.

## 2026-02-22 18:10 EST (Codex)
- Area: travel-ssh status output normalization
- Status:
  - Updated `scripts/travel_ssh_window.sh` status reporting to emit explicit boolean values for SSH service checks:
    - `firewall_ssh_service_runtime=yes|no`
    - `firewall_ssh_service_permanent=yes|no`
  - Eliminated blank outputs on negative query paths.
- Next action:
  - Proceed with user-present live firewall activation and MBP validation.

## 2026-02-22 18:10 EST (Codex)
- Area: subnet-router source assumptions for travel SSH allowlist
- Status:
  - Rechecked `tsDeb` prefs from `rb2` (`qm guest exec 101 -- tailscale debug prefs`): `NoSNAT=false` remains active.
  - Rechecked `tsDeb` tailnet status (`qm guest exec 101 -- tailscale status --json`):
    - self route advertisement still includes `192.168.5.0/24`.
    - `lchl-tsnode-mba` appears online in peer list (backup utility node present).
- Next action:
  - Keep router-source allowlist entries for `192.168.5.102/32` + `192.168.5.113/32` when enabling travel policy.

## 2026-02-22 18:18 EST (Codex)
- Area: deferred-start and manual on/off controls for travel SSH
- Status:
  - Extended `scripts/travel_ssh_window.sh` with:
    - `on` / `off` aliases for quick manual testing
    - `schedule-start --at <datetime> --hours <N>`
    - `cancel-start`
    - status visibility for both expiry timer and deferred start timer
  - Added wrapper scripts + shortcuts:
    - `scripts/travel-ssh-on`, `scripts/travel-ssh-off`
    - `scripts/travel-ssh-schedule-start`, `scripts/travel-ssh-cancel-start`
    - installer updated: `scripts/install_travel_ssh_shortcuts.sh`
  - Updated docs:
    - `runbooks/travel-ssh-window-this-host.md` (manual test flow + deferred start flow)
    - `inventory/network-remote-access.md` command surface update
  - Verified behavior:
    - manual `on/off` works and no longer clears deferred schedule
    - deferred start currently armed for `2026-02-23 14:30:00 EST` (72h window)
    - current policy remains inactive now (`policy_enabled=0`, no firewall mutation active)
- Next action:
  - Tonight: test from Mac with `travel-ssh-on` and `travel-ssh-off`.
  - Tomorrow at scheduled time: policy auto-enables; verify with `travel-ssh-status`.

## 2026-02-22 18:24 EST (Codex)
- Area: live ON/OFF validation with Mac test
- Status:
  - Enabled travel policy for live test (`travel-ssh-on --hours 1`), resulting state:
    - `firewall_ssh_service_runtime=no`
    - allowlist rich-rules active for `100.64.0.0/10`, `192.168.5.102/32`, `192.168.5.113/32`
  - User Mac test result while Tailscale OFF: `connection refused` (expected block).
  - Disabled travel policy (`travel-ssh-off`), resulting state:
    - SSH service restored (`firewall_ssh_service_runtime=yes`, `...permanent=yes`)
    - allowlist rich-rules removed
    - policy inactive (`policy_enabled=0`)
  - Kept deferred start intact:
    - `cheney-travel-ssh-start.timer` still scheduled for `2026-02-23 14:30:00 EST`.
  - Minor status fix applied:
    - `cmd_disable` now writes `policy_firewall_applied=0` after rollback.
- Notes:
  - firewalld operations trigger repeated polkit authentications on this desktop; commands can appear stalled briefly while auth is processed.
- Next action:
  - User retries Mac SSH now (with Tailscale still OFF) to confirm access restored under policy OFF.

## 2026-02-22 18:46 EST (Codex)
- Area: rollback of scripted travel-gating path and tailscale-only simplification
- Status:
  - Canceled/decommissioned scripted travel-gating runtime state:
    - `cheney-travel-ssh-start.timer` disabled and removed
    - `cheney-travel-ssh-expire.timer` disabled and removed
    - user unit files removed from `~/.config/systemd/user/`
    - no `cheney-travel-ssh-*` timers/unit-files remain loaded
  - Removed local convenience symlinks for scripted path from `~/.local/bin` (`travel-ssh*`).
  - Verified host returned to plain/default SSH posture:
    - `sshd` active+enabled, port 22 listening on `0.0.0.0` and `::`
    - firewalld zone `FedoraWorkstation` includes service `ssh`
    - no rich rules active/permanent in that zone
  - Tailscale continuity checks (simple path):
    - local host tailscaled remains intentionally inactive/disabled
    - `tsDeb` (`101`) online and still advertising subnet route `192.168.5.0/24`
    - `tsDeb` prefs still `NoSNAT=false`
    - `tsDeb` can reach this host (`192.168.5.81`) via ping and TCP/22 open
    - peer view from `tsDeb` currently shows MBP and `fedora` tailnet nodes offline; utility nodes `lchl-tsnode-rb2` and `lchl-tsnode-mba` online
- Next action:
  - User enables Tailscale on MBP and validates SSH to `tdj@192.168.5.81` using subnet-route path.

## 2026-02-22 18:48 EST (Codex)
- Area: off-LAN remote access validation (simplified tailscale path)
- Status:
  - User verified successful SSH access to this host over Tailscale from MBP while off-LAN via iPhone hotspot.
  - This confirms the simpler travel posture is working without scripted firewall/scheduler gating.
- Next action:
  - Keep this as primary away-access method; only revisit host-side gating if future policy requires it.

## 2026-02-22 18:52 EST (Codex)
- Area: final travel-access decision checkpoint for repo sync
- Status:
  - Locked final direction to simple tailscale-first access for away work.
  - Retired scripted travel-gating path from active operations and from inventory guidance.
  - Intentionally did not commit travel-gating helper scripts/runbook artifacts, keeping repository guidance aligned with the simpler chosen posture.
- Next action:
  - MBP Codex sessions should use current repo + logs as source of truth; if policy requirements change later, re-open host-side gating as a separate scoped task.

## 2026-02-22 19:39 EST (Codex)
- Area: MBP SSH bootstrap for homelab direct access
- Status:
  - Established control path to MBP via reverse tunnel (`127.0.0.1:2222`) and bridge key.
  - On MBP (`davidnovak`): created dedicated keypair:
    - `~/.ssh/id_ed25519_homelab`
    - `~/.ssh/id_ed25519_homelab.pub` (`mbp-homelab-20260222`)
  - Distributed MBP public key to target hosts' `authorized_keys`:
    - `rb1-admin` (`tdj@192.168.5.114`)
    - `rb2` (`root@192.168.5.108`)
    - `mba` (`root@192.168.5.66`)
    - local workstation (`tdj@192.168.5.81`)
  - Wrote MBP SSH config aliases:
    - `rb1-admin`, `rb1`, `rb2`/`rb2-pve`, `mba`/`mba-pve`, `fedora-workstation`
    - all use `IdentityFile ~/.ssh/id_ed25519_homelab` with `IdentitiesOnly yes`
  - Validated from MBP (non-interactive):
    - `ssh rb1-admin` -> `tdj@rb1-fedora`
    - `ssh rb2` -> `root@rb2-pve`
    - `ssh mba` -> `root@kabbalah`
    - `ssh fedora-workstation` -> `tdj@fedora`
- Next action:
  - On MBP, start Codex from `~/cheney` and use these aliases directly over current tailscale/LAN path.

## 2026-02-22 19:47 EST (Codex)
- Area: WoL validation from `rb2` + sender tooling
- Status:
  - Verified `rb2` sender utility exists: `/usr/bin/wakeonlan`.
  - Validated broadcast behavior on current `/22` LAN:
    - using `255.255.255.255` produced observable WoL UDP traffic.
    - `192.168.5.255` was not correct for this subnet and did not produce expected captures.
  - Packet-capture evidence:
    - `mba` (`vmbr0`) captured WoL UDP packets from `192.168.5.108` to `255.255.255.255:9`.
    - `rb1` capture on `enp20s0u1` showed none in this pass.
    - `rb1` capture on `any` showed WoL UDP packets arriving on `enp0s20f0u1c2`.
  - Added reusable sender script:
    - `scripts/rb2_send_wol.sh` (targets: `rb1`, `rb2`, `mba`, `fedora`; default broadcast `255.255.255.255`)
  - Added runbook:
    - `runbooks/wol-from-rb2-validation.md`
  - Updated inventory notes:
    - `inventory/network-remote-access.md` (`rb2` sender notes and correct broadcast guidance)
- Next action:
  - Perform an attended suspend/off wake test for `rb1` with intended wake NIC path to confirm wake reliability from `rb2` in current cabling topology.

## 2026-02-22 19:49 EST (Codex)
- Area: WoL readiness for local workstation (`fedora`)
- Status:
  - Confirmed local WoL intent settings on `fedora`:
    - NIC: `enp4s0` / MAC `3c:cd:36:67:e2:45`
    - NetworkManager WoL policy: `magic`
    - `/sys/class/net/enp4s0/device/power/wakeup`: `enabled`
  - Confirmed `rb2` sender prepared and target mapping includes `fedora` (`scripts/rb2_send_wol.sh`).
  - `rb2` sender utility available: `wakeonlan`.
- Notes:
  - Local packet capture on `fedora` requires elevated packet-capture capability (`tcpdump` as current user lacks `CAP_NET_RAW`).
  - End-to-end wake proof for this host still requires attended suspend/off wake test.
- Next action:
  - Run live suspend + wake test: trigger repeated WoL packets from `rb2`, suspend `fedora`, verify auto-wake.

## 2026-02-22 19:51 EST (Codex)
- Area: local workstation WoL end-to-end proof (`rb2` -> `fedora`)
- Status:
  - Ran controlled suspend/wake test focused on this host (`fedora`, MAC `3c:cd:36:67:e2:45`).
  - Method:
    - launched `rb2` watcher script to detect ping drop and then send WoL packets.
    - suspended `fedora` via `systemctl suspend`.
    - collected kernel suspend/resume timeline and `rb2` wake-test timeline.
  - Evidence summary:
    - `fedora` journal shows second suspend at `19:50:00 EST`, resume from S3 at `19:50:20 EST`.
    - `rb2` log shows host drop detected, WoL packets sent (`n=1..3`), and host ping returned (`post-wol ping=up`).
    - artifact saved: `notes/wol-artifacts/rb2-wol-wake-test-fedora-20260222.log`.
  - Conclusion:
    - WoL path from `rb2` to this local workstation is operational for suspend-to-wake under current topology.
- Next action:
  - Optional: run equivalent attended off-state wake test if full G3/S5 behavior is required; otherwise current suspend-to-wake path is validated.

## 2026-02-22 19:55 EST (Codex)
- Area: WoL+SSH pattern extension for `rb1`/`rb2`/`mba` (non-disruptive pass)
- Status:
  - Applied operator direction to skip per-host suspend/off wake tests for this pass.
  - Verified key-based SSH access is currently healthy for all three hosts:
    - `ssh -o BatchMode=yes rb1-admin` -> `tdj@rb1-fedora`
    - `ssh -o BatchMode=yes rb2` -> `root@rb2-pve`
    - `ssh -o BatchMode=yes mba` -> `root@kabbalah`
  - Verified current WoL capability state:
    - `rb1` `enp20s0u1`: `Supports Wake-on: pg`, `Wake-on: g`
    - `rb2` `enx00051bde7e6e`: `Supports Wake-on: pumbg`, `Wake-on: g`
    - `mba` `nic0`: `Supports Wake-on: pumbg`, `Wake-on: g`
  - Captured on-wire WoL packet emission from `rb2` for `rb1` + `rb2` + `mba` in one pass:
    - source `192.168.5.108` -> `255.255.255.255:9`
    - payload contains each target MAC block (`90:20:3a:1b:e8:d6`, `00:05:1b:de:7e:6e`, `00:24:32:16:8e:d3`)
    - artifact: `notes/wol-artifacts/rb2-wol-multi-target-emission-20260222-195432.log`
  - Updated docs to reflect accepted validation method and latest test timestamps:
    - `inventory/network-remote-access.md`
    - `runbooks/wol-from-rb2-validation.md`
- Next action:
  - Commit and push WoL/SSH validation updates.

## 2026-02-22 19:56 EST (Codex)
- Area: WoL+SSH validation batch committed and pushed
- Status:
  - Committed validation batch on `main`:
    - commit `9743978`
    - message: `docs: validate rb2 WoL+SSH baseline across core hosts`
  - Pushed to origin:
    - `d31452e..9743978  main -> main`
  - Scope included:
    - `scripts/rb2_send_wol.sh`
    - `runbooks/wol-from-rb2-validation.md`
    - `inventory/network-remote-access.md`
    - `notes/wol-artifacts/rb2-wol-wake-test-fedora-20260222.log`
    - `notes/wol-artifacts/rb2-wol-multi-target-emission-20260222-195432.log`
    - `log.md`
- Next action:
  - Optional: add host-side one-liner wrappers on `rb1`/`mba` for local self-check of WoL config before travel windows.

## 2026-02-22 20:22 EST (Codex)
- Area: smart-switch uplink cable swap validation (before/after)
- Status:
  - Captured pre-swap snapshot: `notes/network-uplink-swap/20260222-201007-before-uplink-cable-swap.txt`.
  - Captured post-swap snapshot: `notes/network-uplink-swap/20260222-202149-after-uplink-cable-swap.txt`.
  - IP/routing continuity check passed; no topology/IP drift detected after replacing the uplink cable.
    - local host remained `192.168.5.81/22`, default gateway `192.168.4.1`.
    - `rb1` remained `192.168.5.114/22`.
    - `rb2` remained `192.168.5.108/22`.
    - `mba` remained `192.168.5.66/22`.
  - Connectivity checks remained healthy post-swap:
    - gateway ping up, internet ping up (`1.1.1.1`, `8.8.8.8`), DNS resolution OK.
    - LAN targets (`192.168.5.114`, `192.168.5.108`, `192.168.5.66`, `192.168.5.100`) all up.
  - Expected minor variance only: DNS answer for `github.com` changed (`140.82.112.4` -> `140.82.113.3`), which is normal CDN rotation and not a local network regression.
- Next action:
  - None required; cable replacement validated as no-impact for addressing/connectivity.

## 2026-02-22 20:27 EST (Codex)
- Area: post-settings WoL interference check (`fedora` target)
- Status:
  - User requested verification after changing desktop remote-desktop settings.
  - Confirmed local WoL intent/config still intact:
    - `enp4s0` up on `192.168.5.81/22`
    - NM WoL policy: `magic`
    - `/sys/class/net/enp4s0/device/power/wakeup`: `enabled`
  - Confirmed sender readiness on `rb2`:
    - `enx00051bde7e6e` still `Wake-on: g`
  - Ran non-disruptive pickup test:
    - started packet capture on `mba` (`vmbr0`), sent WoL from `rb2` to `fedora` MAC `3c:cd:36:67:e2:45`
    - capture shows UDP/9 broadcast from `192.168.5.108` to `255.255.255.255`
    - payload includes repeated `3c:cd:36:67:e2:45` magic pattern
  - Evidence artifact:
    - `notes/wol-artifacts/rb2-wol-fedora-post-remote-desktop-setting-20260222-202637.log`
- Conclusion:
  - No observed interference from the remote-desktop settings change; WoL packet path/pickup remains healthy.
- Next action:
  - None required unless you want a full suspend-to-wake confirmation pass again.

## 2026-02-22 22:38 EST (Codex)
- Area: TrueNAS 1TB add attempt + fallback to oyPool backup path
- Status:
  - User authorized non-perfect path to attempt 1TB pool bring-up.
  - Brought VM100 up with explicit USB mappings and temporarily added third passthrough (`usb2: host=4-2.2.2,usb3=1`).
  - 1TB candidate disk repeatedly failed low-sector reads (`sector 0` / `Input/output error` / unrecovered read errors) on both host and guest probes.
  - `rb1Backups` pool could be created on the device but accumulated immediate read errors and unstable create behavior; disk judged non-functional for reliable use.
  - Per user conditional instruction, abandoned bad-disk path and reverted VM100 to stable mapping (`usb0` easystore + `usb1` oyPool bridge only; removed `usb2`).
  - Post-revert validation: TrueNAS reachable, QGA up, `zpool status -xv` healthy for `boot-pool`, `oyPool`, and `veyDisk`.
- Data movement attempt:
  - Copied existing `oyPool/rb1AssistantBackups` content to `rb1Backups/backups/rb1AssistantBackups` during test path (file/dir counts matched), but this target is on the bad disk and not used after fallback.
- Executed backup action (fallback plan):
  - Ran regular rb1 backup to oyPool via `/home/tdj/bin/rb1_truenas_backup.sh create overwrite-20260222-223637`.
  - Pruned to latest only: `/home/tdj/bin/rb1_truenas_backup.sh prune 1`.
  - Verification: only snapshot remaining is `overwrite-20260222-223637` under `/mnt/oyPool/rb1AssistantBackups/snapshots`; measured size ~23M.
- User-facing state:
  - Bad disk is safe to eject after usb2 removal (not mounted/held by host; VM no longer mapped to it).
- Next action:
  - If a healthy replacement 1TB disk is attached later, recreate `rb1Backups` cleanly and migrate from oyPool in one pass.

## 2026-02-22 22:52 EST (Codex)
- Area: rb1 assistant stack teardown + reboot clean-slate validation
- Scope requested:
  1. Checksum backup.
  2. If backup good, remove assistant stack except Codex (if present).
  3. Reboot and verify clean state.
- Backup integrity evidence:
  - Target snapshot: `/mnt/oyPool/rb1AssistantBackups/snapshots/overwrite-20260222-223637`.
  - Generated per-file manifest (`934` files):
    - `/mnt/oyPool/rb1AssistantBackups/snapshots/overwrite-20260222-223637/meta/file_sha256_manifest-20260222-194925.txt`
    - `/mnt/oyPool/rb1AssistantBackups/snapshots/overwrite-20260222-223637/meta/file_sha256_manifest-20260222-194925.txt.sha256`
  - Manifest self-check passed: `sha256sum -c ... : OK`.
- Teardown performed on `rb1-fedora`:
  - Stopped/disabled `ollama.service`.
  - Stopped/disabled user `openclaw` gateway unit(s) and removed user unit file.
  - Removed global npm assistant packages (root + `tdj`): `openclaw`, `clawhub`, `mcporter`, `@steipete/oracle`.
  - Removed assistant state dirs:
    - `/home/tdj/.openclaw`
    - `/home/tdj/.config/openclaw`
    - `/home/tdj/cognee-native`
    - `/home/tdj/cognee-pilot`
    - related caches under `/home/tdj/.cache/*`
  - Removed Ollama runtime artifacts (`/usr/share/ollama`, binary/service files).
  - Cleaned stale OpenClaw completion line from `/home/tdj/.bashrc`.
  - Preserved Codex artifacts (`/home/tdj/.codex`).
- Reboot and post-boot validation:
  - Reboot issued; host returned (`rb1-fedora`) in ~12s.
  - Post-boot checks show:
    - no `ollama`/`openclaw`/`cognee` services,
    - no assistant processes,
    - npm global list empty,
    - assistant data dirs removed,
    - `.codex` still present.
- Additional operator note:
  - Bad disk is safe to eject (`usb2` removed from VM100; host shows no holders/mounts on the failed device path).
- Next action:
  - Ready for new assistant strategy bootstrap from clean baseline.
