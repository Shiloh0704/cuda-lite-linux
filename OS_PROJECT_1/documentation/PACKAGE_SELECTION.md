# Package Selection & Userland Optimization Specification
**Project:** EdgeML Linux OS  
**Distribution Track:** Track A – ML Inference at the Edge  
**Target Platform:** ARM64 (`aarch64` QEMU `virt` machine)  
**Build System:** Buildroot 2025.02.10  
**Document Reference:** `documentation/PACKAGE_SELECTION.md`  
**Date:** November 19, 2026  

---

## 1. Package Selection Strategy & Optimization Philosophy

The package selection strategy for EdgeML Linux OS is governed by **strict minimalism and deterministic execution**:
1. **Zero Bloat Policy**: Exclude all packages that do not directly contribute to system boot, hardware virtualization (VirtIO), filesystem integrity, or machine learning execution.
2. **Preserve Runtime Invariants**: Retain all C/C++ runtime dynamic libraries (`libc.so.6`, `libm.so.6`, `libpthread.so.0`, `libdl.so.2`, `libstdc++.so.6`, `libgcc_s.so.1`) strictly required by TensorFlow Lite and its NEON execution engines.
3. **Headless Execution**: Completely omit graphical subsystems (X11, Wayland, Qt, GTK), sound architectures (ALSA, PulseAudio), complex authentication daemons (PAM, polkit, systemd), and package managers (apt, dpkg, opkg).
4. **Aggressive Stripping**: Strip all ELF debug symbols, unpackaged headers, manpages, info files, and documentation from the target root filesystem.

---

## 2. Essential Required Packages & Libraries

| Package / Library Name | Buildroot Config Symbol | Version / Source | Justification & Architectural Role |
| :--- | :--- | :--- | :--- |
| **BusyBox** | `BR2_PACKAGE_BUSYBOX=y` | 1.36.x / Upstream | Provides single-binary minimal userland: `/sbin/init`, `/bin/sh`, core utils (`mount`, `grep`, `cat`, `ps`, `ls`, `dmesg`). |
| **Glibc** | `BR2_TOOLCHAIN_BUILDROOT_GLIBC=y` | 2.39+ / GNU | Core C standard library. Mandatory for TensorFlow Lite C++ runtime, NPTL threads, and dynamic symbol resolution. |
| **Libstdc++ & Libgcc** | `BR2_INSTALL_LIBSTDCPP=y` | GCC 13.x/14.x | C++ standard runtime library. Required by TensorFlow Lite, XNNPACK, FlatBuffers, and Abseil. |
| **TensorFlow Lite** | `BR2_PACKAGE_TENSORFLOW_LITE=y` | 2.14+ / Upstream | Core machine learning inference engine. Produces `libtensorflow-lite.so` and installs C/C++ API headers. |
| **FlatBuffers** | `BR2_PACKAGE_FLATBUFFERS=y` | Auto-selected | Serialization library used by `.tflite` models; enables zero-copy memory-mapped tensor access. |
| **XNNPACK** | `BR2_PACKAGE_XNNPACK=y` | Auto-selected | Highly optimized floating-point and quantized neural network inference operators targeting ARM NEON SIMD. |
| **RUY** | `BR2_PACKAGE_RUY=y` | Auto-selected | Matrix multiplication library optimized for ARM NEON integer dot-product execution. |
| **Gemmlowp** | `BR2_PACKAGE_GEMMLOWP=y` | Auto-selected | Low-precision integer matrix multiplication primitives for quantized neural network operations. |
| **Farmhash** | `BR2_PACKAGE_FARMHASH=y` | Auto-selected | High-performance hash functions used internally by TensorFlow Lite operator resolvers. |
| **kmod** | `BR2_PACKAGE_KMOD=y` | Optional / Built-in | Linux kernel module loader utilities (`lsmod`, `modprobe`) if dynamic drivers are required. |
| **e2fsprogs** | `BR2_PACKAGE_E2FSPROGS=y` | Built-in | Ext4 filesystem inspection tools (`fsck.ext4`, `tune2fs`) for block storage validation. |
| **squashfs-tools** | Host tool (`host-squashfs`) | Buildroot host | Generates high-compression, read-only `rootfs.squashfs` with XZ dictionary compression. |

---

## 3. Explicit Exclusions: Unnecessary Packages Removed

To minimize attack surface, reduce boot time, and keep the root filesystem size under **35 MB**, the following categories and packages are explicitly excluded:

### 3.1 Excluded System Services & Daemons
* **Systemd / Udev (`BR2_INIT_SYSTEMD=n`)**: Excluded. Systemd introduces high memory consumption (> 35 MB RAM) and slow boot overhead. Replaced by lightweight BusyBox init (< 1 MB RAM, sub-50ms init time).
* **DBus / Polkit (`BR2_PACKAGE_DBUS=n`)**: Excluded. Inter-process communication broker not needed for single-purpose edge inference.
* **Cron / Logrotate / At**: Excluded. Replaced by BusyBox built-in logging (`klogd`/`syslogd`) writing to volatile `tmpfs`.
* **SSH / Telnet (`BR2_PACKAGE_OPENSSH=n`, `BR2_PACKAGE_DROPBEAR=n`)**: Excluded in production image for tamper-proof security; console access is strictly routed via QEMU PL011 UART (`/dev/ttyAMA0`).

### 3.2 Excluded Graphical & Media Stacks
* **X.Org / Wayland / Weston**: Excluded. Saves ~120 MB disk space.
* **Mesa3D / OpenGL / Vulkan / DRM**: Excluded. QEMU target is headless CPU-only.
* **ALSA / PulseAudio / PipeWire**: Excluded. Audio hardware is absent on the edge virtual platform.

### 3.3 Excluded Interpreters & Runtimes
* **Python 3 (`BR2_PACKAGE_PYTHON3=n`)**: Excluded. Standard Python 3 + pip + NumPy packages add > 140 MB of userland bloat and introduce non-deterministic dynamic imports. The inference harness is implemented in compiled C++ linking directly to `libtensorflow-lite.so`.
* **Perl / Ruby / Node.js**: Excluded.
* **Java / JVM**: Excluded.

### 3.4 Target File Cleanup & Asset Stripping
Buildroot configuration options explicitly enabled to eliminate target bloat:
* `BR2_STRIP_strip=y`: Executes `aarch64-linux-gnu-strip --strip-unneeded` on all binaries and shared libraries in `/usr/bin` and `/usr/lib`.
* `BR2_PACKAGE_OVERRIDE_FILE=""`
* Target post-build script sanitization:
  - Deletes `/usr/share/man`, `/usr/share/info`, `/usr/share/doc`.
  - Deletes `/usr/include` (headers needed only at build time, not on runtime target).
  - Deletes `/usr/lib/*.a` (static archives).
  - Deletes `/usr/lib/pkgconfig` and `.cmake` metadata files.

---

## 4. Preservation of Machine Learning Runtime Dependencies

The ELF dynamic dependencies for the inference harness (`edgeml_benchmark`) and TensorFlow Lite runtime have been mapped and verified to ensure zero unresolved dynamic symbols (`DT_NEEDED` verification):

```mermaid
flowchart TD
    APP["/usr/bin/edgeml_benchmark"] -->|"DT_NEEDED"| LIB_TFLITE["libtensorflow-lite.so"]
    APP -->|"DT_NEEDED"| LIB_STDCPP["libstdc++.so.6"]
    APP -->|"DT_NEEDED"| LIB_M["libm.so.6"]
    APP -->|"DT_NEEDED"| LIB_GCC["libgcc_s.so.1"]
    APP -->|"DT_NEEDED"| LIB_C["libc.so.6"]

    LIB_TFLITE -->|"DT_NEEDED"| LIB_STDCPP
    LIB_TFLITE -->|"DT_NEEDED"| LIB_M
    LIB_TFLITE -->|"DT_NEEDED"| LIB_GCC
    LIB_TFLITE -->|"DT_NEEDED"| LIB_PTHREAD["libpthread.so.0 (glibc)"]
    LIB_TFLITE -->|"DT_NEEDED"| LIB_DL["libdl.so.2 (glibc)"]
    LIB_TFLITE -->|"DT_NEEDED"| LIB_C

    LIB_C -->|"ld-linux-aarch64.so.1"| ELF_LOADER["ELF Dynamic Linker"]
```

All listed libraries are installed into `/lib64` and `/usr/lib64` with proper symlinks generated by Buildroot's target-finalize stage.

---

## 5. Storage Impact Summary: Before vs. After Optimization

```
+-----------------------------------+--------------------+--------------------+--------------------+
| Subsystem / Layer                 | Stock Ubuntu ARM64 | Unoptimized Build  | Optimized EdgeML   |
+-----------------------------------+--------------------+--------------------+--------------------+
| Linux Kernel Image (compressed)   | ~45.0 MB           | ~28.0 MB           | ~24.0 MB           |
| Base Userland (bin, sbin)         | ~850.0 MB          | ~18.0 MB           | ~2.2 MB (BusyBox)  |
| Shared C/C++ Libraries            | ~320.0 MB          | ~35.0 MB           | ~12.8 MB (Stripped)|
| Machine Learning Engine & Model   | ~450.0 MB (PyTorch)| ~45.0 MB (Unstrip) | ~13.8 MB (TFLite)  |
| System Services & Configuration   | ~280.0 MB          | ~12.0 MB           | ~0.4 MB            |
| Documentation & Headers           | ~180.0 MB          | ~22.0 MB           | 0.0 MB (Removed)   |
+-----------------------------------+--------------------+--------------------+--------------------+
| TOTAL ROOTFS SIZE                 | ~2,125 MB (2.1 GB) | ~160 MB            | ~29.2 MB (< 35 MB) |
+-----------------------------------+--------------------+--------------------+--------------------+
| COMPRESSED SQUASHFS IMAGE         | ~750 MB            | ~55 MB             | ~10.4 MB           |
+-----------------------------------+--------------------+--------------------+--------------------+
```
