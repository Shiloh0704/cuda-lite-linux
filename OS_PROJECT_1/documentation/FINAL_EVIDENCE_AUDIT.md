# EdgeML Linux OS — Final Evidence & Technical Verification Audit

**Project Title:** Custom Lightweight Linux Distribution for Edge AI Inference (EdgeML Linux OS)  
**Academic Track:** Track A – ML Inference at the Edge  
**Target Platform:** ARM64 (`aarch64` QEMU `virt` platform, Cortex-A57 CPU, 4 vCPUs, 1024 MB RAM)  
**Audit Document:** [documentation/FINAL_EVIDENCE_AUDIT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_EVIDENCE_AUDIT.md)  
**Audit Date:** November 20, 2026  
**Auditor:** Quality Assurance & Technical Verification Engine  
**Audit Mandate:** Empirical verification of all project claims, codebases, benchmarks, architectures, and test suites. Strictly distinguishes verified facts from assumptions, mock simulations, and unverified projections.

---

## 1. Executive Audit Summary

A comprehensive, ground-truth audit of EdgeML Linux OS was conducted across all configuration files, application source code, compiled binaries, benchmark scripts, test suites, and documentation.

### Key Audit Conclusions:
1. **Benchmark Data Inconsistency**: A direct contradiction exists between `results/benchmark_results.csv` and the markdown documentation (`FINAL_REPORT.md`, `PERFORMANCE_EVALUATION.md`, `SUBMISSION_CHECKLIST.md`). The CSV file records **63.82 ms Mean Latency** and **15.67 FPS Throughput**, whereas the report claims **40.85 ms Mean Latency** and **24.48 FPS Throughput**.
2. **Host-Side Mock Binary on Disk**: The binary `application/edgeml-infer` is an **x86-64 Linux ELF executable**, not an ARM64 binary. Furthermore, it was compiled without `-DHAVE_TFLITE`, executing a fallback host CPU arithmetic loop (`acc += (resized_img[i] * 13) % 256`) that outputs fixed synthetic confidences (`{87.4%, 5.2%, 3.1%, 1.8%, 1.2%}`) rather than actual TensorFlow Lite tensor inference.
3. **Microarchitectural Invalidity (SDOT Claim)**: The documentation repeatedly claims that ARM Cortex-A57 executes `sdot` (Signed Dot Product) vector instructions. This is microarchitecturally impossible: **Cortex-A57 is an ARMv8.0-A core**, whereas `SDOT`/`UDOT` instructions require the **ARMv8.2-A DotProd extension** (`FEAT_DotProd`). Executing `sdot` on Cortex-A57 triggers an Illegal Instruction exception (`SIGILL`).
4. **XNNPACK vs. RUY Packaging in Buildroot**: The documentation claims XNNPACK was enabled for ARM64 inference. In Buildroot 2025.02.10, upstream `package/xnnpack/Config.in` explicitly restricts architecture support to `BR2_i386` and `BR2_x86_64`. On ARM64, Buildroot automatically selects **RUY**, disabling XNNPACK.
5. **Test Suite Scope**: None of the 14 QA test stages in `scripts/test.sh` execute inside a booted QEMU virtual machine. The suite consists of **7 static configuration checks**, **2 file existence checks**, **1 host toolchain check**, and **4 host-side mock simulations**.
6. **Build Image Status**: Full target compilation in `/mnt/d/buildroot_workspace/output_qemu/images/` has not yet taken place. The reported image sizes (28.8 MB rootfs, 10.4 MB SquashFS, 24.2 MB Kernel) represent design projections embedded as fallback defaults in `scripts/benchmark.sh`.

---

## 2. Task 1: Benchmark Reconciliation

### 2.1 Latency, Throughput, and CPU Telemetry Analysis

| Metric | `results/benchmark_results.csv` | `FINAL_REPORT.md` / `PERFORMANCE_EVALUATION.md` | `scripts/benchmark.sh` Logic | Reconciliation / Verified Source |
|:---|:---:|:---:|:---|:---|
| **Mean Latency** | **63.82 ms** | **40.85 ms** | Runs `$BIN` (host x86_64 mock loop). If latency extracted, uses it; otherwise defaults to `40.85 ms`. | **Discrepancy**: CSV on disk contains `63.82 ms` from an earlier host test run, while markdown text was written with `40.85 ms`. |
| **Median Latency** | **39.60 ms** | **39.60 ms** (Omitted in executive tables) | Hardcoded literal: `CUSTOM_LATENCY_MEDIAN_MS=39.60`. Never computed from an array in `benchmark.sh`. | **Unverified constant**: Not computed from multi-run distribution. |
| **P95 Latency** | **44.10 ms** | **44.10 ms** | Hardcoded literal: `CUSTOM_LATENCY_P95_MS=44.10`. Never computed from an array in `benchmark.sh`. | **Unverified constant**: Not computed from multi-run distribution. |
| **Throughput** | **15.67 FPS** | **24.48 FPS** | Calculated as `1000.0 / CUSTOM_LATENCY_MEAN_MS`. `1000 / 63.82 = 15.67 FPS`; `1000 / 40.85 = 24.48 FPS`. | **Discrepancy**: Throughput in CSV matches 63.82 ms latency; throughput in report matches 40.85 ms latency. |
| **CPU Utilisation** | **91.80%** (Delta: -6.70%) | **91.80%** (Delta: -6.70%) | Hardcoded literal in CSV export heredoc: `Inference CPU Utilisation (4 vCPUs),98.50,91.80,-6.70,6.80,%`. | **Static assertion**: No background sampling (`top`/`mpstat`) was performed. |
| **Kernel Size** | **52.40 MB vs 24.20 MB** (Uncompressed) | **52.40 MB vs 24.20 MB** (`FINAL_REPORT.md`)<br>**31.18 MB vs 14.40 MB** (`SUBMISSION_CHECKLIST.md`) | In `benchmark.sh`: `CUSTOM_KERNEL_MB=24.20` fallback when `/mnt/d/.../Image` is absent. | **Discrepancy**: Checklist cited compressed `Image.gz` numbers, report cited raw `Image` numbers, both sharing identical 53.82% reduction. Neither file exists on disk. |

---

## 3. Task 2: Technical Validation

### 3.1 TensorFlow Lite Version
* **Claim in Documentation**: TensorFlow Lite 2.14+ (or 2.11.0 / 2.14 interchangeably).
* **Buildroot 2025.02.10 Reality**: `package/tensorflow-lite/tensorflow-lite.mk` lines 7-8 explicitly declare:
  ```makefile
  TENSORFLOW_LITE_VERSION = 2.11.0
  TENSORFLOW_LITE_SITE = $(call github,tensorflow,tensorflow,v$(TENSORFLOW_LITE_VERSION))
  ```
* **Verdict**: Upstream Buildroot packages **v2.11.0**. All references to 2.14+ must be reconciled to 2.11.0.

### 3.2 Microarchitecture & Vector SIMD (The SDOT Defect)
* **Claim in Documentation**: `FINAL_REPORT.md` (line 134), `INFERENCE_APPLICATION.md` (line 49), and `SYSTEM_ARCHITECTURE.md` (line 189) claim:
  > *"Employs ARMv8-A integer dot-product instructions (`sdot`), calculating four 8-bit multiply-accumulate operations in a single clock cycle per execution lane."*
* **Microarchitecture Reality**:
  * QEMU emulates **ARM Cortex-A57** (`-cpu cortex-a57`).
  * Cortex-A57 implements the **ARMv8.0-A** architecture specification.
  * The `SDOT` and `UDOT` instructions are part of the **ARMv8.2-A DotProd extension** (`FEAT_DotProd`).
  * Cortex-A57 **does not possess hardware support for SDOT**. Executing binary opcodes for `sdot` on a Cortex-A57 core triggers a CPU trap: **Illegal Instruction (`SIGILL`)**.
* **Correct Technical Mechanism**:
  * On ARMv8.0-A (Cortex-A57), INT8 vectorization is performed via standard Advanced SIMD instructions: `smlal` / `smlal2` (Signed Multiply-Accumulate Long), which widen 8-bit integer vectors to 16-bit intermediate accumulators across two vector operations.

### 3.3 ML Acceleration Library: XNNPACK vs. RUY
* **Claim in Documentation**: Claims `-DTFLITE_ENABLE_XNNPACK=ON` was compiled for ARM64 inference.
* **Buildroot 2025.02.10 Reality**:
  * `package/xnnpack/Config.in`:
    ```kconfig
    config BR2_PACKAGE_XNNPACK_ARCH_SUPPORTS
        bool
        default y if BR2_i386
        default y if BR2_x86_64
        depends on BR2_PACKAGE_CPUINFO_ARCH_SUPPORTS
    ```
    `BR2_aarch64` is **not enabled** in `BR2_PACKAGE_XNNPACK_ARCH_SUPPORTS`.
  * `package/ruy/Config.in`:
    ```kconfig
    config BR2_PACKAGE_RUY_ARCH_SUPPORTS
        bool
        default y if BR2_PACKAGE_CPUINFO_ARCH_SUPPORTS
    ```
    `BR2_PACKAGE_RUY` supports `aarch64`.
  * In `package/tensorflow-lite/tensorflow-lite.mk`:
    When `BR2_PACKAGE_XNNPACK` is not set, it explicitly passes `-DTFLITE_ENABLE_XNNPACK=OFF`.
* **Verdict**: On ARM64 Buildroot 2025.02.10, TensorFlow Lite uses **RUY** as its matrix multiplication engine, not XNNPACK.

### 3.4 Model File Integrity
* **File**: `models/mobilenet_v2_quant.tflite`
* **Size**: 4,276,352 bytes (4.08 MB).
* **Header Hexdump**:
  ```
  00000000: 1c00 0000 5446 4c33 0000 0000 0000 0e00  ....TFL3........
  ```
* **Verdict**: **VERIFIED AUTHENTIC**. Bytes 4–7 contain ASCII `TFL3`, confirming a valid TensorFlow Lite schema v3 FlatBuffer from Google.

### 3.5 Target Executable Binary Architecture
* **File**: `application/edgeml-infer`
* **ELF Header Inspection**:
  ```bash
  $ file application/edgeml-infer
  application/edgeml-infer: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV)
  ```
* **Verdict**: **CRITICAL DISCREPANCY**. The binary currently present on disk is an **x86-64 host executable**, not an ARM64 executable.
* **Internal Logic Inspection (`application/edgeml_infer.cpp`)**:
  Because `$(SYSROOT)/usr/include/tensorflow` does not exist on the host, the Makefile built the binary without `-DHAVE_TFLITE`. In lines 250–270:
  ```cpp
  #else
      // Pure CPU deterministic classification emulator (used during verification testing)
      auto infer_start = std::chrono::high_resolution_clock::now();
      volatile int64_t acc = 0;
      for (size_t i = 0; i < resized_img.size() * 50; ++i) {
          acc += (resized_img[i % resized_img.size()] * 13) % 256;
      }
      auto infer_end = std::chrono::high_resolution_clock::now();
      ...
      float confidences[5] = {0.874f, 0.052f, 0.031f, 0.018f, 0.012f};
  #endif
  ```
  The binary executes a host-side loop and outputs hardcoded classification confidences.

### 3.6 Kernel Configuration Deficiencies
* **Preemption Model**: `FINAL_REPORT.md` and `PERFORMANCE_EVALUATION.md` state that `CONFIG_PREEMPT_VOLUNTARY=y` is configured.
  * Inspection of `configs/kernel_defconfig`: `grep -i PREEMPT configs/kernel_defconfig` yields no results.
* **Architecture Token**: In `scripts/test.sh`, Stage 02 checks `CONFIG_ARM64=y|CONFIG_OVERLAY_FS=y`. `configs/kernel_defconfig` does not contain `CONFIG_ARM64=y` (it passes solely because of `CONFIG_OVERLAY_FS=y`).

---

## 4. Task 3: Test Validation & Classification of the 14 QA Stages

Every stage of `scripts/test.sh` was audited to classify its true operational nature:

| Stage # | Stage Description | Code Executed | Verification Category | Ground Truth Assessment |
|:---:|:---|:---|:---:|:---|
| **01** | Buildroot Defconfig Syntax | `grep -E "BR2_aarch64=y" configs/buildroot_defconfig` | **Static Configuration Check** | Verifies string in host text file. |
| **02** | Kernel ARM64 & OverlayFS Defconfig | `grep -E "CONFIG_ARM64=y\|CONFIG_OVERLAY_FS=y" configs/kernel_defconfig` | **Static Configuration Check** | Verifies string in host text file. |
| **03** | RootFS Overlay Skeleton | `test -f board/rootfs_overlay/etc/fstab` | **Static File Check** | Verifies file existence on host. |
| **04** | QEMU ARM64 Readiness | `qemu-system-aarch64 --version` | **Host Toolchain Check** | Verifies QEMU package on host. **Does not launch VM.** |
| **05** | Read-Only Root Invariant | `grep -q "ro" board/rootfs_overlay/etc/fstab` | **Static Configuration Check** | Checks text in host fstab. **Does not test live mount.** |
| **06** | OverlayFS Mount Rules | `grep -q "mount -t overlay" board/.../init.d/rcS` | **Static Configuration Check** | Checks shell script string. **Does not test live mount.** |
| **07** | ML Runtime Specification | `grep -q "BR2_PACKAGE_TENSORFLOW_LITE=y" configs/buildroot_defconfig` | **Static Configuration Check** | Verifies string in host text file. |
| **08** | Quantized Model Staging | `test -f models/mobilenet_v2_quant.tflite` | **Static File Check** | Verifies file existence on host. |
| **09** | Image Preprocessing Header | `test -f application/stb_image.h` | **Static File Check** | Verifies file existence on host. |
| **10** | Inference Application Pipeline | `python3 tests/test_inference.py` | **Host-Side Mock Execution** | Runs host x86_64 mock loop binary on host WSL. **Not TFLite, not ARM64.** |
| **11** | Inference Output & Telemetry | `application/edgeml-infer tests/test.jpg` | **Host-Side Mock Execution** | Runs host x86_64 mock binary directly on host WSL. |
| **12** | Autonomous Service Lifecycle | `bash tests/test_autostart.sh` | **Host-Side Mock Simulation** | Runs shell script against `/tmp/var/run` on host. **Not BusyBox init.** |
| **13** | Security Invariants & ASLR | `bash tests/test_security.sh` | **Host-Side Mock / Static Check** | Tests WSL host root permissions + greps sysctl text file. **Not QEMU kernel.** |
| **14** | Benchmarking Framework | `bash scripts/benchmark.sh` | **Host-Side Static Calculation** | Exports CSV using fallback literals & host mock binary. |

### Summary of Test Realism:
* **Actual QEMU Boot Tests**: **0 / 14 Stages**
* **Actual ARM64 Binary Execution**: **0 / 14 Stages**
* **Actual TensorFlow Lite Inference**: **0 / 14 Stages**
* **Live Target Security Verification**: **0 / 14 Stages**
* **Static File & Configuration Checks**: **9 / 14 Stages**
* **Host-Side Simulation / Mock Tests**: **5 / 14 Stages**

---

## 5. Task 4: Reproducibility Analysis

### 5.1 Pipeline Ordering Defect in `scripts/build.sh`
* In `scripts/build.sh`, the build stages are ordered as:
  * **Step 4**: `make -C "$PROJECT_ROOT/application" all`
  * **Step 5**: `make -C "$OUTPUT_DIR" -j"$NPROC"`
* **Failure Mechanism**:
  * Step 4 invokes `application/Makefile`, which looks for the target cross-compiler (`aarch64-linux-gnu-g++`) and staging headers in `$BUILD_ROOT_WORKSPACE/output_qemu/staging/usr/include/tensorflow`.
  * However, Buildroot has not compiled the toolchain or TensorFlow Lite yet because Buildroot runs in **Step 5**!
  * As a result, Step 4 fails to find the cross-compiler, forcing a fallback to host `g++`, producing an x86_64 non-TFLite binary.
* **Correction**: Step 4 must occur **AFTER** Step 5, utilizing the freshly built cross-compiler at `output_qemu/host/bin/aarch64-linux-g++` and staging sysroot at `output_qemu/staging`.

### 5.2 Build Status on Disk
* Directory `/mnt/d/buildroot_workspace/output_qemu/images/` does not exist.
* The target kernel `Image` and root filesystem `rootfs.squashfs` have not been generated.

---

## 6. Task 5: Master Discrepancy & Rectification Matrix

| # | Discrepancy / Problem | Affected File(s) | Concrete Empirical Evidence | Correct Verified Value / Reality | Required Correction |
|:---:|:---|:---|:---|:---|:---|
| **01** | **Mean Latency & Throughput Conflict** | [results/benchmark_results.csv](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/results/benchmark_results.csv)<br>[documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md)<br>[documentation/PERFORMANCE_EVALUATION.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/PERFORMANCE_EVALUATION.md) | `benchmark_results.csv` records `63.82 ms` and `15.67 FPS`. `FINAL_REPORT.md` claims `40.85 ms` and `24.48 FPS`. | Reconcile: If 40.85 ms is chosen, CSV must be updated. If 63.82 ms is chosen, report must be updated. | Synchronize all documentation and CSV to reflect single authoritative data source. |
| **02** | **Invalid Microarchitecture Claim: `sdot` on Cortex-A57** | [documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md)<br>[documentation/INFERENCE_APPLICATION.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/INFERENCE_APPLICATION.md)<br>[documentation/SYSTEM_ARCHITECTURE.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/SYSTEM_ARCHITECTURE.md) | Cortex-A57 is ARMv8.0-A. `sdot` is an ARMv8.2-A DotProd extension (`FEAT_DotProd`). Cortex-A57 triggers `SIGILL`. | Cortex-A57 uses ARMv8.0-A NEON SIMD (`smlal`/`smlal2` widening multiply-accumulate). | Replace all claims of `sdot` instructions with ARMv8.0-A Advanced SIMD (`smlal`/`smlal2`). |
| **03** | **Application Binary is Host x86-64, not ARM64** | [application/edgeml-infer](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/application/edgeml-infer) | `file application/edgeml-infer` outputs `ELF 64-bit LSB pie executable, x86-64`. | Must be `ELF 64-bit LSB executable, ARM aarch64`. | Cross-compile binary using `aarch64-linux-gnu-g++` or Buildroot host toolchain. |
| **04** | **Application Executes Host CPU Mock Loop without TFLite** | [application/edgeml_infer.cpp](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/application/edgeml_infer.cpp#L250-L270) | Lines 250–270 execute synthetic `acc += ...` loop and fixed confidence array `{0.874f, 0.052f, ...}` when `HAVE_TFLITE` undefined. | Real TFLite `FlatBufferModel::BuildFromFile` and `interpreter->Invoke()` execution. | Link against `libtensorflow-lite.so` in target sysroot. |
| **05** | **XNNPACK Claimed for ARM64 Target** | [documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md)<br>[documentation/ML_FRAMEWORK_INTEGRATION.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/ML_FRAMEWORK_INTEGRATION.md)<br>[documentation/SYSTEM_ARCHITECTURE.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/SYSTEM_ARCHITECTURE.md) | `package/xnnpack/Config.in` only enables `BR2_i386` and `BR2_x86_64`. Buildroot disables XNNPACK on ARM64. | Buildroot 2025.02.10 uses **RUY** (`-DTFLITE_ENABLE_RUY=ON`) on ARM64. | Update documentation to clarify RUY acceleration for ARM64 matrix operations. |
| **06** | **TensorFlow Lite Version Mismatch** | [configs/buildroot_defconfig](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/configs/buildroot_defconfig)<br>[documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md) | Comment in `buildroot_defconfig` says `2.14+`. Buildroot `tensorflow-lite.mk` specifies `2.11.0`. | Version is strictly `2.11.0`. | Correct version reference in defconfig and report from 2.14+ to 2.11.0. |
| **07** | **Kernel Preemption Config Missing** | [configs/kernel_defconfig](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/configs/kernel_defconfig)<br>[documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md) | `CONFIG_PREEMPT_VOLUNTARY` is cited in report but absent from `configs/kernel_defconfig`. | Option must be explicitly present in defconfig if claimed. | Add `CONFIG_PREEMPT_VOLUNTARY=y` to `configs/kernel_defconfig`. |
| **08** | **Kernel Size Unit Conflict** | [documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md)<br>[documentation/SUBMISSION_CHECKLIST.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/SUBMISSION_CHECKLIST.md) | `FINAL_REPORT.md` lists `52.40 MB vs 24.20 MB (Image)`. Checklist lists `31.18 MB vs 14.40 MB (Image.gz)`. | Raw `Image` is uncompressed; `Image.gz` is compressed. | Harmonize tables to clearly state uncompressed `Image` vs compressed `Image.gz`. |
| **09** | **Hardcoded Latency Percentiles & CPU Jitter** | [scripts/benchmark.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/scripts/benchmark.sh)<br>[results/benchmark_results.csv](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/results/benchmark_results.csv) | `CUSTOM_LATENCY_MEDIAN_MS=39.60`, `CUSTOM_LATENCY_P95_MS=44.10`, and `91.80% CPU` are hardcoded strings. | Live array percentile sorting and `vmstat`/`mpstat` background measurement. | Modify `benchmark.sh` to dynamically compute percentiles from iteration array. |
| **10** | **Build Pipeline Dependency Inversion** | [scripts/build.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/scripts/build.sh) | Step 4 attempts to build application before Step 5 builds Buildroot toolchain and staging headers. | Application must be cross-compiled after toolchain and TFLite staging are ready. | Reorder Step 4 to run after Step 5, pointing `CXX` to `output_qemu/host/bin/aarch64-linux-g++`. |
| **11** | **Target Image Absence** | [results/benchmark_results.csv](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/results/benchmark_results.csv)<br>[documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md) | `/mnt/d/buildroot_workspace/output_qemu/images/` does not exist on disk. | Images must be compiled to verify actual disk sizes. | Clearly designate 28.8 MB and 10.4 MB as defconfig-projected dimensions until full compile runs. |
| **12** | **Test Realism Classification** | [documentation/TESTING.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/TESTING.md)<br>[documentation/FINAL_REPORT.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md) | Reports present 14 stages as end-to-end full system verification. Tests are static checks and host mocks. | Tests verify configurations, syntax, and mock logic, not live booted QEMU execution. | Explicitly document test categories: 9 Static Checks, 5 Host Mocks, 0 Live QEMU Boots. |

---

## 7. Evaluator Commands to Verify All Claims Independently

Execute the following commands in WSL2 Ubuntu to verify every claim made in this audit:

```bash
# =============================================================================
# 1. Verify Application Binary Architecture (Reveals x86-64 Host Binary)
# =============================================================================
file /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/application/edgeml-infer

# =============================================================================
# 2. Verify Internal Mock Arithmetic Loop in Application Source
# =============================================================================
sed -n '250,275p' /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/application/edgeml_infer.cpp

# =============================================================================
# 3. Verify Discrepancy Between CSV (63.82 ms) and Report (40.85 ms)
# =============================================================================
grep "Inference Latency (Mean)" /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/results/benchmark_results.csv
grep "40.85" /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/documentation/FINAL_REPORT.md

# =============================================================================
# 4. Verify Hardcoded Literals in Benchmark Script
# =============================================================================
grep -n -E "CUSTOM_LATENCY_MEDIAN_MS|CUSTOM_LATENCY_P95_MS|Inference CPU Utilisation" \
    /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/scripts/benchmark.sh

# =============================================================================
# 5. Verify Buildroot 2025.02.10 TFLite Version (v2.11.0, NOT 2.14+)
# =============================================================================
grep "TENSORFLOW_LITE_VERSION = " \
    /mnt/d/buildroot_workspace/buildroot-2025.02.10/package/tensorflow-lite/tensorflow-lite.mk

# =============================================================================
# 6. Verify XNNPACK Architecture Restriction (Only i386 and x86_64, NOT aarch64)
# =============================================================================
cat /mnt/d/buildroot_workspace/buildroot-2025.02.10/package/xnnpack/Config.in

# =============================================================================
# 7. Verify RUY Architecture Support for ARM
# =============================================================================
cat /mnt/d/buildroot_workspace/buildroot-2025.02.10/package/ruy/Config.in

# =============================================================================
# 8. Verify SDOT Claims Against Cortex-A57 Specification
# =============================================================================
grep -rn -i "sdot" /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/documentation/

# =============================================================================
# 9. Verify Missing CONFIG_PREEMPT_VOLUNTARY in Kernel Defconfig
# =============================================================================
grep -i "PREEMPT" /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/configs/kernel_defconfig || echo "NOT SET"

# =============================================================================
# 10. Verify Build Pipeline Step Inversion in scripts/build.sh
# =============================================================================
grep -n -E "Step 4|Step 5" /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1/scripts/build.sh -A 3

# =============================================================================
# 11. Verify Absence of Compiled Kernel and Rootfs on Drive D:
# =============================================================================
ls -la /mnt/d/buildroot_workspace/output_qemu/images/ 2>/dev/null || echo "Images directory does not exist"
```
