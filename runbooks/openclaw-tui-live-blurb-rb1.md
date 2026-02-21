# OpenClaw TUI Live Blurb Patch (rb1)

Date: 2026-02-21  
Host target: `rb1-admin` (`rb1-fedora`)

## Goal

Add a live footer blurb in OpenClaw TUI showing:

- current action (`idle`, `waiting`, `running`, etc.)
- active model
- inferred tier (`local`, `normal`, `high`, etc.)

## Why this method

- OpenClaw TUI is bundled JS under `/usr/local/lib/node_modules/openclaw/dist/`.
- We patch only known files for current version (`2026.2.15`) and keep on-host backups.
- Patch is idempotent and reversible.

## Files touched on host

- `/usr/local/lib/node_modules/openclaw/dist/tui-DW-D2_SI.js`
- `/usr/local/lib/node_modules/openclaw/dist/tui-CRTpgJsf.js`

Backup suffix:

- `.cheney-live-blurb-v1.bak`

## Commands

1. Apply patch:

```bash
cd /home/tdj/cheney
scripts/rb1_openclaw_tui_live_blurb_patch.sh rb1-admin
```

2. Smoke test:

```bash
cd /home/tdj/cheney
scripts/rb1_openclaw_tui_live_blurb_smoke.sh rb1-admin
```

3. Roll back:

```bash
cd /home/tdj/cheney
scripts/rb1_openclaw_tui_live_blurb_restore.sh rb1-admin
```

## Acceptance checks

- Marker `CHENEY_TUI_LIVE_BLURB_V1` exists in both TUI bundle files.
- `node --check` passes on both files.
- `openclaw status --json` and `openclaw health --json` both return success.

## Notes

- This patch is version-specific and should be revalidated after OpenClaw upgrades.
