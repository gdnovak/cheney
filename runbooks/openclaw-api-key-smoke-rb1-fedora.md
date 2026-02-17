# Runbook: OpenClaw API-Key Smoke on `rb1-fedora`

Purpose: validate headless OpenClaw execution against OpenAI using API key auth, without relying on OAuth/browser flow.

## Current Checkpoint (2026-02-16 21:52 EST)

Completed:

1. Installed OpenClaw on `rb1-fedora` (`openclaw 2026.2.15`).
2. Created isolated profile `rb1eval`.
3. Confirmed no gateway daemon/service is installed.
4. Confirmed API-key wiring by running an intentional invalid-key test and receiving OpenAI `401` (provider path reached successfully).
5. Recorded artifact: `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-prekey-20260216-215225.log`.
6. Executed real-key smoke attempts and confirmed provider/model execution path with live key:
   - `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-realkey-20260216-222828.log` (`openai/gpt-5-mini`)
   - `notes/openclaw-artifacts/openclaw-rb1-headless-smoke-realkey-retry-20260216-222853.log` (`openai/gpt-4.1-nano`)
   - both returned `API rate limit reached` before model completion.
7. Confirmed ephemeral cleanup:
   - `/home/tdj/.openai_key_once` removed.
   - `/tmp/openai_key_once` absent on `rb1`.
   - post-cleanup agent call returns `No API key found for provider "openai"`.

Pending:

1. Re-run one real-key smoke prompt after OpenAI rate-limit window resets (or with a higher-quota key) and capture `OPENCLAW_SMOKE_OK`.

## Scope

In scope:

1. Attended smoke validation only.
2. Ephemeral key handling only.
3. No systemd daemon install in this phase.

Out of scope:

1. OAuth flow hardening.
2. Unattended scheduling.
3. Multi-model routing automation.

## Preconditions

1. `rb1-fedora` reachable over SSH.
2. OpenClaw is installed (`openclaw --version`).
3. User has a valid OpenAI API key.

## Step A: Baseline Quick Check

```bash
ssh rb1-fedora 'hostnamectl --static; node -v; npm -v; openclaw --version'
ssh rb1-fedora 'openclaw --profile rb1eval models status --plain'
ssh rb1-fedora 'openclaw --profile rb1eval status --json | jq -r ".gateway.url, .gateway.reachable, .gatewayService.installed"'
```

Expected:

1. Host is `rb1-fedora`.
2. OpenClaw version prints.
3. Gateway service is not installed and not reachable (normal for this phase).

## Step B: Real-Key Smoke (Ephemeral)

Run this as an attended command:

```bash
ssh rb1-fedora 'bash -lc '"'"'
  read -rsp "OPENAI_API_KEY: " OPENAI_API_KEY; echo
  export OPENAI_API_KEY
  openclaw --profile rb1eval models set openai/gpt-5-mini >/dev/null
  openclaw --profile rb1eval agent --local --agent main --message "Respond with exactly: OPENCLAW_SMOKE_OK" --json \
    | jq -r ".payloads[0].text, .meta.agentMeta.provider, .meta.agentMeta.model, .meta.durationMs"
  unset OPENAI_API_KEY
'"'"''
```

Expected success signature:

1. Response text contains `OPENCLAW_SMOKE_OK`.
2. Provider is `openai`.
3. Model is `gpt-5-mini` (or chosen override).

## Step C: Artifact Capture

Capture output to a timestamped artifact:

```bash
ts=$(date +%Y%m%d-%H%M%S)
mkdir -p notes/openclaw-artifacts
ssh rb1-fedora 'bash -lc '"'"'
  read -rsp "OPENAI_API_KEY: " OPENAI_API_KEY; echo
  export OPENAI_API_KEY
  openclaw --profile rb1eval agent --local --agent main --message "Respond with exactly: OPENCLAW_SMOKE_OK" --json \
    | jq -r ".payloads[0].text, .meta.agentMeta.provider, .meta.agentMeta.model, .meta.durationMs"
  unset OPENAI_API_KEY
'"'"'' | tee "notes/openclaw-artifacts/openclaw-rb1-headless-smoke-realkey-${ts}.log"
```

## Rollback

If scope needs to revert to pre-eval state:

```bash
ssh rb1-fedora 'npm uninstall -g openclaw'
ssh rb1-fedora 'rm -rf ~/.openclaw ~/.openclaw-rb1eval'
```

## Acceptance

1. One successful real-key prompt response captured.
2. No persistent API key stored in repo or host service env.
3. Cheney logs updated with timestamped evidence and next action.
