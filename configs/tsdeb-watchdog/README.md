# tsDeb Watchdog Config

This folder tracks the currently deployed watchdog on `tsDeb` (VM 101) that checks host reachability and sends WoL packets when a node is down.

## Deployed Runtime Paths (tsDeb)

- `/usr/local/sbin/tsdeb-watchdog.sh`
- `/etc/systemd/system/tsdeb-watchdog.service`
- `/etc/systemd/system/tsdeb-watchdog.timer`

## Current Behavior

- Every 2 minutes after boot (initial delay 90 seconds), run ping checks for:
  - `rb1` (`192.168.5.98`)
  - `rb2` (`192.168.5.108`)
  - `mba` (`192.168.5.66`)
- If a host ping fails, send WoL magic packet via broadcast `192.168.7.255` to the configured MAC.
- Logs go to journald via logger tag `tsdeb-watchdog`.

## Verification Commands (inside tsDeb)

```bash
systemctl is-enabled tsdeb-watchdog.timer
systemctl is-active tsdeb-watchdog.timer
systemctl start tsdeb-watchdog.service
journalctl -u tsdeb-watchdog.service -n 50 --no-pager
```

## Notes

- This watcher currently uses ping-only health checks for low friction.
- Closed-lid reboot behavior still needs explicit validation cycles before hardware recabling.
