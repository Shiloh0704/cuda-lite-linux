# Phase 1: Environment & Configuration Repair — Validation Report

**Project Title:** Custom Lightweight Linux Distribution for Edge AI Inference (EdgeML Linux OS)  
**Academic Course:** Operating Systems Engineering (Track A – ML Inference at the Edge)  
**Target Hardware Platform:** ARM64 Virtual Platform (`aarch64` QEMU `virt` Machine, Cortex-A57)  
**Build System:** Buildroot 2025.02.10 LTS  
**Kernel Target:** Linux 6.12.27 LTS  
**Document Reference:** [documentation/PHASE1_VALIDATION.md](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/documentation/PHASE1_VALIDATION.md)  
**Date of Execution:** November 20, 2026  
**Status:** **Phase 1 Complete — Configuration & Environment Validated**

---

## 1. Host Dependency Verification

The host build environment (`wsl -d Ubuntu 24.04`) was inspected for all required compilation tools and headers.

### Detailed Toolchain Status:

| Tool / Dependency | Verification Command | Detected Version / Path | Status |
|:---|:---|:---|:---:|
| **GNU Make** | `which make` | `/usr/bin/make` (GNU Make 4.4.1) | **INSTALLED** |
| **GCC** | `which gcc` | `/usr/bin/gcc` (Ubuntu 15.2.0-16ubuntu1) | **INSTALLED** |
| **G++** | `which g++` | `/usr/bin/g++` (Ubuntu 15.2.0-16ubuntu1) | **INSTALLED** |
| **QEMU ARM64** | `which qemu-system-aarch64` | `/usr/bin/qemu-system-aarch64` (QEMU 10.2.1) | **INSTALLED** |
| **Python 3** | `which python3` | `/usr/bin/python3` (Python 3.14.4) | **INSTALLED** |
| **Git** | `which git` | `/usr/bin/git` (git 2.53.0) | **INSTALLED** |
| **Rsync** | `which rsync` | `/usr/bin/rsync` (rsync 3.4.1) | **INSTALLED** |
| **BC** | `which bc` | `/usr/bin/bc` (bc 1.07.1) | **INSTALLED** |
| **Bison** | `which bison` | Not found in `$PATH` | **MISSING** |
| **Flex** | `which flex` | Not found in `$PATH` | **MISSING** |
| **Cpio** | `which cpio` | Not found in `$PATH` | **MISSING** |
| **libncurses-dev** | `dpkg -s libncurses-dev` | Package not installed | **MISSING** |

> [!IMPORTANT]
> **Action Required from User Before Phase 2 Compilation:**  
> In compliance with strict safety rules, packages were not installed automatically. The user should run the following command in WSL2 Ubuntu to install the missing build dependencies:
> ```bash
> sudo apt update && sudo apt install -y bison flex cpio libncurses-dev
> ```

---

## 2. Kernel Configuration Findings

### Architecture & Preemption Configuration:
1. **ARM64 Architecture (`CONFIG_ARM64`)**:
   * Inspection of Linux kernel Kconfig confirms that when building for `ARCH=arm64`, `CONFIG_ARM64=y` is declared as `def_bool y` in `arch/arm64/Kconfig` (line 1) and is selected automatically by the kernel build system. Blindly injecting it into the minimal defconfig is unnecessary, though Buildroot sets `ARCH=arm64` automatically.
2. **Voluntary Preemption (`CONFIG_PREEMPT_VOLUNTARY`)**:
   * Evaluated `configs/kernel_defconfig`. `CONFIG_PREEMPT_VOLUNTARY` was previously omitted despite being claimed in the academic reports.
   * `CONFIG_PREEMPT_VOLUNTARY=y` is a standard, fully supported Kconfig option on ARM64 Linux 6.12.x kernels under `General setup` -> `Preemption Model`.
   * **Modification**: Added `CONFIG_PREEMPT_VOLUNTARY=y` to `configs/kernel_defconfig`.

### Filesystem Invariants:
* **SquashFS**: `CONFIG_SQUASHFS=y`, `CONFIG_SQUASHFS_FILE_DIRECT=y`, `CONFIG_SQUASHFS_DECOMP_MULTI_PERCPU=y`, `CONFIG_SQUASHFS_XZ=y` — **VERIFIED ENABLED**.
* **OverlayFS**: `CONFIG_OVERLAY_FS=y`, `CONFIG_OVERLAY_FS_REDIRECT_DIR=y`, `CONFIG_OVERLAY_FS_INDEX=y` — **VERIFIED ENABLED**.
* **Virtual Storage & Drivers**: `CONFIG_VIRTIO_BLK=y`, `CONFIG_VIRTIO_NET=y`, `CONFIG_VIRTIO_PCI=y`, `CONFIG_SERIAL_AMBA_PL011=y`, `CONFIG_SERIAL_AMBA_PL011_CONSOLE=y` — **VERIFIED ENABLED**.
* **Bloat Stripping**: Explicit exclusions for DRM, Sound, Bluetooth, Wireless, and USB drivers are confirmed present.

---

## 3. Buildroot Configuration Findings

The existing `configs/buildroot_defconfig` was audited and validated against the Buildroot 2025.02.10 Kconfig package database:

1. **Target Architecture & Variant**:
   * `BR2_aarch64=y` and `BR2_cortex_a57=y` were verified in `arch/Config.in.arm` (lines 296, 878), mapping directly to compiler flag `-mcpu=cortex-a57`.
2. **Kernel Headers & C-Library Selection (Critical Resolution)**:
   * Previously, `configs/buildroot_defconfig` lacked explicit header versioning (`BR2_KERNEL_HEADERS_AS_KERNEL=y`), which caused Buildroot's Kconfig parser to treat header version as unknown (< 3.2), automatically disabling Glibc and falling back to uClibc.
   * Because `package/tensorflow-lite/Config.in` mandates `BR2_TOOLCHAIN_USES_GLIBC=y`, this dependency failure silently dropped `BR2_PACKAGE_TENSORFLOW_LITE` from `.config`.
   * **Modification**: Added `BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_6_12=y` to `configs/buildroot_defconfig`. This immediately satisfies `BR2_TOOLCHAIN_HEADERS_AT_LEAST_3_2`, enabling `BR2_TOOLCHAIN_BUILDROOT_GLIBC=y` and unlocking `BR2_PACKAGE_TENSORFLOW_LITE=y`.
3. **ML Runtime & Acceleration Engine (RUY vs. XNNPACK)**:
   * Audit of `package/xnnpack/Config.in` revealed that Buildroot 2025.02.10 restricts XNNPACK architecture support to `i386` and `x86_64` (`BR2_PACKAGE_XNNPACK_ARCH_SUPPORTS` has no `aarch64` entry).
   * Audit of `package/ruy/Config.in` and `package/tensorflow-lite/Config.in` revealed that Buildroot automatically selects **RUY** (`BR2_PACKAGE_RUY=y`) for ARM64 matrix multiplications.
   * **Modification**: Updated defconfig header comment from `TensorFlow Lite 2.14+ (NEON SIMD / XNNPACK)` to `TensorFlow Lite 2.11.0 (ARM NEON SIMD / RUY)` to reflect authentic package realities.
4. **SquashFS Compression Symbol**:
   * Corrected `BR2_TARGET_ROOTFS_SQUASHFS_XZ=y` to the active Buildroot 2025.02.10 symbol: `BR2_TARGET_ROOTFS_SQUASHFS4_XZ=y`.
5. **Target Post-Build Script Creation**:
   * Defconfig referenced `BR2_ROOTFS_POST_BUILD_SCRIPT="board/edgeml/post-build.sh"`, but the file did not exist on disk, which would abort the target finalization stage.
   * **Action**: Created executable script `board/edgeml/post-build.sh` enforcing `chmod 755` on `/etc/init.d/*` and `/usr/bin/edgeml-infer`.

---

## 4. Storage Safety Verification

Storage volumes were audited to protect the host operating system:

| Volume | Mount Path | Total Size | Used Space | Available Space | Use % | Operational Role |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **Host Windows Drive `C:\`** | `/mnt/c` | 182 GB | 171 GB | **11.5 GB** | **94%** | **Protected**: No build artifacts or download caches are allowed here. |
| **Secondary Volume Drive `D:\`** | `/mnt/d` | 147 GB | 152 MB | **147.0 GB** | **1%** | **Dedicated Workspace**: Hosts Buildroot sources, download cache (`dl/`), and build output (`output_qemu/`). |

### Workspace Directory Layout:
* Source Tree: `/mnt/d/buildroot_workspace/buildroot-2025.02.10`
* Output Directory: `/mnt/d/buildroot_workspace/output_qemu`
* Download Cache: `/mnt/d/buildroot_workspace/dl`

---

## 5. Summary of Files Modified

| File Path | Nature of Modification | Rationale |
|:---|:---|:---|
| [configs/kernel_defconfig](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/configs/kernel_defconfig) | Added `CONFIG_PREEMPT_VOLUNTARY=y` | Aligns kernel configuration with documented low-latency preemption model. |
| [configs/buildroot_defconfig](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/configs/buildroot_defconfig) | Added `BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_6_12=y`<br>Updated to `BR2_TARGET_ROOTFS_SQUASHFS4_XZ=y`<br>Updated comments to TFLite 2.11.0 / RUY | Satisfies Glibc toolchain dependencies, unlocks TensorFlow Lite package, and enables XZ compression. |
| [board/edgeml/post-build.sh](file:///c:/Users/shilo/OneDrive/OS_PROJECT_1/board/edgeml/post-build.sh) | Created executable post-build hook script | Resolves missing script blocker and enforces target filesystem permissions. |
| `/mnt/d/buildroot_workspace/buildroot-2025.02.10/board/edgeml/` | Staged `post-build.sh` and rootfs overlays | Enables out-of-tree Buildroot relative path resolution. |
| `/mnt/d/buildroot_workspace/buildroot-2025.02.10/configs/` | Staged `kernel_defconfig` and `qemu_aarch64_virt_edgeml_defconfig` | Enables out-of-tree Buildroot defconfig evaluation. |

---

## 6. Validation Commands and Actual Results

The following configuration validation command was executed in the workspace without starting compilation:

```bash
make -C /mnt/d/buildroot_workspace/buildroot-2025.02.10 O=/mnt/d/buildroot_workspace/output_qemu qemu_aarch64_virt_edgeml_defconfig
```

### Verified Kconfig Output:
```
make: Entering directory '/mnt/d/buildroot_workspace/buildroot-2025.02.10'
  GEN     /mnt/d/buildroot_workspace/output_qemu/Makefile
#
# configuration written to /mnt/d/buildroot_workspace/output_qemu/.config
#
make: Leaving directory '/mnt/d/buildroot_workspace/buildroot-2025.02.10'
```

### Query of Active Symbols in `/mnt/d/buildroot_workspace/output_qemu/.config`:
```bash
$ grep -E 'BR2_aarch64|BR2_cortex_a57|BR2_TOOLCHAIN_USES_GLIBC|BR2_PACKAGE_TENSORFLOW_LITE|BR2_PACKAGE_RUY|BR2_TARGET_ROOTFS_SQUASHFS4_XZ' /mnt/d/buildroot_workspace/output_qemu/.config

BR2_aarch64=y
BR2_cortex_a57=y
BR2_TOOLCHAIN_USES_GLIBC=y
BR2_TOOLCHAIN_BUILDROOT_GLIBC=y
BR2_PACKAGE_RUY_ARCH_SUPPORTS=y
BR2_PACKAGE_RUY=y
BR2_PACKAGE_TENSORFLOW_LITE_ARCH_SUPPORTS=y
BR2_PACKAGE_TENSORFLOW_LITE=y
BR2_TARGET_ROOTFS_SQUASHFS4_XZ=y
```

**Result:** All target architecture, C-library, kernel headers, matrix acceleration (RUY), ML runtime (TensorFlow Lite), and filesystem compression (SquashFS XZ) symbols are 100% active and validated.

---

## 7. Remaining Blockers

1. **Host Prerequisites**:
   The user must install the missing packages before proceeding to Phase 2:
   ```bash
   sudo apt update && sudo apt install -y bison flex cpio libncurses-dev
   ```
2. **Phase 2 Gate**:
   Phase 1 is complete. No expensive compilation has been launched. Awaiting user authorization to begin Phase 2 (Buildroot toolchain and TensorFlow Lite cross-compilation).
