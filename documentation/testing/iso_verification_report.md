# CUDA-Lite Linux — ISO Integrity Verification Report

**Date of Verification:** 2026-11-21  
**Distribution:** CUDA-Lite Linux (Debian 13 Trixie amd64)  
**Target Hardware:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89)  
**Image File:** `/mnt/d/cuda-lite-linux.iso`  
**Checksum File:** `/mnt/d/cuda-lite-linux.iso.sha256`  

---

## 1. Executive Summary

The CUDA-Lite Linux distribution ISO was generated using GNU GRUB hybrid rescue utilities (`grub-mkrescue` with `xorriso`) and an immutable SquashFS 4.0 root filesystem compressed with XZ (x86 BCJ filter). The resulting image was verified using low-level ISO manipulation utilities (`xorriso -indev`, `unsquashfs -s`), validating structural integrity, dual-boot support (BIOS + UEFI), live initialization scripts, and packaged NVIDIA compute components.

---

## 2. File Properties and Cryptographic Hash

| Property | Value | Verification Status |
| :--- | :--- | :--- |
| **File Location** | `/mnt/d/cuda-lite-linux.iso` | Verified Present |
| **Exact Size (Bytes)** | `2,878,935,040` bytes | Verified |
| **Size (Human Readable)** | `2.68 GiB` (2,746 MB) | Verified |
| **Sector Count** | `1,405,730` sectors (2048 bytes/sector) | Verified |
| **SHA-256 Hash** | `a417a137ba9f16ae22bfe4f8e00d4439dccb67d4ed17fe290329150ead05a3fb` | Verified Matches `.sha256` |
| **Volume Identifier** | `ISOIMAGE` | Verified |

Verification Command:
```bash
sha256sum /mnt/d/cuda-lite-linux.iso
# Output: a417a137ba9f16ae22bfe4f8e00d4439dccb67d4ed17fe290329150ead05a3fb  /mnt/d/cuda-lite-linux.iso
```

---

## 3. El Torito Boot Catalog & Hybrid Architecture

The image is configured as an ISOHybrid medium supporting legacy BIOS MBR booting and modern UEFI GPT booting through El Torito specifications:

```
Boot record  : El Torito, MBR protective-msdos-label grub2-mbr cyl-align-off GPT APM
Media summary: 1 session, 1405730 data blocks, 2746m data
El Torito cat path : /boot.catalog (LBA 1626)

Entry 1 (BIOS Legacy Boot):
  Platform   : BIOS (0x00)
  Bootable   : Yes
  Emulation  : None
  LBA        : 3041
  Load Size  : 4 sectors
  Image Path : /boot/grub/i386-pc/eltorito.img
  Options    : boot-info-table grub2-boot-info

Entry 2 (UEFI Boot):
  Platform   : UEFI (0xEF)
  Bootable   : Yes
  Emulation  : None
  LBA        : 75
  Load Size  : 5760 sectors
  Image Path : /efi.img
```

---

## 4. ISO Directory Hierarchy

Inspection via `xorriso -indev /mnt/d/cuda-lite-linux.iso -ls` confirmed the canonical structure required by Debian `live-boot`:

```
/
├── .disk/
├── System/
├── boot/
│   └── grub/
│       ├── fonts/
│       ├── grub.cfg
│       ├── i386-pc/ (BIOS modules)
│       ├── locale/
│       ├── roms/
│       └── x86_64-efi/ (UEFI modules)
├── boot.catalog
├── efi/
├── efi.img
├── live/
│   ├── filesystem.squashfs (2.68 GiB compressed root)
│   ├── initrd (40 MiB live initramfs with live-boot hooks)
│   └── vmlinuz (12 MiB Linux 6.12.117+deb13-amd64)
└── mach_kernel
```

---

## 5. SquashFS Root Filesystem Integrity

The underlying live system filesystem was validated via `unsquashfs -s`:

```
Superblock: SQUASHFS 4:0
Filesystem size: 2,811,946,933 bytes (2,681.68 MiB)
Compression: XZ (dictionary size 1,048,576 bytes, filter: x86 BCJ)
Block size: 1,048,576 bytes (1 MiB)
Inodes: 66,802
Total Files: 59,268
Directories: 4,994
Symbolic Links: 2,532
Duplicate Files Eliminated: 25,261
Exportable via NFS: Yes
```

---

## 6. Embedded NVIDIA and CUDA Components

Inspection of the unpacked rootfs verified that all critical computing payloads are baked into `filesystem.squashfs`:

1. **Kernel Modules**:
   - `nvidia-current.ko.xz` (v550.163.01) signed and installed for `6.12.117+deb13-amd64` and `6.12.107+deb13-amd64`.
   - `nvidia-current-uvm.ko.xz` (Unified Virtual Memory compute engine).
   - `nvidia-current-modeset.ko.xz` and `nvidia-current-drm.ko.xz`.
2. **CUDA Driver & User Space Libraries**:
   - `/usr/lib/x86_64-linux-gnu/libcuda.so.1` -> `libcuda.so.550.163.01`.
   - `/usr/lib/x86_64-linux-gnu/libcudart.so.12` -> `libcudart.so.12.4.127`.
   - `/usr/lib/x86_64-linux-gnu/libcublas.so.12` -> `libcublas.so.12.4.5.8`.
3. **Firmware**:
   - `/lib/firmware/nvidia/550.163.01/gsp_ga10x.bin` (GSP firmware for Ampere/Ada Lovelace RTX 4050).
   - `/lib/firmware/nvidia/550.163.01/gsp_tu10x.bin` (Turing firmware).
4. **CUDA Compiler and Tools**:
   - `/usr/bin/nvcc` (CUDA 12.4 release).
   - `/usr/bin/nvidia-smi` (System Management Interface 550.163.01).
5. **Project Applications & Services**:
   - `/opt/cuda-lite/bin/matrix_mul` (Compiled FP32 SGEMM with CUDA/Host fallbacks).
   - `/opt/cuda-lite/bin/device_query` (CUDA device enumerator).
   - `/usr/local/sbin/cuda-lite-startup` (Automated boot diagnostic wrapper).
   - `/etc/systemd/system/cuda-lite-autostart.service` (Enabled in `multi-user.target.wants`).
   - `/etc/sysctl.d/99-cuda-lite-hardening.conf` (Kernel attack surface mitigations).
   - `/etc/fstab` (Live OverlayFS mounting configuration).

---

## 7. Verification Outcome

| Check Item | Requirement | Result |
| :--- | :--- | :--- |
| ISO Generation | Successful build without error | **PASS** |
| SHA-256 Hash | Integrity file recorded | **PASS** |
| BIOS El Torito | 512-byte hybrid MBR + eltorito.img | **PASS** |
| UEFI El Torito | FAT efi.img LBA 75 | **PASS** |
| Kernel / Initrd | Matched 6.12.117+deb13-amd64 | **PASS** |
| SquashFS | Valid 4:0 XZ superblock | **PASS** |
| Driver Packaging | NVIDIA 550.163.01 + GSP firmware | **PASS** |
| User Configuration | `cuda` user created, sudo member | **PASS** |
| Service Configuration | `cuda-lite-autostart.service` enabled | **PASS** |

**Conclusion:** The generated ISO `/mnt/d/cuda-lite-linux.iso` meets all Debian Live specifications and is verified ready for QEMU virtual boot and bare-metal testing.
