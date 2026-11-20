# EdgeML Linux OS

**Custom Lightweight Linux Distribution for Edge AI Inference**  
*Track A: University Embedded & Specialized Operating Systems Project*  
*Target Architecture: 64-bit ARM (`aarch64` QEMU `virt` Platform, Cortex-A57)*  
*Build System: Buildroot 2025.02.10 LTS | Linux Kernel 6.12.27 LTS*  

---

## Key Achievements & Benchmark Highlights

* **98.44% Reduction in RootFS Size**: 28.8 MB custom root filesystem vs. 1,850 MB stock Ubuntu ARM64 server minimal.
* **98.47% Reduction in Flash Image Size**: 10.4 MB compressed SquashFS image vs. 680 MB stock baseline.
* **90.00% Faster Cold Boot Time**: 1.85 s kernel-to-userland cold boot vs. 18.50 s stock baseline.
* **93.50% Memory Footprint Savings**: 18.2 MB idle RAM consumption vs. 280 MB stock baseline.
* **189.70% Higher Inference Throughput**: 24.48 FPS vs. 8.45 FPS under identical CPU hardware emulation.
* **Tamper-Proof Immutability**: Read-only SquashFS rootfs unified with an in-memory volatile `tmpfs` OverlayFS.
* **5-Tier Production Security Hardening**: ASLR (`randomize_va_space=2`), kernel pointer hiding (`kptr_restrict=2`), dmesg restriction, unprivileged `edgeml` service account, and zero-port attack surface.
* **100% Quality Assurance Pass**: All 14 automated test verification stages passed cleanly.

---

## Target Hardware Emulation Specifications

| Component | Target Specification |
| :--- | :--- |
| **Virtual Platform** | QEMU ARM Virtual Machine (`-M virt`, version 10.2+) |
| **Virtual CPU** | 4 vCPUs, ARM Cortex-A57 (ARMv8-A Architecture + NEON SIMD) |
| **Virtual RAM** | 1024 MB DDR Memory |
| **Storage Architecture** | VirtIO Block Device (`/dev/vda`) hosting SquashFS Read-Only Root |
| **Volatile Storage** | In-Memory `tmpfs` OverlayFS for `/var` and `/tmp` |
| **Network Interface** | VirtIO Network Adapter (`eth0`) with default inbound packet drop |
| **Serial Console** | ARM PrimeCell PL011 UART mapped to `/dev/ttyAMA0` |
| **ML Framework** | TensorFlow Lite 2.11/2.14+ C++ API (ARM NEON / XNNPACK Micro-Kernels) |
| **Edge Model** | MobileNetV2 INT8 Quantized Model (224x224x3 RGB, 1001 Classes, 4.1 MB) |

---

## Repository Structure

```
OS_PROJECT_1/
├── application/               # Edge AI inference application & Makefile
│   ├── edgeml_infer.cpp       # Core C++ inference engine & Top-5 classifier
│   ├── edgeml-infer           # Compiled native ARM64 executable
│   ├── edgeml_benchmark.cpp   # Latency & throughput telemetry harness
│   ├── stb_image.h            # Single-header zero-dependency image decoder
│   └── Makefile               # Cross-compilation build automation
├── benchmarks/                # Benchmarking suites & configuration
│   ├── benchmark_config.json  # Standardized benchmark workload specification
│   └── run_benchmarks.sh      # Automated benchmarking execution runner
├── board/                     # Target rootfs overlays & initialization scripts
│   ├── rootfs_overlay/        # Clean target root filesystem skeleton
│   │   ├── etc/fstab          # Read-only rootfs mount table
│   │   ├── etc/passwd         # Unprivileged 'edgeml' service user (UID 1001)
│   │   ├── etc/init.d/rcS     # In-memory OverlayFS mount script
│   │   ├── etc/init.d/S05firewall # Inbound network port restriction
│   │   ├── etc/init.d/S90edgeml   # Autonomous inference daemon supervisor
│   │   └── etc/sysctl.d/99-security.conf # Kernel ASLR & exploit mitigations
│   └── edgeml/                # Board support package definitions
├── configs/                   # Reproducible build configurations
│   ├── buildroot_defconfig    # Buildroot 2025.02 defconfig (TFLite, Glibc, C++17)
│   └── kernel_defconfig       # Tailored minimal Linux 6.12.27 ARM64 kernel
├── documentation/             # Technical reports & academic deliverables
│   ├── FINAL_REPORT.md        # Comprehensive 17-section final technical report
│   ├── PERFORMANCE_EVALUATION.md # Comparative benchmark analysis vs stock Linux
│   ├── SYSTEM_ARCHITECTURE.md # System architecture & Mermaid flowcharts
│   ├── INFERENCE_APPLICATION.md # Inference application design & validation
│   ├── SECURITY_HARDENING.md  # Production security hardening audit & evidence
│   ├── SYSTEM_SERVICES.md     # Autonomous service lifecycle & crash handling
│   ├── REPRODUCIBLE_BUILD.md  # Step-by-step reproduction guide
│   ├── TESTING.md             # Complete 14-stage quality assurance report
│   ├── DEPLOYMENT.md          # Edge deployment & partition topography guide
│   ├── DEMO_SCRIPT.md         # 5-8 minute video demonstration walkthrough
│   └── SUBMISSION_CHECKLIST.md# Verification checklist of all 20 requirements
├── models/                    # Staged edge machine learning models
│   ├── mobilenet_v2_quant.tflite # Quantized INT8 MobileNet model (4.1 MB)
│   └── labels.txt             # 1,001 ImageNet classification labels
├── results/                   # Empirical benchmark data & logs
│   ├── benchmark_results.csv  # Full comparison metrics vs stock Ubuntu ARM64
│   └── logs/                  # Persistent build & execution logs
├── scripts/                   # Master automation scripts
│   ├── build.sh               # Master reproducible build pipeline
│   ├── run_qemu.sh            # Configurable QEMU ARM64 launcher
│   ├── test.sh                # Master test runner (All 14 test stages)
│   ├── benchmark.sh           # Repeatable benchmarking script
│   ├── security_check.sh      # Security compliance audit checker
│   └── clean.sh               # Workspace cleanup utility
└── tests/                     # Automated regression test suites
    ├── test_inference.py      # Python regression test for edgeml-infer (5/5 Passed)
    ├── test_security.sh       # Security invariant test suite (5/5 Passed)
    ├── test_autostart.sh      # Service lifecycle test suite (5/5 Passed)
    ├── test_ml_runtime.sh     # ELF and dynamic library auditor
    ├── test.jpg               # Standard ImageNet test image
    └── grace_hopper.jpg       # Canonical benchmark evaluation image
```

---

## Quickstart Guide

### 1. Prerequisites (WSL2 Ubuntu 24.04 or Linux Host)
```bash
sudo apt update && sudo apt install -y \
    build-essential bison flex qemu-system-arm libncurses-dev \
    wget tar unzip file bc python3
```

### 2. Execute the Master Reproducible Build
```bash
./scripts/build.sh
```
*Note: Buildroot output and package caches automatically redirect to secondary volume `D:\` (`/mnt/d/buildroot_workspace`) to safeguard the host system drive `C:\`.*

### 3. Launch EdgeML Linux OS in QEMU ARM64
```bash
./scripts/run_qemu.sh 1024 4
```
*(Press `Ctrl + A` then `X` to exit QEMU at any time).*

### 4. Run Image Classification Inside EdgeML Linux OS
```bash
edgeml-infer /data/test.jpg
```

### 5. Run the Master Quality Assurance Test Suite
```bash
./scripts/test.sh
```
*(Executes all 14 test stages; reports 100% compliance).*

### 6. Run the Repeatable Benchmarking Framework
```bash
./scripts/benchmark.sh
```
*(Calculates image size reductions and updates `results/benchmark_results.csv`).*

---

## License & Attribution

* **EdgeML Linux OS Code & Scripts**: Open-source under the **MIT License**.
* **Linux Kernel 6.12.27**: Licensed under **GPL-2.0-only**.
* **BusyBox 1.36.1**: Licensed under **GPL-2.0-only**.
* **TensorFlow Lite & MobileNetV2**: Developed by Google LLC / The TensorFlow Authors, licensed under **Apache-2.0**.
* **stb_image.h**: Authored by Sean Barrett, released into the **Public Domain / MIT**.
