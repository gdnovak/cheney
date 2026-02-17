# Overnight Reliability Report (OpenClaw Safe-Turn Probe)

Date generated: 2026-02-17 14:52 EST

## Run Context

- Host: `rb1` (process ran locally on host)
- Probe script: `scripts/openclaw_overnight_probe.sh`
- Prompt each cycle: `Write a 3-line haiku about system uptime. End with token: PROBE_<UTC_TIMESTAMP>`
- Interval target: 1800s (30m)
- Mode: `gateway`
- Wrapper path: `scripts/openclaw_agent_safe_turn.sh --host local`
- Source artifact: `notes/openclaw-artifacts/overnight-probe-20260217-041629.jsonl`

## High-Level Results

- Cycles executed: 21
- Success/failure: 21/0
- Backstops used: 0
- Provider split: 21 `ollama` / 0 `openai-codex`
- Error rows: none
- Time window: 2026-02-17T09:16:29Z -> 2026-02-17T19:29:25Z

## Timing and Cost Signals

- Wrapper elapsed ms: avg 38,990 | p95 43,262 | min 7,247 | max 43,777
- Model duration ms: avg 34,443 | min 2,846 | max 39,256
- Tokens per cycle: avg 12,152 | min 11,144 | max 13,161
- Cloud tokens consumed: 0
- Interval behavior: 20 intervals, min 1,807s, max 1,844s, avg 1,838s

## Behavior Notes

1. Reliability was stable: no failed cycles, no fallback events, no transport errors.
2. All outputs included the expected `PROBE_...` marker token.
3. Latency and token counts rose steadily across cycles (first tokens 11,144 -> last 13,161; first wrapper 7,247ms -> last 43,777ms), consistent with context growth in a persistent agent session.
4. Later-cycle latency outliers (>42s) appeared at cycles 17-21 while still succeeding.
5. Output quality looked consistent and non-pathological: short haikus, no malformed/empty outputs, no exact duplicate excerpts.

## Outlier Cycles (>42s wrapper)

- cycle 17 @ 2026-02-17T17:26:33Z: 42,497ms, 12,757 tokens
- cycle 18 @ 2026-02-17T17:57:15Z: 42,976ms, 12,859 tokens
- cycle 19 @ 2026-02-17T18:27:59Z: 43,151ms, 12,959 tokens
- cycle 20 @ 2026-02-17T18:58:42Z: 43,262ms, 13,059 tokens
- cycle 21 @ 2026-02-17T19:29:25Z: 43,777ms, 13,161 tokens

## Cycle-by-Cycle Detail

| Cycle | Timestamp (UTC) | Provider | Model | Tokens | Duration ms | Wrapper ms | Error | Output Excerpt |
|---:|---|---|---|---:|---:|---:|---|---|
| 1 | 2026-02-17T09:16:29Z | ollama | qwen2.5:7b | 11144 | 2846 | 7247 | none | Blinks never fail, Whispers of data flow— Uptime keeps watch PROBE_20260217T091629Z |
| 2 | 2026-02-17T09:46:36Z | ollama | qwen2.5:7b | 11244 | 32942 | 37450 | none | Constantly online, Echoes of tasks fulfilled— Uptime's steadfast beat PROBE_20260217T094636Z |
| 3 | 2026-02-17T10:17:14Z | ollama | qwen2.5:7b | 11345 | 33353 | 37982 | none | Consistent and strong, Pulse of the network beats— Uptime keeps vigil PROBE_20260217T101714Z |
| 4 | 2026-02-17T10:47:52Z | ollama | qwen2.5:7b | 11447 | 33719 | 38261 | none | Endures through time, Silent guardian of bits— Uptime's unwavering PROBE_20260217T104752Z |
| 5 | 2026-02-17T11:18:30Z | ollama | qwen2.5:7b | 11548 | 33895 | 38245 | none | Consistent and clear, Whispers of data flow— Uptime's steady watch PROBE_20260217T111830Z |
| 6 | 2026-02-17T11:49:08Z | ollama | qwen2.5:7b | 11649 | 33902 | 38375 | none | Persistent and bright, Silent sentinel of bits— Uptime's unyielding PROBE_20260217T114908Z |
| 7 | 2026-02-17T12:19:47Z | ollama | qwen2.5:7b | 11751 | 34704 | 39339 | none | Steadfast and true, Whispers of data flow— Uptime's silent guard PROBE_20260217T121947Z |
| 8 | 2026-02-17T12:50:26Z | ollama | qwen2.5:7b | 11851 | 34812 | 39480 | none | Continuous and strong, Whispers of tasks fulfilled— Uptime's silent watch PROBE_20260217T125026Z |
| 9 | 2026-02-17T13:21:06Z | ollama | qwen2.5:7b | 11952 | 35097 | 39790 | none | Endures through time, Whispers of data flow— Uptime's steadfast guard PROBE_20260217T132106Z |
| 10 | 2026-02-17T13:51:46Z | ollama | qwen2.5:7b | 12053 | 35218 | 39849 | none | Consistent and clear, Whispers of bits flow— Uptime's steady watch PROBE_20260217T135146Z |
| 11 | 2026-02-17T14:22:26Z | ollama | qwen2.5:7b | 12153 | 35602 | 40268 | none | Persistent and bright, Whispers of data flow— Uptime's silent guard PROBE_20260217T142226Z |
| 12 | 2026-02-17T14:53:06Z | ollama | qwen2.5:7b | 12255 | 36028 | 40769 | none | Steadfast and true, Whispers of tasks flow— Uptime's silent watch PROBE_20260217T145306Z |
| 13 | 2026-02-17T15:23:47Z | ollama | qwen2.5:7b | 12355 | 36456 | 41008 | none | Continuous and clear, Whispers of bits flow— Uptime's steady watch PROBE_20260217T152347Z |
| 14 | 2026-02-17T15:54:28Z | ollama | qwen2.5:7b | 12455 | 36996 | 41383 | none | Persistent and strong, Whispers of data flow— Uptime's silent guard PROBE_20260217T155428Z |
| 15 | 2026-02-17T16:25:09Z | ollama | qwen2.5:7b | 12557 | 37389 | 41771 | none | Steadfast and true, Whispers of tasks flow— Uptime's silent watch PROBE_20260217T162509Z |
| 16 | 2026-02-17T16:55:51Z | ollama | qwen2.5:7b | 12657 | 37351 | 41928 | none | Continuous and clear, Whispers of data flow— Uptime's steady guard PROBE_20260217T165551Z |
| 17 | 2026-02-17T17:26:33Z | ollama | qwen2.5:7b | 12757 | 37817 | 42497 | none | Persistent and bright, Whispers of bits flow— Uptime's silent watch PROBE_20260217T172633Z |
| 18 | 2026-02-17T17:57:15Z | ollama | qwen2.5:7b | 12859 | 38635 | 42976 | none | Steadfast and true, Whispers of data flow— Uptime's silent guard PROBE_20260217T175715Z |
| 19 | 2026-02-17T18:27:59Z | ollama | qwen2.5:7b | 12959 | 38488 | 43151 | none | Continuous and clear, Whispers of bits flow— Uptime's steady watch PROBE_20260217T182759Z |
| 20 | 2026-02-17T18:58:42Z | ollama | qwen2.5:7b | 13059 | 38810 | 43262 | none | Persistent and strong, Whispers of data flow— Uptime's silent guard PROBE_20260217T185842Z |
| 21 | 2026-02-17T19:29:25Z | ollama | qwen2.5:7b | 13161 | 39256 | 43777 | none | Steadfast and true, Whispers of tasks flow— Uptime's silent watch PROBE_20260217T192925Z |
