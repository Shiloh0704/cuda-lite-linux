#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/tmp/cuda-lite-candidate-build/rootfs"

echo "=== 1. Mounting virtual filesystems ==="
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sys "$ROOTFS/sys"
cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

echo "=== 2. Installing docker.io, containerd, and runc ==="
chroot "$ROOTFS" apt-get update
chroot "$ROOTFS" apt-get install -y --no-install-recommends docker.io containerd runc

echo "=== 3. Installing NVIDIA Container Toolkit ==="
mkdir -p "$ROOTFS/tmp/nvidia-ctk"
cp /var/cache/apt/archives/*nvidia-container* "$ROOTFS/tmp/nvidia-ctk/"
chroot "$ROOTFS" dpkg -i /tmp/nvidia-ctk/*.deb
rm -rf "$ROOTFS/tmp/nvidia-ctk"

echo "=== 4. Configuring Docker and containerd for NVIDIA Runtime ==="
mkdir -p "$ROOTFS/etc/docker" "$ROOTFS/etc/cdi"
cp /etc/docker/daemon.json "$ROOTFS/etc/docker/daemon.json"
cp /etc/cdi/nvidia.yaml "$ROOTFS/etc/cdi/nvidia.yaml" 2>/dev/null || true

chroot "$ROOTFS" systemctl enable containerd
chroot "$ROOTFS" systemctl enable docker

echo "=== 5. Cleaning up APT cache inside candidate rootfs ==="
chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/*"

echo "=== 6. Unmounting virtual filesystems ==="
umount "$ROOTFS/sys"
umount "$ROOTFS/proc"
umount "$ROOTFS/dev/pts"
umount "$ROOTFS/dev"

echo "=== Container stack installation complete ==="
