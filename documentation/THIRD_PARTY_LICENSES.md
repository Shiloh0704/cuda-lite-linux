# CUDA-Lite Linux Distribution: Third-Party Licenses & Software Inventory

**Audit Date:** November 22, 2026  
**Auditor:** Legal & Licensing Compliance Specialist

CUDA-Lite Linux incorporates both open-source software and proprietary vendor components. This document provides a complete license inventory ensuring compliance with Debian Free Software Guidelines (DFSG), GNU licenses, and NVIDIA End User License Agreements (EULA).

---

## 1. Open Source Components

| Software Component | Upstream Project / Author | License | Description / Terms |
| :--- | :--- | :--- | :--- |
| **Linux Kernel (Upstream 6.12)** | Linus Torvalds & Kernel Developers | GPL-2.0-only (with syscall exception) | Core operating system kernel |
| **Debian GNU/Linux Base** | Software in the Public Interest, Inc. | DFSG-compliant (GPL, LGPL, BSD, MIT) | Minimal system utilities, systemd, libc6 |
| **GRUB Bootloader (2.12)** | Free Software Foundation, Inc. | GPL-3.0-or-later | Multi-boot firmware bootloader |
| **SquashFS Tools & Kernel FS** | Phillip Lougher & Linux Developers | GPL-2.0-or-later | Read-only compressed filesystem |
| **Docker Engine & containerd** | Moby Project / Cloud Native Foundation | Apache-2.0 | Container execution engine |
| **runc** | Open Container Initiative (OCI) | Apache-2.0 | Low-level container runtime |

---

## 2. Proprietary NVIDIA Components

| Component | Package / Binary | License | Redistribution & Usage Terms |
| :--- | :--- | :--- | :--- |
| **NVIDIA Display Driver** | `nvidia-kernel-dkms` 550.163.01 | NVIDIA Software License Agreement / MIT-GPL dual | Kernel module source released under dual MIT/GPL; binary blobs governed by NVIDIA Driver EULA. Permitted for non-commercial redistribution with hardware drivers. |
| **NVIDIA GSP Firmware** | `firmware-nvidia-gsp` 550.163.01 | NVIDIA Firmware License Agreement | Redistributable firmware binary images required for GPU System Processor initialization. |
| **NVIDIA CUDA Toolkit 12.4** | `nvidia-cuda-toolkit` 12.4.131 | NVIDIA CUDA Toolkit EULA | Section 2.1 authorizes distribution of runtime libraries (`libcudart.so`, `libcublas.so`) with applications developed using the toolkit. |
| **NVIDIA cuDNN 9** | `nvidia-cudnn` 9.0.0.312 | NVIDIA cuDNN Software License Agreement | Section 2.1 authorizes distribution of cuDNN shared libraries in conjunction with compatible hardware and licensed applications. |
| **NVIDIA Container Toolkit** | `nvidia-container-toolkit` 1.20.2-1 | Apache-2.0 | Open-source wrapper toolkit; backend `libnvidia-container1` links to proprietary NVIDIA driver store. |
