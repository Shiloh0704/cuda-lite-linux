#!/usr/bin/env bash
# CUDA-Lite Linux Benchmark Runner & Telemetry Logger
# Collects CPU/GPU timings, nvidia-smi power/clock telemetry, and system stats.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
LOG_FILE="$RESULTS_DIR/benchmark_run_${TIMESTAMP}.log"
CSV_FILE="$RESULTS_DIR/benchmark_summary_${TIMESTAMP}.csv"

echo "=== CUDA-Lite Linux Benchmark Suite ===" | tee -a "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "Host Kernel: $(uname -r)" | tee -a "$LOG_FILE"

# 1. Capture GPU Telemetry before benchmark
echo -e "\n--- Hardware Telemetry (Pre-run) ---" | tee -a "$LOG_FILE"
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=timestamp,name,driver_version,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used,power.draw \
        --format=csv | tee -a "$LOG_FILE"
fi

# 2. Compile benchmark programs
echo -e "\n--- Building CUDA Benchmark Binaries ---" | tee -a "$LOG_FILE"
make -C "$PROJECT_ROOT/cuda" clean
make -C "$PROJECT_ROOT/cuda"

# 3. Run Device Query
echo -e "\n--- Running CUDA Device Query ---" | tee -a "$LOG_FILE"
"$PROJECT_ROOT/cuda/device_query" | tee -a "$LOG_FILE"

# 4. Run Matrix Multiplication across matrix dimensions
echo -e "\n--- Executing Matrix Multiplication Benchmark Runs ---" | tee -a "$LOG_FILE"
echo "Matrix_Size,CPU_Time_ms,GPU_Tiled_ms,H2D_ms,D2H_ms,Kernel_Speedup,E2E_Speedup" > "$CSV_FILE"

SIZES=(512 1024 2048)

for N in "${SIZES[@]}"; do
    echo -e "\n>>> Testing N = $N..." | tee -a "$LOG_FILE"
    OUT=$("$PROJECT_ROOT/cuda/matrix_mul" "$N" 5)
    echo "$OUT" | tee -a "$LOG_FILE"
    
    # Extract metrics for CSV summary
    CPU_T=$(echo "$OUT" | grep "CPU Average Time:" | awk '{print $4}' || echo "N/A")
    GPU_T=$(echo "$OUT" | grep "GPU Tiled Time:" | awk '{print $4}' || echo "N/A")
    H2D_T=$(echo "$OUT" | grep "Host-to-Device" | awk '{print $4}' || echo "N/A")
    D2H_T=$(echo "$OUT" | grep "Device-to-Host" | awk '{print $4}' || echo "N/A")
    K_SPEED=$(echo "$OUT" | grep "Raw Kernel Compute Speedup:" | awk '{print $5}' | tr -d 'x' || echo "N/A")
    E_SPEED=$(echo "$OUT" | grep "End-to-End System Speedup:" | awk '{print $5}' | tr -d 'x' || echo "N/A")
    
    echo "$N,$CPU_T,$GPU_T,$H2D_T,$D2H_T,$K_SPEED,$E_SPEED" >> "$CSV_FILE"
done

# 5. Capture GPU Telemetry post benchmark
echo -e "\n--- Hardware Telemetry (Post-run) ---" | tee -a "$LOG_FILE"
if command -v nvidia-smi &>/dev/null; then
    nvidia-smi --query-gpu=timestamp,name,driver_version,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used,power.draw \
        --format=csv | tee -a "$LOG_FILE"
fi

echo -e "\nBenchmark Suite Complete! Results recorded to:" | tee -a "$LOG_FILE"
echo "  Raw Log: $LOG_FILE"
echo "  Summary CSV: $CSV_FILE"
