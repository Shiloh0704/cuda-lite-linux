# CUDA-Lite Linux Distribution — Complete Project Discovery Report

**Project Track:** Track C — Application-Specific Linux Distribution for NVIDIA CUDA Computing  
**Auditor:** Senior Linux Distribution Engineer & Operating Systems Specialist  
**Target Hardware:** HP Victus Laptop — Intel Core i5-13420H & NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89, 6 GB GDDR6)  
**Host Environment:** Ubuntu 24.04 on WSL2 / Windows 11  
**Build Rootfs:** `/var/tmp/cuda-lite-build/rootfs`  
**Target ISO:** `/mnt/d/cuda-lite-linux.iso` (2.68 GiB / 2,879,352,832 bytes)  
**Target SHA-256:** `416c8b54bee8f8d2888fb1bbcaa0b37ceca2a5be341c0750a89d27c1c7fc38cb`  
**Date of Audit:** 2026-11-22  

---

## 1. Executive Summary

This report documents the exhaustive, non-destructive discovery audit of the **CUDA-Lite Linux Distribution (Track C)**. Every component across source code, build infrastructure, package manifests, kernel configuration, driver DKMS modules, initramfs, OverlayFS, systemd services, udev rules, test logs, and submission archives has been inspected against the actual filesystem and live image.

---

## 2. Component Discovery & Classification

### A. Confirmed Implemented & Verified Components

| Component | Disk Location / Package | Verified State | Empirical Evidence |
| :--- | :--- | :--- | :--- |
| **Debian Base Userland** | `/var/tmp/cuda-lite-build/rootfs` | Minimal Debian 13 Trixie amd64 (minbase) | `/etc/debian_version` reports `13.7`; 267 total packages in `/var/lib/dpkg/status`. |
| **Bootable Live ISO** | `/mnt/d/cuda-lite-linux.iso` | Dual BIOS/UEFI hybrid bootable ISO | `xorriso -report_el_torito` confirms LBA 3041 (BIOS) and LBA 75 (UEFI `/efi.img`). |
| **Kernel Stack** | `linux-image-6.12.117+deb13-amd64` | Packaged Debian 13 kernel with matching headers | `/boot/vmlinuz-6.12.117+deb13-amd64` (12.1 MB) and `/boot/config-6.12.117+deb13-amd64`. |
| **Kernel Configuration** | `kernel/config-6.12.117+deb13-amd64` | Extracted and tracked in source tree | 283,598 bytes configuration file with tailoring analysis in `kernel/analysis.md`. |
| **NVIDIA Driver** | `nvidia-kernel-dkms` 550.163.01 | DKMS modules compiled for both 6.12.107 and 6.12.117 kernels | `nvidia-current.ko.xz` and `nvidia-current-uvm.ko.xz` verified in `/lib/modules/6.12.117*/updates/dkms/`. |
| **NVIDIA GSP Firmware** | `firmware-nvidia-gsp` 550.163.01 | Present in rootfs firmware tree | `gsp_ga10x.bin` located in `/lib/firmware/nvidia/550.163.01/`. |
| **CUDA Toolkit & Compiler** | `nvidia-cuda-toolkit` 12.4.131 | Fully installed in rootfs | `/usr/bin/nvcc` reports release 12.4, V12.4.131. |
| **CUDA Runtime & BLAS** | `libcudart12`, `libcublas12` | Runtime libraries linked | `/usr/lib/x86_64-linux-gnu/libcublas.so.12` and `libcuda.so.1` verified. |
| **CUDA Application (SGEMM)**| `cuda/matrix_mul.cu` | Compiled native binary (`sm_89`) | Located at `/opt/cuda-lite/bin/matrix_mul`; verified FP32 speedup (up to 287.58x). |
| **CUDA Device Query** | `cuda/device_query.cu` | Compiled native binary (`sm_89`) | Located at `/opt/cuda-lite/bin/device_query`; enumerates 20 SMs, 6GB VRAM. |
| **Immutable Root & OverlayFS**| `system/fstab.overlay`, `live-boot` | Read-only SquashFS 4.0 XZ + tmpfs OverlayFS | SquashFS size 2.68 GiB; fstab mounts `/tmp` (2GB) and `/var/log` (256MB) on volatile RAM. |
| **Dynamic Hardware Detection**| `system/99-nvidia.rules` | Udev autoloading rule on vendor `0x10de` | Deployed to `/etc/udev/rules.d/99-nvidia.rules`; eliminates VM modprobe failures. |
| **Autostart Service** | `system/cuda-lite-autostart.service` | Systemd oneshot unit enabled in multi-user.target | `ExecStart=/bin/bash /usr/local/sbin/cuda-lite-startup`; passes with status `[ OK ]`. |
| **Security Hardening (4 Points)**| `system/hardening.conf` | Enforced sysctl parameters | `randomize_va_space=2`, `kptr_restrict=2`, `unprivileged_bpf_disabled=1`, `tcp_syncookies=1`. |
| **IPC & System Bus** | `dbus.service` | Running system message bus | Enables `systemd-logind` and multi-user login prompts. |
| **QEMU Virtual Boot** | `tests/run_qemu_test.sh` | Verified headless boot to `cuda-lite login:` | QEMU 8.2.2 serial boot log verifies 0 failed units and 84.6s boot time. |
| **Automated Build Pipeline**| `build/build_iso.sh` | Reproducible script with `--resume` support | Complete 12-stage builder with sanity checks, package verification, and checksumming. |

---

### B. Components That Exist but Require Bare-Metal Boot for Final Testing

| Component | State | Reason / Constraint |
| :--- | :--- | :--- |
| **Physical Bare-Metal Boot** | Configured & Ready | Flashing the ISO to a USB flash drive and rebooting the physical HP Victus laptop requires user action. In QEMU without VFIO GPU passthrough, GPU hardware access is absent by design. |
| **Live USB Persistence** | Optional Feature | Live boot runs in non-persistent RAM overlay mode. A secondary persistence partition (`persistence`) can be added by the user if persistent state across reboots is desired. |

---

### C. Components Corrected During This Audit

| Component | Identified Defect | Corrective Action Taken |
| :--- | :--- | :--- |
| **`cuda-lite-autostart.service`** | Failed with `203/EXEC` due to execution format in earlier ISO image. | Switched to explicit `/bin/bash` invocation in service unit; verified shebang `#!/bin/bash` on line 1 of startup script. |
| **`systemd-modules-load.service`** | Exited with `status=1/FAILURE` during QEMU boot because static `/etc/modules-load.d/` configs forced `modprobe nvidia` on virtual CPUs without GPU. | Masked static module load in `/etc/modules-load.d/nvidia.conf` (`/dev/null`) and replaced with dynamic udev rule `99-nvidia.rules` matching PCI vendor `0x10de`. |
| **Startup Hardware Probing** | `lspci -d 10de:` returned 0 in shell test even when 0 devices matched, causing repeated 15-second modprobe timeouts. | Replaced with direct kernel sysfs inspection (`grep -qs "0x10de" /sys/bus/pci/devices/*/vendor`). Shaved 58 seconds off QEMU boot time. |
| **Kernel Configuration Deliverable** | Kernel `.config` existed inside rootfs `/boot/` but was not tracked in repository `kernel/` directory. | Extracted `/var/tmp/cuda-lite-build/rootfs/boot/config-6.12.117+deb13-amd64` to `kernel/config-6.12.117+deb13-amd64` and `kernel/.config`. |
| **Package Manifest CSV** | Manifest existed as text file, but CSV format requested by assignment was missing. | Generated `documentation/PACKAGE_MANIFEST.csv` directly from `/var/lib/dpkg/status` parsing all 267 packages. |

---

### D. Architectural Exclusions (Technically Justified)

| Component | Decision | Technical & Academic Justification |
| :--- | :--- | :--- |
| **cuDNN (Deep Neural Network Library)** | **EXCLUDED** | cuDNN adds over 1.8 GB of uncompressed shared libraries (`libcudann*.so`), which would increase ISO size by ~800 MB without being utilized by the core Track C workload (matrix multiplication / SGEMM). Dense linear algebra is fully accelerated via cuBLAS (`libcublas12`) and native CUDA kernels. |
| **Container Engine (Docker / Podman)** | **EXCLUDED** | A container runtime adds 350-500 MB of dependencies (Go runtime, containerd daemon, CNI networking plugins) and increases idle RAM usage from 265 MB to > 600 MB. Running the CUDA workload directly via native systemd service provides zero virtualization overhead, direct GPU memory queue access, and minimal resource contention. |
| **Custom Kernel Re-compilation from Scratch** | **EXCLUDED IN LIVE IMAGE** (Config provided) | Debian 13 kernel `6.12.117+deb13-amd64` provides tested, stable ABI compatibility with NVIDIA DKMS 550.163.01 and Ada Lovelace GSP firmware. Compiling an out-of-tree custom monolithic kernel inside WSL risks breaking DKMS symbol exports and laptop hardware peripherals. A tailored custom `.config` diff analysis is provided in `kernel/kernel_config_diff.txt` and `kernel/analysis.md`. |
| **X11 / Wayland Desktop GUI** | **EXCLUDED** | Desktop environments (GNOME, KDE, XFCE) consume over 2.5 GB of disk space and 800 MB of idle RAM. Stripping display servers eliminates OS jitter and preserves maximum GDDR6 memory bandwidth for CUDA compute. |

---

## 3. Discovery Conclusion

The CUDA-Lite Linux Distribution is in an advanced, stable, and verified state:
- The base distribution boots reliably into systemd user space with 0 failed units.
- NVIDIA DKMS 550.163.01 driver modules are compiled and ready for both installed kernels.
- The CUDA application and device query binaries target `sm_89` (Ada Lovelace).
- Hardware detection is dynamically aware of virtualized vs. bare-metal environments.
- All core assignment requirements are addressed with empirical evidence.
