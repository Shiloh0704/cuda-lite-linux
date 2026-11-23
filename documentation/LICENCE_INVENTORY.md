# CUDA-Lite Linux Distribution — Software License & Redistribution Inventory

**Project Track:** Track C: Application-Specific Linux Distribution for NVIDIA CUDA/GPU Computing  
**Base Distribution:** Debian 13 (Trixie) amd64 (`13.7`)  
**Target Hardware:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89)  
**Total Installed Packages:** 267 packages  
**Date of Audit:** 2026-11-22  

---

## 1. Executive Summary

CUDA-Lite Linux bundles a curated set of open-source and proprietary software components required for autonomous GPU computing. This document provides a complete audit of all software licenses, redistribution permissions, and legal compliance structures across the entire operating system stack.

The distribution strictly adheres to:
1. **Debian Free Software Guidelines (DFSG)** for all base userland and system components.
2. **GNU General Public License (GPL v2 and v3)** for the Linux kernel, initramfs tools, and GNU core utilities.
3. **GNU Lesser General Public License (LGPL v2.1+)** for the GNU C Library (`glibc`), `systemd`, and `dbus`.
4. **NVIDIA Software License Agreement for Compute Products & Driver EULA** for driver kernel modules and firmware.
5. **NVIDIA CUDA Toolkit EULA (Section 2.1)** for redistributable runtime libraries (`libcuda.so.1`, `libcudart.so.12`, `libcublas.so.12`).
6. **MIT License** for custom benchmark software (`cuda/matrix_mul.cu`, `cuda/device_query.cu`) and startup diagnostics.

---

## 2. Core Licensing Hierarchy

| Component / Layer | License Type | Classification | Redistribution Conditions & Permissibility | Rationale for Inclusion |
| :--- | :--- | :--- | :--- | :--- |
| **Linux Kernel (`vmlinuz-6.12.117+deb13-amd64`)** | GPL-2.0-only | Open Source | Freely redistributable with full source code availability. Matching `.config` provided in `kernel/`. | Monolithic OS kernel managing PCIe, DMA, and scheduling. |
| **GNU C Library (`libc6` 2.40)** | LGPL-2.1-or-later | Open Source | Binary redistribution permitted with dynamic linking. Full source available from Debian upstream. | Fundamental POSIX C runtime required by all binaries. |
| **systemd & udev (v257.3-1)** | LGPL-2.1-or-later | Open Source | Binary redistribution permitted under standard LGPL terms. | Init process (PID 1), hardware udev dynamic module loading, systemd services. |
| **D-Bus System Bus (`dbus` 1.16.2)** | AFL-2.1 / GPL-2.0+ dual | Open Source | Freely redistributable. | IPC mechanism required for systemd-logind and system services. |
| **Live-Boot & Live-Tools** | GPL-3.0-or-later | Open Source | Freely redistributable with source code. | Boot-time discovery of live ISO media and OverlayFS mounting. |
| **SquashFS Tools & Decompressor** | GPL-2.0-or-later | Open Source | Freely redistributable. | Read-only XZ-compressed root filesystem. |
| **GNU GRUB 2.14** | GPL-3.0-or-later | Open Source | Freely redistributable. | BIOS and UEFI bootloader stages. |
| **CUDA-Lite Benchmark Suite** | MIT License | Open Source | Permissive open-source license. Author: OS Project Team. | Verification of RTX 4050 compute and matrix multiplication. |
| **NVIDIA Display Driver (`nvidia-kernel-dkms` 550.163.01)** | Proprietary / NVIDIA EULA | Proprietary | Binary redistribution permitted in unaltered OS/container images. Modern Turing/Ada open GPU kernel modules (`nvidia-open`) are dual MIT/GPLv2. | Direct PCIe hardware driver for NVIDIA RTX 4050 GPU. |
| **NVIDIA GSP Firmware (`firmware-nvidia-gsp` 550.163.01)** | NVIDIA Binary Firmware License | Proprietary Firmware | Redistribution permitted without modification alongside compatible driver. Packaged via Debian `non-free-firmware`. | Microcode for Ada Lovelace GPU System Processor (GSP). |
| **NVIDIA CUDA Toolkit Runtime (`libcudart12`, `libcuda1`)** | NVIDIA CUDA EULA | Proprietary Runtime | Section 2.1 explicitly authorizes royalty-free redistribution of runtime shared libraries (`libcudart.so`, `libcublas.so`). | CUDA execution runtime, memory allocation, and kernel launch. |
| **NVIDIA cuBLAS Library (`libcublas12`)** | NVIDIA CUDA EULA | Proprietary Library | Redistributable under NVIDIA CUDA EULA Section 2.1. | High-performance dense linear algebra acceleration. |

---

## 3. Package Classification Breakdown (267 Packages)

```
┌────────────────────────────────────────────────────────┐
│         Total Installed Packages: 267                  │
├───────────────────────────┬────────────────────────────┤
│   Open-Source Packages    │    Proprietary Packages    │
│       246 (92.1%)         │         21 (7.9%)          │
│   GPL, LGPL, BSD, MIT     │   NVIDIA Driver & CUDA     │
└───────────────────────────┴────────────────────────────┘
```

### Detailed Distribution by Category:

1. **Base Operating System & Coreutilities (148 packages)**:
   - Licenses: GPL-2.0+, GPL-3.0+, LGPL-2.1+, BSD-3-Clause.
   - Examples: `bash`, `coreutils`, `dpkg`, `grep`, `sed`, `login`, `mount`, `util-linux`, `iproute2`.
   - Compliance: 100% DFSG-compliant; source available via Debian mirrors.

2. **Kernel & Device Infrastructure (26 packages)**:
   - Licenses: GPL-2.0-only, LGPL-2.1+.
   - Examples: `linux-image-6.12.117+deb13-amd64`, `linux-headers-6.12.117+deb13-amd64`, `kmod`, `udev`, `pciutils`.
   - Compliance: Exact kernel configuration is tracked in `kernel/config-6.12.117+deb13-amd64`.

3. **Live Media & Storage Subsystem (18 packages)**:
   - Licenses: GPL-2.0+, GPL-3.0+.
   - Examples: `live-boot`, `live-boot-initramfs-tools`, `squashfs-tools`, `e2fsprogs`.
   - Compliance: Standard Debian live packaging.

4. **NVIDIA Driver & Hardware Firmware (12 packages)**:
   - Licenses: NVIDIA Driver EULA / NVIDIA Binary Firmware License.
   - Examples: `firmware-nvidia-gsp`, `nvidia-kernel-dkms`, `nvidia-smi`, `nvidia-modprobe`, `glx-alternative-nvidia`.
   - Compliance: Distributed via Debian `non-free` and `non-free-firmware` archives.

5. **CUDA Compute & Toolchain Stack (9 packages)**:
   - Licenses: NVIDIA CUDA Toolkit EULA.
   - Examples: `nvidia-cuda-toolkit`, `nvidia-cuda-dev`, `libcudart12`, `libcublas12`, `libnvidia-ml1`.
   - Compliance: Unaltered redistribution conforming to Section 2.1 of the CUDA Toolkit EULA.

6. **Custom Application Code (Project Created)**:
   - License: MIT License.
   - Files: `cuda/matrix_mul.cu`, `cuda/device_query.cu`, `system/cuda-lite-startup.sh`, `system/99-nvidia.rules`.
   - Compliance: Permissive open source.

---

## 4. Architectural & Redistribution Guarantees

1. **No License Contamination**:
   - The Linux kernel remains strictly GPL-2.0. The proprietary NVIDIA driver communicates via the open DKMS wrapper (`nvidia-kernel-dkms`), using documented kernel APIs without modifying kernel source code.
2. **GSP Firmware Compliance**:
   - Ada Lovelace GPUs require the GSP firmware image `gsp_ga10x.bin`. This binary is isolated in `/lib/firmware/nvidia/550.163.01/` under the Debian `non-free-firmware` archive.
3. **Clean Attribution**:
   - Complete package-by-package inventory with installed sizes and licensing categories is cataloged in [`documentation/PACKAGE_MANIFEST.csv`](file:///c:/Users/shilo/OneDrive/OS_Project/documentation/PACKAGE_MANIFEST.csv).
