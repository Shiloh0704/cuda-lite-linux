# NVIDIA Container Toolkit Integration for CUDA-Lite Linux

## 1. Overview and Purpose
The **NVIDIA Container Toolkit** enables users to build and run GPU-accelerated containers across standard Open Container Initiative (OCI) runtimes (such as `containerd`, `Docker`, and `Podman`). Rather than installing monolithic CUDA drivers inside each container image, the NVIDIA Container Toolkit dynamically hooks the host GPU driver, libraries, and `/dev/nvidia*` device nodes into the container namespace at startup.

In **CUDA-Lite Linux (Track C)**, container support enables:
- Reproducible, isolated execution of modern deep learning frameworks (PyTorch, TensorFlow, TensorRT).
- Separation of the minimal operating system base from application-specific Python/CUDA dependencies.
- OCI-compliant GPU scheduling via the Container Device Interface (CDI) specification.

---

## 2. Architecture of the GPU Container Stack

```
+-------------------------------------------------------------------+
|               Container Application (PyTorch, CUDA App)           |
+-------------------------------------------------------------------+
|             OCI Runtime (runc / containerd / docker)              |
+-------------------------------------------------------------------+
|     NVIDIA Container Runtime Hook (nvidia-container-runtime)      |
+-------------------------------------------------------------------+
|        NVIDIA Container CLI & Library (libnvidia-container)       |
+-------------------------------------------------------------------+
|     Host Linux Kernel (6.12+) & NVIDIA Drivers (550.163.01)       |
+-------------------------------------------------------------------+
|       Physical GPU Hardware (NVIDIA GeForce RTX 4050 Laptop)      |
+-------------------------------------------------------------------+
```

Key Components:
1. **`libnvidia-container1`**: Core C library and CLI utility providing an automatic CLI hook to configure container namespaces with NVIDIA GPU devices and driver libraries.
2. **`nvidia-container-toolkit`**: Set of tools including `nvidia-ctk` that generates CDI specifications and configures OCI runtime configurations.
3. **`nvidia-container-runtime`**: OCI-compliant runtime shim that wraps `runc` to inject the NVIDIA prestart hook.

---

## 3. Host vs. Guest Execution Environment Caveats

> [!IMPORTANT]
> **WSL2 Host Environment vs. QEMU Virtual Machine:**
> - **Ubuntu 24.04 WSL2 Host:** Possesses direct paravirtualized GPU access to the physical NVIDIA GeForce RTX 4050 Laptop GPU via the DirectX kernel driver (`/dev/dxg`). NVIDIA container workflows (`docker run --gpus all` or `nerdctl run --gpus all`) execute with full hardware acceleration.
> - **CUDA-Lite QEMU Virtual Machine:** Runs inside a virtualized QEMU instance without physical PCIe GPU passthrough (due to single-GPU laptop architecture constraints). In QEMU, the container engine is installed and configured to function in CPU/headless fallback mode; GPU device injection activates whenever a physical NVIDIA PCI device (`0x10de`) is present on the bus.

---

## 4. Configuration Artifacts Provided
- `install_container_toolkit.sh`: Automated installer for `containerd` and NVIDIA Container Toolkit.
- `daemon.json`: OCI runtime definition registering `nvidia-container-runtime`.
- `containerd_config.toml`: High-performance containerd daemon configuration with NVIDIA CDI enabled.
- `test_gpu_container.sh`: Verification script running device discovery inside an OCI container.
