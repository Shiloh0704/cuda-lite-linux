#!/usr/bin/env bash
set -euo pipefail

ROOTFS="/var/tmp/cuda-lite-candidate-build/rootfs"

echo "=== 1. Package Status for Container Tools ==="
grep -E '^Package: (docker.io|docker-cli|containerd|runc|nvidia-container-toolkit|libnvidia-container1)' "$ROOTFS/var/lib/dpkg/status" | sort

echo "=== 2. Binaries in Candidate Rootfs ==="
for b in docker dockerd containerd runc nvidia-container-cli nvidia-ctk; do
  which_b=$(find "$ROOTFS/usr/bin" "$ROOTFS/usr/sbin" -name "$b" 2>/dev/null | head -1)
  echo "$b -> $which_b"
done

echo "=== 3. cuDNN Libraries & Headers ==="
ls -lh "$ROOTFS/usr/lib/x86_64-linux-gnu"/libcudnn*.so* | head -5
ls -lh "$ROOTFS/usr/include/x86_64-linux-gnu"/cudnn*.h 2>/dev/null || ls -lh "$ROOTFS/usr/include"/cudnn*.h 2>/dev/null | head -5

echo "=== 4. Boot Directory Kernels ==="
ls -lh "$ROOTFS/boot/"

echo "=== 5. NVIDIA DKMS Modules for Debian Kernel ==="
ls -la "$ROOTFS/usr/lib/modules/6.12.117+deb13-amd64/updates/dkms/"

echo "=== 6. Total Filesystem Size of Candidate Rootfs ==="
du -sh "$ROOTFS"
