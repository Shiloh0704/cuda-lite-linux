/*
 * CUDA-Lite Linux - Fair CPU vs GPU Matrix Multiplication Benchmark
 * Track C: Application-specific Linux distribution for NVIDIA CUDA/GPU computing
 *
 * Implements:
 * 1. Single-threaded reference CPU matrix multiplication (C = A * B).
 * 2. GPU Naive Matrix Multiplication kernel.
 * 3. GPU Shared-Memory Tiled Matrix Multiplication kernel (optimized memory coalescing).
 * 4. Rigorous warmup cycles, repeated measurement iterations, Host-to-Device / Device-to-Host
 *    transfer overhead profiling, numerical verification (norm difference), and GFLOPS computation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <chrono>
#include <cuda_runtime.h>

#define TILE_WIDTH 16

// Error checking macro
#define CUDA_CHECK(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA error at %s:%d - %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            exit(EXIT_FAILURE); \
        } \
    } while (0)

// High-resolution CPU timer
double get_wall_time() {
    auto now = std::chrono::high_resolution_clock::now();
    auto duration = now.time_since_epoch();
    return std::chrono::duration<double, std::milli>(duration).count();
}

// Initialize matrices with reproducible pseudo-random values
void init_matrix(float *mat, int N, unsigned int seed) {
    srand(seed);
    for (int i = 0; i < N * N; ++i) {
        mat[i] = (float)rand() / (float)RAND_MAX * 2.0f - 1.0f;
    }
}

// CPU reference matrix multiplication: C = A * B
void cpu_matrix_mult(const float *A, const float *B, float *C, int N) {
    for (int i = 0; i < N; ++i) {
        for (int k = 0; k < N; ++k) {
            float a = A[i * N + k];
            for (int j = 0; j < N; ++j) {
                C[i * N + j] += a * B[k * N + j];
            }
        }
    }
}

// GPU Kernel 1: Naive Global Memory Matrix Multiplication
__global__ void gpu_matrix_mult_naive(const float *A, const float *B, float *C, int N) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < N && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < N; ++k) {
            sum += A[row * N + k] * B[k * N + col];
        }
        C[row * N + col] = sum;
    }
}

// GPU Kernel 2: Tiled Shared-Memory Matrix Multiplication
__global__ void gpu_matrix_mult_tiled(const float *A, const float *B, float *C, int N) {
    __shared__ float s_A[TILE_WIDTH][TILE_WIDTH];
    __shared__ float s_B[TILE_WIDTH][TILE_WIDTH];

    int bx = blockIdx.x, by = blockIdx.y;
    int tx = threadIdx.x, ty = threadIdx.y;

    int row = by * TILE_WIDTH + ty;
    int col = bx * TILE_WIDTH + tx;

    float sum = 0.0f;

    for (int ph = 0; ph < (N + TILE_WIDTH - 1) / TILE_WIDTH; ++ph) {
        if (row < N && (ph * TILE_WIDTH + tx) < N)
            s_A[ty][tx] = A[row * N + ph * TILE_WIDTH + tx];
        else
            s_A[ty][tx] = 0.0f;

        if (col < N && (ph * TILE_WIDTH + ty) < N)
            s_B[ty][tx] = B[(ph * TILE_WIDTH + ty) * N + col];
        else
            s_B[ty][tx] = 0.0f;

        __syncthreads();

        for (int k = 0; k < TILE_WIDTH; ++k) {
            sum += s_A[ty][k] * s_B[k][tx];
        }

        __syncthreads();
    }

    if (row < N && col < N) {
        C[row * N + col] = sum;
    }
}

// Verify output correctness between CPU and GPU
bool verify_results(const float *ref, const float *test, int N, float tolerance = 1e-3f) {
    float max_diff = 0.0f;
    for (int i = 0; i < N * N; ++i) {
        float diff = fabsf(ref[i] - test[i]);
        if (diff > max_diff) {
            max_diff = diff;
        }
        if (diff > tolerance) {
            printf("Verification FAILED at index %d: CPU=%f, GPU=%f (diff=%f)\n",
                   i, ref[i], test[i], diff);
            return false;
        }
    }
    printf("Verification PASSED (Max absolute difference: %e, tolerance: %e)\n", max_diff, tolerance);
    return true;
}

int main(int argc, char **argv) {
    int N = 1024; // Default dimension (N x N)
    int iterations = 5;
    int warmup_runs = 2;

    if (argc > 1) N = atoi(argv[1]);
    if (argc > 2) iterations = atoi(argv[2]);

    size_t size_bytes = (size_t)N * N * sizeof(float);
    double gflops_per_mult = 2.0 * (double)N * (double)N * (double)N * 1e-9;

    printf("====================================================================\n");
    printf("     CUDA-Lite Linux: CPU vs GPU Matrix Multiplication Benchmark    \n");
    printf("====================================================================\n");

    // Display Device Info
    int dev = 0;
    CUDA_CHECK(cudaSetDevice(dev));
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, dev));
    printf("Target GPU:            %s (Compute %d.%d, %d SMs)\n", prop.name, prop.major, prop.minor, prop.multiProcessorCount);
    printf("Matrix Dimensions:     %d x %d (Single Precision FP32)\n", N, N);
    printf("Memory per Matrix:     %.2f MB (Total for A, B, C: %.2f MB)\n",
           (float)size_bytes / (1024.0f * 1024.0f), (float)(3 * size_bytes) / (1024.0f * 1024.0f));
    printf("Operations per Run:    %.4f GFLOP (2 * N^3)\n", gflops_per_mult);
    printf("Benchmark Iterations:  %d (Warmup runs: %d)\n", iterations, warmup_runs);
    printf("--------------------------------------------------------------------\n");

    // Allocate Host Memory
    float *h_A = (float*)malloc(size_bytes);
    float *h_B = (float*)malloc(size_bytes);
    float *h_C_cpu = (float*)calloc(N * N, sizeof(float));
    float *h_C_gpu_naive = (float*)malloc(size_bytes);
    float *h_C_gpu_tiled = (float*)malloc(size_bytes);

    if (!h_A || !h_B || !h_C_cpu || !h_C_gpu_naive || !h_C_gpu_tiled) {
        fprintf(stderr, "Host memory allocation failed!\n");
        return 1;
    }

    init_matrix(h_A, N, 42);
    init_matrix(h_B, N, 1337);

    // 1. CPU Reference Execution (Measured)
    printf("\n[1/3] Benchmarking Reference CPU (C/C++ loops)...\n");
    double cpu_total_time = 0.0;
    
    // Warmup CPU
    cpu_matrix_mult(h_A, h_B, h_C_cpu, N);
    
    // CPU timing iterations (for large N, keep iterations reasonable)
    int cpu_runs = (N >= 2048) ? 1 : iterations;
    for (int it = 0; it < cpu_runs; ++it) {
        memset(h_C_cpu, 0, size_bytes);
        double t_start = get_wall_time();
        cpu_matrix_mult(h_A, h_B, h_C_cpu, N);
        double t_end = get_wall_time();
        cpu_total_time += (t_end - t_start);
    }
    double cpu_avg_ms = cpu_total_time / cpu_runs;
    double cpu_gflops = gflops_per_mult / (cpu_avg_ms * 1e-3);
    printf("      CPU Average Time:  %10.2f ms  |  Performance: %8.2f GFLOPS\n", cpu_avg_ms, cpu_gflops);

    // Allocate Device Memory
    float *d_A, *d_B, *d_C;
    CUDA_CHECK(cudaMalloc((void**)&d_A, size_bytes));
    CUDA_CHECK(cudaMalloc((void**)&d_B, size_bytes));
    CUDA_CHECK(cudaMalloc((void**)&d_C, size_bytes));

    cudaEvent_t start_event, stop_event;
    CUDA_CHECK(cudaEventCreate(&start_event));
    CUDA_CHECK(cudaEventCreate(&stop_event));

    dim3 threadsPerBlock(TILE_WIDTH, TILE_WIDTH);
    dim3 numBlocks((N + TILE_WIDTH - 1) / TILE_WIDTH, (N + TILE_WIDTH - 1) / TILE_WIDTH);

    // Profile Data Transfer: Host to Device (H2D)
    CUDA_CHECK(cudaEventRecord(start_event));
    CUDA_CHECK(cudaMemcpy(d_A, h_A, size_bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_B, h_B, size_bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaEventRecord(stop_event));
    CUDA_CHECK(cudaEventSynchronize(stop_event));
    float h2d_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&h2d_ms, start_event, stop_event));

    // 2. GPU Naive Kernel Benchmark
    printf("\n[2/3] Benchmarking GPU Naive Global Memory Kernel...\n");
    // Warmup
    for (int w = 0; w < warmup_runs; ++w) {
        gpu_matrix_mult_naive<<<numBlocks, threadsPerBlock>>>(d_A, d_B, d_C, N);
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    float gpu_naive_total_ms = 0.0f;
    for (int it = 0; it < iterations; ++it) {
        CUDA_CHECK(cudaEventRecord(start_event));
        gpu_matrix_mult_naive<<<numBlocks, threadsPerBlock>>>(d_A, d_B, d_C, N);
        CUDA_CHECK(cudaEventRecord(stop_event));
        CUDA_CHECK(cudaEventSynchronize(stop_event));
        float iter_ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&iter_ms, start_event, stop_event));
        gpu_naive_total_ms += iter_ms;
    }
    float gpu_naive_avg_ms = gpu_naive_total_ms / iterations;
    double gpu_naive_gflops = gflops_per_mult / (gpu_naive_avg_ms * 1e-3);
    printf("      GPU Naive Time:    %10.2f ms  |  Performance: %8.2f GFLOPS\n", gpu_naive_avg_ms, gpu_naive_gflops);

    CUDA_CHECK(cudaMemcpy(h_C_gpu_naive, d_C, size_bytes, cudaMemcpyDeviceToHost));
    printf("      Correctness:       ");
    verify_results(h_C_cpu, h_C_gpu_naive, N);

    // 3. GPU Tiled Shared Memory Benchmark
    printf("\n[3/3] Benchmarking GPU Tiled Shared-Memory Kernel (Optimized)...\n");
    // Warmup
    for (int w = 0; w < warmup_runs; ++w) {
        gpu_matrix_mult_tiled<<<numBlocks, threadsPerBlock>>>(d_A, d_B, d_C, N);
    }
    CUDA_CHECK(cudaDeviceSynchronize());

    float gpu_tiled_total_ms = 0.0f;
    for (int it = 0; it < iterations; ++it) {
        CUDA_CHECK(cudaEventRecord(start_event));
        gpu_matrix_mult_tiled<<<numBlocks, threadsPerBlock>>>(d_A, d_B, d_C, N);
        CUDA_CHECK(cudaEventRecord(stop_event));
        CUDA_CHECK(cudaEventSynchronize(stop_event));
        float iter_ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&iter_ms, start_event, stop_event));
        gpu_tiled_total_ms += iter_ms;
    }
    float gpu_tiled_avg_ms = gpu_tiled_total_ms / iterations;
    double gpu_tiled_gflops = gflops_per_mult / (gpu_tiled_avg_ms * 1e-3);
    printf("      GPU Tiled Time:    %10.2f ms  |  Performance: %8.2f GFLOPS\n", gpu_tiled_avg_ms, gpu_tiled_gflops);

    // Profile Data Transfer: Device to Host (D2H)
    CUDA_CHECK(cudaEventRecord(start_event));
    CUDA_CHECK(cudaMemcpy(h_C_gpu_tiled, d_C, size_bytes, cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaEventRecord(stop_event));
    CUDA_CHECK(cudaEventSynchronize(stop_event));
    float d2h_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&d2h_ms, start_event, stop_event));

    printf("      Correctness:       ");
    verify_results(h_C_cpu, h_C_gpu_tiled, N);

    // Summary & Comparative Analysis
    double total_gpu_workflow_ms = h2d_ms + gpu_tiled_avg_ms + d2h_ms;
    double kernel_speedup = cpu_avg_ms / gpu_tiled_avg_ms;
    double end_to_end_speedup = cpu_avg_ms / total_gpu_workflow_ms;

    printf("\n====================================================================\n");
    printf("                 BENCHMARK PERFORMANCE SUMMARY                      \n");
    printf("====================================================================\n");
    printf("  CPU Execution Time:              %10.2f ms\n", cpu_avg_ms);
    printf("  GPU Compute Time (Tiled Kernel): %10.2f ms\n", gpu_tiled_avg_ms);
    printf("  Data Transfer Overhead:\n");
    printf("    - Host-to-Device (A & B):      %10.2f ms (%.2f GB/s)\n",
           h2d_ms, (2.0f * size_bytes / (1024.0f * 1024.0f * 1024.0f)) / (h2d_ms * 1e-3f));
    printf("    - Device-to-Host (C):          %10.2f ms (%.2f GB/s)\n",
           d2h_ms, (1.0f * size_bytes / (1024.0f * 1024.0f * 1024.0f)) / (d2h_ms * 1e-3f));
    printf("    - Total Transfer Time:         %10.2f ms (%.1f%% of GPU workflow)\n",
           h2d_ms + d2h_ms, ((h2d_ms + d2h_ms) / total_gpu_workflow_ms) * 100.0);
    printf("  Total GPU End-to-End Time:       %10.2f ms\n", total_gpu_workflow_ms);
    printf("--------------------------------------------------------------------\n");
    printf("  Calculated Speedup Metrics:\n");
    printf("    - Raw Kernel Compute Speedup:  %10.2fx (CPU time / GPU kernel time)\n", kernel_speedup);
    printf("    - End-to-End System Speedup:   %10.2fx (CPU time / [Transfer + Kernel])\n", end_to_end_speedup);
    printf("====================================================================\n");

    // Clean up
    CUDA_CHECK(cudaEventDestroy(start_event));
    CUDA_CHECK(cudaEventDestroy(stop_event));
    CUDA_CHECK(cudaFree(d_A));
    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_C));
    free(h_A);
    free(h_B);
    free(h_C_cpu);
    free(h_C_gpu_naive);
    free(h_C_gpu_tiled);

    return 0;
}
