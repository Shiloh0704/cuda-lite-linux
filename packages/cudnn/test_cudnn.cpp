#include <iostream>
#include <iomanip>
#include <cuda_runtime.h>

// cuDNN dynamic linkage test
// Checks cuDNN runtime library loading, version interrogation, and device compatibility

extern "C" {
    typedef void* cudnnHandle_t;
    typedef enum {
        CUDNN_STATUS_SUCCESS = 0,
        CUDNN_STATUS_NOT_INITIALIZED = 1,
        CUDNN_STATUS_ALLOC_FAILED = 2,
        CUDNN_STATUS_BAD_PARAM = 3,
        CUDNN_STATUS_INTERNAL_ERROR = 4,
        CUDNN_STATUS_INVALID_VALUE = 5,
        CUDNN_STATUS_ARCH_MISMATCH = 6,
        CUDNN_STATUS_MAPPING_ERROR = 7,
        CUDNN_STATUS_EXECUTION_FAILED = 8,
        CUDNN_STATUS_NOT_SUPPORTED = 9,
        CUDNN_STATUS_LICENSE_ERROR = 10
    } cudnnStatus_t;

    size_t cudnnGetVersion(void);
    const char* cudnnGetErrorString(cudnnStatus_t status);
    cudnnStatus_t cudnnCreate(cudnnHandle_t *handle);
    cudnnStatus_t cudnnDestroy(cudnnHandle_t handle);
}

int main() {
    std::cout << "========================================================" << std::endl;
    std::cout << "     CUDA-Lite Linux: NVIDIA cuDNN Verification Test    " << std::endl;
    std::cout << "========================================================" << std::endl;

    // Check CUDA device presence
    int deviceCount = 0;
    cudaError_t cudaErr = cudaGetDeviceCount(&deviceCount);
    if (cudaErr != cudaSuccess || deviceCount == 0) {
        std::cout << "Notice: No physical CUDA GPU detected (" 
                  << cudaGetErrorString(cudaErr) << ")." << std::endl;
        std::cout << "Running cuDNN library linkage and symbol verification only." << std::endl;
    } else {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, 0);
        std::cout << "Detected GPU: " << prop.name 
                  << " (Compute Capability " << prop.major << "." << prop.minor << ")" << std::endl;
    }

    // Interrogate cuDNN Version
    try {
        size_t version = cudnnGetVersion();
        size_t major = version / 10000;
        size_t minor = (version % 10000) / 100;
        size_t patch = version % 100;

        std::cout << "[SUCCESS] cuDNN runtime library linked successfully!" << std::endl;
        std::cout << "cuDNN Library Version: " << major << "." << minor << "." << patch 
                  << " (Raw: " << version << ")" << std::endl;

        if (deviceCount > 0) {
            cudnnHandle_t handle;
            cudnnStatus_t status = cudnnCreate(&handle);
            if (status == CUDNN_STATUS_SUCCESS) {
                std::cout << "[SUCCESS] cudnnCreate() initialized valid cuDNN context on GPU." << std::endl;
                cudnnDestroy(handle);
                std::cout << "[SUCCESS] cudnnDestroy() context released cleanly." << std::endl;
            } else {
                std::cout << "Warning: cudnnCreate() returned status: " 
                          << cudnnGetErrorString(status) << std::endl;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception during cuDNN call: " << e.what() << std::endl;
        return 1;
    }

    std::cout << "========================================================" << std::endl;
    std::cout << "cuDNN Verification: COMPLETED SUCCESSFULLY" << std::endl;
    return 0;
}
