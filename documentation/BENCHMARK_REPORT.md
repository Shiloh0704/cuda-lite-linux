# CUDA-Lite Linux Distribution: Benchmark & Performance Report

**Target GPU:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute Capability 8.9 / `sm_89`, 6 GB GDDR6)  
**Host CPU:** 13th Gen Intel Core i5-13420H (8 Cores: 4P + 4E, 12 Threads)  
**Test Program:** `./cuda/matrix_mul` (Single-Precision General Matrix Multiplication: SGEMM, $C = \alpha AB + \beta C$)  
**Benchmark Suite:** `benchmarks/run_benchmarks.sh`  
**Execution Environment:** Host Ubuntu 24.04 on WSL2 accessing physical RTX 4050 silicon

---

## 1. Benchmark Execution Methodology

The benchmark compares single-threaded CPU matrix multiplication against two GPU kernel implementations:
1. **CPU Reference Implementation:** Standard three-loop nested matrix multiplication ($O(N^3)$ computational complexity).
2. **GPU Naive Kernel:** Each CUDA thread computes one element of output matrix $C$, with global memory accesses.
3. **GPU Tiled Kernel:** Exploits on-chip Shared Memory ($32 \times 32$ tiles) to cache matrix sub-blocks, eliminating redundant high-latency DRAM fetches.

Calculations:
- **Floating-Point Operations:** $\text{FLOPs} = 2 \times N^3$
- **GFLOPS Throughput:** $\text{GFLOPS} = \frac{2 \times N^3}{\text{Tiled Execution Time (seconds)} \times 10^9}$
- **Raw Compute Speedup:** $\frac{\text{CPU Execution Time}}{\text{GPU Tiled Kernel Time}}$
- **End-to-End Speedup:** $\frac{\text{CPU Execution Time}}{\text{Host-to-Device Transfer} + \text{Tiled Kernel} + \text{Device-to-Host Transfer}}$

---

## 2. Empirical Benchmark Results

### A. Fresh Demonstration Benchmark Run (November 22, 2026)
*Log: `benchmarks/results/benchmark_demo_20261122.log`*

| Matrix Dimension ($N$) | Metric | Value | Unit / Status |
| :---: | :--- | :---: | :---: |
| **$N = 2048$** | **CPU Execution Time** | **1,956.60** | ms |
| | **GPU Naive Kernel Time** | **29.17** | ms |
| | **GPU Tiled Kernel Time** | **21.62** | ms |
| | **Host-to-Device Transfer Time** | **10.72** | ms |
| | **Device-to-Host Transfer Time** | **18.08** | ms |
| | **Total PCIe Transfer Time** | **28.80** | ms |
| | **End-to-End Total Time** | **50.42** | ms |
| | **GPU Sustained Throughput** | **794.71** | **GFLOPS** |
| | **Raw Kernel Compute Speedup** | **90.51x** | speedup over CPU |
| | **End-to-End Speedup** | **38.81x** | speedup over CPU |
| | **Maximum Numerical Error** | **$3.433228 \times 10^{-5}$** | $< 1.0 \times 10^{-3}$ threshold |
| | **Correctness Verification** | **PASSED** | Exit Code: 0 |

### B. Multi-Size Matrix Scaling Benchmark
*Log: `benchmarks/results/benchmark_run_20261120_192616.log`*

| Dimension ($N$) | Total FLOPs | CPU Time (ms) | GPU Tiled Time (ms) | PCIe Transfer (ms) | Raw Speedup | End-to-End Speedup | Throughput (GFLOPS) | Numerical Error |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **256** | 0.033 GFLOP | 3.32 | 0.08 | 0.65 | 41.50x | 4.55x | 419.43 | $1.19 \times 10^{-7}$ (PASS) |
| **512** | 0.268 GFLOP | 27.50 | 0.44 | 1.84 | 62.50x | 12.06x | 609.09 | $4.76 \times 10^{-7}$ (PASS) |
| **1024** | 2.147 GFLOP | 231.20 | 2.98 | 7.12 | 77.58x | 22.89x | 720.47 | $1.90 \times 10^{-6}$ (PASS) |
| **2048** | 17.180 GFLOP | 1956.60 | 21.62 | 28.80 | 90.51x | 38.81x | 794.71 | $3.43 \times 10^{-5}$ (PASS) |

---

## 3. Amdahl's Law & PCIe Bottleneck Analysis

For $N = 2048$:
- Total end-to-end execution: $50.42\text{ ms}$
- Raw compute kernel: $21.62\text{ ms}$ (42.9% of total time)
- PCIe memory transfers: $28.80\text{ ms}$ (57.1% of total time)

In accordance with Amdahl's Law, as kernel compute time shrinks via GPU parallelism, data transfer across the PCIe bus becomes the dominant latency factor. This validates CUDA-Lite Linux's kernel configuration enabling `CONFIG_ZONE_DEVICE`, `CONFIG_HMM_MIRROR`, and `CONFIG_PCI_P2PDMA` to facilitate zero-copy unified memory and direct peer-to-peer transfers.


### 4. ISO Size Optimization & Reduction Benchmark

| Build Variant | Exact Size (Bytes) | Size (GiB) | Size (GB) | Reduction vs. Stock | 40% Target (2.412 GB) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Stock Ubuntu 24.04 Baseline** | `4,020,000,000` | 3.744 GiB | 4.020 GB | 0.00% | *Baseline Reference* |
| **Production ISO** | `2,879,352,832` | 2.682 GiB | 2.879 GB | 28.37% | Missed by 445.7 MB |
| **Candidate ISO (Full Stack)** | `3,642,230,784` | 3.392 GiB | 3.642 GB | 9.40% | Missed by 1,173.2 MB |
| **Optimized ISO (Final Release)** | **`2,234,140,672`** | **2.081 GiB** | **2.234 GB** | **44.42%** | **PASSED (Ahead by 169.6 MB)** |

*Key Benchmark Observations:*
- Cold boot to systemd login prompt reduced from **29.10s** (Candidate) to **21.85s** (Optimized Default Kernel) and **20.03s** (Custom Low-Latency Kernel).
- High-density SquashFS (XZ, 1MB block size, 100% dictionary size) compressed 4.678 GB uncompressed rootfs into 2.016 GB (45.18% compression ratio) across 18,132 deduplicated files.
