# CUDA Benchmark & Validation Suite

This directory contains the primary demonstration applications for **CUDA-Lite Linux**:

1. **`device_query.cu`**:
   - Enumerates all available CUDA devices via `cudaGetDeviceProperties`.
   - Identifies compute capability (e.g., `sm_89` for RTX 4050 Laptop GPU), streaming multiprocessor (SM) count, total global memory, warp size, clock frequencies, and theoretical peak memory bandwidth.

2. **`matrix_mul.cu`**:
   - Implements a fair CPU vs. GPU matrix multiplication benchmark.
   - Compares:
     - Reference CPU C/C++ nested loops.
     - GPU Naive global-memory kernel.
     - GPU Tiled shared-memory kernel with memory coalescing.
   - Includes warmup cycles and repeated iterations.
   - Profiles explicit data transfer overhead (Host-to-Device and Device-to-Host).
   - Numerically validates GPU output against CPU reference with floating-point tolerance check.
   - Calculates speedup ($Speedup_{kernel} = T_{CPU} / T_{GPU\_kernel}$, $Speedup_{E2E} = T_{CPU} / [T_{Transfer} + T_{GPU\_kernel}]$).

## Compilation
```bash
make clean
make
```

## Running
```bash
# Run device discovery
./device_query

# Run matrix multiplication (default 1024x1024, 5 iterations)
./matrix_mul 1024 5

# Run with larger matrix size (e.g. 2048x2048)
./matrix_mul 2048 5
```
