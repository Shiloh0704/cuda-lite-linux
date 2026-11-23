# CUDA-Lite Linux Distribution: System Architecture

**Track:** Track C — NVIDIA CUDA / GPU Compute Application-Specific Linux  
**Target Hardware:** Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute Capability 8.9 / `sm_89`, 6 GB GDDR6)  
**Distribution Base:** Debian GNU/Linux 13 (Trixie) amd64 (`13.7` minbase)

---

## 1. High-Level Architectural Diagram

```
+--------------------------------------------------------------------------+
|                     APPLICATION & BENCHMARK LAYER                        |
|   - Tiled SGEMM Matrix Multiplication (matrix_mul)                       |
|   - NVIDIA Device Discovery & Telemetry (device_query)                  |
|   - cuDNN 9 Deep Learning Primitives (test_cudnn)                       |
|   - OCI Containers (Docker / containerd / NVIDIA Container Toolkit)      |
+--------------------------------------------------------------------------+
|                     COMPUTE & RUNTIME MIDDLEWARE                         |
|   - NVIDIA CUDA Toolkit 12.4.131 (nvcc, libcudart.so.12, libcublas.so.12)|
|   - NVIDIA cuDNN 9.0.0.312 (libcudnn_ops, libcudnn_cnn, libcudnn_adv)   |
|   - NVIDIA Container Runtime & Container Device Interface (CDI)          |
|   - Dynamic Linker Cache (/etc/ld.so.cache, /etc/ld.so.conf.d/)          |
+--------------------------------------------------------------------------+
|                     INITIALIZATION & USERLAND LAYER                      |
|   - systemd 256.7-1 (PID 1, multi-user.target)                           |
|   - Oneshot Diagnostic Service (cuda-lite-autostart.service)             |
|   - Security Hardening (sysctl, udev 0660 video group permissions)       |
|   - Stripped Debian 13 minbase (260 curated CLI packages, no X11/GUI)    |
+--------------------------------------------------------------------------+
|                     STORAGE & VIRTUAL FILESYSTEM LAYER                   |
|   - Upper Writable Layer: Volatile tmpfs OverlayFS (/run/live/overlay)   |
|   - Lower Read-Only Layer: SquashFS 4.0 XZ-compressed (filesystem.squashfs)|
|   - Storage Media: ISO 9660 Hybrid Optical/USB Media (/dev/sr0)          |
+--------------------------------------------------------------------------+
|                     LINUX KERNEL SUBSYSTEM (DUAL-KERNEL)                 |
|   - Default Production Kernel: Linux 6.12.117+deb13-amd64                |
|     * Out-of-the-box pre-compiled NVIDIA DKMS modules (550.163.01)       |
|     * Stable DRM/video exported symbols & GSP firmware binding           |
|   - Experimental Tailored Kernel: Linux 6.12.0-cuda-lite                 |
|     * CONFIG_PREEMPT=y (Full low-latency preemption)                     |
|     * CONFIG_HZ=1000 (1 ms scheduling quantum), AVX2/Core2 instructions  |
|     * CONFIG_ZONE_DEVICE=y, CONFIG_HMM_MIRROR=y, CONFIG_PCI_P2PDMA=y     |
|     * Built-in storage drivers (loop, squashfs, overlayfs, iso9660, ahci)|
+--------------------------------------------------------------------------+
|                     FIRMWARE & HARDWARE LAYER                            |
|   - Dual Bootloader: GRUB 2.12 (BIOS MBR boot_hybrid + UEFI GPT bootx64) |
|   - Physical Host: 13th Gen Intel Core i5-13420H, 16 GB DDR5             |
|   - Compute Device: NVIDIA GeForce RTX 4050 Laptop GPU (6 GB GDDR6)      |
+--------------------------------------------------------------------------+
```

---

## 2. Dual-Kernel Architectural Strategy

A primary engineering challenge in GPU-centric distribution development is balancing out-of-tree proprietary driver stability against in-tree kernel customisation:
1. **The Out-of-Tree DKMS Symbol Boundary:**
   The NVIDIA display driver (`nvidia.ko`, `nvidia-uvm.ko`) is built out-of-tree via DKMS. In modern kernels, the NVIDIA driver relies on proprietary and GPL-exported Direct Rendering Manager (DRM) APIs (`drm_gem_object_free`, `drm_atomic_helper_check`, `acpi_video_register_backlight`). The Debian distribution kernel packages specific backported patches that export these interfaces cleanly.
2. **The Dual-Kernel Design:**
   - **Production ISO Default:** Retains official Debian `6.12.117+deb13-amd64` with pre-compiled NVIDIA DKMS modules, ensuring 100% out-of-the-box driver stability on physical hardware.
   - **Tailored Research Kernel:** Provides `6.12.0-cuda-lite` compiled from upstream vanilla source with low-latency preemption (`PREEMPT_DYNAMIC`), AVX2 instructions, Intel IOMMU DMA isolation, and built-in storage drivers. It boots in QEMU in **12.18 seconds** and is available as a selectable boot entry in the candidate ISO.

---

## 3. Storage Architecture: SquashFS and OverlayFS

CUDA-Lite Linux uses a two-tier hybrid storage architecture:
1. **Immutable Base Image (Lower Layer):** The complete Debian userland and CUDA stack are compressed into `/live/filesystem.squashfs` using SquashFS 4.0 with XZ block compression (`-b 1048576 -Xbcj x86`). This produces a compression ratio of ~44.5%, turning 7.5 GB of uncompressed data into a compact 3.3 GB payload.
2. **Volatile Copy-on-Write (Upper Layer):** During boot, `live-boot` mounts a RAM-backed `tmpfs` file system at `/run/live/overlay`. An `overlay` mount joins the immutable lower SquashFS and writable upper tmpfs into `/`.
3. **Stateless Reliability:** All runtime modifications (temporary files, package installations, log files) exist solely in RAM. Upon reboot, the system returns immediately to its verified bit-perfect golden state.
