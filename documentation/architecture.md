# CUDA-Lite Linux System Architecture

## 1. System Overview & Layer Stack

```
+-------------------------------------------------------------------------+
|                  CUDA User Application & Benchmarks                     |
|  - matrix_mul (Tiled Shared-Memory FP32 SGEMM)                          |
|  - device_query (Hardware Architecture & Memory Hierarchy Inspector)     |
+-------------------------------------------------------------------------+
                                     │
                                     ▼
+-------------------------------------------------------------------------+
|                      CUDA Userland Driver API                           |
|  - libcuda.so.1 (Driver API)                                            |
|  - libcudart.so.12 (CUDA Runtime) / libcublas.so.12                     |
+-------------------------------------------------------------------------+
                                     │
                         ioctl / DMA / Unified Memory
                                     ▼
+-------------------------------------------------------------------------+
|             Kernel Modules (nvidia-kernel-dkms / nvidia-open)           |
|  - nvidia.ko (Hardware Interface & PCIe Bar Management)                 |
|  - nvidia-uvm.ko (Unified Virtual Memory & Page Fault Migration)        |
|  - nvidia-modeset.ko (Display context management)                       |
+-------------------------------------------------------------------------+
                                     │
                                     ▼
+-------------------------------------------------------------------------+
|                   Custom Tailored Linux Kernel (6.x)                    |
|  - PREEMPT (Low-latency compute scheduling)                             |
|  - NO_HZ_FULL (Tickless CPU cores preventing GPU interrupt jitter)      |
|  - DMA-BUF & IOMMU GPUDirect P2P support                                |
|  - Stripped of sound, wireless, bluetooth, legacy peripherals           |
+-------------------------------------------------------------------------+
                                     │
                                     ▼
+-------------------------------------------------------------------------+
|              Physical Hardware: NVIDIA GeForce RTX 4050                 |
|  - 6 GB GDDR6 VRAM | 96-bit Memory Bus | Ada Lovelace (sm_89)           |
+-------------------------------------------------------------------------+
```

## 2. Boot & Filesystem Architecture (OverlayFS)

```
        BIOS / UEFI Boot
               │
               ▼
       GRUB2 Bootloader
               │
               ▼
   Linux Kernel (vmlinuz)
   + Initramfs (live-boot)
               │
       Mount Lowerdir
               │
               ▼
+------------------------------+     +-------------------------------+
|      Lowerdir (Read-Only)    |     |      Upperdir (Writable)      |
|  SquashFS Compressed Rootfs  |     |  tmpfs (RAM-backed, volatile) |
|  (/live/rofs)                |     |  (/live/cow)                  |
+------------------------------+     +-------------------------------+
               │                                     │
               └──────────────────┬──────────────────┘
                                  ▼
                         OverlayFS Merged Root
                                 (/)
                                  │
                                  ▼
                          systemd (Init PID 1)
                                  │
                                  ▼
                     cuda-lite-autostart.service
                                  │
                ┌─────────────────┴─────────────────┐
                ▼                                   ▼
          nvidia-smi                        matrix_mul (N=1024)
       (Hardware Health)                     (Compute Benchmark)
```

## 3. GPU Driver Boundary & Execution Models

1. **Bare-Metal Physical Boot (Standalone ISO on Target)**:
   - Kernel boots directly on host x86-64 CPU.
   - Loads `nvidia-open` kernel modules.
   - Creates `/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`.
   - Applications talk directly through the PCIe bus to the RTX 4050 hardware.

2. **WSL2 Paravirtualized Development Sandbox**:
   - Host Windows NVIDIA driver manages the hardware via WDDM.
   - `/usr/lib/wsl/lib/libcuda.so.1` communicates with `/dev/dxg` (DirectX kernel graphics interface).
   - Compute pipelines function seamlessly inside Linux without needing a native Linux display driver installed in WSL2.
