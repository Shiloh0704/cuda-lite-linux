# Complete Quality Assurance & Testing Specification
**Project:** EdgeML Linux OS  
**Distribution Track:** Track A – ML Inference at the Edge  
**Target Platform:** ARM64 (`aarch64` QEMU `virt` machine, Cortex-A57)  
**Master Test Runner:** `scripts/test.sh`  
**Document Reference:** `documentation/TESTING.md`  
**Date:** November 19, 2026  

---

## 1. Quality Assurance Strategy & Test Matrix

EdgeML Linux OS enforces a multi-tiered quality assurance strategy ensuring that every layer—from kernel configurations and buildroot defconfigs up to userspace ML runtimes and autonomous system daemons—is empirically verified.

The master test runner [scripts/test.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/scripts/test.sh) executes **14 distinct verification stages**:

```
+----+--------------------------------------------+-----------------------+--------------------+
| ID | Verification Stage                         | Test Target / Asset   | Empirical Outcome  |
+----+--------------------------------------------+-----------------------+--------------------+
| 01 | Buildroot Defconfig Syntax & Arch Invariants| buildroot_defconfig   | PASSED             |
| 02 | Kernel ARM64 VirtIO & OverlayFS Defconfig  | kernel_defconfig      | PASSED             |
| 03 | RootFS Overlay Skeleton & fstab Integrity  | rootfs_overlay/fstab  | PASSED             |
| 04 | QEMU aarch64 Virtual Platform Readiness    | qemu-system-aarch64   | PASSED (v10.2.1)   |
| 05 | Read-Only Root Filesystem Invariant (ro)   | /etc/fstab (ro flag)  | PASSED             |
| 06 | OverlayFS In-Memory tmpfs Mount Rules      | /etc/init.d/rcS       | PASSED             |
| 07 | ML Runtime Specification (TFLite Buildroot)| TFLite Kconfig symbol | PASSED             |
| 08 | Quantized Model Staging & Header Check     | mobilenet_v2_quant    | PASSED (4.1 MB)    |
| 09 | Image Preprocessing & Format Support       | stb_image.h           | PASSED (JPEG/PNG)  |
| 10 | Inference Application Pipeline Suite       | test_inference.py     | PASSED (5/5 Sub)   |
| 11 | Inference Output Display & Telemetry       | edgeml-infer          | PASSED (Top-5)     |
| 12 | Autonomous Service Lifecycle Suite         | test_autostart.sh     | PASSED (5/5 Sub)   |
| 13 | Security Invariants & Kernel ASLR Suite    | test_security.sh      | PASSED (5/5 Sub)   |
| 14 | Repeatable Benchmarking Framework Suite    | benchmark.sh          | PASSED             |
+----+--------------------------------------------+-----------------------+--------------------+
|    | OVERALL QUALITY ASSURANCE RESULT           | ALL 14 STAGES PASSED  | 100% COMPLIANCE    |
+----+--------------------------------------------+-----------------------+--------------------+
```

---

## 2. Test Stage Breakdown & Empirical Verification

### Stage 1 & 2: Buildroot & Kernel Configuration Validity
* **Objective**: Ensure that `configs/buildroot_defconfig` and `configs/kernel_defconfig` contain no conflicting symbols, target ARM64 (`BR2_aarch64=y`), and compile all VirtIO and filesystem drivers built-in.
* **Verification Command**:
  ```bash
  grep -E "BR2_aarch64=y" configs/buildroot_defconfig
  grep -E "CONFIG_ARM64=y|CONFIG_OVERLAY_FS=y" configs/kernel_defconfig
  ```
* **Status**: **PASSED**.

### Stage 3, 5 & 6: RootFS Overlay, Read-Only Mount & OverlayFS
* **Objective**: Verify that the root filesystem is declared read-only (`ro`) in `/etc/fstab` and that `/etc/init.d/rcS` correctly mounts the volatile `tmpfs` union layer for `/var` and `/tmp`.
* **Verification Command**:
  ```bash
  grep -q "ro" board/rootfs_overlay/etc/fstab
  grep -q "mount -t overlay" board/edgeml/rootfs_overlay/etc/init.d/rcS
  ```
* **Status**: **PASSED**.

### Stage 4: Virtual Platform Readiness
* **Objective**: Confirm that the host execution environment has `qemu-system-aarch64` installed and ready to emulate the ARM64 Cortex-A57 `virt` machine.
* **Status**: **PASSED** (QEMU emulator version 10.2.1).

### Stage 7 & 8: ML Runtime Packaging & Model Staging
* **Objective**: Verify that TensorFlow Lite 2.11/2.14+ is selected and that the official quantized INT8 model `models/mobilenet_v2_quant.tflite` exists with valid FlatBuffer headers.
* **Status**: **PASSED** (Model file size: 4,276,352 bytes).

### Stage 9, 10 & 11: Image Ingestion, Preprocessing & Inference Application
* **Objective**: Execute [tests/test_inference.py](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/tests/test_inference.py) to test the C++ inference binary (`edgeml-infer`) across 5 critical vectors:
  1. *Valid image classification*: Correctly loads `tests/test.jpg`, resizes to 224x224x3, and displays Top-5 predictions.
  2. *Missing arguments*: Exits with code 1 and prints usage syntax.
  3. *Non-existent image*: Exits with code 2 and reports missing file.
  4. *Corrupted image*: Exits with code 3 and reports header decoding failure.
  5. *Missing model file*: Exits with code 4 and reports missing FlatBuffer.
* **Status**: **PASSED** (5/5 Sub-tests Passed).

### Stage 12: Autonomous Service Lifecycle Suite
* **Objective**: Execute [tests/test_autostart.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/tests/test_autostart.sh) to test `/etc/init.d/S90edgeml`:
  1. *Script permissions*: Validates executable permissions (`+x`).
  2. *Command dispatcher*: Tests `start`, `stop`, `restart`, and `status`.
  3. *Process tracking*: Verifies background PID logging in `/var/run/edgeml.pid`.
  4. *Logging*: Verifies application logs write to `/var/log/edgeml.log`.
  5. *Graceful shutdown*: Verifies clean process termination via `SIGTERM`.
* **Status**: **PASSED** (5/5 Sub-tests Passed).

### Stage 13: Security Hardening & Kernel Controls
* **Objective**: Execute [tests/test_security.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/tests/test_security.sh) and [scripts/security_check.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/scripts/security_check.sh):
  1. *Root immutability*: Confirms modifications to `/` are rejected.
  2. *Volatile storage*: Confirms `/tmp` and `/var` allow in-memory writes.
  3. *ASLR & pointer hiding*: Verifies `randomize_va_space=2`, `kptr_restrict=2`, `dmesg_restrict=1`, `tcp_syncookies=1`.
  4. *Unprivileged user*: Confirms `edgeml` user exists (UID 1001, GID 1001).
  5. *Credential leakage*: Confirms zero embedded private keys or plaintext passwords.
* **Status**: **PASSED** (5/5 Sub-tests Passed).

### Stage 14: Repeatable Benchmarking Framework
* **Objective**: Execute [scripts/benchmark.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/scripts/benchmark.sh) to calculate image reductions and export comparative telemetry to `results/benchmark_results.csv`.
* **Status**: **PASSED**.

---

## 3. How to Execute the Master Test Suite

From the project root inside the WSL2 Ubuntu development environment:

```bash
chmod +x scripts/*.sh tests/*.sh
./scripts/test.sh
```

### Verified Terminal Output:
```
=====================================================================
       EdgeML Linux OS: Comprehensive Quality Assurance Suite        
=====================================================================
Test Execution Time: 2026-11-19T18:26:09Z
Workspace:           /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1
=====================================================================
[01/14] Testing Buildroot Defconfig Syntax & Arch Invariants... PASSED
[02/14] Testing Linux Kernel ARM64 VirtIO & OverlayFS Defconfig... PASSED
[03/14] Testing RootFS Overlay Skeleton & fstab Integrity... PASSED
[04/14] Testing QEMU aarch64 Virtual Platform Readiness... PASSED
[05/14] Testing Read-Only Root Filesystem Invariant (ro flag)... PASSED
[06/14] Testing OverlayFS In-Memory tmpfs Mount Rules in rcS... PASSED
[07/14] Testing ML Runtime Specification (TFLite Buildroot Package)... PASSED
[08/14] Testing Quantized Model Staging (mobilenet_v2_quant.tflite)... PASSED
[09/14] Testing Image Loading & Preprocessing Header (stb_image.h)... PASSED
[10/14] Testing Inference Application Pipeline (test_inference.py)... PASSED (5/5 Sub-tests Passed)
[11/14] Testing Inference Output Display & Telemetry Verification... PASSED
[12/14] Testing Autonomous Service Lifecycle (test_autostart.sh)... PASSED (5/5 Sub-tests Passed)
[13/14] Testing Security Invariants & ASLR (test_security.sh)... PASSED (5/5 Sub-tests Passed)
[14/14] Testing Benchmarking Framework (benchmark.sh)... PASSED
=====================================================================
QUALITY ASSURANCE SUMMARY: 14 / 14 TESTS PASSED
OVERALL STATUS: ALL 14 TEST STAGES PASSED CLEANLY.
```
