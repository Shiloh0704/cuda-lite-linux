#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/var/tmp/cuda-lite-optimization"
ROOTFS="$WORKSPACE/rootfs"
LIVE_DIR="$WORKSPACE/live_iso"
TEMP_ISO="$WORKSPACE/cuda-lite-linux-optimized.iso"
OUTPUT_ISO="/mnt/d/cuda-lite-linux-optimized.iso"
CHECKSUM_FILE="/mnt/d/cuda-lite-linux-optimized.iso.sha256"

echo "=========================================================="
echo "   CUDA-LITE LINUX OPTIMIZED ISO BUILD PROCESS"
echo "=========================================================="

if [[ ! -d "$ROOTFS" ]]; then
    echo "ERROR: Optimized rootfs does not exist at $ROOTFS" >&2
    exit 1
fi

echo "[1/6] Staging live ISO directory structure..."
rm -rf "$LIVE_DIR"
mkdir -p "$LIVE_DIR/live"
mkdir -p "$LIVE_DIR/boot/grub"

echo "[2/6] Copying verified kernel images..."
# 1. Primary Debian kernel with NVIDIA DKMS
cp "$ROOTFS/boot/vmlinuz-6.12.117+deb13-amd64" "$LIVE_DIR/live/vmlinuz"
cp "$ROOTFS/boot/initrd.img-6.12.117+deb13-amd64" "$LIVE_DIR/live/initrd"

# 2. Custom low-latency kernel
cp "$ROOTFS/boot/vmlinuz-6.12.0-cuda-lite" "$LIVE_DIR/live/vmlinuz-custom"
cp "$ROOTFS/boot/initrd-6.12.0-cuda-lite" "$LIVE_DIR/live/initrd-custom"

echo "[3/6] Configuring GRUB bootloader..."
cat > "$LIVE_DIR/boot/grub/grub.cfg" <<'EOF_GRUB'
set default=0
set timeout=5

menuentry "CUDA-Lite Linux Optimized - Default (Debian 6.12.117 with NVIDIA DKMS)" {
    search --no-floppy --file --set=root /live/vmlinuz
    linux /live/vmlinuz boot=live components quiet console=ttyS0 console=tty0
    initrd /live/initrd
}

menuentry "CUDA-Lite Linux Optimized - Custom Kernel (6.12.0-cuda-lite Low-Latency)" {
    search --no-floppy --file --set=root /live/vmlinuz-custom
    linux /live/vmlinuz-custom boot=live components quiet console=ttyS0 console=tty0
    initrd /live/initrd-custom
}

menuentry "CUDA-Lite Linux Optimized - Verbose Recovery Boot" {
    search --no-floppy --file --set=root /live/vmlinuz
    linux /live/vmlinuz boot=live components verbose console=ttyS0 console=tty0
    initrd /live/initrd
}
EOF_GRUB

echo "[4/6] Creating high-density SquashFS filesystem..."
START_SQUASH=$(date +%s)
mksquashfs "$ROOTFS" "$LIVE_DIR/live/filesystem.squashfs" \
    -comp xz \
    -Xbcj x86 \
    -b 1048576 \
    -Xdict-size 100% \
    -noappend \
    -processors 6

END_SQUASH=$(date +%s)
SQUASH_DURATION=$((END_SQUASH - START_SQUASH))
echo "SquashFS generation completed in ${SQUASH_DURATION}s"
ls -lh "$LIVE_DIR/live/filesystem.squashfs"

echo "[5/6] Generating hybrid BIOS/UEFI bootable ISO with grub-mkrescue..."
grub-mkrescue -o "$TEMP_ISO" "$LIVE_DIR"

if [[ ! -s "$TEMP_ISO" ]]; then
    echo "ERROR: Optimized ISO generation failed." >&2
    exit 1
fi

echo "[6/6] Deploying optimized ISO to destination..."
cp "$TEMP_ISO" "$OUTPUT_ISO"
sha256sum "$OUTPUT_ISO" > "$CHECKSUM_FILE"

echo "=========================================================="
echo "   OPTIMIZATION ISO BUILD COMPLETE"
echo "=========================================================="
ls -lh "$OUTPUT_ISO"
cat "$CHECKSUM_FILE"

# Metrics summary
ROOTFS_BYTES=$(du -sb "$ROOTFS" | cut -f1)
SQUASH_BYTES=$(stat -c%s "$LIVE_DIR/live/filesystem.squashfs")
ISO_BYTES=$(stat -c%s "$OUTPUT_ISO")
BASELINE_BYTES=4020000000
TARGET_MAX_BYTES=2412000000

echo ""
echo "=== METRICS SUMMARY ==="
echo "Uncompressed Rootfs:  $ROOTFS_BYTES bytes ($(awk "BEGIN {printf \"%.2f\", $ROOTFS_BYTES/1073741824}") GiB)"
echo "SquashFS Compressed:  $SQUASH_BYTES bytes ($(awk "BEGIN {printf \"%.2f\", $SQUASH_BYTES/1073741824}") GiB)"
echo "Final ISO Size:       $ISO_BYTES bytes ($(awk "BEGIN {printf \"%.2f\", $ISO_BYTES/1073741824}") GiB, $(awk "BEGIN {printf \"%.2f\", $ISO_BYTES/1000000000}") GB)"
echo "Stock Ubuntu Base:    $BASELINE_BYTES bytes (4.02 GB)"
echo "40% Target Max:       $TARGET_MAX_BYTES bytes (2.412 GB)"

REDUCTION_PCT=$(awk "BEGIN {printf \"%.2f\", (1 - ($ISO_BYTES / $BASELINE_BYTES)) * 100}")
echo "Reduction vs Stock:   ${REDUCTION_PCT}%"

if [ "$ISO_BYTES" -le "$TARGET_MAX_BYTES" ]; then
    echo "TARGET STATUS:        PASSED (Size <= 2,412,000,000 bytes by $(awk "BEGIN {printf \"%.2f\", ($TARGET_MAX_BYTES - $ISO_BYTES)/1048576}") MB)"
else
    echo "TARGET STATUS:        SHORTFALL by $(awk "BEGIN {printf \"%.2f\", ($ISO_BYTES - $TARGET_MAX_BYTES)/1048576}") MB"
fi
