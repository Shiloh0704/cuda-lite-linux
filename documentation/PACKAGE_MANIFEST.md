# CUDA-Lite Linux Distribution (Track C)
# Comprehensive Software Package Manifest

**Date:** November 22, 2026  
**Target Architecture:** x86-64 / AMD64  
**Target Operating System:** Debian 13 (Trixie) GNU/Linux  
**Target Hardware:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute Capability 8.9)  
**Total Installed Packages:** 441  

---

## 1. Overview & Classification Schema
This manifest documents the complete inventory of software packages, system libraries, development runtimes, and proprietary drivers composing the **CUDA-Lite Linux Distribution**.

Each component is categorized by:
- **Package Name & Version:** Exact Debian/upstream package identifier.
- **Architectural Purpose:** Role within the minimal compute node distribution.
- **Classification:** Open Source (FOSS) vs. Proprietary.
- **License:** Exact software license identifier (e.g. GPL-2.0, LGPL-2.1, MIT, NVIDIA EULA).
- **Criticality:** Essential (Required for boot/compute) vs. Optional (Utility/Diagnostic).

---

## 2. Core Operating System & Boot Infrastructure

| Package Name | Installed Version | Architectural Purpose | Classification | License | Criticality |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **linux-image-6.12.117+deb13-amd64** | 6.12.117-1 | Deployed monolithic Linux kernel image (`vmlinuz`) | FOSS | GPL-2.0-only | **Essential** |
| **linux-headers-6.12.117+deb13-amd64** | 6.12.117-1 | Kernel C headers for out-of-tree DKMS module builds | FOSS | GPL-2.0-only | **Essential** |
| **systemd** | 257.13-1~deb13u1 | System and service manager (PID 1) | FOSS | LGPL-2.1-or-later | **Essential** |
| **systemd-sysv** | 257.13-1~deb13u1 | SysV init compatibility shims | FOSS | LGPL-2.1-or-later | **Essential** |
| **udev** | 257.13-1~deb13u1 | Dynamic device node manager (`/dev/nvidia*`) | FOSS | LGPL-2.1-or-later | **Essential** |
| **dbus** | 1.16.2-1 | D-Bus system message bus daemon | FOSS | AFL-2.1 / GPL-2.0+ | **Essential** |
| **dbus-bin** | 1.16.2-1 | D-Bus message bus binary utilities | FOSS | AFL-2.1 / GPL-2.0+ | **Essential** |
| **dbus-daemon** | 1.16.2-1 | D-Bus system daemon executable | FOSS | AFL-2.1 / GPL-2.0+ | **Essential** |
| **live-boot** | 1:20240810 | Live system bootloader scripts (OverlayFS mount) | FOSS | GPL-3.0-or-later | **Essential** |
| **live-boot-initramfs-tools** | 1:20240810 | Initramfs hooks for discovery of live media | FOSS | GPL-3.0-or-later | **Essential** |
| **initramfs-tools** | 0.145 | Generic modular initramfs generator | FOSS | GPL-2.0-only | **Essential** |
| **grub-pc-bin** | 2.14-2 | GRUB 2 BIOS bootloader binaries | FOSS | GPL-3.0-or-later | **Essential** |
| **grub-efi-amd64-bin** | 2.14-2 | GRUB 2 UEFI 64-bit bootloader binaries | FOSS | GPL-3.0-or-later | **Essential** |
| **squashfs-tools** | 1:4.6.1-1 | SquashFS filesystem compression tool (`mksquashfs`)| FOSS | GPL-2.0-or-later | **Essential** |
| **xorriso** | 1.5.6-1.1 | ISO 9660 Rock Ridge / El Torito filesystem generator| FOSS | GPL-3.0-or-later | **Essential** |

---

## 3. Minimal Base Userland & System Libraries

| Package Name | Installed Version | Architectural Purpose | Classification | License | Criticality |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **libc6** | 2.41-1 | GNU C Library (glibc core shared libraries) | FOSS | LGPL-2.1-or-later | **Essential** |
| **libc-bin** | 2.41-1 | GNU C Library binary helpers (`ldconfig`, `iconv`) | FOSS | LGPL-2.1-or-later | **Essential** |
| **libstdc++6** | 14.2.0-19 | GNU Standard C++ Library v3 | FOSS | GPL-3.0-with-GCC-exception | **Essential** |
| **libgcc-s1** | 14.2.0-19 | GCC low-level runtime library | FOSS | GPL-3.0-with-GCC-exception | **Essential** |
| **bash** | 5.2.37-1 | GNU Bourne Again SHell | FOSS | GPL-3.0-or-later | **Essential** |
| **coreutils** | 9.5-1 | Core GNU utilities (file, text, shell utilities) | FOSS | GPL-3.0-or-later | **Essential** |
| **util-linux** | 2.40.4-1 | Miscellaneous system utilities (`mount`, `fdisk`) | FOSS | GPL-2.0-or-later | **Essential** |
| **kmod** | 33+20240816-2 | Linux kernel module management (`modprobe`, `lsmod`)| FOSS | LGPL-2.1-or-later | **Essential** |
| **pciutils** | 1:3.13.0-1 | PCI bus inspection utilities (`lspci`) | FOSS | GPL-2.0-or-later | **Essential** |
| **sudo** | 1.9.16p2-1 | Restricted privilege escalation management | FOSS | ISC / BSD-style | **Essential** |
| **ca-certificates** | 20241223 | Common Certificate Authorities for TLS | FOSS | MPL-2.0 / GPL-2.0+ | **Essential** |

---

## 4. NVIDIA GPU Driver & Kernel Module Stack

| Package Name | Installed Version | Architectural Purpose | Classification | License | Criticality |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **nvidia-kernel-dkms** | 550.163.01-1 | NVIDIA kernel module source for dynamic DKMS build | Proprietary | NVIDIA Driver EULA | **Essential** |
| **nvidia-driver** | 550.163.01-1 | NVIDIA metapackage for X11/GLX/Compute drivers | Proprietary | NVIDIA Driver EULA | **Essential** |
| **nvidia-smi** | 550.163.01-1 | NVIDIA System Management Interface utility | Proprietary | NVIDIA Driver EULA | **Essential** |
| **firmware-nvidia-gsp** | 550.163.01-1 | GPU System Processor firmware binary for Ada Lovelace| Proprietary | NVIDIA Firmware License | **Essential** |
| **libnvidia-compute** | 550.163.01-1 | NVIDIA CUDA driver runtime library (`libcuda.so.1`)| Proprietary | NVIDIA Driver EULA | **Essential** |
| **libcuda1** | 550.163.01-1 | NVIDIA CUDA driver library transition package | Proprietary | NVIDIA Driver EULA | **Essential** |
| **dkms** | 3.1.4-1 | Dynamic Kernel Module Support framework | FOSS | GPL-2.0-or-later | **Essential** |

---

## 5. NVIDIA CUDA Toolkit & Acceleration Libraries

| Package Name | Installed Version | Architectural Purpose | Classification | License | Criticality |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **nvidia-cuda-toolkit** | 12.4.131~12.4.1-8 | NVIDIA CUDA development toolkit metapackage | Proprietary / FOSS | NVIDIA CUDA EULA | **Essential** |
| **nvidia-cuda-dev** | 12.4.127~12.4.1-8 | NVIDIA CUDA compiler headers and static runtimes | Proprietary | NVIDIA CUDA EULA | **Essential** |
| **libcudart12** | 12.4.127~12.4.1-8 | NVIDIA CUDA Runtime shared library | Proprietary | NVIDIA CUDA EULA | **Essential** |
| **libcublas12** | 12.4.5.8~12.4.1-8 | NVIDIA Basic Linear Algebra Subprograms library | Proprietary | NVIDIA cuBLAS EULA | **Essential** |
| **libcublaslt12** | 12.4.5.8~12.4.1-8 | NVIDIA cuBLASLt lightweight matrix library | Proprietary | NVIDIA cuBLAS EULA | **Essential** |
| **libcufft11** | 11.2.1.38~12.4.1-8 | NVIDIA Fast Fourier Transform runtime library | Proprietary | NVIDIA cuFFT EULA | **Essential** |
| **libcurand10** | 10.3.5.147~12.4.1-8 | NVIDIA Random Number Generation runtime library | Proprietary | NVIDIA cuRAND EULA | **Essential** |
| **libcusolver11** | 11.6.1.9~12.4.1-8 | NVIDIA Dense and Sparse Direct Linear Solvers | Proprietary | NVIDIA cuSOLVER EULA| **Essential** |
| **libcusparse12** | 12.3.1.170~12.4.1-8 | NVIDIA Sparse Matrix Operations library | Proprietary | NVIDIA cuSPARSE EULA| **Essential** |
| **libcudnn9-cuda-12** | 9.1.0.70-1 | NVIDIA cuDNN runtime library (`libcudnn.so.9`) | Proprietary | NVIDIA cuDNN SLA | Optional / Staged |
| **libcudnn9-dev-cuda-12**| 9.1.0.70-1 | NVIDIA cuDNN C/C++ development headers | Proprietary | NVIDIA cuDNN SLA | Optional / Staged |

---

## 6. Container Runtime & Orchestration Support

| Package Name | Installed Version | Architectural Purpose | Classification | License | Criticality |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **containerd** | 1.7.25-1 | Industry-standard core container runtime daemon | FOSS | Apache-2.0 | Optional / Staged |
| **runc** | 1.1.12-1 | OCI universal container runtime binary CLI | FOSS | Apache-2.0 | Optional / Staged |
| **nvidia-container-toolkit**| 1.15.0-1 | NVIDIA Container CLI and CDI specification hook | FOSS / Proprietary | Apache-2.0 / NVIDIA EULA | Optional / Staged |
| **libnvidia-container1** | 1.15.0-1 | C library enabling GPU container isolation | FOSS | Apache-2.0 | Optional / Staged |

---

## 7. CUDA-Lite Application Layer

| Component Name | Source Location | Architectural Purpose | Classification | License | Criticality |
| :--- | :---: | :--- | :---: | :---: | :---: |
| **device_query** | `cuda/device_query.cu` | Interrogates RTX 4050 compute capability & SMs | Open Source | MIT License | **Essential** |
| **matrix_mul** | `cuda/matrix_mul.cu` | High-throughput FP32 tiled matrix multiplication | Open Source | MIT License | **Essential** |
| **cuda-lite-startup.sh** | `system/cuda-lite-startup.sh`| Hardware-aware GPU diagnostic & test launcher | Open Source | MIT License | **Essential** |
| **cuda-lite-autostart.service**| `system/cuda-lite-autostart.service`| systemd boot service managing automated startup| Open Source | MIT License | **Essential** |
| **99-nvidia.rules** | `system/99-nvidia.rules` | Dynamic udev rule creating `/dev/nvidia*` nodes | Open Source | MIT License | **Essential** |
