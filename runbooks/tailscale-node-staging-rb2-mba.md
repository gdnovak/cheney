# Tailscale Utility Node Runbook (`rb2` + `mba`)

Purpose: provide low-overhead Tailscale continuity nodes as small utility VMs, not Proxmox host agents.

## Scope

- Hypervisors: `rb2` (`rb2-pve`) and `mba` (`kabbalah`)
- Utility VMs:
  - `lchl-tsnode-rb2` (`VMID 201`, `192.168.5.112/22`)
  - `lchl-tsnode-mba` (`VMID 301`, `192.168.5.113/22`)
- Policy: keep host-level tailscale disabled on Proxmox nodes unless explicitly required.

## Current State (2026-02-14 22:30 EST)

1. Host-level `tailscaled` on `rb2` and `mba` is disabled.
2. Utility VMs `201` and `301` are running and reachable on LAN.
3. `tailscale` installed inside both utility VMs.
4. Both utility VMs are approved and `BackendState=Running`.

## Verification Commands

```bash
ssh rb2-pve 'systemctl is-enabled tailscaled; systemctl is-active tailscaled'
ssh mba-pve 'systemctl is-enabled tailscaled; systemctl is-active tailscaled'
ssh root@192.168.5.112 'tailscale status'
ssh root@192.168.5.113 'tailscale status'
```

Expected:

1. Proxmox hosts report `disabled` / `inactive` for `tailscaled`.
2. Utility VM status shows active peers and a Tailscale IPv4.
3. Utility VMs show `BackendState=Running`.

## Approval Flow (When Ready)

```bash
ssh root@192.168.5.112 'tailscale up --ssh --accept-dns=false --accept-routes=false'
ssh root@192.168.5.113 'tailscale up --ssh --accept-dns=false --accept-routes=false'
```

Then approve each node in the intended tailnet account.

## Notes

- Utility-node pattern reduces blast radius versus running tailscale on Proxmox hosts directly.
- Do not store auth URLs in repository docs; they expire quickly and cause confusion.
