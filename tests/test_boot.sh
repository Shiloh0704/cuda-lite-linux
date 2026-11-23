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

# Boot QEMU with 2048 MB RAM, 2 vCPUs, KVM if genuinely accessible, otherwise modern TCG
ACCEL_OPTS=""
ACCEL_DESC=""
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    ACCEL_OPTS="-enable-kvm -cpu host"
    ACCEL_DESC="KVM (Hardware Accelerated, CPU: host)"
else
    # Use modern 64-bit compatible CPU model supported by QEMU TCG
    ACCEL_OPTS="-accel tcg -cpu max"
    ACCEL_DESC="TCG (Software Emulation, CPU: max)"
fi

echo "Acceleration Mode: $ACCEL_DESC"

# Configure graphical display if X11 or Wayland display environment is available
DISPLAY_OPTS="-display none"
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    DISPLAY_OPTS="-display gtk -vga std"
    echo "Display Backend: GTK (graphical window enabled via WSLg/X11)"
else
    echo "Display Backend: none (headless fallback, serial console active)"
fi

# Launch QEMU with 2 vCPUs, 2048 MB RAM, modern CPU, and legacy hardware disabled:
# - Floppy drive disabled via isa-fdc.fdtypeA=none
# - Parallel port disabled via -parallel none
# - PC speaker / audio disabled via -audiodev none
exec qemu-system-x86_64 \
    $ACCEL_OPTS \
    -m 2048 \
    -smp 2 \
    -machine pc \
    -cdrom "$ISO_PATH" \
    -boot d \
    $DISPLAY_OPTS \
    -serial mon:stdio \
    -global isa-fdc.fdtypeA=none \
    -parallel none \
    -audiodev none,id=snd0 \
    -device virtio-net-pci \
    -no-reboot
