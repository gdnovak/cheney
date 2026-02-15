# Runbook: Tomorrow AI Bootstrap on `rb1-fedora`

Purpose: bring up a first attended AI stack on the new Fedora baremetal host with clear rollback and no overnight autonomy yet.

## Scope

In scope:

1. Baseline `rb1-fedora` host hardening + tooling.
2. Install and verify Ollama service.
3. Install and verify Codex CLI workflow on `rb1`.
4. Re-clone `cheney` repo and re-establish `cheney-vessel-alpha` subagent scope.
5. Run one attended smoke loop (no unattended execution).

Out of scope:

1. OpenClaw production use.
2. Autonomous overnight runs.
3. GPU tuning/benchmark optimization beyond initial detection.

## Preconditions

1. `rb1-fedora` reachable over SSH as `root`.
2. `rb2` remains subnet-router/Tailscale continuity anchor.
3. `truenas` and migrated helper VMs remain stable on `rb2`.

## Phase A: Host Baseline

1. System update and base packages:

```bash
sudo dnf -y update
sudo dnf -y install git tmux jq curl wget htop python3 python3-pip pciutils
```

2. Confirm network identity:

```bash
hostnamectl
ip -4 -br addr
```

3. Confirm GPU visibility (internal + eGPU if attached):

```bash
lspci -nnk | grep -EA3 'VGA|3D|Display'
```

## Phase B: Ollama Bring-Up

1. Install Ollama.
2. Enable/start service.
3. Verify local API:

```bash
systemctl status ollama --no-pager
curl -s http://127.0.0.1:11434/api/tags
```

4. Pull one small validation model first (fast smoke), then planned primary model.

Acceptance:

- `ollama` service survives reboot.
- local inference works from CLI/API.

## Phase C: Codex Contractor Bring-Up

1. Re-clone repo to `rb1`:

```bash
git clone https://github.com/gdnovak/cheney.git ~/cheney
```

2. Enter scoped profile path:

```bash
cd ~/cheney/subagents/cheney-vessel-alpha
```

3. Install/validate Codex CLI in this environment.
4. Run one attended task that only writes docs/logs (no risky infra changes).

Acceptance:

- Codex responds and can read/write repo files under scope.
- First attended task completes and records checkpoint.

## Phase D: Control Plane + Guardrails

1. Keep `rb2` utility tailscale nodes as continuity path.
2. Keep unattended automation disabled until:
   - GPU path is stable on `rb1`
   - watchdog policy and rollback checks pass
3. Record any required secret handling changes before enabling autonomous loops.

## Optional Phase E: First GPU Sanity Check

1. If eGPU is attached and stable, install NVIDIA stack on Fedora.
2. Validate with `nvidia-smi`.
3. Re-test one local model inference.

If unstable, fall back to CPU-only validation and continue architecture work.

## Rollback

1. Stop/disable newly added services (`ollama`, custom agents).
2. Keep network + storage continuity on `rb2` untouched.
3. Re-run from Phase A with minimal model/tool footprint.

## Deliverables for Tomorrow

1. Updated `inventory/` for `rb1-fedora` software role.
2. Updated `log.md` with evidence for each phase.
3. Short follow-up plan for OpenClaw evaluation (deferred until baseline stability).
