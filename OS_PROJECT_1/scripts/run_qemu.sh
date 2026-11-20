#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Configurable QEMU ARM64 Virtual Machine Runner
# Machine: QEMU virt (ARM64 Cortex-A57, VirtIO block/net, PL011 UART)
# Usage: ./scripts/run_qemu.sh [RAM_MB] [VCPUS] [ROOTFS_PATH]
# Example: ./scripts/run_qemu.sh 1024 4
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_ROOT_WORKSPACE="/mnt/d/buildroot_workspace"
IMAGES_DIR="$BUILD_ROOT_WORKSPACE/output_qemu/images"

# Configurable Parameters with Defaults
RAM_MB="${1:-1024}"
VCPUS="${2:-4}"
CUSTOM_ROOTFS="${3:-}"

KERNEL="$IMAGES_DIR/Image"
SQUASHFS="$IMAGES_DIR/rootfs.squashfs"
EXT4="$IMAGES_DIR/rootfs.ext4"

echo "====================================================================="
echo "              Launching EdgeML Linux OS in QEMU ARM64                "
echo "====================================================================="
echo "Host Time:           $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "Target Architecture: ARM64 (aarch64)"
echo "CPU Model:           Cortex-A57 ($VCPUS vCPUs allocated)"
echo "RAM Allocation:      $RAM_MB MB"
echo "Serial Console:      /dev/ttyAMA0 (Mapped to Terminal Stdout/Stdin)"
echo "Exit Sequence:       Press Ctrl+A then X to terminate QEMU"
echo "====================================================================="

# Step 1: Verify QEMU ARM64 Emulator
if ! command -v qemu-system-aarch64 &>/dev/null; then
    echo "ERROR: qemu-system-aarch64 is not installed or not in PATH." >&2
    echo "Install via: sudo apt update && sudo apt install -y qemu-system-arm" >&2
    exit 1
fi

# Step 2: Verify Kernel Binary
if [ ! -f "$KERNEL" ]; then
    echo "ERROR: Kernel image not found at $KERNEL." >&2
    echo "Please run ./scripts/build.sh to compile the distribution." >&2
    exit 1
fi

# Step 3: Determine Root Filesystem Image
ROOT_DRIVE=""
APPEND_ARGS="console=ttyAMA0 earlycon=pl011,0x09000000 panic=1"

if [ -n "$CUSTOM_ROOTFS" ] && [ -f "$CUSTOM_ROOTFS" ]; then
    echo "Using explicitly specified rootfs: $CUSTOM_ROOTFS"
    ROOT_DRIVE="-drive file=$CUSTOM_ROOTFS,format=raw,if=virtio,readonly=on"
    APPEND_ARGS="$APPEND_ARGS root=/dev/vda ro"
elif [ -f "$SQUASHFS" ]; then
    echo "Using Read-Only SquashFS container: $SQUASHFS"
    ROOT_DRIVE="-drive file=$SQUASHFS,format=raw,if=virtio,readonly=on"
    APPEND_ARGS="$APPEND_ARGS root=/dev/vda ro rootfstype=squashfs"
elif [ -f "$EXT4" ]; then
    echo "Using Ext4 block image: $EXT4"
    ROOT_DRIVE="-drive file=$EXT4,format=raw,if=virtio"
    APPEND_ARGS="$APPEND_ARGS root=/dev/vda ro rootfstype=ext4"
else
    echo "ERROR: No root filesystem image found in $IMAGES_DIR." >&2
    exit 1
fi

# Step 4: Execute QEMU Virtual Machine
exec qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -smp "$VCPUS" \
    -m "${RAM_MB}M" \
    -kernel "$KERNEL" \
    $ROOT_DRIVE \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0 \
    -append "$APPEND_ARGS" \
    -nographic
