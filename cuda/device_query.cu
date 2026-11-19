/*
 * CUDA-Lite Linux - Target Hardware Device Query
 * Track C: Application-specific Linux distribution for NVIDIA CUDA/GPU computing
 *
 * This utility enumerates NVIDIA CUDA-capable devices, querying hardware architecture,
 * compute capability, streaming multiprocessors (SMs), memory hierarchy, and clock rates.
 */

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

int main(int argc, char **argv) {
    printf("====================================================================\n");
    printf("        CUDA-Lite Linux: Hardware Device Discovery & Query          \n");
    printf("====================================================================\n");

    int deviceCount = 0;
    cudaError_t error_id = cudaGetDeviceCount(&deviceCount);

    if (error_id != cudaSuccess) {
        printf("cudaGetDeviceCount returned %d: %s\n", (int)error_id, cudaGetErrorString(error_id));
        printf("Result: FAILED to enumerate CUDA devices.\n");
        return 1;
    }

    if (deviceCount == 0) {
        printf("No CUDA-capable devices detected.\n");
        return 1;
    }

    printf("Detected %d CUDA-capable device(s)\n\n", deviceCount);

    for (int dev = 0; dev < deviceCount; ++dev) {
        cudaSetDevice(dev);
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, dev);

        printf("--------------------------------------------------------------------\n");
        printf("Device %d: \"%s\"\n", dev, prop.name);
        printf("--------------------------------------------------------------------\n");
        printf("  CUDA Driver / Runtime Version:      %d.%d / %d.%d\n",
               CUDART_VERSION / 1000, (CUDART_VERSION % 100) / 10,
               CUDART_VERSION / 1000, (CUDART_VERSION % 100) / 10);
        printf("  CUDA Capability Major/Minor version: %d.%d\n", prop.major, prop.minor);
        printf("  Total Global Memory:                 %.2f GB (%llu bytes)\n",
               (float)prop.totalGlobalMem / (1024.0f * 1024.0f * 1024.0f),
               (unsigned long long)prop.totalGlobalMem);
        printf("  Multiprocessors (SM Count):          %d\n", prop.multiProcessorCount);
        printf("  GPU Clock Rate:                      %.2f GHz (%d MHz)\n",
               prop.clockRate * 1e-6f, prop.clockRate / 1000);
        printf("  Memory Clock Rate:                   %.2f GHz (%d MHz)\n",
               prop.memoryClockRate * 1e-6f, prop.memoryClockRate / 1000);
        printf("  Memory Bus Width:                    %d-bit\n", prop.memoryBusWidth);
        
        float peakBandwidth = 2.0f * prop.memoryClockRate * (prop.memoryBusWidth / 8.0f) / 1.0e6f;
        printf("  Theoretical Peak Memory Bandwidth:   %.2f GB/s\n", peakBandwidth);
        
        printf("  L2 Cache Size:                       %d KB\n", prop.l2CacheSize / 1024);
        printf("  Total Constant Memory:               %zu KB\n", prop.totalConstMem / 1024);
        printf("  Shared Memory per Block:             %zu KB\n", prop.sharedMemPerBlock / 1024);
        printf("  Registers per Block:                 %d\n", prop.regsPerBlock);
        printf("  Warp Size:                           %d threads\n", prop.warpSize);
        printf("  Max Threads per Multiprocessor:      %d\n", prop.maxThreadsPerMultiProcessor);
        printf("  Max Threads per Block:               %d\n", prop.maxThreadsPerBlock);
        printf("  Max Dimension Sizes of a Block:      (%d, %d, %d)\n",
               prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
        printf("  Max Dimension Sizes of a Grid:       (%d, %d, %d)\n",
               prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
        printf("  Concurrent Copy and Execution:       %s (Overlap engines: %d)\n",
               prop.asyncEngineCount > 0 ? "Yes" : "No", prop.asyncEngineCount);
        printf("  Unified Addressing (UVA):            %s\n", prop.unifiedAddressing ? "Supported" : "No");
        printf("  ECC Memory Support:                  %s\n", prop.ECCEnabled ? "Enabled" : "Disabled/Unsupported");
        printf("  PCIe Bus ID / Device ID / Domain:    %02x:%02x.%x (Domain %x)\n",
               prop.pciBusID, prop.pciDeviceID, prop.pciDomainID, prop.pciDomainID);
        printf("--------------------------------------------------------------------\n");
    }

    printf("\nCUDA Device Query: SUCCESS\n");
    return 0;
}
