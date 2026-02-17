# OpenClaw CLI Feature Findings (`rb1-fedora`, 2026-02-16)

Context: unattended feature reconnaissance while user was away, after installing `openclaw 2026.2.15` on `rb1-fedora`.

## Most Useful Non-Obvious Features

1. Profile isolation:
   - `--profile <name>` cleanly splits config/state/session stores (`~/.openclaw-<name>`).
   - Useful for safe evaluation tracks (`rb1eval`) without polluting a future production profile.

2. Non-interactive onboarding guardrails:
   - `openclaw onboard --non-interactive` requires `--accept-risk`.
   - Useful to keep automation explicit and avoid silent privileged bootstrap.

3. Model-plane controls beyond simple default model:
   - `models aliases` for short names.
   - `models fallbacks` for outage handling.
   - `models auth order` for per-agent auth precedence.

4. Built-in operational diagnostics:
   - `status --all/--json` returns gateway, sessions, service install state, and security findings.
   - `doctor --non-interactive` gives actionable checks (auth store, memory embeddings, gateway state).

5. Memory readiness checks:
   - Memory plugin can be enabled while semantic recall remains inactive until embeddings are configured.
   - `memory status` and doctor output make this explicit.

6. Approval and execution policy controls:
   - `approvals allowlist/get/set` enables explicit command safety boundaries per agent.

7. Built-in schedulers and extension points:
   - `cron` job lifecycle commands (`add`, `run`, `runs`, `status`).
   - `plugins` install/update/enable/doctor for extensibility.

8. Gateway exposure controls:
   - `gateway --bind` (`loopback|lan|tailnet|auto|custom`) and `--tailscale` (`off|serve|funnel`) are first-class flags.
   - Useful for staged rollout from local-only to remote access.

9. Paired-node and remote tooling:
   - `nodes` includes pairing approval plus capability invokes (`describe`, `invoke`, `status`).

10. Built-in docs search:
   - `openclaw docs <query>` quickly resolves provider/env questions from official docs.

## Key Findings From Live Probes

1. API-key mode works on headless host when model provider is `openai/*`:
   - Intentional invalid key produced OpenAI `401`, proving provider path is active.
2. `openai-codex/*` alias resolution currently expects dedicated auth profile/OAuth path:
   - with only `OPENAI_API_KEY`, agent run reported `No API key found for provider "openai-codex"`.
3. For API-key smoke, set model explicitly to `openai/gpt-5-mini` (or other `openai/*`) before test.

## Evidence

1. Artifact: `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-prekey-20260216-215225.log`.
2. Command surfaces sampled: `openclaw --help`, `models --help`, `onboard --help`, `gateway --help`, `status --help`, `doctor --help`, `cron --help`, `plugins --help`, `approvals --help`, `memory --help`, `nodes --help`.
