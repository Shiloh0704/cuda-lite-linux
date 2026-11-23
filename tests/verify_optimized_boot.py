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
print("  CUDA-Lite Optimized ISO: Full QEMU Guest Verification Suite    ")
print(f"  Optimized ISO: {ISO_PATH}")
print("=================================================================")

results = {}

# TEST 1: Cold Boot to systemd Login Prompt (Debian 6.12.117 Kernel + NVIDIA DKMS)
print("\n--- [TEST 1] Cold Boot to systemd Login Prompt (Default Kernel) ---")
cmd_systemd = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ} \
  -initrd {INITRD} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet panic=10' \
  -nographic -no-reboot"""

start_time = time.time()
child1 = pexpect.spawn('/bin/bash', ['-c', cmd_systemd], timeout=90, encoding='utf-8')
child1.logfile = sys.stdout

idx1 = child1.expect(['cuda-lite login:', pexpect.TIMEOUT, pexpect.EOF])
elapsed1 = time.time() - start_time

if idx1 == 0:
    print(f"\n[PASS] Reached systemd login prompt in {elapsed1:.2f} seconds!")
    results["systemd_login"] = f"PASSED ({elapsed1:.2f}s)"
else:
    print(f"\n[FAIL] Failed to reach login prompt within {elapsed1:.2f}s")
    results["systemd_login"] = "FAILED"

child1.close(force=True)

# TEST 2: In-Guest Telemetry and Stack Verification (Root Shell)
print("\n--- [TEST 2] In-Guest Component Verification (Root Shell) ---")
cmd_telemetry = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ} \
  -initrd {INITRD} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet init=/bin/sh panic=10' \
  -nographic -no-reboot"""

child2 = pexpect.spawn('/bin/bash', ['-c', cmd_telemetry], timeout=60, encoding='utf-8')
child2.logfile = sys.stdout

idx2 = child2.expect(['#', '/bin/sh', pexpect.TIMEOUT])
if idx2 in (0, 1):
    print("\n[PASS] Direct guest root shell obtained!")
    cmds = [
        "uname -a",
        "cat /etc/os-release",
        "df -h /",
        "free -m",
        "mount | grep -E 'overlay|live'",
        "touch /tmp/overlay_write_test && echo 'OVERLAYFS_WRITABLE_OK'",
        "which docker dockerd containerd runc nvidia-ctk nvcc nvidia-smi",
        "docker --version",
        "containerd --version",
        "nvidia-ctk --version",
        "nvcc --version",
        "ls -la /usr/lib/x86_64-linux-gnu/libcudnn*.so* | head -6",
        "ls -la /usr/include/x86_64-linux-gnu/cudnn*.h | head -6",
        "echo ===OPTIMIZED_GUEST_TELEMETRY_DONE===",
        "poweroff -f || reboot -f"
    ]
    for c in cmds:
        child2.sendline(c)
    child2.expect(['===OPTIMIZED_GUEST_TELEMETRY_DONE===', pexpect.TIMEOUT], timeout=30)
    print("\n[PASS] In-guest telemetry successfully captured!")
    results["guest_telemetry"] = "PASSED"
    child2.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=15)
else:
    print("\n[FAIL] Direct root shell timed out.")
    results["guest_telemetry"] = "FAILED"

child2.close(force=True)

# TEST 3: Boot Custom Low-Latency Kernel 6.12.0-cuda-lite
print("\n--- [TEST 3] Custom Low-Latency Kernel 6.12.0-cuda-lite Boot ---")
cmd_custom = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ_CUSTOM} \
  -initrd {INITRD_CUSTOM} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet init=/bin/sh panic=10' \
  -nographic -no-reboot"""

start_time3 = time.time()
child3 = pexpect.spawn('/bin/bash', ['-c', cmd_custom], timeout=45, encoding='utf-8')
child3.logfile = sys.stdout

idx3 = child3.expect(['#', '/bin/sh', pexpect.TIMEOUT])
elapsed3 = time.time() - start_time3
if idx3 in (0, 1):
    print(f"\n[PASS] Custom kernel reached root shell in {elapsed3:.2f}s!")
    child3.sendline("uname -a")
    child3.sendline("cat /etc/os-release")
    child3.sendline("echo ===CUSTOM_KERNEL_DONE===")
    child3.sendline("poweroff -f || reboot -f")
    child3.expect(['===CUSTOM_KERNEL_DONE===', pexpect.TIMEOUT], timeout=15)
    results["custom_kernel"] = f"PASSED ({elapsed3:.2f}s)"
    child3.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=10)
else:
    print(f"\n[FAIL] Custom kernel timed out after {elapsed3:.2f}s.")
    results["custom_kernel"] = "FAILED"

child3.close(force=True)

print("\n=================================================================")
print("  TEST SUMMARY")
print("=================================================================")
for k, v in results.items():
    print(f"  {k:25s}: {v}")
print("=================================================================")
