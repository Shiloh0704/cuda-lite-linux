# CUDA-Lite Linux Build Log & Environment Record
# Track C: Application-Specific Linux Distribution for NVIDIA CUDA Computing

## 1. Environment Record

* **Date & Timestamp**: 2026-11-19
* **Host Machine**: HP Victus Gaming Laptop 15-fa1xxx
* **Host Operating System**: Microsoft Windows 11 Home (Build 10.0.26300)
* **Processor (CPU)**: 13th Gen Intel Core i5-13420H (8 Cores: 4 Performance + 4 Efficient, 12 Threads)
* **Host RAM**: 16.0 GB DDR4/DDR5
* **Target GPU**: NVIDIA GeForce RTX 4050 Laptop GPU (6141 MiB GDDR6 VRAM, PCI ID 01:00.0)
* **NVIDIA Windows Display Driver**: 592.82
* **WSL2 Environment**: Ubuntu 26.04.1 LTS (resolute) running Linux Kernel 6.18.58.1-microsoft-standard-WSL2
* **Build Engine Directory**: Native ext4 filesystem `/var/tmp/cuda-lite-build`

## 2. Toolchain Versions

* **Debootstrap**: v1.0.142
* **Xorriso**: v1.5.6
* **SquashFS-tools**: v4.7.5
* **GCC / G++**: v15.2.0
* **NVIDIA CUDA Toolkit**: v12.4 / 13.1 driver API
* **Target OS Base**: Debian 13 (Trixie) / Bookworm amd64 minbase

## 3. Build Milestones & Verification Steps

1. **Phase 0: Discovery & Boundary Audit**:
   - Enumerated hardware using Windows PowerShell and WSL2.
   - Verified RTX 4050 Laptop GPU with 6GB VRAM.
   - Identified driver boundary: Windows owns the kernel-mode driver, WSL2 uses paravirtualized `/usr/lib/wsl/lib/libcuda.so`.
   - Prevented installation of native Linux display drivers into WSL to protect the host.

2. **Phase 1: Repository & Workspace Structuring**:
   - Initialized Git repository with clean separation of build, kernel, system, packages, cuda, benchmarks, and documentation.
   - Configured secondary partition (Drive D: with 146 GB free) as the safe overflow and backup storage target.

3. **Phase 2: Build System Selection**:
   - Analyzed Buildroot, Yocto Project, and Debian live-build.
   - Selected Debian live-build/debootstrap approach for superior binary compatibility with NVIDIA's official Debian/Ubuntu driver packaging and package security tracking.

4. **Phase 3: Base ISO Generation**:
   - Minbase bootstrapping using xz-compressed SquashFS and OverlayFS tmpfs.
   - Configured hybrid UEFI and legacy BIOS bootloader via GRUB2.

5. **Phase 4 & 5: Kernel Tailoring & CUDA Toolchain**:
   - Configured low-latency compute kernel parameters (`PREEMPT`, `NO_HZ_FULL`, `ZONE_DEVICE`, `IOMMU`).
   - Prepared CUDA benchmark binaries (`device_query` and `matrix_mul`) targeting compute capability 8.9 (`sm_89`).

6. **Phase 6: Benchmark Execution & Speedup Analysis**:
   - Tested CPU vs. GPU matrix multiplication across matrix dimensions 512, 1024, and 2048.
   - Verified numerical correctness (CPU reference vs. GPU tiled shared-memory kernel).

7. **Phase 7: Hardening & Services**:
   - Automated systemd service execution on boot.
   - Injected four justified sysctl kernel hardening parameters.
