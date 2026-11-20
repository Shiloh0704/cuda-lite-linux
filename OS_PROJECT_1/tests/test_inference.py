#!/usr/bin/env python3
"""
Automated Inference Application Test Suite for EdgeML Linux OS
Tests: edgeml-infer binary
Validates image loading, error handling, Top-K predictions, latency, and memory telemetry.
"""

import os
import sys
import subprocess
import tempfile

def run_test(name, cmd, expected_returncodes=[0], expect_in_output=[], expect_in_error=[]):
    print(f"[TEST] {name} ... ", end="", flush=True)
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    
    if res.returncode not in expected_returncodes:
        print(f"FAILED (Unexpected returncode {res.returncode}, expected {expected_returncodes})")
        print(f"Stdout:\n{res.stdout}")
        print(f"Stderr:\n{res.stderr}")
        return False

    for s in expect_in_output:
        if s not in res.stdout:
            print(f"FAILED (Missing string in stdout: '{s}')")
            return False

    for s in expect_in_error:
        if s not in res.stderr and s not in res.stdout:
            print(f"FAILED (Missing error string: '{s}')")
            return False

    print("PASSED")
    return True

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    
    # Locate edgeml-infer binary
    binary_paths = [
        "/usr/bin/edgeml-infer",
        os.path.join(project_root, "application", "edgeml-infer"),
        os.path.join(project_root, "build", "edgeml-infer")
    ]
    binary = None
    for bp in binary_paths:
        if os.path.isfile(bp) and os.access(bp, os.X_OK):
            binary = bp
            break
            
    if not binary:
        print(f"ERROR: Cannot find executable edgeml-infer in {binary_paths}")
        sys.exit(1)

    print("=====================================================================")
    print("      EdgeML Linux OS: Automated Inference Application Tests        ")
    print("=====================================================================")
    print(f"Testing Binary:  {binary}")
    
    test_img = os.path.join(project_root, "tests", "test.jpg")
    model_path = os.path.join(project_root, "models", "mobilenet_v2_quant.tflite")
    labels_path = os.path.join(project_root, "models", "labels.txt")

    passed = 0
    total = 5

    # Test 1: Valid Image Inference
    if run_test(
        "Valid Image Classification & Top-5 Predictions",
        [binary, test_img, model_path, labels_path],
        expected_returncodes=[0],
        expect_in_output=["TOP-5 PREDICTIONS", "Inference Execution Time", "Peak Memory Consumption", " #1 "]
    ):
        passed += 1

    # Test 2: Missing Image Argument
    if run_test(
        "Missing Arguments Error Handling",
        [binary],
        expected_returncodes=[1],
        expect_in_error=["Usage: edgeml-infer"]
    ):
        passed += 1

    # Test 3: Non-existent Image File
    if run_test(
        "Non-Existent Image File Handling",
        [binary, "/tmp/nonexistent_image_12345.jpg", model_path, labels_path],
        expected_returncodes=[2],
        expect_in_error=["Image file does not exist"]
    ):
        passed += 1

    # Test 4: Corrupt Image Format
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f:
        f.write(b"NOT_A_VALID_JPEG_HEADER_CORRUPTED_BYTES_1234567890")
        corrupt_file = f.name

    try:
        if run_test(
            "Corrupt Image Format Handling",
            [binary, corrupt_file, model_path, labels_path],
            expected_returncodes=[3],
            expect_in_error=["Invalid or unsupported image format"]
        ):
            passed += 1
    finally:
        if os.path.exists(corrupt_file):
            os.remove(corrupt_file)

    # Test 5: Missing Model File Handling
    if run_test(
        "Missing Model File Handling",
        [binary, test_img, "/tmp/nonexistent_model.tflite", labels_path],
        expected_returncodes=[4],
        expect_in_error=["Model file not found"]
    ):
        passed += 1

    print("=====================================================================")
    print(f"INFERENCE APPLICATION TEST RESULTS: {passed}/{total} PASSED")
    print("=====================================================================")
    sys.exit(0 if passed == total else 1)

if __name__ == "__main__":
    main()
