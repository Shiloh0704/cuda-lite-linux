import zipfile
import os
import sys

ZIP_PATH = "/mnt/c/Users/shilo/OneDrive/OS_Project/submission/CUDA_Lite_Final_Submission.zip"
EXTRACT_DIR = "/tmp/test_audit_extract"

print("=================================================================")
print("  CUDA-Lite Final Submission ZIP: Comprehensive Read-Only Audit  ")
print(f"  Target Archive: {ZIP_PATH}")
print("=================================================================")

if not os.path.exists(ZIP_PATH):
    print(f"ERROR: Archive not found at {ZIP_PATH}")
    sys.exit(1)

stat_info = os.stat(ZIP_PATH)
print(f"Archive Size: {stat_info.st_size:,} bytes ({stat_info.st_size / (1024*1024):.2f} MiB)")

zf = zipfile.ZipFile(ZIP_PATH, 'r')

# Check 1: CRC32 Integrity Test
print("\n--- Check 1: CRC32 Internal Consistency ---")
bad_file = zf.testzip()
if bad_file:
    print(f"FAIL: Corrupt file detected in archive: {bad_file}")
    sys.exit(1)
else:
    print("PASS: 100% of files passed CRC32 cyclic redundancy checks (0 errors).")

# Check 2: Top-level Directory & Required 8 Subdirectories
print("\n--- Check 2: Verifying Required 8 Modules ---")
REQUIRED_DIRS = [
    "CUDA_Lite_Final_Submission/01_Source_Code/",
    "CUDA_Lite_Final_Submission/02_Kernel_Configuration/",
    "CUDA_Lite_Final_Submission/03_System_Configuration/",
    "CUDA_Lite_Final_Submission/04_Build_Scripts/",
    "CUDA_Lite_Final_Submission/05_Testing_and_Benchmarks/",
    "CUDA_Lite_Final_Submission/06_Documentation/",
    "CUDA_Lite_Final_Submission/07_Screenshots_and_Evidence/",
    "CUDA_Lite_Final_Submission/08_Licenses_and_Manifest/"
]

all_entries = zf.namelist()
missing_dirs = []
for req_dir in REQUIRED_DIRS:
    found = any(entry.startswith(req_dir) for entry in all_entries)
    if found:
        print(f"  [PASS] Found: {req_dir}")
    else:
        print(f"  [FAIL] Missing: {req_dir}")
        missing_dirs.append(req_dir)

if missing_dirs:
    print(f"FAIL: Missing {len(missing_dirs)} required directories.")
else:
    print("PASS: All 8 required modules are present.")

# Check 3: Zero-byte / Empty Files Check
print("\n--- Check 3: Scanning for 0-Byte / Empty Files ---")
empty_files = []
non_empty_count = 0
for info in zf.infolist():
    if not info.is_dir():
        if info.file_size == 0:
            print(f"  [WARNING/EMPTY] 0-byte file: {info.filename}")
            empty_files.append(info.filename)
        else:
            non_empty_count += 1

print(f"Total files: {non_empty_count} non-empty regular files.")
if empty_files:
    print(f"Notice: {len(empty_files)} empty file(s) found.")
else:
    print("PASS: Zero 0-byte empty files detected.")

# Check 4: Verifying Key Required Documents
print("\n--- Check 4: Verifying Mandatory Core Documents ---")
MANDATORY_FILES = [
    "CUDA_Lite_Final_Submission/06_Documentation/FINAL_PROJECT_REPORT.md",
    "CUDA_Lite_Final_Submission/06_Documentation/PROJECT_OVERVIEW.md",
    "CUDA_Lite_Final_Submission/06_Documentation/SYSTEM_ARCHITECTURE.md",
    "CUDA_Lite_Final_Submission/06_Documentation/BUILD_GUIDE.md",
    "CUDA_Lite_Final_Submission/06_Documentation/INSTALLATION_GUIDE.md",
    "CUDA_Lite_Final_Submission/06_Documentation/TESTING_AND_VERIFICATION.md",
    "CUDA_Lite_Final_Submission/06_Documentation/BENCHMARK_REPORT.md",
    "CUDA_Lite_Final_Submission/06_Documentation/SECURITY_REPORT.md",
    "CUDA_Lite_Final_Submission/06_Documentation/KNOWN_LIMITATIONS.md",
    "CUDA_Lite_Final_Submission/06_Documentation/THIRD_PARTY_LICENSES.md",
    "CUDA_Lite_Final_Submission/06_Documentation/SUBMISSION_CHECKLIST.md",
    "CUDA_Lite_Final_Submission/06_Documentation/ASSIGNMENT_COMPLIANCE_MATRIX.md",
    "CUDA_Lite_Final_Submission/08_Licenses_and_Manifest/PACKAGE_MANIFEST.csv",
    "CUDA_Lite_Final_Submission/08_Licenses_and_Manifest/LICENCE_INVENTORY.md",
    "CUDA_Lite_Final_Submission/01_Source_Code/cuda/matrix_mul.cu",
    "CUDA_Lite_Final_Submission/01_Source_Code/cuda/device_query.cu",
    "CUDA_Lite_Final_Submission/01_Source_Code/cudnn/test_cudnn.cpp",
    "CUDA_Lite_Final_Submission/02_Kernel_Configuration/custom/vmlinuz-6.12.0-cuda-lite",
    "CUDA_Lite_Final_Submission/04_Build_Scripts/build_iso.sh",
    "CUDA_Lite_Final_Submission/04_Build_Scripts/build_candidate_iso.sh"
]

missing_mandatory = []
for mf in MANDATORY_FILES:
    if mf in all_entries:
        size = zf.getinfo(mf).file_size
        print(f"  [PASS] {mf} ({size:,} bytes)")
    else:
        print(f"  [FAIL] Missing: {mf}")
        missing_mandatory.append(mf)

# Check 5: Extraction into Temporary Directory
print(f"\n--- Check 5: Extracting into Temporary Sandbox ({EXTRACT_DIR}) ---")
os.system(f"rm -rf {EXTRACT_DIR} && mkdir -p {EXTRACT_DIR}")
zf.extractall(EXTRACT_DIR)
extracted_files = [os.path.join(dp, f) for dp, dn, filenames in os.walk(EXTRACT_DIR) for f in filenames]
print(f"PASS: Extracted {len(extracted_files)} files cleanly onto filesystem.")

# Check 6: PDF Reports Structural Validation
print("\n--- Check 6: PDF Structure & Magic Header Validation ---")
pdf_files = [f for f in extracted_files if f.endswith(".pdf")]
for pdf in pdf_files:
    with open(pdf, 'rb') as f:
        header = f.read(10)
        f.seek(-1024, os.SEEK_END)
        tail = f.read(1024)
    has_magic = header.startswith(b'%PDF-')
    has_eof = b'%%EOF' in tail
    size = os.path.getsize(pdf)
    print(f"  File: {os.path.basename(pdf)}")
    print(f"    Size: {size:,} bytes")
    print(f"    Magic Header (%PDF-): {'VALID' if has_magic else 'INVALID'}")
    print(f"    Trailer (%%EOF):      {'VALID' if has_eof else 'INVALID'}")
    if has_magic and has_eof:
        print(f"    Result: PASS (Valid PDF)")
    else:
        print(f"    Result: FAIL (Corrupted PDF)")

# Cleanup temporary extraction directory
os.system(f"rm -rf {EXTRACT_DIR}")
print("\nCleaned up temporary sandbox.")

print("\n=================================================================")
print("  Final Audit Conclusion: All Verification Checks Completed     ")
print("=================================================================")
