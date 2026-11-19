#!/usr/bin/env bash
# CUDA-Lite Linux CUDA Application & GPU Driver Test Script
# Satisfies Assignment Requirement F: End-to-end CUDA testing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "====================================================================="
echo "       CUDA-Lite Linux: End-to-End CUDA Validation Test              "
echo "====================================================================="

# Check nvidia-smi
echo -n "[Test 1/4] Checking NVIDIA Driver & SMI Presence: "
if command -v nvidia-smi &>/dev/null; then
    echo "PASSED"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
    echo "FAILED: nvidia-smi command not found."
    exit 1
fi

# Check CUDA compiler
echo -n "[Test 2/4] Checking NVCC CUDA Compiler: "
if command -v nvcc &>/dev/null; then
    echo "PASSED"
    nvcc --version | grep "release"
else
    echo "FAILED: nvcc compiler not found."
    exit 1
fi

# Test Device Query
echo -e "\n[Test 3/4] Running Device Query Test:"
if [ -x "$PROJECT_ROOT/cuda/device_query" ]; then
    "$PROJECT_ROOT/cuda/device_query"
else
    echo "Building device_query first..."
    make -C "$PROJECT_ROOT/cuda" device_query
    "$PROJECT_ROOT/cuda/device_query"
fi

# Test Matrix Multiplication (512x512 quick verification)
echo -e "\n[Test 4/4] Executing CUDA Matrix Multiplication Verification (N=512):"
if [ -x "$PROJECT_ROOT/cuda/matrix_mul" ]; then
    "$PROJECT_ROOT/cuda/matrix_mul" 512 2
else
    echo "Building matrix_mul first..."
    make -C "$PROJECT_ROOT/cuda" matrix_mul
    "$PROJECT_ROOT/cuda/matrix_mul" 512 2
fi

echo -e "\n====================================================================="
echo "All CUDA Validation Tests PASSED Successfully!"
echo "====================================================================="
