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
