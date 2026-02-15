# Event Line Schema (`coordination/state/events.log`)

Format:

`timestamp_utc|host|agent_id|event_type|task_id|severity|message`

Fields:

1. `timestamp_utc`: ISO-8601 UTC timestamp.
2. `host`: hostname emitting event.
3. `agent_id`: logical agent ID.
4. `event_type`: one of known event names.
5. `task_id`: task ID or `-` if none.
6. `severity`: `info|warn|error|critical`.
7. `message`: short one-line message.
