# CUDA-Lite Linux Benchmark Makefile
# Target: NVIDIA GeForce RTX 4050 Laptop GPU (Compute Capability 8.9 / sm_89)

NVCC := nvcc
CXX := g++

# Target sm_89 for Ada Lovelace RTX 40-series GPUs, fallback to sm_80/sm_86 for compatibility
NVCC_FLAGS := -O3 -std=c++17 -arch=sm_89 -gencode=arch=compute_89,code=sm_89 -gencode=arch=compute_86,code=sm_86
CXX_FLAGS := -O3 -std=c++17 -Wall

TARGETS := device_query matrix_mul

all: $(TARGETS)

device_query: device_query.cu
	$(NVCC) $(NVCC_FLAGS) $< -o $@

matrix_mul: matrix_mul.cu
	$(NVCC) $(NVCC_FLAGS) $< -o $@

clean:
	rm -f $(TARGETS) *.o
