# OpenClaw Safe-Turn Benchmark

timestamp_local: 2026-02-17 03:47:00 EST  
host_alias: rb1-admin  
mode: gateway  
agent: main  
thinking: off

| case | forced_outage | backstop_used | final_provider | final_model | final_rc | tokens | duration_ms | wrapper_elapsed_ms | response_excerpt |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| bench_01_marker | 0 | 0 | ollama | qwen2.5:7b | 0 | 9625 | 26365 | 31781 | BENCH_OK_01 |
| bench_02_math | 0 | 0 | ollama | qwen2.5:7b | 0 | 9672 | 777 | 6217 | 399 |
| bench_03_extract | 0 | 0 | ollama | qwen2.5:7b | 0 | 9747 | 1324 | 6644 | 192.168.5.107 |
| bench_04_wol | 0 | 0 | ollama | qwen2.5:7b | 0 | 9811 | 1747 | 7101 | Wake-on-LAN is a standard that allows a computer to be turned on or awakened by a network  |
| bench_05_cmd | 0 | 0 | ollama | qwen2.5:7b | 0 | 9890 | 1770 | 7303 | ping -c 2 -W 1 172.31.99.2 |
| bench_06_status | 0 | 0 | ollama | qwen2.5:7b | 0 | 9937 | 965 | 6483 | BENCH_OK_06 |
| bench_07_forced_outage | 1 | 1 | openai-codex | gpt-5.3-codex | 0 | 9083 | 1747 | 12219 | BENCH_OK_07 |

## Summary
count=7
success_count=7
backstop_count=1
final_provider_ollama=6
final_provider_openai_codex=1
avg_tokens=9680
avg_duration_ms=4956
avg_wrapper_elapsed_ms=11106
forced_outage_wrapper_elapsed_ms=12219

Artifacts:
- JSONL: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-034700.jsonl
- Log: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260217-034700.log
