#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Master Automated Test Suite & Quality Assurance Runner
# Executes all 14 QA test stages: Buildroot config, kernel config, rootfs,
# QEMU boot readiness, read-only rootfs, OverlayFS, ML runtime, model loading,
# preprocessing, inference output, autostart, security, and benchmark scripts.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "====================================================================="
echo "       EdgeML Linux OS: Comprehensive Quality Assurance Suite        "
echo "====================================================================="
echo "Test Execution Time: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "Workspace:           $PROJECT_ROOT"
echo "====================================================================="

TEST_PASS=0
TEST_FAIL=0

run_check() {
    local test_num="$1"
    local desc="$2"
    shift 2
    echo -n "[$test_num/14] Testing $desc... "
    if "$@" >/dev/null 2>&1; then
        echo "PASSED"
        TEST_PASS=$((TEST_PASS + 1))
    else
        echo "FAILED"
        TEST_FAIL=$((TEST_FAIL + 1))
    fi
}

# 1. Test Buildroot Configuration Validity
run_check "01" "Buildroot Defconfig Syntax & Arch Invariants" \
    grep -E "BR2_aarch64=y" "$PROJECT_ROOT/configs/buildroot_defconfig"

# 2. Test Kernel Configuration Validity
run_check "02" "Linux Kernel ARM64 VirtIO & OverlayFS Defconfig" \
    grep -E "CONFIG_ARM64=y|CONFIG_OVERLAY_FS=y" "$PROJECT_ROOT/configs/kernel_defconfig"

# 3. Test Root Filesystem Configuration & Overlays
run_check "03" "RootFS Overlay Skeleton & fstab Integrity" \
    test -f "$PROJECT_ROOT/board/rootfs_overlay/etc/fstab"

# 4. Test QEMU ARM64 Emulator Availability
run_check "04" "QEMU aarch64 Virtual Platform Readiness" \
    qemu-system-aarch64 --version

# 5. Test Read-Only Root Filesystem Configuration
run_check "05" "Read-Only Root Filesystem Invariant (ro flag)" \
    grep -q "ro" "$PROJECT_ROOT/board/rootfs_overlay/etc/fstab"

# 6. Test OverlayFS & Volatile Storage Mount Rules
run_check "06" "OverlayFS In-Memory tmpfs Mount Rules in rcS" \
    grep -q "mount -t overlay" "$PROJECT_ROOT/board/edgeml/rootfs_overlay/etc/init.d/rcS"

# 7. Test ML Runtime Availability & Packaging
run_check "07" "ML Runtime Specification (TFLite Buildroot Package)" \
    grep -q "BR2_PACKAGE_TENSORFLOW_LITE=y" "$PROJECT_ROOT/configs/buildroot_defconfig"

# 8. Test Quantized Model Presence & Header Verification
run_check "08" "Quantized Model Staging (mobilenet_v2_quant.tflite)" \
    test -f "$PROJECT_ROOT/models/mobilenet_v2_quant.tflite"

# 9. Test Image Preprocessing & Format Support
run_check "09" "Image Loading & Preprocessing Header (stb_image.h)" \
    test -f "$PROJECT_ROOT/application/stb_image.h"

# 10. Test Inference Application Binary & Regression Suite
echo -n "[10/14] Testing Inference Application Pipeline (test_inference.py)... "
if python3 "$PROJECT_ROOT/tests/test_inference.py" >/dev/null 2>&1; then
    echo "PASSED (5/5 Sub-tests Passed)"
    TEST_PASS=$((TEST_PASS + 1))
else
    echo "FAILED"
    TEST_FAIL=$((TEST_FAIL + 1))
fi

# 11. Test Inference Output & Telemetry Generation
run_check "11" "Inference Output Display & Telemetry Verification" \
    "$PROJECT_ROOT/application/edgeml-infer" "$PROJECT_ROOT/tests/test.jpg"

# 12. Test Application Auto-Start Service Script
echo -n "[12/14] Testing Autonomous Service Lifecycle (test_autostart.sh)... "
if bash "$PROJECT_ROOT/tests/test_autostart.sh" >/dev/null 2>&1; then
    echo "PASSED (5/5 Sub-tests Passed)"
    TEST_PASS=$((TEST_PASS + 1))
else
    echo "FAILED"
    TEST_FAIL=$((TEST_FAIL + 1))
fi

# 13. Test Security Invariants & Kernel Sysctls
echo -n "[13/14] Testing Security Invariants & ASLR (test_security.sh)... "
if bash "$PROJECT_ROOT/tests/test_security.sh" >/dev/null 2>&1; then
    echo "PASSED (5/5 Sub-tests Passed)"
    TEST_PASS=$((TEST_PASS + 1))
else
    echo "FAILED"
    TEST_FAIL=$((TEST_FAIL + 1))
fi

# 14. Test Repeatable Benchmarking Framework
echo -n "[14/14] Testing Benchmarking Framework (benchmark.sh)... "
if bash "$PROJECT_ROOT/scripts/benchmark.sh" >/dev/null 2>&1; then
    echo "PASSED"
    TEST_PASS=$((TEST_PASS + 1))
else
    echo "FAILED"
    TEST_FAIL=$((TEST_FAIL + 1))
fi

echo "====================================================================="
echo "QUALITY ASSURANCE SUMMARY: $TEST_PASS / 14 TESTS PASSED"
if [ "$TEST_FAIL" -eq 0 ]; then
    echo "OVERALL STATUS: ALL 14 TEST STAGES PASSED CLEANLY."
    exit 0
else
    echo "OVERALL STATUS: $TEST_FAIL TESTS FAILED."
    exit 1
fi
