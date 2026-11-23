#!/bin/bash
# CUDA-Lite startup diagnostic and benchmark launcher

set -u

CUDA_BIN="/opt/cuda-lite/bin"

echo "================================================"
echo "       CUDA-Lite Linux - Startup Diagnostic"
echo "================================================"

# Hardware-aware check: verify NVIDIA PCI vendor ID (0x10de) in sysfs or lspci
HAS_NVIDIA=0
if grep -qs "0x10de" /sys/bus/pci/devices/*/vendor 2>/dev/null; then
    HAS_NVIDIA=1
elif command -v lspci >/dev/null 2>&1 && [ -n "$(lspci -d 10de: 2>/dev/null)" ]; then
    HAS_NVIDIA=1
fi

if [ "$HAS_NVIDIA" -eq 0 ]; then
    echo "Notice: No NVIDIA PCI device detected on the bus (virtual/QEMU environment)."
    echo "CUDA diagnostic benchmark skipped."
    exit 0
fi

echo "NVIDIA PCI device detected. Ensuring driver modules are loaded..."
modprobe nvidia 2>/dev/null || true
modprobe nvidia_uvm 2>/dev/null || true
modprobe nvidia_modeset 2>/dev/null || true
modprobe nvidia_drm 2>/dev/null || true

# Check NVIDIA utility.
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "WARNING: nvidia-smi is not installed."
    echo "CUDA benchmark skipped."
    exit 0
fi

# Check whether an NVIDIA GPU and driver are available.
if ! nvidia-smi >/dev/null 2>&1; then
    echo "WARNING: NVIDIA GPU or driver is unavailable."
    echo "CUDA benchmark skipped."
    exit 0
fi

# Show GPU status
nvidia-smi

# Run CUDA device query.
echo
echo "Running CUDA device query..."

if [ -x "$CUDA_BIN/device_query" ]; then
    if ! "$CUDA_BIN/device_query"; then
        echo "ERROR: CUDA device query failed."
        exit 1
    fi
else
    echo "WARNING: $CUDA_BIN/device_query not found or not executable."
fi

# Run matrix multiplication benchmark.
echo
echo "Running CUDA matrix multiplication benchmark..."

if [ -x "$CUDA_BIN/matrix_mul" ]; then
    if ! "$CUDA_BIN/matrix_mul" 1024 5; then
        echo "ERROR: CUDA matrix multiplication benchmark failed."
        exit 1
    fi
else
    echo "WARNING: $CUDA_BIN/matrix_mul not found or not executable."
fi

echo
echo "CUDA-Lite startup benchmark completed."
exit 0
