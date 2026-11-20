#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Automated Performance & Telemetry Benchmark Suite
# =============================================================================

set -euo pipefail

RESULTS_DIR="/tmp/results"
mkdir -p "$RESULTS_DIR"

echo "====================================================================="
echo "        EdgeML Linux OS: Live Inference Benchmark Suite              "
echo "====================================================================="
echo "Target Platform:     ARM64 QEMU virt (Cortex-A57 CPU Inference)"
echo "Telemetry Dir:       $RESULTS_DIR"
echo "====================================================================="

# Check CPU specifications
echo -e "\n[Telemetry 1/4] Querying CPU Architecture..."
lscpu || cat /proc/cpuinfo | grep -E 'model name|Hardware|Features|processor' | head -n 10

# Check Memory State
echo -e "\n[Telemetry 2/4] Querying Memory Allocation..."
free -m || cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Buffers|Cached'

# Check Storage & OverlayFS
echo -e "\n[Telemetry 3/4] Querying Mount Hierarchy..."
df -h || mount | grep -E 'overlay|squashfs|tmpfs'

# Execute Inference Harness
echo -e "\n[Telemetry 4/4] Executing Inference Engine (50 passes)..."
if [ -x /usr/bin/edgeml_benchmark ]; then
    /usr/bin/edgeml_benchmark /usr/share/models/mobilenet_v2_quant.tflite 50 4
elif [ -f "./application/edgeml_benchmark" ]; then
    ./application/edgeml_benchmark ./models/mobilenet_v2_quant.tflite 50 4
else
    echo "ERROR: edgeml_benchmark binary not found." >&2
    exit 1
fi

echo "====================================================================="
echo "Benchmark run completed. Telemetry exported to $RESULTS_DIR."
