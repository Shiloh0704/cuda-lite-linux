# NVIDIA cuDNN Integration for CUDA-Lite Linux

## 1. Overview and Purpose
The **NVIDIA CUDA Deep Neural Network library (cuDNN)** is a GPU-accelerated library of primitives for deep neural networks. cuDNN provides highly tuned implementations for standard routines such as:
- Forward and backward convolution passes (2D/3D convolutions, cross-correlation).
- Pooling (max, average).
- Normalization (Batch Normalization, Layer Normalization, Instance Normalization, Group Normalization).
- Activation layers (ReLU, Sigmoid, Tanh, GELU, Swish).
- Attention mechanisms and fused Multi-Head Attention (MHA) optimized for Transformer models.

In **CUDA-Lite Linux (Track C)**, cuDNN complements the core CUDA Toolkit 12.4 runtime, enabling accelerated deep learning and scientific tensor compute workloads on modern NVIDIA architectures.

---

## 2. Architectural Compatibility & Version Pinning
- **Target Hardware:** NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute Capability 8.9).
- **Host Driver:** 550.163.01.
- **CUDA Toolkit:** 12.4.131.
- **cuDNN Version:** **9.1.0.70-1** (compatible with CUDA 12.x on Linux x86-64).
- **Shared Libraries Provided:**
  - `libcudnn.so.9` (Core cuDNN runtime)
  - `libcudnn_ops.so.9` (Basic tensor operations)
  - `libcudnn_cnn.so.9` (Convolutional and pooling neural network layers)
  - `libcudnn_adv.so.9` (Advanced RNN and attention models)
  - `libcudnn_graph.so.9` (cuDNN Graph API engine)

---

## 3. Redistribution & Licensing
cuDNN is proprietary software governed by the **NVIDIA cuDNN Software License Agreement (SLA)**. Key compliance points:
- **Redistribution:** Redistribution of cuDNN runtime binaries in custom operating system images or container appliances is permitted solely in binary form pursuant to NVIDIA's license terms.
- **Commercial Restrictions:** Modification, reverse engineering, or sublicensing of cuDNN binary libraries is prohibited.
- **Inclusion in CUDA-Lite:** The runtime libraries (`libcudnn*.so.9`) are integrated into the distribution's library path (`/usr/lib/x86_64-linux-gnu` or `/opt/cuda-lite/lib64`), with headers (`cudnn*.h`) provided in `/opt/cuda-lite/include` or development manifests.

---

## 4. Dynamic Linker & Environment Configuration
cuDNN libraries are resolved automatically via the dynamic linker configuration:
```bash
# /etc/ld.so.conf.d/cuda-lite.conf
/usr/local/cuda-12.4/lib64
/opt/cuda-lite/lib64
/usr/lib/x86_64-linux-gnu
```

To verify library detection:
```bash
ldconfig -p | grep cudnn
```
