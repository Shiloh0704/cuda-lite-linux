CUDA_PATH ?= /usr/local/cuda-12.4
NVCC := $(CUDA_PATH)/bin/nvcc
CXX := g++

CXXFLAGS := -O3 -Wall -std=c++17 -I/usr/include/x86_64-linux-gnu -I$(CUDA_PATH)/include -I/opt/cuda-lite/include
LDFLAGS := -L/usr/lib/x86_64-linux-gnu -L$(CUDA_PATH)/lib64 -L/opt/cuda-lite/lib64 -lcudart -lcudnn -Wl,-rpath,/usr/lib/x86_64-linux-gnu -Wl,-rpath,$(CUDA_PATH)/lib64

TARGET := test_cudnn

all: $(TARGET)

$(TARGET): test_cudnn.cpp
	@echo "Building $(TARGET) using $(CXX)..."
	$(CXX) $(CXXFLAGS) test_cudnn.cpp -o $(TARGET) $(LDFLAGS)
	@echo "Built $(TARGET) successfully."

clean:
	rm -f $(TARGET)

.PHONY: all clean
