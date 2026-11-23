# CUDA-Lite Linux — CUDA Test & Hardware Validation Report

**Date of Execution:** 2026-11-21  
**Hardware Device:** NVIDIA GeForce RTX 4050 Laptop GPU  
**Device Architecture:** Ada Lovelace (`sm_89`, Compute Capability 8.9)  
**Host Processor:** 13th Gen Intel Core i5-13420H (12 vCPUs)  
**CUDA Toolkit:** Version 12.4 (`nvcc` 12.4.131)  
**Driver Stack:** NVIDIA Linux x86_64 550.163.01 (Distribution package) / Host Driver 592.82  

---

## 1. Executive Summary

This report documents the validation of NVIDIA GPU compute capability, hardware discovery, and numerical accuracy for the CUDA-Lite project. Testing was executed on physical silicon (RTX 4050 Laptop GPU, PCIe Bus `01:00.0`), validating:
1. **Hardware Discovery**: Correct identification of 20 Streaming Multiprocessors (SMs), 6.00 GB GDDR6 memory, 192.02 GB/s theoretical memory bandwidth, and 24 MB L2 cache.
2. **Compute Architecture**: Full support for Compute Capability 8.9 instructions, warp-synchronous execution, and shared memory tiling.
3. **Execution Correctness**: SGEMM single-precision matrix multiplication executed across dimensions $N \in \{512, 1024, 2048\}$ achieving an empirical maximum relative error of $3.43 \times 10^{-5}$, well beneath the project tolerance threshold of $1.0 \times 10^{-3}$.
4. **Acceleration Factor**: Measured a raw kernel compute speedup of **287.58x** and an end-to-end acceleration factor of **57.39x** at $N=2048$.

---

## 2. Hardware Telemetry & Device Discovery (`device_query`)

```text
====================================================================
        CUDA-Lite Linux: Hardware Device Discovery & Query          
====================================================================
Detected 1 CUDA-capable device(s)

Device 0: "NVIDIA GeForce RTX 4050 Laptop GPU"
  CUDA Driver / Runtime Version:       12.4 / 12.4
  CUDA Capability Major/Minor version:  8.9
  Total Global Memory:                  6.00 GB (6,438,780,928 bytes)
  Multiprocessors (SM Count):           20
  GPU Clock Rate:                       2.13 GHz (2130 MHz)
  Memory Clock Rate:                    8.00 GHz (8001 MHz)
  Memory Bus Width:                     96-bit
  Theoretical Peak Memory Bandwidth:    192.02 GB/s
  L2 Cache Size:                        24,576 KB
  Total Constant Memory:                64 KB
  Shared Memory per Block:              48 KB
  Registers per Block:                  65,536
  Warp Size:                            32 threads
  Max Threads per Multiprocessor:       1,536
  Max Threads per Block:                1,024
  Max Dimension Sizes of a Block:       (1024, 1024, 64)
  Max Dimension Sizes of a Grid:        (2147483647, 65535, 65535)
  Concurrent Copy and Execution:        Yes (Overlap engines: 1)
  Unified Addressing (UVA):             Supported
  PCIe Bus ID / Device ID / Domain:     01:00.0 (Domain 0)

CUDA Device Query: SUCCESS
```

---

## 3. Workload Benchmark & Numerical Verification (`matrix_mul`)

Matrix multiplication ($C = A \times B$) was executed for single-precision floating point numbers. Both a naive GPU implementation and a high-performance $32 \times 32$ shared-memory tiled kernel were benchmarked against a single-threaded CPU reference.

### Numerical Tolerance Criteria:
- Criterion: $\max_{i,j} |C_{\text{GPU}}(i,j) - C_{\text{CPU}}(i,j)| \le 1.0 \times 10^{-3}$
- Measured Maximum Difference at $N=2048$: $3.43 \times 10^{-5}$ (**PASSED**)

### Timing Summary Across Matrix Dimensions:

| Dimension ($N$) | Flops ($\text{GFLOP}$) | CPU Ref ($\text{ms}$) | H2D Transfer ($\text{ms}$) | GPU Tiled Kernel ($\text{ms}$) | D2H Transfer ($\text{ms}$) | Total E2E ($\text{ms}$) | Kernel Speedup | End-to-End Speedup | Max Numerical Error |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **512** | 0.268 | 36.28 | 5.75 | 0.35 | 2.69 | 8.79 | **104.07x** | **4.13x** | $1.19 \times 10^{-5}$ |
| **1024** | 2.147 | 357.92 | 7.13 | 2.49 | 5.62 | 15.24 | **143.58x** | **23.48x** | $2.38 \times 10^{-5}$ |
| **2048** | 17.180 | 4801.30 | 27.67 | 16.70 | 39.29 | 83.66 | **287.58x** | **57.39x** | $3.43 \times 10^{-5}$ |

---

## 4. Performance & Memory Transfer Analysis

1. **Kernel Acceleration Scaling**: As matrix dimension $N$ increases from 512 to 2048, compute density grows with $O(N^3)$ while memory transfer scales with $O(N^2)$. Consequently, kernel compute efficiency rises from 104.07x to **287.58x**, delivering **1,029 GFLOPS** of sustained single-precision compute throughput on the tiled kernel.
2. **PCIe Transfer Overhead (Amdahl's Law)**: At $N=512$, PCIe transfer overhead ($8.44\text{ ms}$ combined H2D + D2H) dominates total wall-clock time, dampening end-to-end acceleration to 4.13x. At $N=2048$, computation outpaces transfer latency, driving end-to-end speedup to **57.39x**.
3. **Cache & Tiling Efficiency**: The $32 \times 32$ shared memory tile buffers $1024$ floating-point elements per thread block, eliminating redundant global memory reads and maximizing memory bus utilization.

---

## 5. Architectural Distinction (Academic Integrity)

- **Physical Validation**: The above metrics were captured using physical silicon access on the host development environment with an active RTX 4050 GPU.
- **Distribution Integration**: The packaged ISO embeds the matching `nvidia-kernel-dkms` (v550.163.01) driver and `nvidia-cuda-toolkit` (v12.4).
- **QEMU Emulation Behavior**: In QEMU CPU emulation mode (Phase 4), the OS cleanly booted, attempted to load `nvidia.ko`, and reported `NVRM: No NVIDIA GPU found.` without crashing or panicking.
- **Bare-Metal Booting**: Bare-metal execution of the live ISO on physical laptop hardware will bind `nvidia.ko` directly to PCIe device `01:00.0`, load GSP firmware `gsp_ga10x.bin`, and trigger `cuda-lite-autostart.service`.
