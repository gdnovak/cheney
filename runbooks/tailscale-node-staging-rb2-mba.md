# Tailscale Node Staging Runbook (`rb2` + `mba`)

Purpose: stage tailscale on additional nodes without forcing account binding during setup.

## Scope

- Hosts: `rb2` (`rb2-pve`), `mba` (`kabbalah`)
- Current policy: install and stage only; do not finalize login if account ownership is uncertain.

## Current State (2026-02-14)

1. `tailscale` installed from official stable repo on both nodes.
2. `tailscaled` enabled and active on both nodes.
3. Both nodes are in `BackendState=NeedsLogin`.
4. No tailnet account has been bound on these nodes yet.

## Verification Commands

```bash
ssh rb2 'tailscale status --json | sed -n "1,80p"'
ssh mba 'tailscale status --json | sed -n "1,80p"'
```

Expected:

1. `BackendState` is `NeedsLogin`.
2. `AuthURL` is present.
3. `Health` includes `You are logged out.`

## Login (When Approved)

```bash
ssh rb2 'tailscale up --hostname=rb2-pve --accept-dns=false --accept-routes=false --netfilter-mode=off'
ssh mba 'tailscale up --hostname=mba-pve --accept-dns=false --accept-routes=false --netfilter-mode=off --shields-up'
```

Then approve each node in the correct tailnet account.

## Notes

- `netfilter-mode=off` is intentional for low-friction staging on Proxmox hosts.
- If account ownership is uncertain, keep nodes in `NeedsLogin` until identity is confirmed.
