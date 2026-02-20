# OpenClaw Safe-Turn Benchmark

timestamp_local: 2026-02-20 14:48:33 EST  
host_alias: rb1-admin  
mode: gateway  
agent: main  
thinking: off  
profile: control

| case | forced_outage | backstop_used | final_provider | final_model | final_rc | tokens | duration_ms | wrapper_elapsed_ms | response_excerpt |
|---|---:|---:|---|---|---:|---:|---:|---:|---|
| bench_01_marker | 0 | 0 | ollama | qwen2.5:7b | 0 | 8817 | 24074 | 30103 | BENCH_OK_01 |
| bench_02_math | 0 | 0 | ollama | qwen2.5:7b | 0 | 8864 | 750 | 7163 | 399 |
| bench_03_extract | 0 | 0 | ollama | qwen2.5:7b | 0 | 8939 | 1282 | 7661 | 192.168.5.107 |
| bench_04_wol | 0 | 0 | ollama | qwen2.5:7b | 0 | 8999 | 1544 | 7774 | Wake-on-LAN allows a computer to be booted via a network wake-up message. |
| bench_05_cmd | 0 | 0 | ollama | qwen2.5:7b | 0 | 9083 | 1974 | 8281 | ```bash ping -c 2 -W 1 172.31.99.2 ``` |
| bench_06_status | 0 | 0 | ollama | qwen2.5:7b | 0 | 9130 | 895 | 7223 | BENCH_OK_06 |
| bench_07_forced_outage | 1 | 1 | openai-codex | gpt-5.3-codex | 0 | 8428 | 1093 | 13215 | BENCH_OK_07 |

## Summary
count=7
success_count=7
backstop_count=1
final_provider_ollama=6
final_provider_openai_codex=1
avg_tokens=8894
avg_duration_ms=4516
avg_wrapper_elapsed_ms=11631
cloud_final_tokens_total=8428
cloud_final_tokens_avg=8428
forced_outage_wrapper_elapsed_ms=13215

Artifacts:
- JSONL: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260220-144833.jsonl
- Log: notes/openclaw-artifacts/openclaw-safe-turn-benchmark-20260220-144833.log
