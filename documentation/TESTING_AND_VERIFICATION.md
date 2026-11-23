# CUDA-Lite Linux Distribution: Testing & Verification Report

**Author:** QA & Systems Engineering Team  
**Evaluation Platform:** HP Victus Laptop (Intel Core i5-13420H, NVIDIA GeForce RTX 4050 Laptop GPU, 16 GB RAM)  
**Host Environment:** Windows 11 + Ubuntu 24.04 LTS on WSL2  
**Virtual Environment:** QEMU x86_64 10.2.1 with KVM acceleration  
**Date of Testing:** November 22, 2026

---

## 1. Testing Framework and Environment Separation

To ensure absolute academic rigor, testing is divided into two mutually exclusive environments:
1. **Physical Hardware Host Tests (WSL2):** Evaluates physical NVIDIA GeForce RTX 4050 GPU compute performance, CUDA SGEMM throughput, cuDNN 9 context creation, and hardware GPU-accelerated container execution.
2. **Virtualized Operating System Tests (QEMU):** Evaluates live ISO booting, bootloader handoff, live SquashFS discovery, OverlayFS mounting, systemd PID 1 service startup, and serial console interaction.

> [!NOTE]
> In virtualized QEMU, the physical RTX 4050 GPU cannot be passed through due to mobile single-GPU hardware limitations. Therefore, GPU workloads are executed on the physical host under WSL2, while OS distribution boot architecture is verified in QEMU.

---

## 2. QEMU Virtual Machine Boot Verification

### Test 2.1: Production ISO Cold Boot
- **Command:** `python3 tests/verify_graphical_boot.py`
- **Result:** Reached graphical login prompt in **23.21 seconds** under KVM acceleration.
- **Headless Serial Boot:** Reached `cuda-lite login:` in **84.6 seconds** (serial log: `documentation/testing/qemu_serial_boot.log`).

### Test 2.2: Candidate ISO Cold Boot
- **Command:** `python3 tests/verify_candidate_systemd_login.py`
- **Result:** Reached systemd login prompt on `ttyS0` in **29.10 seconds** (`candidate_systemd_login.log`).

### Test 2.3: In-Guest Telemetry Collection
Booting into the candidate guest root filesystem via QEMU produced:
- `uname -a`: `Linux (none) 6.12.117+deb13-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.12.117-1 (2026-11-12) x86_64 GNU/Linux`
- `cat /etc/os-release`: `Debian GNU/Linux 13 (trixie)`
- `df -h /`: `overlay 987M 8.0K 987M 1% /`
- `mount | grep overlay`: `tmpfs on /run/live/overlay type tmpfs`, `overlay on / type overlay`
- `docker --version`: `Docker version 26.1.5+dfsg1`
- `nvidia-ctk --version`: `NVIDIA Container Toolkit CLI version 1.20.2`

### Test 2.4: Custom Kernel In-Guest Telemetry
Booting `6.12.0-cuda-lite` into the candidate rootfs produced:
- `uname -a`: `Linux (none) 6.12.0-cuda-lite #2 SMP PREEMPT_DYNAMIC Sun Nov 22 12:18:08 UTC 2026 x86_64 GNU/Linux`
- Boot-to-powerdown: **6.60 seconds**.

---

## 3. Physical Hardware GPU Verification (Host WSL2)

### Test 3.1: CUDA Hardware Discovery
- **Command:** `./cuda/device_query`
- **Result:** `PASS (Exit code 0)`
- **Device Details:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute Capability 8.9 / `sm_89`, 6141 MB GDDR6 memory, 18 Streaming Multiprocessors / 2304 CUDA cores).

### Test 3.2: cuDNN 9 Context Creation & Destruction
- **Command:** `./packages/cudnn/test_cudnn`
- **Result:** `PASS (Exit code 0)`
- **Output:** cuDNN Library Version 9.0.0; `cudnnCreate()` and `cudnnDestroy()` succeeded with `CUDNN_STATUS_SUCCESS (0)`.

### Test 3.3: Hardware GPU-Accelerated Container
- **Command:** `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`
- **Result:** `PASS (Exit code 0)`
- **Output:** Container enumerated physical RTX 4050 GPU (Driver 592.82, CUDA 13.1).
