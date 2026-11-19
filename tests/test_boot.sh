#!/usr/bin/env bash
# CUDA-Lite Linux QEMU Boot Verification Script
# Satisfies Assignment Requirement F: QEMU boot testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ISO_PATH="$PROJECT_ROOT/build/cuda-lite-linux.iso"

if [ ! -f "$ISO_PATH" ]; then
    if [ -f "/mnt/d/cuda-lite-linux.iso" ]; then
        ISO_PATH="/mnt/d/cuda-lite-linux.iso"
    else
        echo "ERROR: ISO image not found at $ISO_PATH. Run build/build_iso.sh first." >&2
        exit 1
    fi
fi

echo "====================================================================="
echo "       CUDA-Lite Linux: QEMU Virtual Machine Boot Test               "
echo "====================================================================="
echo "Target ISO: $ISO_PATH"
echo "RAM Allocated: 2048 MB, Cores: 2"
echo "Press Ctrl+A then X to exit QEMU if running in nographic mode."
echo "====================================================================="

# Boot QEMU with 2 GB RAM, 2 CPU cores, KVM acceleration if supported
ACCEL="-enable-kvm"
if [ ! -e /dev/kvm ]; then
    ACCEL=""
    echo "Notice: KVM hardware acceleration not available inside current nested layer. Using standard TCG emulation."
fi

qemu-system-x86_64 \
    $ACCEL \
    -m 2048 \
    -smp 2 \
    -cdrom "$ISO_PATH" \
    -boot d \
    -display none \
    -serial mon:stdio \
    -device virtio-net-pci \
    -no-reboot
