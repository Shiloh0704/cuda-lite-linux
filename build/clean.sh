#!/usr/bin/env bash
# CUDA-Lite Linux Build Cleanup Script
# Safely unmounts chroot virtual filesystems and cleans temporary workspace.

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run with sudo: sudo ./build/clean.sh" >&2
    exit 1
fi

BUILD_DIR="/var/tmp/cuda-lite-build"
ROOTFS="$BUILD_DIR/rootfs"

echo "Cleaning up CUDA-Lite Linux temporary build files..."

if [ -d "$ROOTFS" ]; then
    for mp in "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys"; do
        if mountpoint -q "$mp" 2>/dev/null; then
            echo "Unmounting $mp..."
            umount -lf "$mp" || true
        fi
    done

    # Verify no mount remains before deleting directory tree
    for mp in "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys"; do
        if mountpoint -q "$mp" 2>/dev/null; then
            echo "ERROR: Filesystem $mp is still mounted. Aborting directory deletion to protect host." >&2
            exit 1
        fi
    done
fi

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

echo "Cleanup complete."
