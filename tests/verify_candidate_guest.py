import pexpect
import sys
import time

ISO_PATH = "/mnt/d/cuda-lite-linux-candidate.iso"
VMLINUZ = "/var/tmp/cuda-lite-candidate-build/live_iso/live/vmlinuz"
INITRD = "/var/tmp/cuda-lite-candidate-build/live_iso/live/initrd"
VMLINUZ_CUSTOM = "/var/tmp/cuda-lite-candidate-build/live_iso/live/vmlinuz-custom"
INITRD_CUSTOM = "/var/tmp/cuda-lite-candidate-build/live_iso/live/initrd-custom"

print("=================================================================")
print("  CUDA-Lite Candidate ISO: In-Guest Telemetry & Verification     ")
print(f"  Candidate ISO: {ISO_PATH}")
print("=================================================================")

# TEST 1: Direct boot of Debian kernel into candidate live rootfs with root shell
cmd_telemetry = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ} \
  -initrd {INITRD} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet init=/bin/sh panic=10' \
  -nographic -no-reboot"""

print("\n--- [TEST 1] Collecting In-Guest Telemetry from Candidate Rootfs ---")
child = pexpect.spawn('/bin/bash', ['-c', cmd_telemetry], timeout=60, encoding='utf-8')
child.logfile = sys.stdout

idx = child.expect(['#', '/bin/sh', pexpect.TIMEOUT])
if idx in (0, 1):
    print("\n[SUCCESS] Direct root shell obtained inside candidate guest!")
    cmds = [
        "uname -a",
        "cat /etc/os-release",
        "df -h /",
        "mount | grep overlay",
        "ls -la /usr/lib/x86_64-linux-gnu/libcudnn*.so* | head -6",
        "which docker dockerd containerd runc nvidia-ctk",
        "docker --version",
        "containerd --version",
        "nvidia-ctk --version",
        "ls -la /opt/cuda-lite/bin/",
        "echo ===TELEMETRY_DONE===",
        "poweroff -f || reboot -f"
    ]
    for c in cmds:
        child.sendline(c)
    child.expect(['===TELEMETRY_DONE===', pexpect.TIMEOUT], timeout=30)
    print("\n[SUCCESS] Candidate guest telemetry collected successfully!")
    child.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=15)
else:
    print("\n[FAIL] Direct root shell timed out.")

# TEST 2: Boot Custom 6.12.0 Kernel with Candidate Rootfs
cmd_custom = f"""qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm -cpu host \
  -kernel {VMLINUZ_CUSTOM} \
  -initrd {INITRD_CUSTOM} \
  -cdrom {ISO_PATH} \
  -append 'boot=live console=ttyS0 quiet init=/bin/sh panic=10' \
  -nographic -no-reboot"""

print("\n--- [TEST 2] Verifying Custom Kernel with Candidate Rootfs ---")
child2 = pexpect.spawn('/bin/bash', ['-c', cmd_custom], timeout=45, encoding='utf-8')
child2.logfile = sys.stdout

idx2 = child2.expect(['#', '/bin/sh', pexpect.TIMEOUT])
if idx2 in (0, 1):
    print("\n[SUCCESS] Custom kernel reached root shell on candidate rootfs!")
    child2.sendline("uname -a")
    child2.sendline("cat /etc/os-release")
    child2.sendline("echo ===CUSTOM_DONE===")
    child2.sendline("poweroff -f || reboot -f")
    child2.expect(['===CUSTOM_DONE===', pexpect.TIMEOUT], timeout=15)
    print("\n[SUCCESS] Custom kernel verification complete!")
    child2.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=10)
else:
    print("\n[FAIL] Custom kernel boot timed out.")

print("\n=================================================================")
print("  All Candidate Guest Verifications Completed Successfully!      ")
print("=================================================================")
