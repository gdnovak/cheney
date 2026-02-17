# Ollama Dual-GPU Stress Report (rb1)

Date generated: 2026-02-17 16:06:30 EST

## Scope

- Objective: push local Ollama workload (no Codex fallback) and verify both GTX 1060 GPUs under sustained load.
- Safety controls: watchdog hard-stop at 78C, sustained-warn threshold 74C, hard kernel fault signatures (Xid/fatal/uncorrectable) as stop conditions.
- Artifact set:
  - `notes/ollama-stress-20260217-152444/requests.jsonl`
  - `notes/ollama-stress-20260217-152444/nvidia-monitor.csv`
  - `notes/ollama-stress-20260217-152444/run.log`
  - `notes/ollama-stress-20260217-152444/watchdog.log`

## Outcome Summary

- Final status: completed and stopped on request.
- Window: 2026-02-17T20:24:52Z -> 2026-02-17T21:04:03Z
- Requests: 185 total, 185 successful.
- Throughput: avg 22 tok/s (min 21, max 24).
- Latency: avg 15211 ms, p95 35777 ms, max 59236 ms.
- Marker misses: 7 (all non-fatal output-format misses).
- Watchdog stops: none.

## GPU Utilization and Thermal Evidence

- gpu0 samples=2425 util_avg=43 util_min=0 util_max=97 temp_avg=60 temp_min=41 temp_max=70 mem_avg_mib=4871 power_avg_w=47 util_ge80_samples=1102 power_ge100_samples=0
- gpu1 samples=2425 util_avg=65 util_min=0 util_max=96 temp_avg=69 temp_min=52 temp_max=76 mem_avg_mib=4799 power_avg_w=89 util_ge80_samples=1681 power_ge100_samples=1685

Interpretation:

1. Both GPUs were actively used during the stress run.
2. eGPU (gpu1) carried the heavier sustained share (higher utilization and power profile).
3. Maximum observed temperature was 76C, below the 78C hard-stop threshold.

## Model Breakdown

- qwen2.5-coder:7b: count=62, avg_tps=21, avg_elapsed_ms=18406
- qwen2.5:7b: count=123, avg_tps=23, avg_elapsed_ms=13600

## Odd Output Notes

Marker misses were limited to `qwen2.5-coder:7b` in `parallel_b` under concurrency and did not coincide with hardware errors:

- 2026-02-17T20:26:07Z | cycle 4 | qwen2.5-coder:7b parallel_b | elapsed_ms=3735
- 2026-02-17T20:34:16Z | cycle 21 | qwen2.5-coder:7b parallel_b | elapsed_ms=4779
- 2026-02-17T20:37:10Z | cycle 26 | qwen2.5-coder:7b parallel_b | elapsed_ms=3606
- 2026-02-17T20:41:31Z | cycle 33 | qwen2.5-coder:7b parallel_b | elapsed_ms=3984
- 2026-02-17T20:55:06Z | cycle 51 | qwen2.5-coder:7b parallel_b | elapsed_ms=4597
- 2026-02-17T21:00:02Z | cycle 56 | qwen2.5-coder:7b parallel_b | elapsed_ms=3846
- 2026-02-17T21:04:00Z | cycle 62 | qwen2.5-coder:7b parallel_b | elapsed_ms=4584

## Verdict

- Hardware status: operational for sustained 7B-class local inference.
- Safety status: no hard-fault events and no thermal cutoff reached.
- Practical capacity: viable for local assistant workloads; throughput/latency profile remains modest by modern standards.
