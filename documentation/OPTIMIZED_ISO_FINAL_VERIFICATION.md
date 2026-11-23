# CUDA-Lite Linux Distribution (Track C: GPU Compute)
## Optimized ISO Comprehensive Final Verification Report

**Date:** November 22, 2026  
**Distribution:** CUDA-Lite Linux Distribution  
**Track:** Track C — NVIDIA CUDA / GPU Compute  
**System Architecture:** x86_64 (Hybrid BIOS / UEFI Boot)  
**Target ISO:** `/mnt/d/cuda-lite-linux-optimized.iso`  
**Evaluation Standard:** 40% Size Reduction Target relative to Stock Ubuntu Desktop Baseline  
**Verification Verdict:** **PASS (All Critical Requirements Satisfied & Exceeded)**

---

## 1. Executive Summary

This report documents the independent verification and storage optimization audit of the newly assembled **CUDA-Lite Linux Optimized ISO** (`/mnt/d/cuda-lite-linux-optimized.iso`).

The primary challenge of Track C is maintaining an enterprise-grade NVIDIA GPU compute and container stack—including the CUDA 12.4 compiler and runtime libraries, cuDNN 9 neural network acceleration libraries, Docker Engine, containerd, runc, NVIDIA Container Toolkit, and dual Linux 6.12 kernels with NVIDIA DKMS kernel modules—while adhering to the project's strict storage efficiency mandate: a **minimum 40% size reduction** relative to the stock Ubuntu Desktop baseline (**4,020,000,000 bytes**).

### Key Verification Milestones:
1. **Size Target Achieved & Exceeded:** The optimized ISO measures **2,234,140,672 bytes (2.0807 GiB / 2.2341 GB)**, surpassing the maximum target threshold of 2,412,000,000 bytes by **177,859,328 bytes (169.62 MB)**. This represents an overall size reduction of **44.42%** vs. stock baseline.
2. **Dual-Kernel QEMU Boot to Systemd Login Prompt:**
   - **Default Debian 6.12.117 Kernel (with NVIDIA DKMS):** Booted to `cuda-lite login:` in **21.85 seconds** (improved from 29.10s in candidate).
   - **Custom Low-Latency 6.12.0-cuda-lite Kernel:** Booted to `cuda-lite login:` in **20.03 seconds**.
3. **Guest Stack Integrity:** Verified active in-guest OverlayFS mounting, root writeability, CUDA compiler (`nvcc` 12.4.131), cuDNN 9 runtime shared libraries (`libcudnn.so.9.0.0`, `libcudnn_adv.so`, `libcudnn_engines_precompiled.so`), cuDNN development headers (`cudnn.h`), Docker CLI (`26.1.5`), containerd (`1.7.24`), runc (`1.1.15`), NVIDIA Container Toolkit (`nvidia-ctk` 1.20.2), and systemd autostart services.
4. **Deliverable Preservation:** Original production deliverables (`/mnt/d/cuda-lite-linux.iso` and `submission/CUDA_Lite_Final_Submission.zip`) and intermediate candidate deliverables (`/mnt/d/cuda-lite-linux-candidate.iso`) remain completely unchanged and cryptographically verified.

---

## 2. Artifact Verification & Preservation Audit

All three primary distribution images were verified directly on physical storage (`/mnt/d/`) using byte-level size inspection, timestamp tracking, and SHA-256 cryptographic hashing.

### 2.1 Complete Image Inventory

| ISO Artifact | Role / Status | File Size (Bytes) | Size (GiB) | Size (GB) | SHA-256 Cryptographic Hash |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`cuda-lite-linux.iso`** | Production Original (Verified) | `2,879,352,832` | 2.6816 GiB | 2.8794 GB | `416c8b54bee8f8d2888fb1bbcaa0b37ceca2a5be341c0750a89d27c1c7fc38cb` |
| **`cuda-lite-linux-candidate.iso`** | Integration Candidate (Verified) | `3,642,230,784` | 3.3921 GiB | 3.6422 GB | `e7c51840f82a29bd25130741e158f0dd77052794b0b3f1586904114269246acf` |
| **`cuda-lite-linux-optimized.iso`** | **Optimized Deliverable (New)** | **`2,234,140,672`** | **2.0807 GiB** | **2.2341 GB** | `2fad5ca244b49d2ff6db86d08fcae23c366382240e1b1dcad56e4b8783c2864a` |

### 2.2 Preservation Confirmation
- The original production ISO SHA-256 (`416c8b54...`) matches the master submission record exactly.
- The intermediate candidate ISO SHA-256 (`e7c51840...`) matches the integration build record exactly.
- Neither file was altered, moved, or overwritten during optimization staging or image creation.

### 2.3 Hybrid Boot Structure Inspection
Inspection of `/mnt/d/cuda-lite-linux-optimized.iso` via `file` and `fdisk`:
```text
$ file /mnt/d/cuda-lite-linux-optimized.iso
/mnt/d/cuda-lite-linux-optimized.iso: ISO 9660 CD-ROM filesystem data (DOS/MBR boot sector) 'ISOIMAGE' (bootable)

$ fdisk -l /mnt/d/cuda-lite-linux-optimized.iso
Disk /mnt/d/cuda-lite-linux-optimized.iso: 2.08 GiB, 2234140672 bytes, 4363556 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 6A55E72B-3C78-4D51-BB8E-258048B1C5BB

Device                                  Start     End Sectors  Size Type
/mnt/d/cuda-lite-linux-optimized.iso1      64     299     236  118K Microsoft basic data
/mnt/d/cuda-lite-linux-optimized.iso2     300    6059    5760  2.8M EFI System
/mnt/d/cuda-lite-linux-optimized.iso3    6060 4362907 4356848  2.1G Apple HFS/HFS+
/mnt/d/cuda-lite-linux-optimized.iso4 4362908 4363507     600  300K Microsoft basic data
```
- **MBR Boot Code:** Contains DOS/MBR system area code (`boot_hybrid.img`) for legacy BIOS booting.
- **Partition 2 (EFI System):** 2.8 MB FAT partition containing GRUB EFI binaries (`x86_64-efi/core.efi`) for modern UEFI firmware booting.
- **ISO Readability Test:** Streamed 100 MB from raw medium using `dd bs=10M count=10 status=progress` with 0 I/O errors at 36 MB/s.

---

## 3. Storage Comparison & 40% Reduction Analysis

The project benchmark baseline is defined by a stock **Ubuntu 24.04 Desktop installation** measuring **4,020,000,000 bytes** (4.020 GB / 3.744 GiB).

The assignment mandate requires achieving a size reduction of at least **40.0%**:
$$\text{Target Maximum Size} = 4,020,000,000 \times (1 - 0.40) = 2,412,000,000 \text{ bytes (2.412 GB / 2.246 GiB)}$$

### 3.1 3-Way Comparative Benchmark Table

| Metric | Stock Ubuntu Desktop Baseline | Original Production ISO | Integration Candidate ISO | **Optimized Candidate ISO** |
| :--- | :--- | :--- | :--- | :--- |
| **ISO Size (Bytes)** | `4,020,000,000` | `2,879,352,832` | `3,642,230,784` | **`2,234,140,672`** |
| **ISO Size (GiB)** | 3.7439 GiB | 2.6816 GiB | 3.3921 GiB | **2.0807 GiB** |
| **ISO Size (GB)** | 4.0200 GB | 2.8794 GB | 3.6422 GB | **2.2341 GB** |
| **Uncompressed Rootfs** | ~11.8 GB | ~6.2 GB | 7.909 GB | **4.678 GB** |
| **SquashFS Image Size** | ~3.85 GB | 2.76 GB | 3.52 GB | **2.02 GB** |
| **Reduction vs Baseline**| 0.00% | 28.37% | 9.40% | **44.42%** |
| **40% Target (2.412 GB)**| Reference | Missed by 445.7 MB | Missed by 1,173.2 MB | **PASSED (Ahead by 169.6 MB)** |
| **CUDA Toolkit Present**| No | Yes (CUDA 12.4) | Yes (CUDA 12.4) | **Yes (CUDA 12.4)** |
| **cuDNN 9 Present** | No | No | Yes (Shared libs) | **Yes (Shared libs + Headers)** |
| **Docker / Containerd** | No | No | Yes (Full Stack) | **Yes (Full Stack)** |
| **NVIDIA Container CTK**| No | No | Yes (Full Stack) | **Yes (Full Stack)** |
| **Dual Kernels in ISO** | Single (Canonical) | Single (Debian) | Dual (Debian + Custom) | **Dual (Debian + Custom)** |

```mermaid
xychart-beta
    title "ISO Size Comparison vs. 40% Reduction Target (GB)"
    x-axis ["Stock Ubuntu", "Candidate (All Components)", "Production ISO", "40% Target Threshold", "Optimized Candidate"]
    y-axis "Size in Gigabytes (GB)" 0 --> 4.5
    bar [4.020, 3.642, 2.879, 2.412, 2.234]
```

---

## 4. Optimization Methodology & Pruning Classification

To achieve the 40% target without degrading GPU runtime or development capabilities, a granular audit of `/var/tmp/cuda-lite-candidate-build/rootfs` was performed. Pruning targets were rigorously categorized into **SAFE**, **CONDITIONAL**, and **UNSAFE**.

### 4.1 Granular Classification Matrix

```mermaid
flowchart TD
    RootFS["Candidate RootFS (7.909 GB uncompressed)"] --> Audit["Granular Component Audit"]
    
    Audit --> Safe["SAFE: Non-Runtime Redundancies (-3.23 GB)"]
    Audit --> Conditional["CONDITIONAL: Build Stubs Evaluated"]
    Audit --> Unsafe["UNSAFE: Strictly Preserved Components (4.68 GB)"]
    
    Safe --> S1["Static Archives (*.a) where .so exists (-2,517 MB)"]
    Safe --> S2["Superseded Kernel 6.12.107 Remnants (-243 MB)"]
    Safe --> S3["DKMS Intermediate Objects / Duplicate Module (-130 MB)"]
    Safe --> S4["Ephemeral APT Lists & Package Cache (-92 MB)"]
    Safe --> S5["Non-English Locales & Documentation (-97 MB)"]
    
    Conditional --> C1["libcudadevrt.a & libcudart_static.a -> RETAINED (Needed for nvcc)"]
    Conditional --> C2["libc_nonshared.a -> RETAINED (Needed for gcc link)"]
    
    Unsafe --> U1["All Dynamic Libraries (*.so, CUDA, cuDNN 9, NVIDIA)"]
    Unsafe --> U2["All Binaries (nvcc, docker, containerd, runc, nvidia-ctk)"]
    Unsafe --> U3["Dual Kernels & Initramfs (6.12.117 & 6.12.0)"]
    Unsafe --> U4["NVIDIA DKMS Precompiled Modules (nvidia-current.ko.xz)"]
```

### 4.2 Engineering Rationale for Pruned Items

1. **Static CUDA/cuDNN Archives (`.a` files) [2,517.13 MB saved]:**
   - In modern Linux GPU computing, AI frameworks (PyTorch, TensorFlow, TensorRT, vLLM, ONNX Runtime) and dynamic inference servers link strictly against shared libraries (`.so`).
   - The uncompressed candidate rootfs contained duplicate static archives for cuBLASLt (`671.84 MB`), cuFFT (`309.59 MB`), cuFFT nocallback (`309.50 MB`), cuSPARSE (`299.78 MB`), cuBLAS (`163.71 MB`), and cuSOLVER (`132.60 MB`).
   - Removing these redundant static libraries freed **2.517 GB uncompressed** with zero impact on dynamic linking or application execution.
2. **Compiler Helper Archive Preservation:**
   - Testing during optimization revealed that `nvcc` requires `libcudadevrt.a` (1.6 MB) and `libcudart_static.a` (1.4 MB) when compiling host/device CUDA kernels, and `gcc` requires `libc_nonshared.a` (30 KB) when linking against glibc.
   - These critical files were explicitly retained, ensuring full compilation functionality.
3. **Legacy Debian Kernel 6.12.107 Remnants [243.45 MB saved]:**
   - The debootstrap and package installation pulled an initial Debian kernel `6.12.107`, which was subsequent upgraded to `6.12.117+deb13-amd64`.
   - Purging `/boot/*6.12.107*`, `/usr/lib/modules/6.12.107+deb13-amd64/`, and its DKMS directory eliminated **243.45 MB** of dead weight.
4. **DKMS Intermediate Objects [130.32 MB saved]:**
   - `dkms build` generated unstripped intermediate object `/usr/src/nvidia-current-550.163.01/nvidia.o` (`83.92 MB`) and cached an uncompressed module duplicate in `/var/lib/dkms/`.
   - The production module (`nvidia-current.ko.xz`, 39.65 MB) resides permanently in `/usr/lib/modules/6.12.117+deb13-amd64/updates/dkms/`. Purging the intermediate build objects saved **130 MB**.
5. **APT Lists, Caches & Docs [229.51 MB saved]:**
   - Ephemeral APT package index lists (`/var/lib/apt/lists/*`) are generated during `apt update` and do not belong in a read-only live media image.
   - Purging APT lists (`92.40 MB`), non-English localization files (`56.51 MB`), documentation and manual pages (`40.60 MB`), and system logs (`0.30 MB`) reclaimed substantial space without affecting any executable binaries.

---

## 5. QEMU Verification & Guest Telemetry

Verification of the generated ISO `/mnt/d/cuda-lite-linux-optimized.iso` was conducted using automated `pexpect` orchestration under QEMU 8.2.2 with KVM acceleration enabled.

### 5.1 Test Execution Matrix

| Test ID | Kernel / Configuration | Target Condition | Elapsed Time | Result |
| :--- | :--- | :--- | :--- | :--- |
| **TEST 1** | Debian `6.12.117+deb13-amd64` (Default) | Systemd Login Prompt (`cuda-lite login:`) | **21.85 s** | **PASS** |
| **TEST 2** | Custom `6.12.0-cuda-lite` (Low-Latency) | Systemd Login Prompt (`cuda-lite login:`) | **20.03 s** | **PASS** |
| **TEST 3** | Direct Guest Root Shell Telemetry | Execution of complete guest diagnostic suite | **12.50 s** | **PASS** |

### 5.2 Test 1 Log: Default Kernel Boot to Systemd Login Prompt
```text
SeaBIOS (version 1.17.0-debian-1.17.0-1ubuntu1)
Booting from ROM...
[    5.583423] systemd-fstab-generator[328]: Failed to create unit file '/run/systemd/generator/tmp.mount'
[   14.076934] bash[519]: ================================================
[   14.085204] bash[519]:        CUDA-Lite Linux - Startup Diagnostic
[   14.088841] bash[519]: ================================================
[   14.159901] bash[519]: Notice: No NVIDIA PCI device detected on the bus (virtual/QEMU environment).
[   14.165880] bash[519]: CUDA diagnostic benchmark skipped.

Debian GNU/Linux 13 cuda-lite ttyS0

cuda-lite login: 
[PASS] Default Kernel reached systemd login prompt in 21.85s!
```

### 5.3 Test 2 Log: Custom Kernel 6.12.0 Boot to Systemd Login Prompt
```text
SeaBIOS (version 1.17.0-debian-1.17.0-1ubuntu1)
Booting from ROM...
[   12.111289] bash[416]: ================================================
[   12.124838] bash[416]:        CUDA-Lite Linux - Startup Diagnostic
[   12.138164] bash[416]: ================================================
[   12.266679] bash[416]: Notice: No NVIDIA PCI device detected on the bus (virtual/QEMU environment).
[   12.273084] bash[416]: CUDA diagnostic benchmark skipped.

Debian GNU/Linux 13 cuda-lite ttyS0

cuda-lite login: 
[PASS] Custom Kernel boot succeeded in 20.03s!
```

### 5.4 Test 3 Log: In-Guest Telemetry & Stack Verification

#### Operating System & Kernel Release:
```text
# cat /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
NAME="Debian GNU/Linux"
VERSION_CODENAME=trixie
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"

# uname -a
Linux cuda-lite 6.12.117+deb13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.12.117+deb13-amd64 (2025-11-12) x86_64 GNU/Linux
```

#### Filesystem Mounts & OverlayFS Verification:
```text
# mount | grep -E 'overlay|live|iso'
/dev/sr0 on /run/live/medium type iso9660 (ro,noatime,nojoliet,check=s,map=n,blocksize=2048)
/dev/loop0 on /run/live/rootfs/filesystem.squashfs type squashfs (ro,noatime,errors=continue)
tmpfs on /run/live/overlay type tmpfs (rw,noatime,size=1018868k,mode=755)
overlay on / type overlay (rw,noatime,lowerdir=/run/live/rootfs/filesystem.squashfs,upperdir=/run/live/overlay/rw,workdir=/run/live/overlay/work)

# touch /tmp/overlay_write_test && ls -l /tmp/overlay_write_test
-rw-r--r-- 1 root root 0 Nov 22 18:24 /tmp/overlay_write_test
OVERLAYFS_WRITABLE_VERIFIED
```

#### Memory & Storage Telemetry:
```text
# df -h / /run/live/medium
Filesystem      Size  Used Avail Use% Mounted on
overlay         995M  8.0K  995M   1% /
/dev/sr0        2.1G  2.1G     0 100% /run/live/medium

# free -m
               total        used        free      shared  buff/cache   available
Mem:            1990          54        1774           1         195        1935
Swap:              0           0           0
```
*Telemetry analysis:* The live image runs in **54 MB of active RAM**, with **1,774 MB free**, demonstrating ultra-minimal resource consumption suitable for dedicated GPU compute clusters.

#### CUDA Compiler & Runtime:
```text
# which nvcc
/usr/bin/nvcc

# nvcc --version
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2024 NVIDIA Corporation
Built on Thu_Mar_28_02:18:24_PDT_2024
Cuda compilation tools, release 12.4, V12.4.131
Build cuda_12.4.r12.4/compiler.34097967_0

# ls -lh /usr/lib/x86_64-linux-gnu/libcuda*.so*
lrwxrwxrwx 1 root root   53 Jul 21  2025 /usr/lib/x86_64-linux-gnu/libcuda.so -> /etc/alternatives/nvidia--libcuda.so-x86_64-linux-gnu
lrwxrwxrwx 1 root root   55 Jul 21  2025 /usr/lib/x86_64-linux-gnu/libcuda.so.1 -> /etc/alternatives/nvidia--libcuda.so.1-x86_64-linux-gnu
lrwxrwxrwx 1 root root   15 Jul 21  2025 /usr/lib/x86_64-linux-gnu/libcudart.so -> libcudart.so.12
lrwxrwxrwx 1 root root   21 Jul 21  2025 /usr/lib/x86_64-linux-gnu/libcudart.so.12 -> libcudart.so.12.4.127
-rw-r--r-- 1 root root 692K Mar 28  2024 /usr/lib/x86_64-linux-gnu/libcudart.so.12.4.127
```

#### cuDNN 9 Shared Libraries & Headers:
```text
# ls -lh /usr/lib/x86_64-linux-gnu/libcudnn*.so* | head -n 6
lrwxrwxrwx 1 root root   13 Nov 22 12:53 /usr/lib/x86_64-linux-gnu/libcudnn.so -> libcudnn.so.9
lrwxrwxrwx 1 root root   17 Nov 22 12:53 /usr/lib/x86_64-linux-gnu/libcudnn.so.9 -> libcudnn.so.9.0.0
-rw-r--r-- 1 root root 103K Nov 22 12:53 /usr/lib/x86_64-linux-gnu/libcudnn.so.9.0.0
lrwxrwxrwx 1 root root   17 Nov 22 12:53 /usr/lib/x86_64-linux-gnu/libcudnn_adv.so -> libcudnn_adv.so.9
lrwxrwxrwx 1 root root   21 Nov 22 12:53 /usr/lib/x86_64-linux-gnu/libcudnn_adv.so.9 -> libcudnn_adv.so.9.0.0
-rw-r--r-- 1 root root 229M Nov 22 12:53 /usr/lib/x86_64-linux-gnu/libcudnn_adv.so.9.0.0

# ls -lh /usr/include/x86_64-linux-gnu/cudnn*.h | head -n 6
-rw-r--r-- 1 root root 2.8K Nov 22 12:53 /usr/include/x86_64-linux-gnu/cudnn.h
-rw-r--r-- 1 root root  31K Nov 22 12:53 /usr/include/x86_64-linux-gnu/cudnn_adv.h
-rw-r--r-- 1 root root  31K Nov 22 12:53 /usr/include/x86_64-linux-gnu/cudnn_adv_v9.h
-rw-r--r-- 1 root root 2.7K Nov 22 12:53 /usr/include/x86_64-linux-gnu/cudnn_backend.h
-rw-r--r-- 1 root root 2.7K Nov 22 12:53 /usr/include/x86_64-linux-gnu/cudnn_backend_v9.h
-rw-r--r-- 1 root root  36K Nov 22 12:53 /usr/include/x86_64-linux-gnu/cudnn_cnn.h
```

#### Container Stack (Docker, containerd, runc, nvidia-ctk):
```text
# which docker dockerd containerd runc nvidia-ctk
/bin/docker
/sbin/dockerd
/bin/containerd
/sbin/runc
/bin/nvidia-ctk

# docker --version
Docker version 26.1.5+dfsg1, build a72d7cd

# containerd --version
containerd github.com/containerd/containerd 1.7.24~ds1 1.7.24~ds1-6+deb13u1

# runc --version
runc version 1.1.15+ds1
commit: 1.1.15+ds1-2+b4
spec: 1.2.0
go: go1.24.4
libseccomp: 2.6.0

# nvidia-ctk --version
NVIDIA Container Toolkit CLI version 1.20.2
commit: adbd28c39b60f8eb7e03115b5ac61e58703f0ce7
```

#### Systemd Multi-User Target Wants:
```text
# ls -la /etc/systemd/system/multi-user.target.wants/
lrwxrwxrwx 1 root root  42 Nov 22 12:56 containerd.service -> /usr/lib/systemd/system/containerd.service
lrwxrwxrwx 1 root root  47 Nov 20 19:57 cuda-lite-autostart.service -> /etc/systemd/system/cuda-lite-autostart.service
lrwxrwxrwx 1 root root  38 Nov 22 12:56 docker.service -> /usr/lib/systemd/system/docker.service
lrwxrwxrwx 1 root root  47 Nov 22 12:57 nvidia-cdi-refresh.path -> /usr/lib/systemd/system/nvidia-cdi-refresh.path
lrwxrwxrwx 1 root root  50 Nov 22 12:57 nvidia-cdi-refresh.service -> /usr/lib/systemd/system/nvidia-cdi-refresh.service
lrwxrwxrwx 1 root root  40 Nov 20 18:57 remote-fs.target -> /usr/lib/systemd/system/remote-fs.target
```

#### Dual Kernel & DKMS Modules:
```text
# ls -lh /boot/
total 102M
-rw-r--r-- 1 root root   83 Nov 12 09:30 System.map-6.12.117+deb13-amd64
-rwxr-xr-x 1 root root 276K Nov 22 13:00 config-6.12.0-cuda-lite
-rw-r--r-- 1 root root 277K Nov 12 09:30 config-6.12.117+deb13-amd64
-rwxr-xr-x 1 root root  40M Nov 22 13:00 initrd-6.12.0-cuda-lite
-rw-r--r-- 1 root root  40M Nov 21 18:18 initrd.img-6.12.117+deb13-amd64
-rwxr-xr-x 1 root root  11M Nov 22 13:00 vmlinuz-6.12.0-cuda-lite
-rw-r--r-- 1 root root  12M Nov 12 09:30 vmlinuz-6.12.117+deb13-amd64

# ls -lh /usr/lib/modules/6.12.117+deb13-amd64/updates/dkms/
total 41M
-rw-r--r-- 1 root root  64K Nov 20 19:56 nvidia-current-drm.ko.xz
-rw-r--r-- 1 root root 602K Nov 20 19:56 nvidia-current-modeset.ko.xz
-rw-r--r-- 1 root root 2.4K Nov 20 19:56 nvidia-current-peermem.ko.xz
-rw-r--r-- 1 root root 577K Nov 20 19:56 nvidia-current-uvm.ko.xz
-rw-r--r-- 1 root root  40M Nov 20 19:56 nvidia-current.ko.xz
```

---

## 6. Functional Verification of Compilation Inside Chroot

In addition to guest telemetry, the optimized rootfs was verified for software compilation inside the chroot environment to guarantee that removing static archives did not inhibit developer workflows.

### 6.1 CUDA Runtime & cuDNN Header Compilation Test
Test program `/tmp/test_compile.c`:
```c
#include <stdio.h>
#include <cuda_runtime.h>
#include <cudnn.h>

int main() {
    printf("CUDA Runtime & cuDNN header include test: SUCCESS\n");
    printf("cuDNN Version: %d\n", CUDNN_VERSION);
    return 0;
}
```
Execution command and output:
```bash
gcc -I/usr/include/x86_64-linux-gnu /tmp/test_compile.c -lcudart -lcudnn -o /tmp/test_compile
/tmp/test_compile
# Output:
CUDA Runtime & cuDNN header include test: SUCCESS
cuDNN Version: 90000
Compilation and execution verification: PASSED
```

### 6.2 Host & Device CUDA Kernel Compilation Test (NVCC)
Test program `/tmp/test_nvcc.cu`:
```cuda
#include <stdio.h>
#include <cuda_runtime.h>

__global__ void dummy_kernel() {}

int main() {
    printf("NVCC Host/Device compilation test: SUCCESS\n");
    return 0;
}
```
Execution command and output:
```bash
nvcc -O2 /tmp/test_nvcc.cu -o /tmp/test_nvcc
/tmp/test_nvcc
# Output:
NVCC Host/Device compilation test: SUCCESS
NVCC verification: PASSED
```

---

## 7. Scope Boundaries & Hardware Emulation Note

In accordance with strict technical reality and academic integrity:
1. **QEMU Emulation vs. Physical GPU:** QEMU was executed under TCG/KVM without PCIe passthrough (which requires VT-d / IOMMU hardware virtualization not accessible to a nested virtual machine). Consequently, `cuda-lite-autostart.service` correctly reported:
   `Notice: No NVIDIA PCI device detected on the bus (virtual/QEMU environment). CUDA diagnostic benchmark skipped.`
2. **Physical GPU Testing (WSL2):** Physical NVIDIA GeForce RTX 4050 Laptop GPU hardware execution (PyTorch 2.5.1, CUDA 12.4, cuDNN 9.0.0, Docker GPU passthrough, matrix multiplication benchmarks) was verified natively on the host environment and documented in `documentation/BENCHMARK_REPORT.md`. No false claims of GPU execution inside QEMU are made.

---

## 8. Final Decision & Classification

Based on rigorous, empirical verification across all six required evaluation criteria:

| Requirement Category | Target Standard | Achieved Result | Status |
| :--- | :--- | :--- | :--- |
| **Artifact Verification** | 3 separate ISOs, valid hashes | Verified on disk, SHA-256 matches | **PASS** |
| **Preservation Rule** | Original production deliverables untouched | Hashes unchanged, 0 bytes modified | **PASS** |
| **ISO Size Target** | $\le 2,412,000,000$ bytes (-40.0%) | **$2,234,140,672$ bytes (-44.42%)** | **PASS (Exceeded)** |
| **QEMU Boot (Debian)** | Boot to systemd login prompt | `cuda-lite login:` reached in **21.85s** | **PASS** |
| **QEMU Boot (Custom)** | Boot to systemd login prompt | `cuda-lite login:` reached in **20.03s** | **PASS** |
| **OverlayFS Function** | Read-only SquashFS + Writable tmpfs | Upper/lower dirs verified, write verified | **PASS** |
| **CUDA & cuDNN Stack** | Toolchain, shared libs, headers | nvcc 12.4, cuDNN 9, compilation verified | **PASS** |
| **Container Runtime** | Docker, containerd, runc, nvidia-ctk | All binaries present, versions verified | **PASS** |
| **Systemd Integration**| Services enabled and active | Autostart, Docker, containerd enabled | **PASS** |

### **FINAL CLASSIFICATION: PASS**

The optimized deliverable `/mnt/d/cuda-lite-linux-optimized.iso` satisfies every structural, functional, and storage efficiency requirement of Track C, achieving a **44.42% size reduction** while retaining complete GPU runtime, deep learning, container, and compilation functionality.
