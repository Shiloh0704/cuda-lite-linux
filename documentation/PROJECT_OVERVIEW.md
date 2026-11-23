# CUDA-Lite Linux Distribution: Project Overview

**Course Track:** Track C — NVIDIA CUDA / GPU Compute Application-Specific Linux  
**Target Hardware:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute Capability 8.9 / `sm_89`, 6 GB GDDR6) & 13th Gen Intel Core i5-13420H  
**Base Distribution:** Debian GNU/Linux 13 (Trixie) amd64 (`13.7` minbase)  
**Production ISO:** `/mnt/d/cuda-lite-linux.iso` (2,879,352,832 bytes / 2.68 GiB, SHA-256: `416c8b54bee8f8d2888fb1bbcaa0b37ceca2a5be341c0750a89d27c1c7fc38cb`)  
**Candidate Integrated ISO:** `/mnt/d/cuda-lite-linux-candidate.iso` (3,642,230,784 bytes / 3.39 GiB, SHA-256: `e7c51840f82a29bd25130741e158f0dd77052794b0b3f1586904114269246acf`)

---

## 1. Executive Summary

CUDA-Lite Linux is an application-specific, minimal, reproducible, and bootable live Linux operating system designed specifically for high-throughput, low-latency GPU computing on modern NVIDIA graphics architectures. Standard general-purpose desktop operating systems (e.g., Ubuntu Desktop 24.04, Fedora Workstation) are burdened with over 1,700 packages, graphical display managers (GNOME/Wayland), audio subsystems (PipeWire), printing daemons (CUPS), and thousands of unnecessary peripheral drivers. This architectural overhead inflates the base operating system footprint to over 4 GB, consumes 1.3 GB of idle memory, and introduces timer interrupt jitter that disrupts GPU queue dispatch loops.

CUDA-Lite Linux strips away all desktop bloat to deliver an appliance-like computing environment:
- **Core Operating System Reduction:** The stripped base Debian 13 operating system occupies only ~860 MB uncompressed, achieving an extraordinary **78.61% size reduction** against the stock desktop baseline.
- **Production ISO:** A 2.68 GiB hybrid BIOS/UEFI bootable live image embedding the official Debian kernel `6.12.117+deb13-amd64`, pre-compiled NVIDIA DKMS driver modules (`550.163.01`), GSP firmware, CUDA Toolkit 12.4, and an automated SGEMM benchmark diagnostic service.
- **Candidate ISO:** A 3.39 GiB extended candidate image integrating NVIDIA cuDNN 9 (`9.0.0.312`), Docker Engine 26.1.5, containerd 1.7.24, runc 1.1.15, NVIDIA Container Toolkit 1.20.2-1, and dual-kernel boot options.

---

## 2. Key Technical Achievements

1. **Dual-Path Hybrid Bootloader:** Full El Torito dual-boot catalog supporting both legacy BIOS (MBR SeaBIOS) and modern UEFI (GPT EDK2/OVMF) firmware.
2. **Read-Only SquashFS & Volatile OverlayFS:** Read-only XZ-compressed SquashFS 4.0 root filesystem combined with a RAM-backed tmpfs OverlayFS layer, ensuring zero storage degradation across repeated reboots.
3. **Hardware-Accelerated Compute Performance:**
   - Physical RTX 4050 hardware validation on host WSL2 demonstrated **794.71 GFLOPS sustained throughput** and a **90.51x raw compute speedup** over CPU execution for $2048 \times 2048$ single-precision matrix multiplication (SGEMM).
   - Numerical error maintained below $3.43 \times 10^{-5}$ ($< 1.0 \times 10^{-3}$ threshold).
4. **NVIDIA cuDNN 9 & Container Stack:** Official cuDNN 9 libraries verified with `test_cudnn` (clean exit code 0); Docker and NVIDIA Container Toolkit verified running live GPU-accelerated containers (`docker run --gpus all ... nvidia-smi`).
5. **Multi-Layer Security Hardening:** Restricted device node permissions (`/dev/nvidia*` mode `0660` for group `video`), strict sysctl hardening (`kptr_restrict=2`, `dmesg_restrict=1`, `randomize_va_space=2`), zero listening network ports, and disabled direct root login.
