# System Architecture & Security Configuration

This directory details the init system, filesystem architecture, automatic service startup, and security hardening measures implemented in **CUDA-Lite Linux**.

## 1. Init System & Process Management
- **Chosen Init**: `systemd` (v256+).
- **Justification**:
  - Direct integration with Linux `udev` for GPU device node enumeration (`/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`).
  - Native dependency orchestration (`After=systemd-udev-settle.service`).
  - Predictable system teardown and hardware resource reclamation.
  - Ability to enforce cgroups resource constraints on compute jobs.

## 2. Automatic Application Startup
- Configured via `cuda-lite-autostart.service`.
- Runs at `multi-user.target` after device settlement.
- Executes `nvidia-smi` to log hardware health and temperature, followed by the compiled matrix multiplication benchmark.
- Standard output and errors are multiplexed to the system console (TTY1) and `systemd-journald`.

## 3. Read-Only Root Filesystem with OverlayFS
- **Base Layer (Lowerdir)**: The root filesystem is compressed using SquashFS (`xz` compression) and mounted strictly read-only (`ro`). This guarantees immutability, tamper-resistance, and zero risk of filesystem corruption during power loss.
- **Overlay Layer (Upperdir)**: A volatile `tmpfs` RAM disk acts as the copy-on-write (COW) layer. Any runtime state changes, temporary files, or logs are written to RAM and automatically discarded on reboot.
- **Benefits**:
  - Complete reproducibility on every boot.
  - No wear or degradation on USB/flash storage.
  - Immune to persistent malware or unauthorized root modifications.

## 4. Hardening Measures (Requirement E)
Four specific hardening measures have been implemented and justified:
1. **Kernel Address Space & Pointer Restriction (`kptr_restrict=2`, `dmesg_restrict=1`, `randomize_va_space=2`)**:
   - Neutralizes kernel information leakage to unprivileged users, preventing return-oriented programming (ROP) exploits.
2. **Unprivileged eBPF & Process Tracing Restrictions (`unprivileged_bpf_disabled=1`, `ptrace_scope=2`)**:
   - Eliminates microarchitectural side-channel attacks against CPU/GPU memory regions and sandboxes processes.
3. **Network Stack Hardening (`tcp_syncookies=1`, `rp_filter=1`, disabled redirects)**:
   - Prevents SYN flood denial of service and blocks IP spoofing and man-in-the-middle source routing.
4. **Filesystem Link Protection & Core Dump Suppression (`protected_symlinks=1`, `suid_dumpable=0`)**:
   - Protects multi-user temporary directories (`/tmp`) from symlink/hardlink racing and prevents GPU matrix data/weights from leaking into disk dumps.
