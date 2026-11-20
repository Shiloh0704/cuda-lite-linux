# Reproducible Build Guide for EdgeML Linux OS
**Project:** EdgeML Linux OS  
**Distribution Track:** Track A – ML Inference at the Edge  
**Target Platform:** ARM64 (`aarch64` QEMU `virt` machine, Cortex-A57)  
**Build System:** Buildroot 2025.02.10  
**Document Reference:** `documentation/REPRODUCIBLE_BUILD.md`  
**Date:** November 19, 2026  

---

## 1. Overview & Build Philosophy

This guide provides end-to-end instructions allowing any student, instructor, or evaluator to reproduce the entire **EdgeML Linux OS** distribution from source.

The build process is fully automated via [scripts/build.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/scripts/build.sh) and is designed to run in a standard **Ubuntu 24.04 LTS** environment (native Linux or WSL2).

---

## 2. Host System Prerequisites

### 2.1 Hardware Requirements
* **Architecture:** x86_64 or ARM64 host system.
* **CPU:** Multi-core processor (4 to 12 cores recommended for parallel compilation).
* **RAM:** Minimum 8 GB (16 GB recommended for toolchain compilation).
* **Storage Capacity:** Minimum **15 GB** of free disk space on the build volume.
  - *Storage Safeguard Note*: If the primary host system drive `C:\` has less than 15 GB free space, the build scripts automatically redirect build artifacts (`output_qemu`) and package downloads (`dl/`) to secondary volume `D:\` (`/mnt/d/buildroot_workspace`), safeguarding the host OS.

### 2.2 Host Software Packages
Install all mandatory build tools via `apt`:

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    bison \
    flex \
    qemu-system-arm \
    libncurses-dev \
    wget \
    tar \
    unzip \
    file \
    bc \
    git \
    python3
```

---

## 3. Step-by-Step Reproduction Instructions

### Step 1: Clone or Navigate to the Project Root
```bash
cd /mnt/c/Users/shilo/OneDrive/OS_PROJECT_1
chmod +x scripts/*.sh tests/*.sh
```

### Step 2: Inspect Configurations (Optional)
The reproducible configurations are located in:
* Buildroot Defconfig: `configs/buildroot_defconfig`
* Linux Kernel Defconfig: `configs/kernel_defconfig`
* Benchmark Configuration: `benchmarks/benchmark_config.json`

### Step 3: Trigger the Automated Master Build
Execute the master build script:
```bash
./scripts/build.sh
```

### What `scripts/build.sh` Performs Automatically:
1. Validates host dependencies (`gcc`, `make`, `qemu-system-aarch64`, etc.).
2. Checks and verifies Buildroot **2025.02.10** source tree in the build workspace.
3. Applies `configs/buildroot_defconfig` and points the kernel to `configs/kernel_defconfig`.
4. Stages the rootfs overlay, including:
   - Read-only `/etc/fstab`
   - In-memory OverlayFS boot script `/etc/init.d/rcS`
   - Autonomous service daemon `/etc/init.d/S90edgeml`
   - Security sysctl hardening `/etc/sysctl.d/99-security.conf`
   - Quantized MobileNetV2 INT8 model and labels
5. Compiles the C++ inference application (`edgeml-infer`).
6. Executes parallel compilation (`make -j$(nproc)`).
7. Verifies generated images in `output_qemu/images/` and saves a timestamped log to `results/logs/`.

---

## 4. Launching & Testing in QEMU ARM64

### Launch the Virtual Machine:
```bash
./scripts/run_qemu.sh 1024 4
```

### QEMU Runtime Parameters:
* `-M virt`: ARM Virtual Platform.
* `-cpu cortex-a57`: High-performance 64-bit ARMv8-A CPU emulation with NEON SIMD.
* `-smp 4`: 4 allocated virtual CPU cores.
* `-m 1024M`: 1024 MB system RAM.
* `-drive file=.../rootfs.squashfs,readonly=on`: Immutable read-only rootfs block device.
* `-append "root=/dev/vda ro console=ttyAMA0 quiet"`: Serial console output.

### Terminating QEMU:
Press **`Ctrl + A`** then **`X`** to exit QEMU and return to the host terminal.

---

## 5. Running the Complete Quality Assurance Test Suite

To verify that the system satisfies all 14 assignment requirements:
```bash
./scripts/test.sh
```

All 14 test stages will execute and report **100% PASSED**.

---

## 6. Workspace Cleanup Procedure

To remove temporary build objects and test logs while preserving configurations and source code:
```bash
./scripts/clean.sh
```
