# Assistant Sandbox Bootstrap (`rb1`)

Purpose: bootstrap a temporary safe VM on `rb1` for Codex subagent + Ollama experiments without mutating core host workflows.

## Scope

- In scope: disposable sandbox VM + coordination bus + guardrails.
- Out of scope: direct deployment to Proxmox host, OpenClaw production rollout.

## Hard Gate

Autonomous unattended runs are disabled until eGPU accessibility check passes:

```bash
scripts/assistant/check_egpu_ready.sh rb1-pve
```

If this fails, only attended/manual runs are allowed.

## VM Baseline

1. Host: `rb1-pve`.
2. Guest OS: Ubuntu Server (LTS recommended).
3. Suggested starter size:
   - vCPU: 4
   - RAM: 8G (adjust later)
   - disk: 64G
4. Enable guest agent and snapshot capability.
5. Create baseline snapshot: `clean-base`.

## In-Guest Setup Steps

1. Install system packages:
   - `git`, `curl`, `jq`, `python3`, `tmux`, `ca-certificates`.
2. Clone repo:
   - `git clone <repo-url> ~/cheney`
3. Install Ollama runtime.
4. Install Codex in VM (operator-managed step).
5. Pull one small and one medium local model in Ollama.

## Coordination Bus Setup

1. Use `coordination/` directory as shared protocol.
2. Validate templates exist:
   - `coordination/tasks/TASK_TEMPLATE.yaml`
   - `coordination/reports/REPORT_TEMPLATE.md`
3. Validate policy files:
   - `coordination/policies/safety.yaml`
   - `coordination/policies/budget.yaml`
   - `coordination/policies/approvals.yaml`

## Subagent Runtime Setup

1. Ensure assistant scripts are executable:
   - `scripts/assistant/*.sh`
2. Configure environment variables:
   - `AGENT_ID=vm-codex-rb1`
   - `SAFETY_MODE=enforced`
3. Start periodic heartbeat job (timer/cron).
4. Configure event emission path.

## Push Notifications

Use hybrid notification:

1. Durable:
   - heartbeat + `events.log` in repo.
2. Push:
   - webhook notifier (e.g., ntfy) for `task_done`, `task_failed`, `rebooting`, `watchdog_kill`.

## Acceptance Criteria

1. VM reachable and snapshotted.
2. Ollama responds locally.
3. Codex environment installed in VM.
4. Heartbeat updates and events append correctly.
5. eGPU gate check integrated and enforced for unattended mode.
6. Watchdog blocks unattended tasks if eGPU not ready.

## Rollback

1. Stop subagent services.
2. Revert VM to `clean-base` snapshot.
3. Restore repo state from `main`.
