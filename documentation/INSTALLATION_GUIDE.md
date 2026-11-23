# CUDA-Lite Linux Distribution: Installation & Deployment Guide

**Target Hardware:** PC with x86-64 CPU and discrete NVIDIA GPU (optimized for Ada Lovelace RTX 4050)  
**Supported Firmware:** Legacy BIOS (SeaBIOS / CSM) or UEFI (64-bit EDK2 / OVMF)  
**Primary ISO Image:** `/mnt/d/cuda-lite-linux.iso` (SHA-256: `416c8b54...`)  
**Candidate Extended ISO:** `/mnt/d/cuda-lite-linux-candidate.iso` (SHA-256: `e7c51840...`)

---

## 1. Preparing Bootable Installation Media

CUDA-Lite Linux is distributed as a hybrid ISO 9660 image that can be written directly to physical USB media without third-party bootloader modifications.

### Option A: Using `dd` on Linux / macOS
```bash
# Identify your USB drive (e.g., /dev/sdb - DO NOT use partition numbers like /dev/sdb1)
lsblk

# Write the hybrid ISO image directly to the block device
sudo dd if=/mnt/d/cuda-lite-linux.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

### Option B: Using Rufus on Windows
1. Insert a USB flash drive (minimum 4 GB for production ISO, 8 GB for candidate ISO).
2. Open **Rufus 4.x**.
3. Under **Boot selection**, choose `cuda-lite-linux.iso` or `cuda-lite-linux-candidate.iso`.
4. Partition scheme: **MBR** (for maximum BIOS and UEFI compatibility).
5. Target system: **BIOS or UEFI**.
6. When prompted, select **Write in DD Image mode**.

### Option C: Using Ventoy
Copy `cuda-lite-linux.iso` directly onto an existing Ventoy formatted USB drive.

---

## 2. Booting Physical Laptop / Desktop Hardware

1. Insert the prepared USB flash drive into the target computer.
2. Power on the system and repeatedly press the BIOS/Boot Menu hotkey:
   - **HP Laptop:** Press `F9` for Boot Menu, or `F10` for BIOS Setup.
   - **Dell:** Press `F12`.
   - **Lenovo:** Press `F12` or `Fn+F12`.
   - **ASUS:** Press `F8` or `Esc`.
3. In the boot menu, select the USB drive (UEFI or Legacy USB).
4. In the GRUB boot menu, select:
   - **Normal Boot** (Default Debian kernel with pre-compiled NVIDIA DKMS driver modules).
   - Or **Custom Kernel** (if using the candidate ISO with low-latency `6.12.0-cuda-lite`).
5. The operating system will cold boot into RAM in under 30 seconds.

---

## 3. Logging In and User Accounts

| Account Role | Username | Default Password | Access Level | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Compute User** | `cuda` | Set during build (or `cuda`) | User (`sudo`, `video`, `render`) | Standard user for running CUDA applications and benchmarks. |
| **Root Administrator** | `root` | *Locked* | Root | Direct root login is disabled for security; use `sudo -i` or `sudo <command>`. |

---

## 4. Running Benchmarks & Verifying Hardware

Once logged in at the terminal prompt:

```bash
# 1. Verify NVIDIA GPU Hardware Discovery
/opt/cuda-lite/bin/device_query

# 2. Run SGEMM Matrix Multiplication Benchmark (N=2048, 5 iterations)
/opt/cuda-lite/bin/matrix_mul 2048 5

# 3. Test cuDNN (Candidate ISO)
/opt/cuda-lite/bin/test_cudnn

# 4. Check Docker & Container Runtime (Candidate ISO)
sudo docker run --rm alpine uname -a
```
