#!/bin/sh
# Output directly to ttyS0 so serial console captures all guest telemetry
T="/dev/ttyS0"
if [ ! -e "$T" ]; then T="/dev/console"; fi

echo "=== CUDA-LITE CUSTOM KERNEL GUEST TELEMETRY ===" > $T
echo "--- UNAME ---" > $T
uname -a > $T
echo "--- OS-RELEASE ---" > $T
cat /root/etc/os-release > $T
echo "--- LSMOD ---" > $T
lsmod > $T
echo "--- MOUNT ---" > $T
mount > $T
echo "--- OVERLAYFS CHECK ---" > $T
mount | grep -E 'overlay|squashfs' > $T
echo "=== END GUEST TELEMETRY ===" > $T
