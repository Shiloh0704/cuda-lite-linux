# CUDA-Lite Linux — GPU Hardware Test Results

**Date of Execution:** 2026-11-21  
**Tested GPU:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89)  
**Host Platform:** Intel Core i5-13420H / Ubuntu 26.04.1 WSL2 / Debian 13 Target  

---

## 1. Device Specification Summary

| Attribute | Measured Hardware Specification |
| :--- | :--- |
| **GPU Model** | NVIDIA GeForce RTX 4050 Laptop GPU |
| **Compute Capability** | 8.9 (Ada Lovelace Architecture) |
| **Streaming Multiprocessors (SMs)** | 20 |
| **CUDA Cores** | 2,560 |
| **GPU Clock Rate** | 2,130 MHz (2.13 GHz) |
| **VRAM Total Capacity** | 6,141 MiB (6.00 GB GDDR6) |
| **Memory Bus Width** | 96-bit |
| **Memory Clock Rate** | 8,001 MHz (8.00 GHz) |
| **Peak Bandwidth** | 192.02 GB/s |
| **L2 Cache Size** | 24,576 KB (24 MB) |
| **PCIe Bus Location** | Bus `01:00.0` (Domain 0) |

---

## 2. Telemetry and Operational Status (`nvidia-smi`)

During active testing, NVIDIA-SMI confirmed normal power and thermal characteristics:

- **Thermal State:** 44°C idle / low load.
- **Power Draw:** 14W idle / 70W power ceiling.
- **Performance State:** P3.
- **Driver Model:** WDDM host interface with WSL Direct3D/DXG GPU abstraction layer.
- **Driver Version:** 592.82 host kernel interface / CUDA Toolkit 12.4 compatible.

---

## 3. Test Matrix and Functional Verification

| Test Identifier | Test Target | Evaluation Method | Result | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **GPU-01** | Device Discovery | `device_query` binary execution | **PASS** | Correctly identified RTX 4050, 20 SMs, sm_89. |
| **GPU-02** | CUDA Context Creation | Runtime API `cudaSetDevice(0)` | **PASS** | Context created in < 20 ms. |
| **GPU-03** | Host-to-Device Transfer | `cudaMemcpyHostToDevice` | **PASS** | 27.67 ms for 32 MiB payload at N=2048. |
| **GPU-04** | Naive Kernel Execution | Global memory matrix mul | **PASS** | Accelerated vs CPU; high memory latency. |
| **GPU-05** | Tiled Kernel Execution | Shared memory $32 \times 32$ tiles | **PASS** | 16.70 ms at N=2048 (1,029 GFLOPS). |
| **GPU-06** | Device-to-Host Transfer | `cudaMemcpyDeviceToHost` | **PASS** | 39.29 ms for 16 MiB payload at N=2048. |
| **GPU-07** | Numerical Precision | FP32 difference vs CPU reference| **PASS** | Max error: $3.43 \times 10^{-5}$ (< $1.0 \times 10^{-3}$). |
| **GPU-08** | Repeated Run Stability | 5 continuous iterations | **PASS** | Standard deviation < 2.5% of mean runtime. |
| **GPU-09** | QEMU Fallback Behavior | Headless QEMU without vGPU | **PASS** | Gracefully logged `NVRM: No NVIDIA GPU found.` |

---

## 4. Hardware Verification Conclusion

The target hardware (NVIDIA GeForce RTX 4050 Laptop GPU) was verified to operate with high computational throughput and numerical accuracy under CUDA 12.4. All binaries compiled for the distribution (`device_query` and `matrix_mul`) executed without errors, achieving a 287.58x kernel acceleration over single-threaded CPU execution.
