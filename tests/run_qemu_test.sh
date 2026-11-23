#!/bin/bash
set -eu

LOGFILE="/tmp/qemu_boot_new.log"
rm -f "$LOGFILE"

ACCEL_OPTS=""
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    ACCEL_OPTS="-enable-kvm -cpu host"
else
    ACCEL_OPTS="-accel tcg -cpu max"
fi

echo "Starting QEMU boot test with 120s timeout..."
timeout 120s qemu-system-x86_64 \
    $ACCEL_OPTS \
    -m 2048 \
    -smp 2 \
    -machine pc \
    -cdrom /mnt/d/cuda-lite-linux.iso \
    -kernel /var/tmp/cuda-lite-build/live_iso/live/vmlinuz \
    -initrd /var/tmp/cuda-lite-build/live_iso/live/initrd \
    -append "boot=live components console=ttyS0,115200 console=tty0 systemd.show_status=1" \
    -display none \
    -serial stdio \
    -global isa-fdc.fdtypeA=none \
    -parallel none \
    -audiodev none,id=snd0 \
    -device virtio-net-pci \
    -no-reboot > "$LOGFILE" 2>&1 || true

echo "QEMU completed."
echo "Log file: $LOGFILE"
echo "Total lines: $(wc -l < "$LOGFILE")"
