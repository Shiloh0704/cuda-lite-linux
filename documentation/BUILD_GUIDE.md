# CUDA-Lite Linux Distribution: Reproducible Build Guide

**Author:** CUDA-Lite Systems Engineering Team  
**Host Environment:** Ubuntu 24.04 LTS on WSL2 / Windows 11  
**Target Architecture:** x86-64 / AMD64  
**Primary ISO Output:** `/mnt/d/cuda-lite-linux.iso`  
**Candidate ISO Output:** `/mnt/d/cuda-lite-linux-candidate.iso`

---

## 1. Prerequisites and Toolchain Dependencies

The build host requires the following packages installed in Ubuntu WSL2:

```bash
sudo apt-get update && sudo apt-get install -y \
  debootstrap chroot mount squashfs-tools grub-pc-bin grub-efi-amd64-bin \
  xorriso systemd gcc g++ gcc-13 g++-13 zstd make bc bison flex libssl-dev \
  libelf-dev python3 python3-pexpect qemu-system-x86
```

At least **50 GiB of free disk space** is required on Windows Drive `D:\` (`/mnt/d`), where temporary build trees and ISO outputs reside.

---

## 2. Production ISO Build Execution

The production ISO build is completely automated through `build/build_iso.sh`:

```bash
# Navigate to the project root
cd /mnt/c/Users/shilo/OneDrive/OS_Project

# Execute the 12-stage automated ISO builder
sudo ./build/build_iso.sh
```

### Build Pipeline Stages:
1. **Host Sanity & Privilege Check:** Validates root EUID, required tools, and free space on `/mnt/d`.
2. **Project File Validation:** Verifies pre-compiled CUDA binaries (`device_query`, `matrix_mul`), udev rules, and systemd service files.
3. **Debootstrap Phase:** Bootstraps a pristine Debian 13 (Trixie) minbase userland into `/var/tmp/cuda-lite-build/rootfs`.
4. **Kernel & Driver Installation:** Installs Debian `linux-image-amd64`, `nvidia-kernel-dkms` (550.163.01), GSP firmware, and builds DKMS modules for `6.12.117+deb13-amd64`.
5. **CUDA Toolkit Integration:** Installs `nvidia-cuda-toolkit` 12.4.131 and runtime libraries.
6. **User & Group Provisioning:** Creates user `cuda` in `sudo,video,render` groups; disables direct root login.
7. **Systemd Autostart Configuration:** Enables `cuda-lite-autostart.service` in `multi-user.target`.
8. **SquashFS Generation:** Compresses rootfs into `/var/tmp/cuda-lite-build/live_iso/live/filesystem.squashfs` with XZ/BCJ.
9. **Hybrid Bootloader Integration:** Executes `grub-mkrescue` to generate the dual BIOS/UEFI bootable ISO image.
10. **Delivery & Checksum:** Writes `/mnt/d/cuda-lite-linux.iso` and generates `/mnt/d/cuda-lite-linux.iso.sha256`.

---

## 3. Candidate Extended ISO Build Execution

To build the extended candidate ISO incorporating cuDNN 9, Docker, containerd, and the NVIDIA Container Toolkit:

```bash
# 1. Run the isolated candidate staging script
sudo ./build/integrate_candidate.sh

# 2. Complete container toolkit package setup
sudo ./build/finish_ctk.sh

# 3. Assemble and compress candidate SquashFS and generate ISO
sudo ./build/build_candidate_iso.sh
```

This generates `/mnt/d/cuda-lite-linux-candidate.iso` and `/mnt/d/cuda-lite-linux-candidate.iso.sha256`.

---

## 4. Standalone Custom Kernel Build Sequence

To independently compile the tailored low-latency compute kernel (`6.12.0-cuda-lite`):

```bash
# 1. Extract Linux 6.12 vanilla source
mkdir -p /var/tmp/kernel-src
tar -xf /var/tmp/linux-6.12.tar.xz -C /var/tmp/kernel-src --strip-components=1

# 2. Apply tailored GPU configuration
cp kernel/configs/config-6.12.0-cuda-lite.config /var/tmp/kernel-src/.config
cd /var/tmp/kernel-src
make CC=gcc-13 olddefconfig

# 3. Compile bzImage
make CC=gcc-13 -j8 bzImage

# 4. Copy resulting bzImage
cp arch/x86/boot/bzImage /mnt/c/Users/shilo/OneDrive/OS_Project/kernel/custom/vmlinuz-6.12.0-cuda-lite
```
