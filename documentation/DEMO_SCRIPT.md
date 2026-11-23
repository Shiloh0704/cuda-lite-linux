# CUDA-Lite Linux Distribution — Live Demonstration Script & Protocol

**Course Track:** Track C — Application-Specific Linux Distribution for NVIDIA CUDA Computing  
**Audience:** Academic Evaluators, Course Instructors & Operating Systems Evaluators  
**Target Platform:** HP Victus Laptop — Intel Core i5-13420H & NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89, 6 GB GDDR6)  
**Distribution:** Debian 13 (Trixie) amd64 (`13.7`) | Linux 6.12.117+deb13-amd64  
**Date:** 2026-11-22  

---

## 1. Demonstration Overview

This document provides the exact, step-by-step interactive demonstration protocol for evaluating CUDA-Lite Linux. It covers two clear, separate execution environments:
1. **Scenario A: QEMU Virtual Machine Graphical Boot & OS Verification**
   - Demonstrates cold boot to graphical login in **23.21 seconds** via KVM hardware acceleration (`-enable-kvm -cpu host -display gtk`).
   - Demonstrates clean systemd userland startup, immutable read-only SquashFS with writable tmpfs OverlayFS, D-Bus system bus activation, and hardware-aware NVIDIA vendor ID (`0x10de`) fallback.
2. **Scenario B: Physical NVIDIA GeForce RTX 4050 GPU Execution (Host WSL2)**
   - Demonstrates direct hardware execution on the laptop's physical discrete GPU (Ada Lovelace, SM 8.9, 6 GB GDDR6).
   - Demonstrates CUDA Toolkit 12.4.131 device query, driver interrogation (`nvidia-smi`), and the high-throughput $N=2048$ tiled matrix multiplication benchmark (**794.71 GFLOPS**, **38.81x speedup**).
3. **Scenario C: Optional Bare-Metal Hardware Boot Protocol**
   - USB flash procedure for native laptop boot without host virtualization.

---

## 2. Default System Credentials

| User Account | Username | Password | Privileges |
| :--- | :--- | :--- | :--- |
| **Primary Live User** | `cuda` | `cuda` | Full passwordless `sudo` privileges, member of `video` and `render` groups. |
| **Root Administrator** | `root` | *Locked* | Access via `sudo su` or `sudo <command>`. Direct root login disabled for security. |

---

## 3. Scenario A: Bare-Metal Hardware Demonstration Protocol

### Step 1: Flashing the Bootable USB Drive
Using Rufus (Windows) or `dd` (Linux), flash the generated ISO to a USB flash drive (>= 4 GB):
```bash
# Linux example (replace /dev/sdX with USB block device):
sudo dd if=/mnt/d/cuda-lite-linux.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### Step 2: Booting into CUDA-Lite Linux
1. Insert the USB drive into the HP Victus laptop.
2. Power on and press **F9** (or **F12** / **Esc**) to open the UEFI Boot Menu.
3. Select the USB flash drive (`UEFI: USB Drive`).
4. The GNU GRUB 2.14 boot menu will appear:
   - Select `CUDA-Lite Linux - Normal Boot` (or let the 5-second countdown timer auto-boot).

### Step 3: Logging In
At the login prompt:
```text
Debian GNU/Linux 13 cuda-lite tty1
cuda-lite login: cuda
Password: cuda
```

### Step 4: Verifying Operating System & Kernel Integrity
Run the following commands to display system specifications:
```bash
# 1. Verify Debian 13 release
cat /etc/debian_version
# Expected: 13.7 (or trixie)

# 2. Verify Linux kernel version and architecture
uname -a
# Expected: Linux cuda-lite 6.12.117+deb13-amd64 #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux

# 3. Check memory footprint at idle
free -h
# Expected: Used RAM ~265 MB, Buffers/Cache ~120 MB (over 5.5 GB free)

# 4. Check active OverlayFS root filesystem
df -h /
# Expected: Filesystem 'overlay' mounted on / with read-only lowerdir
```

### Step 5: Verifying NVIDIA Hardware & Driver Initialization
Verify that the RTX 4050 GPU and Ada Lovelace driver modules are active:
```bash
# 1. Check loaded NVIDIA kernel modules
lsmod | grep nvidia
# Expected: nvidia, nvidia_uvm, nvidia_modeset, nvidia_drm

# 2. Verify GPU status, VRAM, and power via nvidia-smi
nvidia-smi
```
Expected output:
```text
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.163.01             Driver Version: 550.163.01     CUDA Version: 12.4     |
|-----------------------------------+------------------------+----------------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC   |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M.   |
|===================================+========================+============================|
|   0  NVIDIA GeForce RTX 4050 ...    Off |   00000000:01:00.0 Off |                    N/A |
| N/A   46C    P8              4W /   60W |      12MiB /   6141MiB |      0%        Default |
+-----------------------------------+------------------------+----------------------------+
```

### Step 6: Verifying CUDA Compiler & Toolchain
```bash
# Verify NVCC compiler version
nvcc --version
# Expected: Cuda compilation tools, release 12.4, V12.4.131
```

### Step 7: Executing CUDA Device Enumeration (`device_query`)
Enumerate hardware specifications and compute capability:
```bash
/opt/cuda-lite/bin/device_query
```
Expected key outputs:
- **Device 0:** "NVIDIA GeForce RTX 4050 Laptop GPU"
- **CUDA Capability Major/Minor version:** 8.9 (Ada Lovelace, `sm_89`)
- **Total amount of global memory:** 6141 MBytes (6.00 GB)
- **Multiprocessors (SMs):** 20
- **Total CUDA Cores:** 2560
- **Peak Memory Bandwidth:** ~192.02 GB/s

### Step 8: Executing Matrix Multiplication Benchmark (`matrix_mul`)
Run the end-to-end CPU vs. GPU matrix multiplication benchmark:
```bash
# Run benchmark with N=1024, 5 iterations
/opt/cuda-lite/bin/matrix_mul 1024 5

# Run benchmark with N=2048, 5 iterations
/opt/cuda-lite/bin/matrix_mul 2048 5
```
Expected key metrics across benchmark runs:
- **Matrix Dimension:** $2048 \times 2048$ ($17.18$ GFLOP).
- **CPU Time (Intel Core i5-13420H):** $\sim 1,956.60\text{ ms}$ to $4,801.30\text{ ms}$ (depending on CPU Turbo frequency).
- **GPU Kernel Compute Time:** $\sim 16.70\text{ ms}$ to $21.62\text{ ms}$ ($794.71$ to $1,029.01\text{ GFLOPS}$).
- **Raw Compute Acceleration:** **$\sim 90.51\times$ to $287.58\times$ speedup**.
- **End-to-End Speedup (including PCIe transfers):** **$\sim 38.81\times$ to $57.39\times$ speedup**.
- **Numerical Validation:** Maximum measured error $3.433228 \times 10^{-5}$ (within $1.0 \times 10^{-3}$ tolerance).

### Step 9: Verifying Systemd Autostart Service
Inspect the automated startup service that ran upon boot:
```bash
systemctl status cuda-lite-autostart.service
```
Expected output:
- `Active: active (exited)`
- `Status: [ OK ] Finished CUDA-Lite Linux GPU Diagnostic and Benchmark.`

---

## 4. Scenario B: Virtual QEMU Demonstration Protocol

When demonstrating inside a virtualized environment or evaluating OS architecture:

### Fast Graphical Launch (Recommended for Live Evaluation):
```bash
cd /mnt/c/Users/shilo/OneDrive/OS_Project
./tests/test_boot.sh
```
*Demonstrated Capabilities:*
- **Acceleration:** Hardware-accelerated KVM (`-enable-kvm -cpu host`).
- **Resource Footprint:** Strictly 2 vCPUs and 2048 MB RAM.
- **Display Backend:** GTK visible graphical window via WSLg with serial monitor (`mon:stdio`) in terminal.
- **Clean Topology:** Legacy floppy, parallel port, and PC speaker disabled.
- **Boot Latency:** Cold boots to `cuda-lite login:` in **23.21 seconds**.

### Automated Verification Script:
```bash
python3 tests/verify_graphical_boot.py
```
*Demonstrated Capabilities:*
- Connects to QEMU via QMP monitor socket.
- Programmatically tracks boot duration and captures live framebuffer (`/tmp/qemu_login_screen.ppm`).
- Exits cleanly without leaving background processes.

### Automated Headless Test:
```bash
./tests/run_qemu_test.sh
```

### Demonstrated Behaviors:
1. **Bootloader Handoff:** QEMU loads kernel `vmlinuz-6.12.117+deb13-amd64` and `initrd`.
2. **OverlayFS Root:** Live-boot scans `/dev/sr0`, mounts read-only SquashFS 4.0, and establishes tmpfs OverlayFS.
3. **Module Loading (`systemd-modules-load.service`):** Finished with status **[ OK ]**. Udev dynamic rules prevent forced driver loading on virtual CPUs.
4. **Diagnostic Autostart (`cuda-lite-autostart.service`):**
   ```text
   ================================================
          CUDA-Lite Linux - Startup Diagnostic
   ================================================
   Notice: No NVIDIA PCI device detected on the bus (virtual/QEMU environment).
   CUDA diagnostic benchmark skipped.
   [  OK  ] Finished cuda-lite-autostart.service - CUDA-Lite Linux GPU Diagnostic and Benchmark.
   ```
5. **System Target:** Reaches `multi-user.target` with zero failed systemd units and displays `cuda-lite login:`.

---

## 5. Concise 2–3 Minute Faculty Presentation Script

**Speaker Introduction (0:00 - 0:30):**
> "Good morning, evaluators. Today I am presenting CUDA-Lite Linux, an application-specific Linux distribution built for Track C: NVIDIA CUDA and GPU Compute. 
> Standard Linux distributions like Ubuntu Desktop carry over 1,700 packages and over 1.3 GB of idle RAM overhead, along with hundreds of unneeded drivers that introduce interrupt jitter.
> CUDA-Lite slims the operating system down to a 441-package minimal Debian 13 base consuming only 138 MB of idle RAM, hardening security with an immutable SquashFS root and zero listening ports, while packing the full NVIDIA Driver and CUDA 12.4 Toolkit into a compact 2.88 GB bootable ISO."

**Demonstration Phase 1 — OS Boot & Architecture in QEMU (0:30 - 1:15):**
> *(Execute `./tests/test_boot.sh`)*
> "Here, we launch CUDA-Lite in QEMU with 2 vCPUs and 2 GB of RAM under KVM acceleration. In just 23 seconds, the system cold-boots from GRUB directly into the graphical login prompt.
> Notice the boot logs: live-boot mounts our read-only SquashFS with a volatile tmpfs OverlayFS layer, ensuring that any runtime filesystem mutations are discarded on reboot.
> The startup service `cuda-lite-autostart` detects that we are in a virtual environment without a physical NVIDIA PCI device (`0x10de`), gracefully logging a notice without failing."

**Demonstration Phase 2 — GPU Compute Benchmarks on Hardware (1:15 - 2:15):**
> *(Execute `./cuda/matrix_mul 2048 5` on host)*
> "Next, we demonstrate our high-throughput CUDA application layer running on the laptop's physical NVIDIA GeForce RTX 4050 Laptop GPU.
> For a 2048 by 2048 single-precision matrix multiplication, the CPU baseline requires 1.96 seconds. Our shared-memory tiled CUDA kernel executes in just 21.62 milliseconds—achieving 794.71 GFLOPS, representing a 90.5x raw kernel speedup and a 38.8x end-to-end speedup including PCIe transfers, verified mathematically to within 3.4 times 10 to the minus 5th."

**Conclusion & Evaluation Wrap-Up (2:15 - 2:45):**
> "In summary, CUDA-Lite delivers a 78.6% reduction in core OS size, an 89.5% reduction in idle RAM footprint, an 83% reduction in boot time down to 23 seconds, and verified CIS-aligned security hardening, satisfying 22 of 24 assignment requirements with complete empirical reproducibility. Thank you, and I welcome your questions."
