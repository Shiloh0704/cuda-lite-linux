#!/usr/bin/env bash
# CUDA-Lite Linux Security Hardening Audit Script
# Tests kernel pointer restrictions, unprivileged BPF, and network sysctl parameters.

set -euo pipefail

echo "====================================================================="
echo "       CUDA-Lite Linux: Security Hardening Verification Audit        "
echo "====================================================================="

check_sysctl() {
    local key="$1"
    local expected="$2"
    local actual
    actual=$(sysctl -n "$key" 2>/dev/null || echo "N/A")
    if [ "$actual" = "$expected" ]; then
        echo -e "[PASS] $key = $actual"
    else
        echo -e "[WARN] $key = $actual (Expected: $expected)"
    fi
}

echo "1. Checking Kernel Pointer Restrict & Address Space Randomization:"
check_sysctl "kernel.kptr_restrict" "2"
check_sysctl "kernel.dmesg_restrict" "1"
check_sysctl "kernel.randomize_va_space" "2"

echo -e "\n2. Checking eBPF & Process Tracing Hardening:"
check_sysctl "kernel.unprivileged_bpf_disabled" "1"
check_sysctl "kernel.yama.ptrace_scope" "2"

echo -e "\n3. Checking Network Protocol Hardening & DoS Protection:"
check_sysctl "net.ipv4.tcp_syncookies" "1"
check_sysctl "net.ipv4.conf.all.rp_filter" "1"
check_sysctl "net.ipv4.conf.all.accept_redirects" "0"

echo -e "\n4. Checking Filesystem Link Protection:"
check_sysctl "fs.protected_hardlinks" "1"
check_sysctl "fs.protected_symlinks" "1"

echo "====================================================================="
echo "Security Audit Complete."
echo "====================================================================="
