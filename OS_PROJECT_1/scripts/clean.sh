#!/usr/bin/env bash
# =============================================================================
# EdgeML Linux OS: Workspace & Build Cleanup Utility
# Cleans temporary build artifacts, intermediate object files, and test logs
# while strictly preserving configuration files, models, and source code.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "====================================================================="
echo "           EdgeML Linux OS: Workspace Cleanup Utility                "
echo "====================================================================="

echo "Cleaning application build artifacts..."
make -C "$PROJECT_ROOT/application" clean 2>/dev/null || rm -f "$PROJECT_ROOT/application/edgeml-infer" "$PROJECT_ROOT/application/edgeml_benchmark"

echo "Cleaning temporary test logs..."
rm -f /tmp/edgeml_test.* /tmp/security_test_* /tmp/test_immutable_* 2>/dev/null || true

echo "Workspace cleanup completed."
echo "Note: To purge the entire out-of-tree Buildroot build cache on Drive D:, run:"
echo "  rm -rf /mnt/d/buildroot_workspace/output_qemu"
echo "====================================================================="
