import pexpect
import sys
import time

ISO_PATH = "/mnt/d/cuda-lite-linux-candidate.iso"
VMLINUZ = "/var/tmp/cuda-lite-candidate-build/live_iso/live/vmlinuz"
INITRD = "/var/tmp/cuda-lite-candidate-build/live_iso/live/initrd"

cmd = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ} \
  -initrd {INITRD} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet panic=10' \
  -nographic -no-reboot"""

print("Starting QEMU systemd boot verification...")
start_time = time.time()
child = pexpect.spawn('/bin/bash', ['-c', cmd], timeout=90, encoding='utf-8')
child.logfile = sys.stdout

idx = child.expect(['cuda-lite login:', pexpect.TIMEOUT, pexpect.EOF])
elapsed = time.time() - start_time

if idx == 0:
    print(f"\n[SUCCESS] Candidate ISO reached systemd login prompt in {elapsed:.2f} seconds!")
else:
    print(f"\n[FAIL] Did not reach login prompt within {elapsed:.2f}s.")

child.close(force=True)
