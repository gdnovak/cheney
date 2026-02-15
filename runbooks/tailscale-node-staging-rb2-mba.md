# Tailscale Utility Node Runbook (`rb2` + `mba`)

Purpose: provide low-overhead Tailscale continuity nodes as small utility VMs, not Proxmox host agents.

## Scope

- Hypervisors: `rb2` (`rb2-pve`) and `mba` (`kabbalah`)
- Utility VMs:
  - `tsnode-rb2` (`VMID 201`, `192.168.5.112/22`)
  - `tsnode-mba` (`VMID 301`, `192.168.5.113/22`)
- Policy: keep host-level tailscale disabled on Proxmox nodes unless explicitly required.

## Current State (2026-02-14 22:14 EST)

1. Host-level `tailscaled` on `rb2` and `mba` is disabled.
2. Utility VMs `201` and `301` are running and reachable on LAN.
3. `tailscale` installed inside both utility VMs.
4. Both utility VMs are `NeedsLogin` pending admin approval.

## Verification Commands

```bash
ssh rb2-pve 'systemctl is-enabled tailscaled; systemctl is-active tailscaled'
ssh mba-pve 'systemctl is-enabled tailscaled; systemctl is-active tailscaled'
ssh root@192.168.5.112 'tailscale status'
ssh root@192.168.5.113 'tailscale status'
```

Expected:

1. Proxmox hosts report `disabled` / `inactive` for `tailscaled`.
2. Utility VM status includes `Logged out` and a `Log in at` URL.
3. Utility VMs show `state: NeedsLogin`.

## Approval Flow (When Ready)

```bash
ssh root@192.168.5.112 'tailscale up --ssh --accept-dns=false --accept-routes=false'
ssh root@192.168.5.113 'tailscale up --ssh --accept-dns=false --accept-routes=false'
```

Then approve each node in the intended tailnet account.

## Captured Approval URLs (Current Session)

- `tsnode-rb2`: `https://login.tailscale.com/a/c7cba0f016792`
- `tsnode-mba`: `https://login.tailscale.com/a/c8bf33201fbaa`

## Notes

- Utility-node pattern reduces blast radius versus running tailscale on Proxmox hosts directly.
- If account ownership is uncertain, leave both nodes in `NeedsLogin`.
