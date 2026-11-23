# CUDA-Lite Linux: Software License & Redistribution Inventory
# Satisfies Assignment Requirement H (Licence list & redistribution restrictions).

This inventory catalogs the open-source and proprietary software components bundled or utilized in CUDA-Lite Linux, their corresponding licenses, redistribution rules, and justifications for inclusion.

| Component / Layer | License Type | Redistribution Conditions & Permissibility | Rationale for Inclusion |
| :--- | :--- | :--- | :--- |
| **Linux Kernel (`vmlinuz`)** | GPL-2.0-only | Free to redistribute with corresponding source code (`.config` and patches included). | Monolithic OS core managing memory, PCIe, and scheduling. |
| **GNU C Library (`glibc`)** | LGPL-2.1-or-later | Permitted for distribution in binary format with dynamic linking. | Standard C runtime required by all userland binaries. |
| **GNU Coreutils & Tools** | GPL-3.0-or-later | Permitted with source code availability. | Essential command-line userland (cat, cp, ls, etc.). |
| **systemd & udev** | LGPL-2.1-or-later | Permitted with standard dynamic linking terms. | Init process, device node creation (`/dev/nvidia*`), and service management. |
| **Live-Boot & Busybox** | GPL-2.0-only | Permitted with source code availability. | Bootloader ramdisk stage and SquashFS OverlayFS mounting. |
| **CUDA-Lite Benchmark Suite** | MIT License | Freely distributable, permissive open-source license. | Verification of RTX 4050 compute and matrix multiplication. |
| **NVIDIA Display Driver (`nvidia.ko`)** | Proprietary / NVIDIA EULA | Binary redistribution allowed in non-modified container/OS images under NVIDIA Software License Agreement for Compute Products, provided no reverse engineering occurs. Packaged in Debian non-free as `nvidia-kernel-dkms` alongside redistributable open GSP firmware (`firmware-nvidia-gsp`). Note: NVIDIA's Open GPU Kernel Modules (`nvidia-open`) are dual MIT/GPLv2 for Turing+ GPUs (including RTX 4050 Ada Lovelace). | Required for direct PCIe communication with RTX 4050 hardware. |
| **NVIDIA CUDA Toolkit Runtime (`libcudart`, `libcuda`)** | NVIDIA CUDA EULA | Free for development and deployment. Redistribution of runtime shared libraries (`libcudart.so`, `libcublas.so`) is explicitly permitted under section 2.1 of the CUDA Toolkit End User License Agreement (EULA). Redistribution of full developer toolchain in custom ISOs is governed by Debian non-free / non-free-firmware packaging policies. | GPU computing API, memory management, and kernel launch runtime. |

### Redistribution Architecture Note
To ensure 100% legal compliance and prevent licensing conflicts:
1. **Target Packaging Stream (`nvidia-kernel-dkms`)**: Built using Debian 13 Trixie official `non-free` and `non-free-firmware` repositories, incorporating official NVIDIA GSP firmware blobs for modern Ada Lovelace GPUs.
2. **Open Kernel Modules (`nvidia-open`)**: For modern Ada Lovelace GPUs (RTX 4050), NVIDIA also publishes open-source kernel modules under a dual **MIT / GPLv2** open-source license, allowing direct kernel compilation without license contamination.
3. **Userland CUDA Runtime**: Distributed via standard Debian non-free repository packages under official NVIDIA EULA redistribution terms.
