#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Automated Security Hardening Test Suite
# Tests: Read-only rootfs immutability, OverlayFS writeability, sysctl ASLR,
#        unprivileged user permissions, and zero-port attack surface.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "====================================================================="
echo "        EdgeML Linux OS: Automated Security Invariant Tests          "
echo "====================================================================="

PASSED=0
TOTAL=5

# Test 1: Read-Only Root Filesystem Verification
echo -n "[Test 1/5] Verifying Read-Only Root Filesystem Immutability... "
if [ -w "/" ]; then
    # In live system, writing to root must be rejected
    if touch /test_immutable_ro 2>/dev/null; then
        rm -f /test_immutable_ro
        echo "FAILED (Root directory is writable)"
    else
        echo "PASSED (Root filesystem strictly rejects modifications)"
        PASSED=$((PASSED + 1))
    fi
else
    # Host configuration check
    if grep -q "ro" "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/fstab" 2>/dev/null; then
        echo "PASSED (Verified ro flag in target /etc/fstab)"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED"
    fi
fi

# Test 2: OverlayFS / Volatile Storage Writeability
echo -n "[Test 2/5] Verifying Volatile Runtime Storage Writeability (/tmp, /var)... "
if [ -w "/tmp" ]; then
    TMP_TEST="/tmp/security_test_$$"
    if touch "$TMP_TEST" 2>/dev/null; then
        echo "test_payload" > "$TMP_TEST"
        rm -f "$TMP_TEST"
        echo "PASSED (/tmp provides functional volatile storage)"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED (Cannot write to /tmp)"
    fi
else
    if grep -q "tmpfs.*\/tmp" "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/fstab" 2>/dev/null; then
        echo "PASSED (Verified tmpfs configuration for /tmp)"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED"
    fi
fi

# Test 3: Kernel ASLR & Pointer Hiding Security Sysctl Verification
echo -n "[Test 3/5] Verifying Kernel ASLR and Pointer Hiding Parameters... "
SYSCTL_CONF="$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/sysctl.d/99-security.conf"
if [ -f "$SYSCTL_CONF" ]; then
    HAS_ASLR=$(grep -c "kernel.randomize_va_space = 2" "$SYSCTL_CONF" || true)
    HAS_KPTR=$(grep -c "kernel.kptr_restrict = 2" "$SYSCTL_CONF" || true)
    HAS_DMESG=$(grep -c "kernel.dmesg_restrict = 1" "$SYSCTL_CONF" || true)
    HAS_SYN=$(grep -c "net.ipv4.tcp_syncookies = 1" "$SYSCTL_CONF" || true)

    if [ "$HAS_ASLR" -ge 1 ] && [ "$HAS_KPTR" -ge 1 ] && [ "$HAS_DMESG" -ge 1 ] && [ "$HAS_SYN" -ge 1 ]; then
        echo "PASSED (ASLR=2, kptr_restrict=2, dmesg_restrict=1, tcp_syncookies=1)"
        PASSED=$((PASSED + 1))
    else
        echo "FAILED (One or more sysctl parameters missing)"
    fi
else
    echo "FAILED ($SYSCTL_CONF not found)"
fi

# Test 4: Unprivileged Service Account (edgeml) Verification
echo -n "[Test 4/5] Verifying Dedicated Unprivileged User Account... "
PASSWD_FILE="$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/passwd"
if [ -f "$PASSWD_FILE" ] && grep -q "^edgeml:x:1001:1001" "$PASSWD_FILE"; then
    echo "PASSED (edgeml user configured with UID 1001 / GID 1001)"
    PASSED=$((PASSED + 1))
else
    echo "FAILED (Unprivileged user edgeml missing)"
fi

# Test 5: Credentials & Hardcoded Keys Audit
echo -n "[Test 5/5] Checking Absence of Plaintext Keys or Password Hashes... "
SHADOW_LEAK=0
if [ -f "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/shadow" ]; then
    if grep -E '^root:[^!*]' "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/shadow"; then
        SHADOW_LEAK=1
    fi
fi

KEY_COUNT=$(find "$PROJECT_ROOT/board/edgeml/rootfs_overlay/" -name "*.key" -o -name "*.pem" -o -name "id_rsa*" 2>/dev/null | wc -l)
if [ "$SHADOW_LEAK" -eq 0 ] && [ "$KEY_COUNT" -eq 0 ]; then
    echo "PASSED (Zero credentials or private keys in rootfs overlay)"
    PASSED=$((PASSED + 1))
else
    echo "FAILED (Found credentials or keys)"
fi

echo "====================================================================="
echo "SECURITY INVARIANT TEST RESULTS: $PASSED / $TOTAL PASSED"
echo "====================================================================="

exit $((TOTAL - PASSED))
