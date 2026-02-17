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
