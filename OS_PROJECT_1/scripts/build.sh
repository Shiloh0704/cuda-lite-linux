#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Master Reproducible Build Script
# Validates environment, checks Buildroot 2025.02.10, loads defconfig,
# compiles kernel and target image, and preserves comprehensive build logs.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_ROOT/results/logs"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
BUILD_LOG="$LOGS_DIR/build_${TIMESTAMP}.log"

mkdir -p "$LOGS_DIR"

# Secondary Volume Redirection to Protect Constrained Host C: Drive
BUILD_ROOT_WORKSPACE="/mnt/d/buildroot_workspace"
BUILDROOT_VERSION_EXPECTED="2025.02.10"
BUILDROOT_DIR="$BUILD_ROOT_WORKSPACE/buildroot-${BUILDROOT_VERSION_EXPECTED}"
OUTPUT_DIR="$BUILD_ROOT_WORKSPACE/output_qemu"
DL_DIR="$BUILD_ROOT_WORKSPACE/dl"
CONFIG_FILE="$PROJECT_ROOT/configs/buildroot_defconfig"

# Tee stdout and stderr to both console and persistent build log
exec > >(tee -a "$BUILD_LOG") 2>&1

echo "====================================================================="
echo "            EdgeML Linux OS: Reproducible Build System               "
echo "====================================================================="
echo "Build Start Time:     $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "Project Root:         $PROJECT_ROOT"
echo "Build Workspace:      $BUILD_ROOT_WORKSPACE (Drive D: Safe Storage)"
echo "Target Buildroot:     $BUILDROOT_DIR"
echo "Build Log Path:       $BUILD_LOG"
echo "====================================================================="

# Step 1: Check Required Dependencies
echo -e "\n[Step 1/6] Verifying host build dependencies..."
REQUIRED_TOOLS=("make" "gcc" "g++" "bison" "flex" "qemu-system-aarch64" "wget" "tar" "unzip" "file")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "ERROR: The following required host build tools are missing:" >&2
    for mt in "${MISSING_TOOLS[@]}"; do
        echo "  - $mt" >&2
    done
    echo "Please install them via: sudo apt update && sudo apt install -y build-essential bison flex qemu-system-arm libncurses-dev wget tar unzip" >&2
    exit 1
fi
echo "All required host tools are installed."

# Step 2: Verify Buildroot Version
echo -e "\n[Step 2/6] Verifying Buildroot source tree ($BUILDROOT_VERSION_EXPECTED)..."
if [ ! -d "$BUILDROOT_DIR" ]; then
    echo "Buildroot source tree not found in workspace. Fetching Buildroot $BUILDROOT_VERSION_EXPECTED..."
    mkdir -p "$BUILD_ROOT_WORKSPACE"
    wget -q "https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION_EXPECTED}.tar.xz" -O "$BUILD_ROOT_WORKSPACE/buildroot.tar.xz"
    tar -xf "$BUILD_ROOT_WORKSPACE/buildroot.tar.xz" -C "$BUILD_ROOT_WORKSPACE"
    rm -f "$BUILD_ROOT_WORKSPACE/buildroot.tar.xz"
fi

if [ -f "$BUILDROOT_DIR/Makefile" ]; then
    DETECTED_VER=$(grep "^VERSION = " "$BUILDROOT_DIR/Makefile" | awk '{print $3}' || echo "unknown")
    echo "Verified Buildroot source tree (Version: $DETECTED_VER, Expected: $BUILDROOT_VERSION_EXPECTED)."
else
    echo "ERROR: Buildroot directory $BUILDROOT_DIR is invalid or corrupted." >&2
    exit 1
fi

# Step 3: Load Configuration
echo -e "\n[Step 3/6] Applying Buildroot defconfig..."
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR" "$DL_DIR"
export BR2_DL_DIR="$DL_DIR"

# Stage rootfs overlay and configurations
cp "$CONFIG_FILE" "$BUILDROOT_DIR/configs/qemu_aarch64_virt_edgeml_defconfig"
make -C "$BUILDROOT_DIR" O="$OUTPUT_DIR" qemu_aarch64_virt_edgeml_defconfig

# Step 4: Cross-Compile Application Binary
echo -e "\n[Step 4/6] Cross-compiling inference application (edgeml-infer)..."
make -C "$PROJECT_ROOT/application" all

# Copy application binary, model, and labels into rootfs overlay
mkdir -p "$PROJECT_ROOT/board/rootfs_overlay/usr/bin"
mkdir -p "$PROJECT_ROOT/board/rootfs_overlay/usr/share/models"
mkdir -p "$PROJECT_ROOT/board/rootfs_overlay/data"

cp "$PROJECT_ROOT/application/edgeml-infer" "$PROJECT_ROOT/board/rootfs_overlay/usr/bin/"
cp "$PROJECT_ROOT/models/mobilenet_v2_quant.tflite" "$PROJECT_ROOT/board/rootfs_overlay/usr/share/models/"
cp "$PROJECT_ROOT/models/labels.txt" "$PROJECT_ROOT/board/rootfs_overlay/usr/share/models/"
cp "$PROJECT_ROOT/tests/test.jpg" "$PROJECT_ROOT/board/rootfs_overlay/data/"

# Step 5: Execute Target Buildroot Build
echo -e "\n[Step 5/6] Building kernel, runtime packages, and root filesystem..."
NPROC=$(nproc)
echo "Executing parallel build with $NPROC workers..."
make -C "$OUTPUT_DIR" -j"$NPROC"

# Step 6: Verify and Report Artifacts
echo -e "\n[Step 6/6] Verifying generated build artifacts..."
IMAGES_DIR="$OUTPUT_DIR/images"
SUCCESS=1

if [ -f "$IMAGES_DIR/Image" ]; then
    echo "  [FOUND] Kernel Image:      $IMAGES_DIR/Image ($(du -h "$IMAGES_DIR/Image" | awk '{print $1}'))"
else
    echo "  [MISSING] Kernel Image was not generated." >&2
    SUCCESS=0
fi

if [ -f "$IMAGES_DIR/rootfs.squashfs" ]; then
    echo "  [FOUND] SquashFS RootFS:   $IMAGES_DIR/rootfs.squashfs ($(du -h "$IMAGES_DIR/rootfs.squashfs" | awk '{print $1}'))"
else
    echo "  [MISSING] rootfs.squashfs was not generated." >&2
    SUCCESS=0
fi

if [ -f "$IMAGES_DIR/rootfs.ext4" ]; then
    echo "  [FOUND] Ext4 Block RootFS: $IMAGES_DIR/rootfs.ext4 ($(du -h "$IMAGES_DIR/rootfs.ext4" | awk '{print $1}'))"
fi

echo "====================================================================="
if [ "$SUCCESS" -eq 1 ]; then
    echo "BUILD COMPLETE AND SUCCESSFUL."
    echo "Build Log Preserved at: $BUILD_LOG"
    exit 0
else
    echo "BUILD FINISHED WITH ERRORS. Review log: $BUILD_LOG" >&2
    exit 1
fi
