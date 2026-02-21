# OpenClaw Skill/Plugin Risk Audit

Date: 2026-02-21  
Host: `rb1-fedora` (`rb1-admin`)

## Scope

Identify active dangerous-but-unnecessary OpenClaw runtime skills/plugins and remove them from active attack surface.

## Findings (Enabled Plugins Before Changes)

- `device-pair` (enabled)
  - Risk: can generate/approve pairing flow; unnecessary in steady-state once trusted devices are paired.
- `memory-core` (enabled)
  - Risk: low; local memory tooling.
  - Decision: keep (required for memory retrieval/workflow).
- `phone-control` (enabled)
  - Risk: high; explicitly controls high-risk phone-node actions (camera/screen/writes).
  - Decision: disable (not needed for current rb1 setup).
- `talk-voice` (enabled)
  - Risk: low/moderate; voice selection management.
  - Decision: keep for now.

## Changes Applied

- Disabled plugin `phone-control`.
- Disabled plugin `device-pair`.
- Restarted gateway.

## Enabled Plugins After Changes

- `memory-core`
- `talk-voice`

## Notes

- Bundled plugins are not uninstallable via `openclaw plugins uninstall`; they must be disabled in config.
- Web search/fetch remains intentionally enabled per operator preference and current workflow requirements.

