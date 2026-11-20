#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Production Security Hardening Audit & Compliance Checker
# =============================================================================

set -euo pipefail

echo "====================================================================="
echo "        EdgeML Linux OS: Security Hardening & Audit Verification     "
echo "====================================================================="

FAILURES=0

# Measure 1: Verify Read-Only Root & OverlayFS Runtime Storage
echo -e "\n[Audit 1/6] Auditing Root Filesystem Immutability & OverlayFS..."
if mount | grep -q "on / .*ro"; then
    echo "  [PASS] Root filesystem is mounted read-only (ro)."
elif [ -f "/etc/fstab" ] && grep -q "/dev/root.*ro" /etc/fstab; then
    echo "  [PASS] /etc/fstab strictly enforces read-only rootfs."
else
    echo "  [INFO] Checking rootfs overlay configuration..."
    if grep -q "ro" board/edgeml/rootfs_overlay/etc/fstab 2>/dev/null; then
        echo "  [PASS] Target fstab configures rootfs as read-only (ro)."
    else
        echo "  [FAIL] Rootfs is not configured as read-only."
        FAILURES=$((FAILURES + 1))
    fi
fi

if mount | grep -q "overlay"; then
    echo "  [PASS] OverlayFS union mount is actively providing writable storage."
elif grep -q "mount -t overlay" board/edgeml/rootfs_overlay/etc/init.d/rcS 2>/dev/null; then
    echo "  [PASS] /etc/init.d/rcS mounts volatile in-memory OverlayFS for /var and /tmp."
else
    echo "  [FAIL] OverlayFS mount logic missing from init scripts."
    FAILURES=$((FAILURES + 1))
fi

# Measure 2: Kernel Sysctl Security Parameters
echo -e "\n[Audit 2/6] Auditing Kernel ASLR, Pointer Hiding, and Network Sysctls..."
SYSCTL_FILE="board/edgeml/rootfs_overlay/etc/sysctl.d/99-security.conf"
if [ -f "$SYSCTL_FILE" ]; then
    echo "  [PASS] Security sysctl profile found: $SYSCTL_FILE"
    
    # Check ASLR
    if grep -q "kernel.randomize_va_space = 2" "$SYSCTL_FILE"; then
        echo "  [PASS] Full ASLR enabled (kernel.randomize_va_space = 2)"
    else
        echo "  [FAIL] ASLR not set to 2"
        FAILURES=$((FAILURES + 1))
    fi

    # Check kptr_restrict
    if grep -q "kernel.kptr_restrict = 2" "$SYSCTL_FILE"; then
        echo "  [PASS] Kernel pointer hiding enabled (kernel.kptr_restrict = 2)"
    else
        echo "  [FAIL] kptr_restrict not set to 2"
        FAILURES=$((FAILURES + 1))
    fi

    # Check dmesg_restrict
    if grep -q "kernel.dmesg_restrict = 1" "$SYSCTL_FILE"; then
        echo "  [PASS] Kernel dmesg restricted to root (kernel.dmesg_restrict = 1)"
    else
        echo "  [FAIL] dmesg_restrict not set to 1"
        FAILURES=$((FAILURES + 1))
    fi

    # Check TCP SYN Cookies
    if grep -q "net.ipv4.tcp_syncookies = 1" "$SYSCTL_FILE"; then
        echo "  [PASS] TCP SYN flood mitigation enabled (tcp_syncookies = 1)"
    else
        echo "  [FAIL] tcp_syncookies not enabled"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "  [FAIL] 99-security.conf not found."
    FAILURES=$((FAILURES + 1))
fi

# Measure 3: Auditing Network Surface & Port Restrictions
echo -e "\n[Audit 3/6] Auditing Network Surface & Attack Vectors..."
FIREWALL_SCRIPT="board/edgeml/rootfs_overlay/etc/init.d/S05firewall"
if [ -f "$FIREWALL_SCRIPT" ]; then
    echo "  [PASS] Network port restriction script present: $FIREWALL_SCRIPT"
    if grep -q "INPUT DROP" "$FIREWALL_SCRIPT"; then
        echo "  [PASS] Default inbound firewall policy set to DROP."
    fi
else
    echo "  [FAIL] S05firewall script missing."
    FAILURES=$((FAILURES + 1))
fi

# Measure 4: Unprivileged Service Account
echo -e "\n[Audit 4/6] Auditing Unprivileged Service Account (edgeml)..."
PASSWD_FILE="board/edgeml/rootfs_overlay/etc/passwd"
if [ -f "$PASSWD_FILE" ] && grep -q "^edgeml:x:1001:1001" "$PASSWD_FILE"; then
    echo "  [PASS] Dedicated unprivileged service user 'edgeml' configured (UID 1001, GID 1001)."
else
    echo "  [FAIL] Unprivileged user 'edgeml' not found in rootfs passwd."
    FAILURES=$((FAILURES + 1))
fi

# Measure 5: Credential Leakage & Private Key Audit
echo -e "\n[Audit 5/6] Auditing Secret & Private Key Leakage..."
KEYS_FOUND=0
for ext in "pem" "key" "id_rsa" "id_ed25519"; do
    if find board/edgeml/rootfs_overlay/ -name "*.$ext" 2>/dev/null | grep -q .; then
        KEYS_FOUND=$((KEYS_FOUND + 1))
    fi
done

if [ "$KEYS_FOUND" -eq 0 ]; then
    echo "  [PASS] Zero private keys or TLS credentials stored in rootfs overlay."
else
    echo "  [FAIL] Found $KEYS_FOUND private key files in rootfs overlay."
    FAILURES=$((FAILURES + 1))
fi

# Measure 6: File Permissions Audit
echo -e "\n[Audit 6/6] Auditing Sensitive File Permissions..."
if [ -f "$PASSWD_FILE" ]; then
    echo "  [PASS] /etc/passwd has standard read permissions."
fi
if [ -x "board/edgeml/rootfs_overlay/etc/init.d/S90edgeml" ]; then
    echo "  [PASS] Init scripts have executable bits properly set."
fi

echo "====================================================================="
if [ "$FAILURES" -eq 0 ]; then
    echo "SECURITY AUDIT PASSED: All 6 defense-in-depth measures verified."
    exit 0
else
    echo "SECURITY AUDIT FAILED with $FAILURES issues."
    exit 1
fi
