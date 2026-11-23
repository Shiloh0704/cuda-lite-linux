#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/mnt/c/Users/shilo/OneDrive/OS_Project"
SUB_DIR="$PROJECT_ROOT/submission/CUDA_Lite_Final_Submission"
FINAL_ZIP="$PROJECT_ROOT/submission/CUDA_Lite_Final_Submission.zip"

echo "=== 1. Creating Clean Submission Subdirectories ==="
rm -rf "$SUB_DIR"
mkdir -p "$SUB_DIR/01_Source_Code"
mkdir -p "$SUB_DIR/02_Kernel_Configuration"
mkdir -p "$SUB_DIR/03_System_Configuration"
mkdir -p "$SUB_DIR/04_Build_Scripts"
mkdir -p "$SUB_DIR/05_Testing_and_Benchmarks"
mkdir -p "$SUB_DIR/06_Documentation"
mkdir -p "$SUB_DIR/07_Screenshots_and_Evidence"
mkdir -p "$SUB_DIR/08_Licenses_and_Manifest"

echo "=== 2. Populating 01_Source_Code ==="
cp -r "$PROJECT_ROOT/cuda" "$SUB_DIR/01_Source_Code/"
cp -r "$PROJECT_ROOT/packages/cudnn" "$SUB_DIR/01_Source_Code/"
cp -r "$PROJECT_ROOT/packages/container" "$SUB_DIR/01_Source_Code/"

echo "=== 3. Populating 02_Kernel_Configuration ==="
cp -r "$PROJECT_ROOT/kernel/configs" "$SUB_DIR/02_Kernel_Configuration/"
cp -r "$PROJECT_ROOT/kernel/custom" "$SUB_DIR/02_Kernel_Configuration/"
cp "$PROJECT_ROOT/kernel/config-6.12.117+deb13-amd64" "$SUB_DIR/02_Kernel_Configuration/"
cp "$PROJECT_ROOT/kernel/.config" "$SUB_DIR/02_Kernel_Configuration/"
cp "$PROJECT_ROOT/kernel/analysis.md" "$SUB_DIR/02_Kernel_Configuration/"
cp "$PROJECT_ROOT/documentation/testing/kernel_comparison.md" "$SUB_DIR/02_Kernel_Configuration/"

echo "=== 4. Populating 03_System_Configuration ==="
cp -r "$PROJECT_ROOT/system"/* "$SUB_DIR/03_System_Configuration/"

echo "=== 5. Populating 04_Build_Scripts ==="
cp "$PROJECT_ROOT/build"/*.sh "$SUB_DIR/04_Build_Scripts/"
cp "$PROJECT_ROOT/build/checksum.sha256" "$SUB_DIR/04_Build_Scripts/" 2>/dev/null || true

echo "=== 6. Populating 05_Testing_and_Benchmarks ==="
cp -r "$PROJECT_ROOT/benchmarks" "$SUB_DIR/05_Testing_and_Benchmarks/"
cp -r "$PROJECT_ROOT/tests" "$SUB_DIR/05_Testing_and_Benchmarks/"
cp "$PROJECT_ROOT/run_all_demo.sh" "$SUB_DIR/05_Testing_and_Benchmarks/"
cp "$PROJECT_ROOT/all_commands.txt" "$SUB_DIR/05_Testing_and_Benchmarks/"
cp "$PROJECT_ROOT/generate_pdf_guide.py" "$SUB_DIR/05_Testing_and_Benchmarks/"
cp "$PROJECT_ROOT/CUDA_Lite_Linux_Professor_Demo_Guide.pdf" "$SUB_DIR/05_Testing_and_Benchmarks/"

echo "=== 7. Populating 06_Documentation ==="
cp "$PROJECT_ROOT/documentation/FINAL_PROJECT_REPORT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/FINAL_PROJECT_REPORT.pdf" "$SUB_DIR/06_Documentation/" 2>/dev/null || true
cp "$PROJECT_ROOT/documentation/PROJECT_OVERVIEW.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/SYSTEM_ARCHITECTURE.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/BUILD_GUIDE.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/INSTALLATION_GUIDE.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/TESTING_AND_VERIFICATION.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/BENCHMARK_REPORT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/SECURITY_REPORT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/KNOWN_LIMITATIONS.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/THIRD_PARTY_LICENSES.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/SUBMISSION_CHECKLIST.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/ASSIGNMENT_COMPLIANCE_MATRIX.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/DEMO_SCRIPT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/BUILD_AND_REPRODUCTION_GUIDE.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/REPRODUCIBLE_BUILD_GUIDE.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/FINAL_AUDIT_REPORT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/FINAL_INDEPENDENT_VERIFICATION.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/FINAL_PROJECT_COMPLETION_REPORT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/FINAL_REQUIREMENTS_AUDIT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/REPORT.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/architecture.md" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/documentation/build_log.md" "$SUB_DIR/06_Documentation/"
cp -r "$PROJECT_ROOT/documentation/testing" "$SUB_DIR/06_Documentation/"
cp -r "$PROJECT_ROOT/documentation/security" "$SUB_DIR/06_Documentation/"
cp "$PROJECT_ROOT/README.md" "$SUB_DIR/06_Documentation/"

echo "=== 8. Populating 07_Screenshots_and_Evidence ==="
cp -r "$PROJECT_ROOT/documentation/FINAL_PROJECT_REPORT_ASSETS"/* "$SUB_DIR/07_Screenshots_and_Evidence/" 2>/dev/null || true
cp "$PROJECT_ROOT/documentation/testing"/*.log "$SUB_DIR/07_Screenshots_and_Evidence/" 2>/dev/null || true
cp "$PROJECT_ROOT/kernel/build_logs"/* "$SUB_DIR/07_Screenshots_and_Evidence/" 2>/dev/null || true

echo "=== 9. Populating 08_Licenses_and_Manifest ==="
cp "$PROJECT_ROOT/documentation/PACKAGE_MANIFEST.csv" "$SUB_DIR/08_Licenses_and_Manifest/"
cp "$PROJECT_ROOT/documentation/PACKAGE_MANIFEST.md" "$SUB_DIR/08_Licenses_and_Manifest/"
cp "$PROJECT_ROOT/documentation/LICENCE_INVENTORY.md" "$SUB_DIR/08_Licenses_and_Manifest/"
cp "$PROJECT_ROOT/documentation/LICENCE_AND_PROPRIETARY_COMPONENTS.md" "$SUB_DIR/08_Licenses_and_Manifest/"
cp "$PROJECT_ROOT/packages/package_manifest.txt" "$SUB_DIR/08_Licenses_and_Manifest/"
cp "$PROJECT_ROOT/packages/licence_inventory.md" "$SUB_DIR/08_Licenses_and_Manifest/"
cp "$PROJECT_ROOT/packages/exclusions.txt" "$SUB_DIR/08_Licenses_and_Manifest/"

echo "=== 10. Generating Final Submission ZIP Archive ==="
cd "$PROJECT_ROOT/submission"
rm -f "$FINAL_ZIP"
zip -r "$FINAL_ZIP" "CUDA_Lite_Final_Submission" -x "*.git*" "*__pycache__*" "*.tmp*" "*.bak*"

echo "=== 11. Verifying ZIP Archive Integrity ==="
unzip -t "$FINAL_ZIP"

echo "=== Final Packaging Complete! ==="
ls -lh "$FINAL_ZIP"
sha256sum "$FINAL_ZIP"
