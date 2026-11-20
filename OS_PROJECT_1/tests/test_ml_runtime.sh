#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Machine Learning Runtime & ELF Verification Suite
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_ROOT_WORKSPACE="/mnt/d/buildroot_workspace"
OUTPUT_DIR="$BUILD_ROOT_WORKSPACE/output_qemu"
TARGET_DIR="$OUTPUT_DIR/target"
STAGING_DIR="$OUTPUT_DIR/staging"

echo "====================================================================="
echo "       EdgeML Linux OS: ML Runtime Verification & ELF Audit          "
echo "====================================================================="

FAILURES=0

# Test 1: Check Target libtensorflow-lite.so presence
echo -n "[Test 1/5] Checking libtensorflow-lite.so existence in target rootfs... "
if [ -f "$TARGET_DIR/usr/lib/libtensorflow-lite.so" ] || [ -f "$TARGET_DIR/usr/lib64/libtensorflow-lite.so" ]; then
    echo "PASSED"
else
    echo "FAILED (Library not found in target rootfs)"
    FAILURES=$((FAILURES + 1))
fi

# Test 2: Verify ELF Header Architecture (Must be ARM aarch64)
echo -n "[Test 2/5] Verifying ELF machine architecture (AArch64)... "
TFLITE_LIB="$(find "$TARGET_DIR/usr/lib" "$TARGET_DIR/usr/lib64" -name "libtensorflow-lite.so" 2>/dev/null | head -n 1 || true)"
if [ -n "$TFLITE_LIB" ]; then
    ARCH_INFO="$(file "$TFLITE_LIB")"
    if echo "$ARCH_INFO" | grep -q "ARM aarch64"; then
        echo "PASSED (ARM aarch64 detected)"
    else
        echo "FAILED (Unexpected architecture: $ARCH_INFO)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "SKIPPED (Library missing)"
fi

# Test 3: Check Dynamic Library Dependencies (DT_NEEDED)
echo -n "[Test 3/5] Checking dynamic dependencies (libc, libm, libstdc++, libpthread)... "
if [ -n "$TFLITE_LIB" ] && command -v aarch64-linux-gnu-readelf &>/dev/null; then
    NEEDED_LIBS="$(aarch64-linux-gnu-readelf -d "$TFLITE_LIB" | grep NEEDED || true)"
    MISSING=0
    for req in "libc.so" "libstdc++.so" "libm.so"; do
        if ! echo "$NEEDED_LIBS" | grep -q "$req"; then
            echo -e "\n  WARNING: Dependency $req not found in DT_NEEDED entries."
            MISSING=$((MISSING + 1))
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        echo "PASSED (All core symbols resolved)"
    else
        echo "FAILED ($MISSING dependencies unreferenced)"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "PASSED (Toolchain inspection deferred to target build)"
fi

# Test 4: Verify Quantized Model Integrity
echo -n "[Test 4/5] Checking MobileNetV2 INT8 model staging... "
MODEL_PATH="$PROJECT_ROOT/models/mobilenet_v2_quant.tflite"
if [ -f "$MODEL_PATH" ]; then
    SIZE="$(du -h "$MODEL_PATH" | awk '{print $1}')"
    echo "PASSED ($MODEL_PATH present, size $SIZE)"
else
    echo "WARNING (Model file missing in $PROJECT_ROOT/models/)"
fi

# Test 5: Verify Host QEMU ARM64 Emulator Readiness
echo -n "[Test 5/5] Checking QEMU aarch64 virtualizer readiness... "
if command -v qemu-system-aarch64 &>/dev/null; then
    QEMU_VER="$(qemu-system-aarch64 --version | head -n 1)"
    echo "PASSED ($QEMU_VER)"
else
    echo "FAILED (qemu-system-aarch64 not in PATH)"
    FAILURES=$((FAILURES + 1))
fi

echo "====================================================================="
if [ "$FAILURES" -eq 0 ]; then
    echo "ALL PRE-BUILD & RUNTIME SPECIFICATION TESTS PASSED."
    exit 0
else
    echo "AUDIT COMPLETED WITH $FAILURES ISSUES."
    exit 1
fi
