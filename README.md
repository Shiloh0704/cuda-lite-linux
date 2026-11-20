# CUDA-Lite Linux

**Application-Specific Linux Distribution for NVIDIA CUDA/GPU Computing**  
*Track C: University Embedded & Specialized Operating Systems Project*

CUDA-Lite Linux is an application-specific, minimal, reproducible, and bootable Linux operating system engineered specifically for high-throughput, low-latency GPU computing on NVIDIA Ada Lovelace hardware (NVIDIA GeForce RTX 4050).

---

## Key Achievements
* **78.6% Reduction in Image Size**: 860 MB bootable ISO vs. 4.0 GB stock Ubuntu Desktop.
* **78.3% Reduction in Idle RAM**: 265 MB idle memory vs. 1,220 MB stock baseline.
* **61.8% Faster Kernel Boot**: 1.84 s kernel initialization time vs. 4.82 s stock.
* **End-to-End Speedup**: Up to **117.7x** speedup on single-precision matrix multiplication over host CPU.
* **Tamper-Proof Reliability**: Read-only SquashFS root with volatile tmpfs OverlayFS and systemd autostart.
* **4-Point Security Hardening**: ASLR enforcement, kernel pointer hiding, eBPF disabling, and TCP SYN flood mitigation.

---

## Target Hardware Specifications

| Component | Target Specification |
| :--- | :--- |
| **GPU** | NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, Compute 8.9 / `sm_89`) |
| **VRAM** | 6141 MiB (6 GB) GDDR6, 96-bit bus, ~192 GB/s theoretical peak bandwidth |
| **Host CPU** | 13th Gen Intel Core i5-13420H (8 Cores, 12 Threads) |
| **Host RAM** | 16 GB DDR4/DDR5 |
| **Driver & Toolchain** | NVIDIA Driver 592.82 / CUDA Toolkit 12.4+ |

---

## Repository Structure

```
CUDA-LITE-LINUX/
├── build/                 # Reproducible ISO generation & cleanup scripts
│   ├── build_iso.sh       # Main hybrid ISO build automation
│   ├── clean.sh           # Chroot unmount and temporary workspace cleaner
│   └── checksum.sha256    # Cryptographic integrity signature
├── config/                # Build configuration files
├── kernel/                # Kernel customization & configuration
│   ├── kernel_config_diff.txt # Delta between stock and tailored kernel
│   └── analysis.md        # Quantitative kernel size & boot-time analysis
├── packages/              # Package manifests & licensing
│   ├── package_manifest.txt # Minimal 142-package userland inventory
│   ├── exclusions.txt     # Justifications for excluded stock bloat
│   └── licence_inventory.md # Open-source & NVIDIA EULA license compliance
├── cuda/                  # Primary CUDA demonstration suite
│   ├── device_query.cu    # Hardware & compute capability enumerator
│   ├── matrix_mul.cu      # CPU vs GPU matrix multiplication benchmark
│   ├── Makefile           # Optimized build script targeting sm_89
│   └── README.md          # Benchmark compilation and execution guide
├── system/                # Systemd services & security hardening
│   ├── cuda-lite-autostart.service # Boot autostart unit for GPU benchmark
│   ├── fstab.overlay      # Read-only root + OverlayFS RAM configuration
│   ├── hardening.conf     # Sysctl kernel security parameters
│   └── README.md          # Architectural documentation
├── benchmarks/            # Benchmark scripts & raw telemetry
│   ├── run_benchmarks.sh  # Automated benchmark suite runner
│   └── results/           # Benchmark outputs, telemetry logs & CSVs
├── tests/                 # Verification & validation suite
│   ├── test_boot.sh       # QEMU virtual machine boot test
│   ├── test_cuda.sh       # End-to-end CUDA driver & compute test
│   └── test_hardening.sh  # Security sysctl audit script
├── documentation/         # Academic deliverables & technical architecture
│   ├── REPORT.md          # Comprehensive final project report (Sections A-H)
│   ├── architecture.md    # System layer & OverlayFS boot flow diagrams
│   └── build_log.md       # Chronological environment & build milestone log
└── README.md              # Project overview & quickstart guide
```

---

## Quickstart Guide

### 1. Build the CUDA Applications
```bash
cd cuda
make
./device_query
./matrix_mul 1024 5
```

### 2. Run the Benchmark Suite
```bash
./benchmarks/run_benchmarks.sh
```

### 3. Build the Minimal Bootable ISO
```bash
sudo ./build/build_iso.sh
```

### 4. Test Boot in QEMU
```bash
./tests/test_boot.sh
```

---

## License
* **Base System & Kernel Scripts**: GPLv2 / GPLv3.
* **CUDA-Lite Benchmark Code**: MIT License.
* **NVIDIA Drivers & CUDA Runtime**: NVIDIA Software License Agreement & CUDA Toolkit EULA.
