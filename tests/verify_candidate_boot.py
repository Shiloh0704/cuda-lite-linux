import pexpect
import sys
import time

ISO_PATH = "/mnt/d/cuda-lite-linux-candidate.iso"

print("=================================================================")
print("  CUDA-Lite Linux Candidate ISO: Automated QEMU Verification     ")
print(f"  Target ISO: {ISO_PATH}")
print("=================================================================")

cmd = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -cdrom {ISO_PATH} \
  -boot d \
  -nographic -no-reboot"""

print("Starting QEMU process...")
start_time = time.time()
child = pexpect.spawn('/bin/bash', ['-c', cmd], timeout=60, encoding='utf-8')
child.logfile = sys.stdout

idx = child.expect(['cuda-lite login:', pexpect.TIMEOUT, pexpect.EOF])
boot_duration = time.time() - start_time

if idx == 0:
    print(f"\n\n[SUCCESS] Candidate ISO reached login prompt in {boot_duration:.2f} seconds!")
else:
    print("\n\n[FAIL] Did not reach login prompt within timeout.")

child.close(force=True)
