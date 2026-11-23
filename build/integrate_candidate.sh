#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/tmp/cuda-lite-candidate-build/rootfs"

echo "=== 1. Copying package archives to candidate rootfs ==="
mkdir -p "$ROOTFS/tmp/debs"
cp /var/cache/apt/archives/containerd_*.deb "$ROOTFS/tmp/debs/"
cp /var/cache/apt/archives/docker.io_*.deb "$ROOTFS/tmp/debs/"
cp /var/cache/apt/archives/runc_*.deb "$ROOTFS/tmp/debs/"
cp /var/cache/apt/archives/libnvidia-container*.deb "$ROOTFS/tmp/debs/"
cp /var/cache/apt/archives/nvidia-container-toolkit*.deb "$ROOTFS/tmp/debs/"

echo "=== 2. Mounting virtual filesystems for chroot ==="
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sys "$ROOTFS/sys"
cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"

echo "=== 3. Installing Container Packages in chroot ==="
chroot "$ROOTFS" dpkg -i --force-depends /tmp/debs/*.deb || true
chroot "$ROOTFS" apt-get update || true
chroot "$ROOTFS" apt-get install -f -y

rm -rf "$ROOTFS/tmp/debs"

echo "=== 4. Integrating cuDNN 9 Shared Libraries and Headers ==="
cp -d /usr/lib/x86_64-linux-gnu/libcudnn*.so* "$ROOTFS/usr/lib/x86_64-linux-gnu/"
mkdir -p "$ROOTFS/usr/include/x86_64-linux-gnu"
cp -d /usr/include/x86_64-linux-gnu/cudnn*.h "$ROOTFS/usr/include/x86_64-linux-gnu/" 2>/dev/null || true
cp -d /usr/include/cudnn*.h "$ROOTFS/usr/include/" 2>/dev/null || true

echo "/usr/lib/x86_64-linux-gnu" > "$ROOTFS/etc/ld.so.conf.d/cuda-lite-cudnn.conf"
chroot "$ROOTFS" ldconfig

echo "=== 5. Integrating Test Binaries and Container Configs ==="
mkdir -p "$ROOTFS/opt/cuda-lite/bin"
cp /mnt/c/Users/shilo/OneDrive/OS_Project/packages/cudnn/test_cudnn "$ROOTFS/opt/cuda-lite/bin/test_cudnn"
chmod 755 "$ROOTFS/opt/cuda-lite/bin/test_cudnn"

cp /mnt/c/Users/shilo/OneDrive/OS_Project/packages/container/test_gpu_container.sh "$ROOTFS/opt/cuda-lite/bin/test_container.sh"
chmod 755 "$ROOTFS/opt/cuda-lite/bin/test_container.sh"

mkdir -p "$ROOTFS/etc/docker" "$ROOTFS/etc/cdi"
cp /etc/docker/daemon.json "$ROOTFS/etc/docker/daemon.json" 2>/dev/null || true
cp /etc/cdi/nvidia.yaml "$ROOTFS/etc/cdi/nvidia.yaml" 2>/dev/null || true

echo "=== 6. Configuring System Services and Hardening ==="
chroot "$ROOTFS" systemctl enable containerd 2>/dev/null || true
chroot "$ROOTFS" systemctl enable docker 2>/dev/null || true

cp /mnt/c/Users/shilo/OneDrive/OS_Project/system/71-nvidia-dev-permissions.rules "$ROOTFS/etc/udev/rules.d/" 2>/dev/null || true
cp /mnt/c/Users/shilo/OneDrive/OS_Project/system/hardening.conf "$ROOTFS/etc/sysctl.d/99-cuda-lite-hardening.conf" 2>/dev/null || true

echo "=== 7. Cleaning up mounts ==="
umount "$ROOTFS/sys"
umount "$ROOTFS/proc"
umount "$ROOTFS/dev/pts"
umount "$ROOTFS/dev"

echo "=== Candidate Rootfs Integration Complete! ==="
