# Naming Convention (`lcHL`)

Purpose: standardize identifiers without forcing immediate host/service renames.

## Canonical Prefix

- Project codename: `LichCheney`.
- Standard abbreviation: `lcHL`.
- Canonical lowercase prefix for machine-readable IDs: `lchl-`.

## Pattern

- Preferred format: `lchl-<role>-<node>`.
- Keep role tokens short and explicit (`pve`, `tsnode`, `storage`, `watcher`).

Examples:

- `lchl-pve-rb1`
- `lchl-pve-rb2`
- `lchl-pve-mba`
- `lchl-tsnode-rb2`
- `lchl-tsnode-mba`
- `lchl-tsdeb-rb1`

## Current-to-Canonical Mapping

| current_name | canonical_name |
|---|---|
| `rb1-pve` | `lchl-pve-rb1` |
| `rb2-pve` | `lchl-pve-rb2` |
| `kabbalah` (`mba`) | `lchl-pve-mba` |
| `tsDeb` / `tsdeb-rb1` | `lchl-tsdeb-rb1` |
| `lchl-tsnode-rb2` (legacy: `tsnode-rb2`) | `lchl-tsnode-rb2` |
| `lchl-tsnode-mba` (legacy: `tsnode-mba`) | `lchl-tsnode-mba` |
| `truenas` VM | `lchl-storage-truenas` |

## Rollout Rule

- Apply this naming first in documentation, tags, and labels.
- Live rename completed for utility Tailscale VMs (`201`, `301`) on 2026-02-14.
- Defer core host/critical service renames to a scheduled maintenance window.
