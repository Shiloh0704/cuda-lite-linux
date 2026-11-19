#!/usr/bin/env bash
# =============================================================================
# CUDA-Lite Linux: Fully Automated, Reproducible Bootable ISO Build Script
# Track C: Application-Specific Linux Distribution for NVIDIA CUDA Computing
# Target Architecture: x86-64 (AMD64)
# =============================================================================

set -euo pipefail

# Ensure script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: build_iso.sh must be executed as root (e.g., sudo ./build_iso.sh or wsl -u root)." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Build paths: Use native Linux ext4 filesystem for chroot & debootstrap
BUILD_DIR="/var/tmp/cuda-lite-build"
ROOTFS="$BUILD_DIR/rootfs"
LIVE_DIR="$BUILD_DIR/live_iso"
OUTPUT_DIR="$PROJECT_ROOT/build"
ISO_NAME="cuda-lite-linux.iso"
TARGET_ISO="$OUTPUT_DIR/$ISO_NAME"

DEBIAN_MIRROR="http://deb.debian.org/debian"
DEBIAN_SUITE="bookworm"

echo "====================================================================="
echo "             CUDA-Lite Linux: Bootable ISO Generator                 "
echo "====================================================================="
echo "Target Architecture:  x86-64 (amd64)"
echo "Debian Release:       $DEBIAN_SUITE"
echo "Working Build Dir:    $BUILD_DIR"
echo "Output ISO:           $TARGET_ISO"
echo "====================================================================="

# Step 0: Clean previous build artifacts
echo -e "\n[Step 0/7] Cleaning previous build environment..."
umount -lf "$ROOTFS/proc" 2>/dev/null || true
umount -lf "$ROOTFS/sys" 2>/dev/null || true
umount -lf "$ROOTFS/dev/pts" 2>/dev/null || true
umount -lf "$ROOTFS/dev" 2>/dev/null || true
rm -rf "$BUILD_DIR"
mkdir -p "$ROOTFS" "$LIVE_DIR/live" "$LIVE_DIR/boot/grub" "$OUTPUT_DIR"

# Step 1: Bootstrap minimal Debian system
echo -e "\n[Step 1/7] Bootstrapping minimal base system with debootstrap..."
debootstrap --arch=amd64 \
    --variant=minbase \
    --include=linux-image-amd64,live-boot,systemd,systemd-sysv,udev,pciutils,kmod,iproute2,isc-dhcp-client,procps,less,nano \
    "$DEBIAN_SUITE" "$ROOTFS" "$DEBIAN_MIRROR"

# Step 2: Configure System, Hostname & Repositories
echo -e "\n[Step 2/7] Configuring system identity, APT repositories, and networking..."
cat << 'EOF' > "$ROOTFS/etc/apt/sources.list"
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

echo "cuda-lite" > "$ROOTFS/etc/hostname"

cat << 'EOF' > "$ROOTFS/etc/hosts"
127.0.0.1   localhost
127.0.1.1   cuda-lite
EOF

# Setup fstab with OverlayFS tmpfs
cp "$PROJECT_ROOT/system/fstab.overlay" "$ROOTFS/etc/fstab"

# Step 3: Apply Security Hardening Measures
echo -e "\n[Step 3/7] Injecting security hardening policies (Requirement E)..."
cp "$PROJECT_ROOT/system/hardening.conf" "$ROOTFS/etc/sysctl.d/99-cuda-lite-hardening.conf"

# Step 4: Install CUDA Application & Autostart Service
echo -e "\n[Step 4/7] Deploying CUDA-Lite autostart benchmark service..."
mkdir -p "$ROOTFS/opt/cuda-lite/bin"

if [ -f "$PROJECT_ROOT/cuda/matrix_mul" ]; then
    cp "$PROJECT_ROOT/cuda/matrix_mul" "$ROOTFS/opt/cuda-lite/bin/"
    cp "$PROJECT_ROOT/cuda/device_query" "$ROOTFS/opt/cuda-lite/bin/"
    chmod +x "$ROOTFS/opt/cuda-lite/bin/"*
fi

cp "$PROJECT_ROOT/system/cuda-lite-autostart.service" "$ROOTFS/etc/systemd/system/"

# Step 5: Mount virtual filesystems & execute chroot setup
echo -e "\n[Step 5/7] Executing chroot configuration & service enablement..."
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sys "$ROOTFS/sys"

chroot "$ROOTFS" /bin/bash << 'CHROOT_EOF'
export DEBIAN_FRONTEND=noninteractive
apt-get update
# Enable autostart service
systemctl enable cuda-lite-autostart.service 2>/dev/null || true
# Set root password to 'cudalite' for safe diagnostic access
echo "root:cudalite" | chpasswd
# Clean package caches to ensure absolute minimum image footprint
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CHROOT_EOF

# Safely unmount chroot filesystems
umount -lf "$ROOTFS/proc"
umount -lf "$ROOTFS/sys"
umount -lf "$ROOTFS/dev/pts"
umount -lf "$ROOTFS/dev"

# Step 6: Compress Root Filesystem into SquashFS
echo -e "\n[Step 6/7] Compressing rootfs into immutable SquashFS (Lowerdir)..."
mksquashfs "$ROOTFS" "$LIVE_DIR/live/filesystem.squashfs" \
    -comp xz -Xbcj x86 -b 1048576 -noappend

# Copy kernel and initrd from chroot into live ISO boot directory
cp "$ROOTFS/boot/vmlinuz-"* "$LIVE_DIR/live/vmlinuz"
cp "$ROOTFS/boot/initrd.img-"* "$LIVE_DIR/live/initrd"

# Configure GRUB for BIOS & UEFI Hybrid Boot
cat << 'EOF' > "$LIVE_DIR/boot/grub/grub.cfg"
set default="0"
set timeout=5

menuentry "CUDA-Lite Linux (Autonomous GPU Compute Node)" {
    linux /live/vmlinuz boot=live components quiet splash
    initrd /live/initrd
}

menuentry "CUDA-Lite Linux (Safe Graphics / Verbose Boot)" {
    linux /live/vmlinuz boot=live components nomodeset verbose
    initrd /live/initrd
}
EOF

# Step 7: Create Hybrid Bootable ISO (BIOS + UEFI)
echo -e "\n[Step 7/7] Generating hybrid bootable ISO image with xorriso..."
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "CUDA_LITE" \
    -eltorito-boot boot/grub/grub.cfg \
    -eltorito-catalog boot.catalog \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -output "$TARGET_ISO" \
    "$LIVE_DIR" 2>/dev/null || \
grub-mkrescue -o "$TARGET_ISO" "$LIVE_DIR"

# Also place copy on drive D if available
if [ -d "/mnt/d" ]; then
    cp "$TARGET_ISO" "/mnt/d/$ISO_NAME" 2>/dev/null || true
fi

echo -e "\n====================================================================="
echo "BUILD SUCCESSFUL!"
echo "ISO Location:     $TARGET_ISO"
if [ -f "/mnt/d/$ISO_NAME" ]; then
    echo "Secondary Backup: /mnt/d/$ISO_NAME"
fi
ls -lh "$TARGET_ISO"
sha256sum "$TARGET_ISO" | tee "$OUTPUT_DIR/checksum.sha256"
echo "====================================================================="
