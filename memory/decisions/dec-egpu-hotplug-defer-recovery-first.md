---
id: dec-egpu-hotplug-defer-recovery-first
title: Defer eGPU Hotplug Tuning and Operate with Recovery-First Policy
type: decision
tags: [decision, egpu, operations, risk]
created: 2026-02-16
updated: 2026-02-16
scope: cheney
status: accepted
---

# Defer eGPU Hotplug Tuning and Operate with Recovery-First Policy

## Question

Should we spend additional cycles now on stabilizing physical eGPU hot-unplug/replug behavior, or defer that work and proceed with broader project priorities using known recovery procedures?

## Options Considered

1. Continue immediate hotplug tuning and repeatability testing now.
2. Defer hotplug tuning, accept current risk, and proceed with recovery-first operations.

## Decision

Choose option 2.

Hotplug is known temperamental; we will avoid unnecessary cable churn and rely on the validated recovery path if disconnection issues occur.

## Consequences

1. Faster progress on broader project priorities.
2. Known residual risk remains for physical hot-unplug/replug events.
3. Recovery steps must stay current and easy to execute.

## Recovery Baseline

1. Prefer cold-attach workflows.
2. If reattach instability occurs, reboot `rb1` and verify:
   - SSH service availability
   - external GPU presence in `nvidia-smi`
   - fallback VLAN99 bidirectional ping (`rb1` <-> `rb2`)

## Trigger To Revisit

Revisit hotplug tuning when any one condition is true:

1. Hotplug is required for an unattended workflow.
2. Reboot-based recovery is no longer acceptable operationally.
3. We need guaranteed rapid attach/detach behavior for external-display workflows.

## Links

- Index: [[mem-index]]
- Project: [[proj-rb1-fedora-env-baseline]]
