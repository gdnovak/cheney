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
