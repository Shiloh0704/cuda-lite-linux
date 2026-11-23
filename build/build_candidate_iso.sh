#!/usr/bin/env bash
set -euo pipefail

CANDIDATE_BUILD_DIR="/var/tmp/cuda-lite-candidate-build"
CANDIDATE_ROOTFS="$CANDIDATE_BUILD_DIR/rootfs"
CANDIDATE_LIVE_DIR="$CANDIDATE_BUILD_DIR/live_iso"
TEMP_ISO="$CANDIDATE_BUILD_DIR/cuda-lite-linux-candidate.iso"
OUTPUT_ISO="/mnt/d/cuda-lite-linux-candidate.iso"
CHECKSUM_FILE="/mnt/d/cuda-lite-linux-candidate.iso.sha256"

echo "=== 1. Preparing staging live directories ==="
rm -rf "$CANDIDATE_LIVE_DIR"
mkdir -p "$CANDIDATE_LIVE_DIR/live"
mkdir -p "$CANDIDATE_LIVE_DIR/boot/grub"

echo "=== 2. Copying primary and experimental kernels ==="
# Primary Debian production kernel
cp "$CANDIDATE_ROOTFS/boot/vmlinuz-6.12.117+deb13-amd64" "$CANDIDATE_LIVE_DIR/live/vmlinuz"
cp "$CANDIDATE_ROOTFS/boot/initrd.img-6.12.117+deb13-amd64" "$CANDIDATE_LIVE_DIR/live/initrd"

# Custom experimental low-latency kernel
cp "$CANDIDATE_ROOTFS/boot/vmlinuz-6.12.0-cuda-lite" "$CANDIDATE_LIVE_DIR/live/vmlinuz-custom"
cp "$CANDIDATE_ROOTFS/boot/initrd-6.12.0-cuda-lite" "$CANDIDATE_LIVE_DIR/live/initrd-custom"

echo "=== 3. Writing GRUB configuration ==="
cat > "$CANDIDATE_LIVE_DIR/boot/grub/grub.cfg" <<'EOF_GRUB'
set default=0
set timeout=5

menuentry "CUDA-Lite Linux Candidate - Default (Debian 6.12.117 with NVIDIA DKMS)" {
    search --no-floppy --file --set=root /live/vmlinuz
    linux /live/vmlinuz boot=live components quiet console=ttyS0 console=tty0
    initrd /live/initrd
}

menuentry "CUDA-Lite Linux Candidate - Custom Kernel (6.12.0-cuda-lite Low-Latency)" {
    search --no-floppy --file --set=root /live/vmlinuz-custom
    linux /live/vmlinuz-custom boot=live components quiet console=ttyS0 console=tty0
    initrd /live/initrd-custom
}

menuentry "CUDA-Lite Linux Candidate - Verbose Recovery Boot" {
    search --no-floppy --file --set=root /live/vmlinuz
    linux /live/vmlinuz boot=live components verbose console=ttyS0 console=tty0
    initrd /live/initrd
}
EOF_GRUB

echo "=== 4. Creating compressed SquashFS root filesystem ==="
mksquashfs "$CANDIDATE_ROOTFS" "$CANDIDATE_LIVE_DIR/live/filesystem.squashfs" \
    -comp xz \
    -Xbcj x86 \
    -b 1048576 \
    -noappend \
    -processors 4

echo "=== 5. Creating BIOS/UEFI bootable hybrid candidate ISO ==="
grub-mkrescue -o "$TEMP_ISO" "$CANDIDATE_LIVE_DIR"

if [[ ! -s "$TEMP_ISO" ]]; then
    echo "ERROR: Candidate ISO generation failed." >&2
    exit 1
fi

echo "=== 6. Deploying candidate ISO to Drive D: ==="
cp "$TEMP_ISO" "$OUTPUT_ISO"
sha256sum "$OUTPUT_ISO" > "$CHECKSUM_FILE"

echo "=== Candidate ISO generated successfully! ==="
ls -lh "$OUTPUT_ISO"
cat "$CHECKSUM_FILE"
