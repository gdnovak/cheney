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
