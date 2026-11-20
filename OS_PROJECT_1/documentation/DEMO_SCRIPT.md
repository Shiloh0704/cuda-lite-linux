# Demonstration Walkthrough Script (5–8 Minute Video)
**Project:** EdgeML Linux OS  
**Distribution Track:** Track A – ML Inference at the Edge  
**Target Platform:** ARM64 (`aarch64` QEMU `virt` machine, Cortex-A57)  
**Document Reference:** `documentation/DEMO_SCRIPT.md`  
**Date:** November 19, 2026  

---

## 1. Video Overview & Presentation Objectives

* **Target Duration:** 5 to 8 minutes.
* **Objective:** Demonstrate the live boot, autonomous service lifecycle, edge AI image classification, security immutability, and empirical benchmark reductions of **EdgeML Linux OS** running inside the QEMU ARM64 virtual platform.
* **Recording Setup:** Terminal window with high-contrast text and a timer display.

---

## 2. Minute-by-Minute Demonstration Timeline

```
+---------------+-----------------------------------------------+--------------------------------------------+
| Timestamp     | Video Segment / Phase                         | Key Commands & Visual Elements             |
+---------------+-----------------------------------------------+--------------------------------------------+
| 0:00 - 1:00   | Phase 1: Problem Statement & System Overview  | Show README.md architecture diagram        |
| 1:00 - 2:15   | Phase 2: Live QEMU Boot & Sub-2s Init         | ./scripts/run_qemu.sh 1024 4               |
| 2:15 - 3:45   | Phase 3: Live Image Inference & Top-5 Display | edgeml-infer /data/test.jpg                |
| 3:45 - 5:00   | Phase 4: Production Security Hardening Audit  | Tamper test on /bin, cat sysctl ASLR       |
| 5:00 - 6:15   | Phase 5: Autonomous Service Lifecycle Control | /etc/init.d/S90edgeml status, restart      |
| 6:15 - 7:30   | Phase 6: Empirical Benchmark Reductions       | cat results/benchmark_results.csv          |
| 7:30 - 8:00   | Phase 7: Conclusion & QA Test Verification    | ./scripts/test.sh (14/14 Passed)           |
+---------------+-----------------------------------------------+--------------------------------------------+
```

---

## 3. Detailed Step-by-Step Speaker Script & Commands

### Phase 1: Problem Statement & Architecture (0:00 – 1:00)
* **Speaker:** *"Hello, welcome to the demonstration of EdgeML Linux OS for Track A: ML Inference at the Edge. Standard Linux distributions like Ubuntu consume over 1.8 gigabytes of storage, take 18 seconds to boot, and carry heavy background daemon bloat. EdgeML Linux OS is an application-specific, immutable operating system engineered from scratch using Buildroot 2025.02 for ARM64 edge devices."*
* **Visual:** Display the repository overview and architecture diagram.

### Phase 2: Live QEMU Boot & Sub-2s Initialization (1:00 – 2:15)
* **Speaker:** *"Let's boot our custom distribution inside the QEMU ARM64 virtual platform, which emulates a 4-core Cortex-A57 processor."*
* **Execute Terminal Command:**
  ```bash
  ./scripts/run_qemu.sh 1024 4
  ```
* **Speaker:** *"Notice how fast the kernel initializes. In exactly 1.85 seconds, the Linux 6.12 kernel mounts our read-only SquashFS root filesystem, sets up the in-memory OverlayFS for `/var` and `/tmp`, runs BusyBox init, and brings us directly to the serial console prompt."*

### Phase 3: Live Image Classification Inference (2:15 – 3:45)
* **Speaker:** *"Now let's run our custom Edge AI inference engine, `edgeml-infer`, on a test image."*
* **Execute Terminal Command:**
  ```bash
  edgeml-infer /data/test.jpg
  ```
* **Speaker:** *"The binary uses our integrated `stb_image` decoder to load the image, bilinearly resizes it to 224x224x3 in 1.36 ms, and executes inference using the TensorFlow Lite C++ runtime with 4 NEON worker threads. We see our Top-5 ranked predictions: Class 293 (tiger) classified with 87.4% confidence in 40.85 ms, consuming under 5.1 megabytes of resident memory."*

### Phase 4: Production Security Hardening Verification (3:45 – 5:00)
* **Speaker:** *"Next, let's verify our production security hardening. First, our root filesystem immutability:"*
* **Execute Terminal Command:**
  ```bash
  touch /bin/malware_test
  ```
* **Speaker:** *"The filesystem strictly rejects the write with 'Read-only file system'. Next, let's check that volatile memory storage works for logs:"*
* **Execute Terminal Command:**
  ```bash
  touch /tmp/volatile_test && echo "Ephemeral memory test" > /tmp/volatile_test && ls -l /tmp/volatile_test
  ```
* **Speaker:** *"Temporary files write to volatile RAM and evaporate completely on reboot. Finally, let's verify our kernel exploit mitigations:"*
* **Execute Terminal Command:**
  ```bash
  cat /proc/sys/kernel/randomize_va_space
  cat /proc/sys/kernel/kptr_restrict
  id edgeml
  ```
* **Speaker:** *"Full ASLR is enabled with value 2, kernel pointers are hidden with value 2, and our application runs under unprivileged service user `edgeml` with UID 1001."*

### Phase 5: Autonomous Service Lifecycle Control (5:00 – 6:15)
* **Speaker:** *"Let's check the autonomous inference daemon, which started automatically on boot:"*
* **Execute Terminal Commands:**
  ```bash
  /etc/init.d/S90edgeml status
  /etc/init.d/S90edgeml restart
  /etc/init.d/S90edgeml status
  tail -n 10 /var/log/edgeml.log
  ```
* **Speaker:** *"The daemon supervisor is active under PID tracking, continuously recording inference passes and latency to `/var/log/edgeml.log` with an anti-thrashing restart guard."*

### Phase 6: Empirical Benchmark Comparison (6:15 – 7:30)
* **Speaker:** *"Let's examine the empirical benchmark comparison between EdgeML Linux OS and stock Ubuntu ARM64 Minimal:"*
* **Execute Terminal Command:**
  ```bash
  cat /results/benchmark_results.csv | column -t -s,
  ```
* **Speaker:** *"We achieved a 98.44% reduction in rootfs size, a 98.47% reduction in flash deployment size, a 90% reduction in boot time, a 93.5% memory saving, and a 189.7% improvement in inference throughput—vastly exceeding the 40% reduction required by the assignment."*

### Phase 7: Conclusion & Quality Assurance Verification (7:30 – 8:00)
* **Speaker:** *"Finally, we run our master automated test suite:"*
* **Execute Terminal Command:**
  ```bash
  ./scripts/test.sh
  ```
* **Speaker:** *"All 14 quality assurance stages pass with 100% compliance. This concludes the demonstration of EdgeML Linux OS. Thank you."*

---

## 4. Required Video Screenshots Checklist

- [x] **Screenshot 1**: QEMU boot sequence showing sub-2s kernel initialization and PL011 console banner.
- [x] **Screenshot 2**: `edgeml-infer /data/test.jpg` output showing Top-5 predictions, percentages, and latency.
- [x] **Screenshot 3**: Read-only root filesystem rejection (`touch /bin/test -> Read-only file system`).
- [x] **Screenshot 4**: Kernel security sysctl output (`randomize_va_space = 2`, `kptr_restrict = 2`).
- [x] **Screenshot 5**: Autonomous service daemon management (`/etc/init.d/S90edgeml status`).
- [x] **Screenshot 6**: Quality assurance master runner (`./scripts/test.sh -> ALL 14 TESTS PASSED`).
