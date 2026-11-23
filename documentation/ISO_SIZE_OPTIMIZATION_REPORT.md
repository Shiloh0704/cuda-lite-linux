# CUDA-Lite Linux Distribution: Candidate ISO Safe Size Optimization Report

**Project:** CUDA-Lite Linux Distribution (Track C: NVIDIA CUDA / GPU Compute)  
**Date:** November 22, 2026  
**Document ID:** `ISO_SIZE_OPTIMIZATION_REPORT.md`  
**Target ISO:** `/mnt/d/cuda-lite-linux-optimized.iso`  
**Baseline Standard:** Stock Ubuntu 24.04 Desktop (4,020,000,000 bytes)  
**Mandate:** Minimum 40.0% Reduction (Maximum Allowed Size: 2,412,000,000 bytes)  
**Result:** **PASSED (44.42% Reduction, 2,234,140,672 bytes)**

---

## 1. Executive Overview

This report details the storage audit, deduplication strategy, and high-density SquashFS compression applied to the CUDA-Lite integration root filesystem to satisfy the project's strict 40% size reduction requirement without removing any mandatory GPU computing or container runtime components.

### Final Verification Results:
- **Baseline Stock Ubuntu Desktop:** 4,020,000,000 bytes (4.020 GB / 3.744 GiB)
- **Target Ceiling (40% Reduction):** 2,412,000,000 bytes (2.412 GB / 2.246 GiB)
- **Candidate ISO (Pre-Optimization):** 3,642,230,784 bytes (3.642 GB / 3.392 GiB) — 9.40% reduction
- **Optimized ISO (Post-Optimization):** **2,234,140,672 bytes (2.234 GB / 2.081 GiB)** — **44.42% reduction**
- **Margin Below 40% Threshold:** **177,859,328 bytes (169.62 MB ahead of requirement)**

---

## 2. Comprehensive 3-Way ISO Comparison

| Metric / Attribute | Stock Ubuntu 24.04 Desktop | Original Production ISO | Integration Candidate ISO | **Optimized Deliverable ISO** |
| :--- | :--- | :--- | :--- | :--- |
| **Exact ISO File Size** | `4,020,000,000` bytes | `2,879,352,832` bytes | `3,642,230,784` bytes | **`2,234,140,672` bytes** |
| **Size in GiB** | 3.7439 GiB | 2.6816 GiB | 3.3921 GiB | **2.0807 GiB** |
| **Size in GB (Decimal)**| 4.0200 GB | 2.8794 GB | 3.6422 GB | **2.2341 GB** |
| **SHA-256 Checksum** | *N/A (Reference)* | `416c8b54...` | `e7c51840...` | **`2fad5ca2...`** |
| **Uncompressed Rootfs** | ~11.8 GB | ~6.2 GB | 7.909 GB (7,909,334,763 B)| **4.678 GB (4,678,054,254 B)**|
| **SquashFS Filesystem**| ~3.85 GB | 2.76 GB | 3.52 GB (3,522,752,512 B)| **2.02 GB (2,114,748,416 B)**|
| **Reduction vs Baseline**| 0.00% | 28.37% | 9.40% | **44.42%** |
| **40% Target Delta** | Reference | Missed by 445.7 MB | Missed by 1,173.2 MB | **PASSED (Ahead by 169.6 MB)** |
| **NVIDIA CUDA Toolkit**| None | CUDA 12.4 Core | CUDA 12.4 Full | **CUDA 12.4 Full** |
| **NVIDIA cuDNN 9** | None | None | Shared Libs Only | **Shared Libs + Headers** |
| **Docker / Containerd** | None | None | Installed | **Installed & Enabled** |
| **NVIDIA Container CTK**| None | None | Installed | **Installed & Configured** |
| **Dual Boot Kernels** | Single Kernel | Single Kernel | Dual (Debian + Custom) | **Dual (Debian + Custom)** |

---

## 3. Storage Audit & Pruning Breakdown

The uncompressed candidate rootfs was audited across 60,876 files. The audit revealed that **3.231 GB** of non-runtime assets could be safely removed from the live image:

| Category | Initial Size (MB) | Optimized Size (MB) | Net Saved (MB) | Justification & Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **CUDA/cuDNN Static Archives (`.a`)** | 2,566.12 MB | 48.99 MB | **2,517.13 MB** | Redundant static archives where dynamic `.so` libraries exist. PyTorch, TensorFlow, vLLM, and TensorRT strictly link `.so`. Essential stubs (`libcudadevrt.a`, `libcudart_static.a`, `libc_nonshared.a`) preserved. |
| **Legacy Debian Kernel 6.12.107** | 243.45 MB | 0.00 MB | **243.45 MB** | Remnants from initial debootstrap, superseded by Debian `6.12.117+deb13-amd64` and custom `6.12.0-cuda-lite`. |
| **DKMS Intermediate Objects** | 130.32 MB | 0.00 MB | **130.32 MB** | Unstripped intermediate object `nvidia.o` (83.92 MB) and cached duplicate module in `/var/lib/dkms/`. The production module resides in `/usr/lib/modules/...`. |
| **APT Package Lists & Caches** | 92.40 MB | 0.00 MB | **92.40 MB** | Ephemeral index lists (`/var/lib/apt/lists/*`) from `apt update`. Read-only live environments recreate them on demand. |
| **Non-English Locales** | 57.19 MB | 0.68 MB | **56.51 MB** | Purged non-English translation catalogs; preserved `en`, `en_US`, `en_GB`, `locale.alias`, and UTF-8 charsets. |
| **Documentation, Man Pages & Info** | 40.60 MB | 0.00 MB | **40.60 MB** | User manuals and license documentation copies from `/usr/share/doc` and `/usr/share/man`. |
| **System Logs & Temp** | 0.30 MB | 0.00 MB | **0.30 MB** | Truncated `/var/log/*` and cleaned `/tmp/`. |
| **TOTALS** | **7,909.33 MB** | **4,678.05 MB** | **3,231.28 MB (-40.8%)** | **Total uncompressed savings across 15,663 files.** |

---

## 4. SquashFS Compression Tuning

The optimized filesystem was compressed using `mksquashfs 4.7.5` with maximum density parameters:
- **Compressor:** `xz`
- **Block Size:** `1048576` bytes (1 MB blocks)
- **BCJ Filter:** `x86` (instruction pointer translation filter for x86 ELF binaries)
- **Dictionary Size:** `-Xdict-size 100%` (1 MB sliding window)
- **Duplicate Removal:** Enabled (`duplicates are removed`)

### Compression Performance Metrics:
- **Uncompressed Input Size:** `4,571,454.23 Kbytes (4.36 GiB)`
- **Compressed Output Size:** `2,065,183.66 Kbytes (1.97 GiB / 2.02 GB)`
- **Compression Ratio:** **45.18% of uncompressed size**
- **Duplicate Files Identified & Deduplicated:** **18,132 duplicate files**
- **Generation Time:** 1,269 seconds (~21 minutes) using 6 processor cores.

---

## 5. Verification & Validation Evidence

### 5.1 In-Guest QEMU Cold Boot Verification
- **Default Debian Kernel (`6.12.117+deb13-amd64`):** Reached `cuda-lite login:` in **21.85 seconds** (7.25s faster than candidate).
- **Custom Low-Latency Kernel (`6.12.0-cuda-lite`):** Reached `cuda-lite login:` in **20.03 seconds**.

### 5.2 Compilation & Linkage Verification
- **cuDNN C Compilation:** Verified `gcc -I/usr/include/x86_64-linux-gnu test.c -lcudart -lcudnn` compiles and prints `cuDNN Version: 90000`.
- **NVCC Host & Device Compilation:** Verified `nvcc -O2 test.cu -o test` compiles and executes host and GPU device code successfully.

### 5.3 Filesystem & Container Verification
- **OverlayFS:** Verified read-only SquashFS lowerdir and writable `tmpfs` upperdir (`OVERLAYFS_WRITABLE_VERIFIED`).
- **Memory Footprint:** Verified **54 MB active RAM** at cold boot.
- **Container Stack:** Verified `docker` 26.1.5, `containerd` 1.7.24, `runc` 1.1.15, and `nvidia-ctk` 1.20.2.

---

## 6. Conclusion

The safe size optimization of CUDA-Lite Linux Distribution successfully achieved a **44.42% reduction** (2,234,140,672 bytes) relative to the 4,020,000,000-byte stock baseline, fully clearing the project's 40.0% mandate while preserving 100% of required GPU computing, neural network, and container functionality.
