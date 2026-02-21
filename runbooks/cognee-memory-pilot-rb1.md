# Cognee Memory Pilot (rb1)

Date: 2026-02-21  
Target host: `rb1-admin` (`rb1-fedora`)

## Goal

Pilot Cognee as a memory sidecar for resumable context retrieval, without changing live OpenClaw routing defaults.

## Phase 0: Non-invasive prep (implemented)

1. Build safe ingest scope manifest:

```bash
cd /home/tdj/cheney
scripts/cognee_memory_scope_build.sh
```

2. Probe rb1 prerequisites and capture report:

```bash
cd /home/tdj/cheney
scripts/cognee_env_probe.sh rb1-admin
```

Outputs:

- `notes/cognee/cognee-scope-manifest.txt`
- `notes/cognee/cognee-env-probe-<timestamp>.md`

## Phase 1: Isolated pilot (deferred until approved)

Suggested approach:

1. Create isolated venv on `rb1`:

```bash
ssh rb1-admin 'python3 -m venv /home/tdj/.venvs/cognee-pilot'
```

2. Install Cognee with Ollama integration:

```bash
ssh rb1-admin 'source /home/tdj/.venvs/cognee-pilot/bin/activate && pip install -U pip && pip install "cognee[ollama]"'
```

3. Ingest only manifest-approved markdown content.
4. Run retrieval checks against real resume prompts.
5. Record precision/failure notes before any OpenClaw integration.

## Guardrails

- Keep OpenClaw router settings unchanged during pilot.
- Do not index `notes/*artifacts*`, raw logs, or token-bearing files.
- Keep pilot storage isolated from existing OpenClaw state directories.

## Exit criteria

- Retrieval quality passes the acceptance gate in `notes/cognee-fit-assessment-20260221.md`.
- If quality is poor or noisy, remove pilot and keep lexical memory workflow only.
