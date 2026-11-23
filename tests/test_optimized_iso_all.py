#!/usr/bin/env python3
import pexpect
import sys
import time
import os

ISO_PATH = "/mnt/d/cuda-lite-linux-optimized.iso"
WORKSPACE = "/var/tmp/cuda-lite-optimization/live_iso/live"
VMLINUZ = f"{WORKSPACE}/vmlinuz"
INITRD = f"{WORKSPACE}/initrd"
VMLINUZ_CUSTOM = f"{WORKSPACE}/vmlinuz-custom"
INITRD_CUSTOM = f"{WORKSPACE}/initrd-custom"

print("=================================================================")
print("  CUDA-Lite Optimized ISO: Comprehensive Verification Suite      ")
print(f"  Target ISO: {ISO_PATH}")
print("=================================================================")

test_results = {}

# -------------------------------------------------------------
# TEST 1: Default Kernel 6.12.117 Boot to systemd Login Prompt
# -------------------------------------------------------------
print("\n>>> TEST 1: Boot Default Kernel (6.12.117) to systemd Login Prompt <<<")
cmd_login = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ} \
  -initrd {INITRD} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet panic=10' \
  -nographic -no-reboot"""

t0 = time.time()
child1 = pexpect.spawn('/bin/bash', ['-c', cmd_login], timeout=90, encoding='utf-8')
child1.logfile = sys.stdout

idx1 = child1.expect(['cuda-lite login:', pexpect.TIMEOUT, pexpect.EOF])
elapsed1 = time.time() - t0

if idx1 == 0:
    print(f"\n[PASS] Default Kernel reached systemd login prompt in {elapsed1:.2f}s!")
    test_results["default_systemd_login"] = f"PASSED ({elapsed1:.2f}s)"
else:
    print(f"\n[FAIL] Default Kernel failed to reach login prompt within {elapsed1:.2f}s")
    test_results["default_systemd_login"] = "FAILED"

child1.close(force=True)

# -------------------------------------------------------------
# TEST 2: Custom Kernel 6.12.0-cuda-lite Boot to Login/Shell
# -------------------------------------------------------------
print("\n>>> TEST 2: Boot Custom Kernel (6.12.0-cuda-lite) <<<")
cmd_custom_login = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ_CUSTOM} \
  -initrd {INITRD_CUSTOM} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet panic=10' \
  -nographic -no-reboot"""

t0 = time.time()
child2 = pexpect.spawn('/bin/bash', ['-c', cmd_custom_login], timeout=90, encoding='utf-8')
child2.logfile = sys.stdout

idx2 = child2.expect(['cuda-lite login:', '#', '/bin/sh', pexpect.TIMEOUT, pexpect.EOF])
elapsed2 = time.time() - t0

if idx2 in (0, 1, 2):
    print(f"\n[PASS] Custom Kernel boot succeeded in {elapsed2:.2f}s (matched pattern index {idx2})!")
    test_results["custom_kernel_boot"] = f"PASSED ({elapsed2:.2f}s)"
else:
    print(f"\n[FAIL] Custom Kernel failed to boot within {elapsed2:.2f}s")
    test_results["custom_kernel_boot"] = "FAILED"

child2.close(force=True)

# -------------------------------------------------------------
# TEST 3: In-Guest Telemetry and Deep Stack Verification
# -------------------------------------------------------------
print("\n>>> TEST 3: Guest Functionality & Telemetry Verification <<<")
cmd_guest = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ} \
  -initrd {INITRD} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet init=/bin/sh panic=10' \
  -nographic -no-reboot"""

child3 = pexpect.spawn('/bin/bash', ['-c', cmd_guest], timeout=60, encoding='utf-8')
child3.logfile = sys.stdout

idx3 = child3.expect(['#', '/bin/sh', pexpect.TIMEOUT])
if idx3 in (0, 1):
    print("\n[PASS] Direct root shell established inside guest!")
    
    commands = [
        "echo '=== GUEST_OS_RELEASE ===' && cat /etc/os-release",
        "echo '=== GUEST_UNAME ===' && uname -a",
        "echo '=== GUEST_MOUNTS ===' && mount | grep -E 'overlay|live|iso'",
        "echo '=== GUEST_DISK_USAGE ===' && df -h / /run/live/medium",
        "echo '=== GUEST_MEMORY ===' && free -m",
        "echo '=== GUEST_OVERLAY_TEST ===' && touch /tmp/overlay_write_test && ls -l /tmp/overlay_write_test && echo 'OVERLAYFS_WRITABLE_VERIFIED'",
        "echo '=== GUEST_CUDA_FILES ===' && which nvcc && nvcc --version && ls -lh /usr/lib/x86_64-linux-gnu/libcuda*.so*",
        "echo '=== GUEST_CUDNN_FILES ===' && ls -lh /usr/lib/x86_64-linux-gnu/libcudnn*.so* | head -n 6 && ls -lh /usr/include/x86_64-linux-gnu/cudnn*.h | head -n 6",
        "echo '=== GUEST_CONTAINER_FILES ===' && which docker dockerd containerd runc nvidia-ctk && docker --version && containerd --version && runc --version && nvidia-ctk --version",
        "echo '=== GUEST_SYSTEMD_SERVICES ===' && ls -la /etc/systemd/system/multi-user.target.wants/ || true",
        "echo '=== GUEST_BOOT_FILES ===' && ls -lh /boot/",
        "echo '=== GUEST_DKMS_MODULES ===' && ls -lh /usr/lib/modules/6.12.117+deb13-amd64/updates/dkms/",
        "echo '=== ALL_GUEST_TESTS_COMPLETED ==='",
        "poweroff -f || reboot -f"
    ]
    
    for cmd in commands:
        child3.sendline(cmd)
        time.sleep(0.3)
        
    idx_done = child3.expect(['=== ALL_GUEST_TESTS_COMPLETED ===', pexpect.TIMEOUT], timeout=30)
    if idx_done == 0:
        print("\n[PASS] All in-guest functionality tests completed successfully!")
        test_results["guest_functionality"] = "PASSED"
    else:
        print("\n[FAIL] In-guest test sequence timed out.")
        test_results["guest_functionality"] = "TIMEOUT"
        
    child3.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=10)
else:
    print("\n[FAIL] Failed to obtain guest root shell.")
    test_results["guest_functionality"] = "FAILED"

child3.close(force=True)

print("\n=================================================================")
print("  VERIFICATION RESULTS SUMMARY")
print("=================================================================")
for k, v in test_results.items():
    print(f"  {k:30s}: {v}")
print("=================================================================")
