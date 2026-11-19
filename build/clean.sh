#!/usr/bin/env bash
# CUDA-Lite Linux Build Cleanup Script

set -euo pipefail

BUILD_DIR="/var/tmp/cuda-lite-build"
ROOTFS="$BUILD_DIR/rootfs"

echo "Cleaning up CUDA-Lite Linux temporary build files..."

if [ -d "$ROOTFS" ]; then
    umount -lf "$ROOTFS/proc" 2>/dev/null || true
    umount -lf "$ROOTFS/sys" 2>/dev/null || true
    umount -lf "$ROOTFS/dev/pts" 2>/dev/null || true
    umount -lf "$ROOTFS/dev" 2>/dev/null || true
fi

rm -rf "$BUILD_DIR"
echo "Cleanup complete."
