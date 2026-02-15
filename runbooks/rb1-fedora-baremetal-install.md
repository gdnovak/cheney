# Runbook: `rb1` Fedora Baremetal Install (Post-`truenas` Cutover)

Purpose: convert `rb1` from Proxmox host to Fedora baremetal after storage service has moved to `rb2`.

## Preconditions

1. `truenas` is running and healthy on `rb2` (VM `100`).
2. `rb1` no longer carries active storage-critical workloads.
3. You have physical console access for install/reboot handling.
4. A USB installer for Fedora Server is prepared.

## Preflight Capture (Before Wipe)

Run on `rb1` and copy artifacts off-host (`rb2` or workstation):

```bash
mkdir -p /root/pre-fedora-capture
cp -a /etc/pve /root/pre-fedora-capture/etc-pve
cp -a /etc/network/interfaces /root/pre-fedora-capture/interfaces
qm list > /root/pre-fedora-capture/qm-list.txt
pct list > /root/pre-fedora-capture/pct-list.txt
ip -4 -br addr > /root/pre-fedora-capture/ip-addr.txt
ip route > /root/pre-fedora-capture/ip-route.txt
tar -C /root -czf /root/pre-fedora-capture.tar.gz pre-fedora-capture
```

Copy out:

```bash
scp root@<rb1-ip>:/root/pre-fedora-capture.tar.gz ./rb1-pre-fedora-capture-$(date +%Y%m%d-%H%M%S).tar.gz
```

## Install Guidance

1. Use Fedora Server installer (recommended stable branch).
2. Use full-disk install on `rb1` system disk (this is destructive to current Proxmox OS).
3. During install networking:
   - Keep management bound to the dedicated USB Ethernet path.
   - Keep eGPU Ethernet disconnected for first boot validation.
4. Set hostname target to `rb1-fedora` (or agreed canonical `lchl-compute-rb1`).

## First Boot Baseline

```bash
sudo dnf -y update
sudo dnf -y install git tmux jq htop curl wget python3 python3-pip
sudo systemctl enable --now sshd
ip -4 -br addr
```

## Post-Install Validation

1. SSH from workstation to new `rb1` host succeeds.
2. Reboot once and verify host returns on same management interface/IP.
3. Only after network stability is confirmed, connect eGPU path and proceed with NVIDIA stack work.

## Rollback

If Fedora install fails operationally:

1. Reinstall Proxmox on `rb1` from ISO.
2. Restore captured network settings and SSH access.
3. Keep `truenas` on `rb2` as primary until rollback host is stable.
