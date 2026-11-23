#!/usr/bin/env bash
set -euo pipefail

echo "=== 1. Candidate ISO & Checksum ==="
ls -lh /mnt/d/cuda-lite-linux-candidate.iso
cat /mnt/d/cuda-lite-linux-candidate.iso.sha256
stat -c '%s bytes | %y' /mnt/d/cuda-lite-linux-candidate.iso

echo "=== 2. Candidate Live Staging Directory ==="
ls -lh /var/tmp/cuda-lite-candidate-build/live_iso/live/
stat -c '%s bytes | %y' /var/tmp/cuda-lite-candidate-build/live_iso/live/filesystem.squashfs

echo "=== 3. Candidate GRUB Configuration ==="
cat /var/tmp/cuda-lite-candidate-build/live_iso/boot/grub/grub.cfg

echo "=== 4. Original Production ISO Verification (Immutable Check) ==="
ls -lh /mnt/d/cuda-lite-linux.iso
sha256sum /mnt/d/cuda-lite-linux.iso
