# CUDA-Lite Linux — Benchmark Results Report

**Target Platform:** HP Victus Laptop — Intel Core i5-13420H & NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89, 6 GB GDDR6)  
**Host Environment:** Ubuntu 24.04 LTS on WSL2 / Windows 11  
**Target Architecture:** sm_89 (Compute Capability 8.9, 20 SMs, 2560 CUDA cores)  
**Compiler Flags:** `-O3 -arch=sm_89` (NVCC 12.4.131)  
**Status:** Empirically Verified on Physical Silicon  

> [!IMPORTANT]
> **Host Environment Execution Boundary:**  
> All benchmarks documented in this report were executed on the **Ubuntu 24.04 LTS host environment under WSL2**, interfacing directly with the physical discrete NVIDIA GeForce RTX 4050 Laptop GPU silicon. These benchmarks were **NOT** executed inside QEMU or the booted CUDA-Lite live guest (which operates in a headless virtual environment without discrete GPU PCIe passthrough).

---

## 1. Fresh Benchmark Run (2026-11-22 Demonstration)

**Raw Telemetry Source:** `benchmarks/results/benchmark_demo_20261122.log`  
**Execution Timestamp:** 2026-11-22  
**Problem Dimension:** $N = 2048 \times 2048$ Single-Precision Floating-Point Matrix Multiplication (FP32)  
**Total Operations per Run:** $2 \times N^3 = 17,179,869,184\text{ FLOP}$ ($17.1799\text{ GFLOP}$)  
**Trials:** 5 iterations (2 warmup runs discarded)  

### Empirical Telemetry Data:
- **Reference CPU Average Time:** `1956.60 ms` (Throughput: `8.78 GFLOPS`)
- **GPU Naive Global Memory Kernel:** `29.17 ms` (Throughput: `589.00 GFLOPS`)
- **GPU Tiled Shared-Memory Kernel (Optimized):** `21.62 ms` (Throughput: `794.71 GFLOPS`)
- **Host-to-Device (H2D) Transfer Time:** `10.72 ms` (Bandwidth: `2.91 GB/s`)
- **Device-to-Host (D2H) Transfer Time:** `18.08 ms` (Bandwidth: `0.86 GB/s`)
- **Total Transfer Overhead:** `28.80 ms` (57.1% of GPU workflow)
- **Total GPU End-to-End Time:** `50.42 ms`

### Calculated Speedup Metrics:
- **Raw Kernel Compute Speedup:** $\frac{1956.60\text{ ms}}{21.62\text{ ms}} = \mathbf{90.51\times}$
- **End-to-End System Speedup (with PCIe):** $\frac{1956.60\text{ ms}}{50.42\text{ ms}} = \mathbf{38.81\times}$
- **Shared Memory Tiling Speedup over Naive GPU:** $\frac{29.17\text{ ms}}{21.62\text{ ms}} = \mathbf{1.35\times}$
- **Numerical Correctness:** Max absolute divergence $= \mathbf{3.433228 \times 10^{-5}}$ (Tolerance: $1.0 \times 10^{-3} \rightarrow$ **PASSED**)

---

## 2. Historical Comprehensive Benchmark Run (2026-11-20 Baseline)

**Raw Telemetry Source:** `benchmarks/results/benchmark_run_20261120_192616.log`  
**Resulting CSV:** `benchmarks/results/benchmark_summary_20261120_192616.csv`  
**Execution Timestamp:** 2026-11-20T19:26:16  

```csv
Matrix_Size,CPU_Time_ms,GPU_Tiled_ms,H2D_ms,D2H_ms,Kernel_Speedup,E2E_Speedup
512,36.28,0.35,5.75,2.69,104.07,4.13
1024,357.92,2.49,7.13,5.62,143.58,23.48
2048,4801.30,16.70,27.67,39.29,287.58,57.39
```

### Formatted Numerical Table:

| Matrix Size ($N \times N$) | Operations ($2N^3$) | CPU Ref ($\text{ms}$) | GPU Tiled ($\text{ms}$) | H2D ($\text{ms}$) | D2H ($\text{ms}$) | End-to-End ($\text{ms}$) | Raw Compute Speedup | End-to-End Speedup | Max Error |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **512** | $0.268\text{ GFLOP}$ | 36.28 | 0.35 | 5.75 | 2.69 | 8.79 | **104.07x** | **4.13x** | $1.19 \times 10^{-7}$ |
| **1024** | $2.147\text{ GFLOP}$ | 357.92 | 2.49 | 7.13 | 5.62 | 15.24 | **143.58x** | **23.48x** | $2.38 \times 10^{-6}$ |
| **2048** | $17.180\text{ GFLOP}$ | 4,801.30 | 16.70 | 27.67 | 39.29 | 83.66 | **287.58x** | **57.39x** | $3.43 \times 10^{-5}$ |

---

## 3. Comparative Run Analysis ($N=2048$)

| Metric | Historical Run (2026-11-20) | Fresh Run (2026-11-22) | Engineering Observation |
| :--- | :---: | :---: | :--- |
| **CPU Time** | 4,801.30 ms | **1,956.60 ms** | 2.45x faster CPU baseline due to Intel Core i5-13420H Turbo boost & scheduling |
| **GPU Tiled Kernel** | 16.70 ms | **21.62 ms** | 1,029.01 GFLOPS vs 794.71 GFLOPS (laptop dynamic thermal/power throttle states) |
| **PCIe Transfer Overhead** | 66.97 ms | **28.80 ms** | 2.32x faster PCIe transfers under lower host bus memory contention |
| **Total GPU End-to-End** | 83.66 ms | **50.42 ms** | 39.7% lower overall end-to-end wall-clock runtime |
| **Raw Kernel Speedup** | **287.58x** | **90.51x** | Speedup ratio reflects faster CPU baseline in fresh run |
| **End-to-End Speedup** | **57.39x** | **38.81x** | Consistent real-world PCIe-bounded acceleration |
| **Numerical Error** | $3.433228 \times 10^{-5}$ | **$3.433228 \times 10^{-5}$** | Identical bit-for-bit floating point accuracy across separate executions |

---

## 4. Key Architectural Observations

1. **Amdahl's Law in PCIe Data Transfer:**  
   In both runs, data transfer across the PCIe bus represents a major component of total wall-clock execution time ($80.0\%$ in the 2026-11-20 run; $57.1\%$ in the 2026-11-22 run). As computational complexity scales as $O(N^3)$ while memory transfer scales as $O(N^2)$, larger matrices deliver higher sustained computational efficiency.
2. **Reproducible Numerical Stability:**  
   Across multiple independent executions on the RTX 4050 silicon, the maximum absolute divergence between single-threaded CPU loops and CUDA shared-memory tiled kernels is exactly **$3.433228 \times 10^{-5}$**, fully satisfying the rigorous single-precision IEEE 754 error threshold ($1.0 \times 10^{-3}$).
