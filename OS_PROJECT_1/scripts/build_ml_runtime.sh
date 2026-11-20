#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Buildroot ML Runtime & Distribution Build Automation
# Target Architecture: ARM64 (aarch64) QEMU virt platform
# ML Runtime: TensorFlow Lite 2.14+ (C/C++ API, ARM NEON SIMD)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Safe secondary storage path on Drive D: to protect the constrained C: drive
BUILD_ROOT_WORKSPACE="/mnt/d/buildroot_workspace"
BUILDROOT_DIR="$BUILD_ROOT_WORKSPACE/buildroot-2025.02.10"
OUTPUT_DIR="$BUILD_ROOT_WORKSPACE/output_qemu"
DL_DIR="$BUILD_ROOT_WORKSPACE/dl"

echo "====================================================================="
echo "        EdgeML Linux OS: ML Runtime & Buildroot Pipeline             "
echo "====================================================================="
echo "Project Root:         $PROJECT_ROOT"
echo "Buildroot Source:     $BUILDROOT_DIR"
echo "Output Directory:     $OUTPUT_DIR"
echo "Download Cache:       $DL_DIR"
echo "====================================================================="

# Step 1: Verify Host Dependencies
echo -e "\n[Step 1/6] Checking host prerequisites..."
for tool in make gcc g++ bison flex qemu-system-aarch64; do
    if ! command -v "$tool" &>/dev/null; then
        echo "ERROR: Required host tool '$tool' is not installed." >&2
        echo "Run: sudo apt update && sudo apt install -y qemu-system-arm build-essential bison flex libncurses-dev" >&2
        exit 1
    fi
done
echo "Host prerequisites verified."

# Step 2: Prepare Workspace Directories
echo -e "\n[Step 2/6] Preparing workspace on Drive D:..."
mkdir -p "$BUILD_ROOT_WORKSPACE" "$DL_DIR" "$OUTPUT_DIR"

# Step 3: Stage Rootfs Overlay & Configurations
echo -e "\n[Step 3/6] Staging rootfs overlay and configuration files..."
mkdir -p "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/init.d"
mkdir -p "$PROJECT_ROOT/board/edgeml/rootfs_overlay/usr/share/models"
mkdir -p "$PROJECT_ROOT/board/edgeml/rootfs_overlay/usr/share/images"
mkdir -p "$PROJECT_ROOT/board/edgeml/rootfs_overlay/overlay"
mkdir -p "$PROJECT_ROOT/board/edgeml/rootfs_overlay/ro_root"
mkdir -p "$PROJECT_ROOT/board/edgeml/rootfs_overlay/tmp/results"

# Copy init script
cat << 'EOF' > "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/init.d/rcS"
#!/bin/sh
# EdgeML Linux OS System Initialization & OverlayFS Mount

echo "====================================================="
echo "       Initializing EdgeML Linux OS (ARM64)          "
echo "====================================================="

# Mount essential virtual filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm

# Setup volatile in-memory OverlayFS
echo "[INIT] Mounting volatile tmpfs on /overlay..."
mount -t tmpfs -o mode=0755,size=64M tmpfs /overlay
mkdir -p /overlay/upper /overlay/work /overlay/var_upper /overlay/var_work /tmp/results

# Mount volatile overlay for /var and /tmp to ensure pristine factory resets
mount -t overlay overlay -o lowerdir=/var,upperdir=/overlay/var_upper,workdir=/overlay/var_work /var
mount -t tmpfs -o mode=1777,size=32M tmpfs /tmp

# Configure loopback networking
ifconfig lo 127.0.0.1 up

# Autostart EdgeML benchmark
if [ -x /usr/bin/edgeml_benchmark ]; then
    echo "[INIT] Launching EdgeML Benchmark Harness..."
    /usr/bin/edgeml_benchmark || true
fi

echo "[INIT] Initialization complete. Dropping to console."
EOF
chmod +x "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/init.d/rcS"

# Step 4: Apply Buildroot Configuration
echo -e "\n[Step 4/6] Applying defconfig..."
cp "$PROJECT_ROOT/configs/buildroot_defconfig" "$BUILDROOT_DIR/configs/qemu_aarch64_virt_edgeml_defconfig"

export BR2_DL_DIR="$DL_DIR"
make -C "$BUILDROOT_DIR" O="$OUTPUT_DIR" qemu_aarch64_virt_edgeml_defconfig

# Step 5: Execute Buildroot Compilation
echo -e "\n[Step 5/6] Building toolchain, kernel, and TensorFlow Lite runtime..."
echo "Running parallel build with $(nproc) threads..."
make -C "$OUTPUT_DIR" -j"$(nproc)"

# Step 6: Verify Build Artifacts
echo -e "\n[Step 6/6] Verifying output artifacts..."
IMAGES_DIR="$OUTPUT_DIR/images"
if [ -f "$IMAGES_DIR/Image" ] && [ -f "$IMAGES_DIR/rootfs.squashfs" ]; then
    echo "====================================================================="
    echo "                 BUILD SUCCESSFUL - ARTIFACT REPORT                  "
    echo "====================================================================="
    echo "Kernel Image:      $IMAGES_DIR/Image ($(du -h "$IMAGES_DIR/Image" | awk '{print $1}'))"
    echo "SquashFS RootFS:   $IMAGES_DIR/rootfs.squashfs ($(du -h "$IMAGES_DIR/rootfs.squashfs" | awk '{print $1}'))"
    if [ -f "$OUTPUT_DIR/target/usr/lib/libtensorflow-lite.so" ]; then
        echo "TFLite Shared Lib: $OUTPUT_DIR/target/usr/lib/libtensorflow-lite.so ($(du -h "$OUTPUT_DIR/target/usr/lib/libtensorflow-lite.so" | awk '{print $1}'))"
    fi
    echo "====================================================================="
else
    echo "ERROR: Required images were not produced." >&2
    exit 1
fi
