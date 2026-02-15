# Heartbeat Schema (`coordination/state/heartbeat.json`)

Required keys:

1. `agent_id` (string)
2. `host` (string)
3. `status` (`idle|running|blocked|paused`)
4. `active_task_id` (string, can be empty)
5. `last_update_utc` (ISO-8601 UTC)
6. `egpu_ready` (boolean)
7. `safety_mode` (string)
8. `notes` (string)
