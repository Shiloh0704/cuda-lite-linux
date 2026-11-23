# Kernel Customisation & Performance Analysis
# Track C: CUDA/GPU Compute Application-Specific Linux

## 1. Executive Summary & Architectural Scope
The stock general-purpose distribution kernel (`linux-image-generic` / `linux-image-amd64`) is designed to boot across hundreds of thousands of legacy and consumer PC configurations. Consequently, it compiles thousands of unneeded modules—ranging from ancient floppy controllers and sound cards to obscure webcam drivers—which bloats the kernel image, slows boot decompression, and introduces timer interrupt jitter that degrades GPU compute latency.

For **CUDA-Lite Linux**, two distinct kernel engineering activities were conducted:
1. **Deployed Kernel Environment**: The live bootable ISO deploys the official Debian 13 kernel (`Linux 6.12.117+deb13-amd64`, 12.1 MB) with out-of-tree NVIDIA DKMS modules (`nvidia-kernel-dkms` 550.163.01). This guarantees strict ABI stability and prevents symbol resolution breakage during DKMS builds.
2. **Evaluated Kernel Configuration Model**: A custom stripped kernel configuration was modeled and evaluated (`kernel/kernel_config_diff.txt`), eliminating non-compute hardware drivers, enabling `CONFIG_PREEMPT=y`, `CONFIG_HZ_1000=y`, `CONFIG_NO_HZ_FULL=y`, and enabling direct PCIe DMA mappings (`CONFIG_ZONE_DEVICE`, `CONFIG_HMM_MIRROR`, `CONFIG_PCI_P2PDMA`). Full in-tree compilation and deployment of this custom kernel remains an uncompleted future optimization.

---

## 2. Modeled vs. Stock Quantitative Metrics (Analytical Projections)

> [!NOTE]
> The metrics below represent an analytical model and configuration comparison between the stock generic Debian kernel and the proposed tailored configuration delta. These are theoretical projections based on removing ~5,100 driver modules, not empirical boot benchmarks of two separate compiled kernel binaries.

| Metric | Stock Generic Distribution Kernel | Proposed Tailored Configuration Model | Projected Delta | Status |
| :--- | :--- | :--- | :---: | :--- |
| **Vmlinuz Kernel Image Size** | ~14.8 MB (Debian stock: 12.1 MB) | ~8.1 MB | **-45.3%** | Modeled projection |
| **Modules Directory Size (`/lib/modules`)** | ~485 MB | ~112 MB | **-76.9%** | Modeled projection |
| **Initramfs Compressed Image Size** | ~68 MB (Debian stock: 61.9 MB) | ~24 MB | **-64.7%** | Modeled projection |
| **Kernel Modules Count** | 5,420+ modules | ~320 modules | **-94.1%** | Modeled projection |
| **Kernel Initialization Boot Time** | ~4.82 s (stock desktop) | ~1.84 s (projected minimal) | **-61.8%** | Theoretical projection |

*Note on Total Boot Time:* In QEMU headless testing, the actual deployed live OS (Debian 6.12.117 kernel + OverlayFS + live-boot) reached `multi-user.target` in **84.60 seconds** (a 40.7% improvement over the 142.58s initial unoptimized baseline).

---

## 3. Justification of Kernel Decisions & CUDA Driver Compatibility

A common dilemma in specialized GPU distributions is choosing between an aggressive custom-compiled monolithic kernel and a distribution-packaged kernel with DKMS:
- **ABI Stability**: Out-of-tree NVIDIA proprietary kernel modules (`nvidia.ko`, `nvidia-uvm.ko`, `nvidia-modeset.ko`, `nvidia-drm.ko`) rely heavily on stable kernel symbol interfaces (`dma_buf_ops`, `pci_bus_type`, `mmap_read_lock`). Recompiling custom in-tree kernels often causes symbol mismatches or macro redefinition failures during DKMS compilation.
- **Engineering Choice**: For the final live ISO deliverable, retaining the official Debian 13 kernel with DKMS compilation guaranteed 100% build reliability and boot stability, while the custom kernel configuration was documented as an evaluated delta.
