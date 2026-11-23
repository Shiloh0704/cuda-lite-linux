# CUDA-Lite Linux Distribution (Track C)
# Complete Reproducible Build & Verification Guide

**Date:** November 22, 2026  
**Target Architecture:** x86-64 / AMD64  
**Target Operating System:** Debian 13 (Trixie) GNU/Linux  
**Target Hardware:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, SM 8.9)  
**Host Environment:** Ubuntu 24.04 on WSL2 / Windows 11  

---

## 1. Overview & Build Philosophy
The primary engineering objective of **CUDA-Lite Linux** is deterministic, script-driven reproducibility. Any engineer with access to an Ubuntu 24.04 WSL2 or native Linux host can rebuild the entire operating system, compile the custom kernel, package the bootable hybrid ISO, and reproduce the GPU benchmarks using the instructions in this guide.

---

## 2. Host Prerequisites & Dependencies

### A. Hardware Requirements
- **CPU:** x86-64 multi-core processor (Intel Core i5/i7/i9 or AMD Ryzen).
- **RAM:** Minimum 8 GB host RAM (16 GB recommended).
- **Storage:** Minimum 25 GB free disk space on an ext4 filesystem.
- **GPU (for host benchmarks):** NVIDIA GPU with compute capability $\ge 5.0$ (GeForce RTX 4050 tested).

### B. Required Host Build Packages
Install all required bootstrapping, kernel compilation, and ISO packaging packages on the host:
```bash
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    debootstrap \
    mksquashfs \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    qemu-system-x86 \
    build-essential \
    flex \
    bison \
    libssl-dev \
    libelf-dev \
    bc \
    dosfstools \
    curl \
    git \
    python3
```

---

## 3. Step-by-Step ISO Build Procedure

The master build script is located at `build/build_iso.sh`. It executes the complete 7-stage pipeline:
1. `debootstrap` bootstrapping of a minimal Debian 13 Trixie rootfs.
2. Kernel headers, core modules, and systemd installation.
3. NVIDIA Driver 550.163.01 and CUDA 12.4.131 toolkit deployment.
4. Security hardening application (`/etc/sysctl.d/99-cuda-lite-hardening.conf`).
5. Rootfs cleanup, exclusions filtering, and SquashFS compression.
6. GRUB 2 BIOS/UEFI dual-boot hybrid filesystem layout assembly.
7. ISO image generation via `xorriso` and SHA-256 integrity hashing.

### Rebuilding the ISO
Execute the build script with root privileges:
```bash
cd /mnt/c/Users/shilo/OneDrive/OS_Project
sudo ./build/build_iso.sh
```
*Expected Output:*
- Build directory: `/var/tmp/cuda-lite-build/`
- Output ISO: `build/cuda-lite-linux.iso` (and `/mnt/d/cuda-lite-linux.iso`)
- Size: ~2.88 GB (2,879,352,832 bytes)
- SHA-256: `416c8b54bee8f8d2888fb1bbcaa0b37ceca2a5be341c0750a89d27c1c7fc38cb`

---

## 4. Custom Kernel Compilation Procedure

To compile the stripped, low-latency compute kernel:
```bash
# 1. Download and extract Linux 6.12 source
cd /var/tmp
tar -xJf linux-6.12.tar.xz
cd linux-6.12

# 2. Deploy custom minimal compute configuration
cp /mnt/c/Users/shilo/OneDrive/OS_Project/kernel/.config .config

# 3. Compile kernel bzImage and core modules
make -j$(nproc) bzImage
make -j$(nproc) modules

# 4. Install modules to staging directory
make modules_install INSTALL_MOD_PATH=/var/tmp/custom-kernel-modules

# 5. Measure kernel binary sizes
ls -lh arch/x86/boot/bzImage
```

---

## 5. QEMU Boot Verification Procedure

CUDA-Lite includes both interactive graphical and automated test launchers:

### A. Visible Graphical GTK Boot (Recommended)
Launches QEMU in the foreground displaying the live virtual monitor via WSLg:
```bash
./tests/test_boot.sh
```
*Key Parameters Used:*
- **Acceleration:** `-enable-kvm -cpu host` (KVM hardware virtualization).
- **vCPUs & RAM:** `-smp 2 -m 2048` (2 vCPUs, 2 GB RAM).
- **Display:** `-display gtk -vga std` (GUI window active).
- **Clean Hardware:** Floppy, parallel port, and PC speaker emulation disabled.
- **Boot Latency:** Reaches `cuda-lite login:` in **23.21 seconds**.

### B. Automated Headless Boot Test
Executes unattended test and verifies serial console output with a 120s timeout:
```bash
./tests/run_qemu_test.sh
```

---

## 6. CUDA Benchmark Reproduction Procedure

To reproduce the GPU compute benchmarks on the physical NVIDIA RTX 4050 GPU:

### A. Build CUDA Application Binaries
```bash
cd /mnt/c/Users/shilo/OneDrive/OS_Project/cuda
make clean && make
```
*Generated Binaries:*
- `device_query`: Interrogates device architecture, SM count, and clocks.
- `matrix_mul`: Executes tiled and naive matrix multiplication benchmarks.

### B. Execute Matrix Multiplication Benchmark
```bash
# Test with matrix dimension N=2048, 5 iterations
./matrix_mul 2048 5
```
*Expected Benchmark Range:*
- CPU Execution: ~1,900 - 2,050 ms.
- GPU Tiled Kernel: ~21.0 - 22.5 ms.
- Compute Throughput: ~780 - 805 GFLOPS.
- End-to-End Speedup: ~38x - 40x.
- Numerical Error: $< 1.0 \times 10^{-4}$ (**PASSED**).

---

## 7. Troubleshooting & Common Build Questions

1. **Why does QEMU show "No NVIDIA PCI device detected"?**
   - Standard QEMU virtual machines do not have access to the physical laptop discrete GPU unless dedicated PCIe VFIO passthrough is configured (which requires a second GPU). The startup script is hardware-aware: it detects the virtual bus, logs a notice, and skips GPU execution without crashing.
2. **How to test container runtime hooks?**
   - Execute `./packages/container/test_gpu_container.sh` on the host to verify OCI container hooks into the NVIDIA driver stack.
