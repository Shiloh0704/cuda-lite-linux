CXX ?= aarch64-linux-gnu-g++
CXXFLAGS ?= -std=c++17 -O3 -Wall -Wextra -pthread
TARGETS = edgeml-infer edgeml_benchmark

SYSROOT ?= /mnt/d/buildroot_workspace/output_qemu/staging
INCLUDES = -I$(SYSROOT)/usr/include
LDFLAGS = -L$(SYSROOT)/usr/lib -L$(SYSROOT)/usr/lib64 -ltensorflow-lite -lpthread -ldl -lm

all: $(TARGETS)

edgeml-infer: edgeml_infer.cpp stb_image.h
	@echo "Compiling edgeml-infer..."
	@if [ -d "$(SYSROOT)/usr/include/tensorflow" ]; then \
		$(CXX) $(CXXFLAGS) -DHAVE_TFLITE $(INCLUDES) edgeml_infer.cpp -o edgeml-infer $(LDFLAGS); \
	else \
		$(CXX) $(CXXFLAGS) edgeml_infer.cpp -o edgeml-infer -lm -lpthread; \
	fi

edgeml_benchmark: edgeml_benchmark.cpp
	@echo "Compiling edgeml_benchmark..."
	@if [ -d "$(SYSROOT)/usr/include/tensorflow" ]; then \
		$(CXX) $(CXXFLAGS) -DHAVE_TFLITE $(INCLUDES) edgeml_benchmark.cpp -o edgeml_benchmark $(LDFLAGS); \
	else \
		$(CXX) $(CXXFLAGS) edgeml_benchmark.cpp -o edgeml_benchmark -lm -lpthread; \
	fi

clean:
	rm -f $(TARGETS)

.PHONY: all clean
