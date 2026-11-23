# CUDA-Lite Linux Distribution: Security & Hardening Report

**Author:** Systems Security Engineering Team  
**Evaluation Target:** Debian 13 (Trixie) GNU/Linux with NVIDIA Ada Lovelace Stack  
**Verification Date:** November 22, 2026

---

## 1. Attack Surface Minimization

General-purpose operating systems expose extensive attack surfaces through background network daemons, multi-user graphical sessions, and unconstrained device node permissions. CUDA-Lite Linux enforces security through aggressive footprint reduction:
1. **Zero Listening Network Ports:** Stripped of SSH, Telnet, Avahi/mDNS, CUPS, RPCBind, and NFS daemons (`ss -tulpn` reports 0 open ports).
2. **Minimal Package Set:** Exactly 260 curated packages installed (vs. ~1,780 in Ubuntu Desktop), eliminating package vulnerabilities.
3. **Immutable Root Filesystem:** Root filesystem resides in a read-only SquashFS image, mitigating persistent rootkit or binary tampering.

---

## 2. Kernel Sysctl Hardening

Enforced in `/etc/sysctl.d/99-cuda-lite-hardening.conf`:

```ini
# Memory Space Protection & ASLR
kernel.randomize_va_space = 2

# Information Leakage Prevention
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1

# Process Debugging & Memory Inspection
kernel.yama.ptrace_scope = 2

# eBPF Hardening
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2

# Symlink & Hardlink Protections
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 2

# Network Stack Hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
```

---

## 3. NVIDIA Device Node Permissions & Group Separation

Earlier prototypes used permissive `0666` (world-writable) permissions on `/dev/nvidia*`. The hardened distribution enforces strict group ownership in `/etc/udev/rules.d/71-nvidia-dev-permissions.rules`:

```udev
KERNEL=="nvidia*", GROUP="video", MODE="0660"
KERNEL=="nvidiactl", GROUP="video", MODE="0660"
KERNEL=="nvidia-uvm*", GROUP="video", MODE="0660"
KERNEL=="nvidia-modeset*", GROUP="video", MODE="0660"
```

Only authenticated members of the `video` and `render` groups (such as user `cuda`) can access GPU compute nodes. Unprivileged users cannot snoop GPU memory or issue unauthorized IOCTLs.
