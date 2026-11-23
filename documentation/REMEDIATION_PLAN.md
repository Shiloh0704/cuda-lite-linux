# CUDA-Lite Linux Distribution — Prioritised Remediation & Resolution Plan

**Project Track:** Track C — Application-Specific Linux Distribution for NVIDIA CUDA Computing  
**Author:** Senior Linux Distribution Engineer & Systems Specialist  
**Target Hardware:** HP Victus Laptop — Intel Core i5-13420H & NVIDIA GeForce RTX 4050 Laptop GPU (Ada Lovelace, sm_89, 6 GB GDDR6)  
**Date of Completion:** 2026-11-22  

---

## 1. Remediation Policy & Severity Hierarchy

Issues discovered during the project lifecycle are categorized into five rigorous severity levels:
- **CRITICAL**: Prevents boot, filesystem mounting, or basic operating system operation.
- **HIGH**: Major assignment requirement missing or non-compliant.
- **MEDIUM**: Subsystem improvement, performance bottleneck, or missing empirical evidence.
- **LOW**: Documentation correction, manifest formatting, or presentation update.
- **OPTIONAL**: Useful system enhancement not strictly mandated by assignment rubrics.

---

## 2. Issues Audit & Resolution Ledger

### Issue 1: `cuda-lite-autostart.service` Failed with `203/EXEC`
- **Severity:** **HIGH**
- **Symptom:** In earlier ISO boots, `cuda-lite-autostart.service` failed with `Main process exited, code=exited, status=203/EXEC`.
- **Root Cause Analysis:** The script `/usr/local/sbin/cuda-lite-startup` had formatting/shebang inconsistencies in older images, and the systemd unit executed the binary path directly (`ExecStart=/usr/local/sbin/cuda-lite-startup`) relying on kernel `execve` binfmt_script parsing without a direct interpreter.
- **Evaluated Solutions:**
  1. *Approach A:* Add a wrapper shell script in `/bin/`.
  2. *Approach B:* Ensure strict POSIX `#!/bin/bash` with Unix LF line endings on line 1, and configure systemd to invoke explicitly: `ExecStart=/bin/bash /usr/local/sbin/cuda-lite-startup`.
- **Selected Resolution:** *Approach B*. Guarantees execution under all environments regardless of executable bit or path formatting.
- **Verification Evidence:** QEMU serial boot log confirms `[  OK  ] Finished cuda-lite-autostart.service - CUDA-Lite Linux GPU Diagnostic and Benchmark.` with exit code 0.
- **Status:** **RESOLVED & VERIFIED (PASS)**

---

### Issue 2: `systemd-modules-load.service` Failed During Virtual Boot
- **Severity:** **HIGH**
- **Symptom:** During QEMU boot, `systemd-modules-load.service` exited with `status=1/FAILURE`.
- **Root Cause Analysis:** Static configuration files in `/etc/modules-load.d/` (`cuda-lite-nvidia.conf` and `nvidia.conf`) unconditionally forced the kernel to load `nvidia` and `nvidia_uvm` during early userland startup. On virtual CPUs without GPU passthrough, `nvidia.ko` failed with `NVRM: No NVIDIA GPU found`, returning status 1 and crashing `systemd-modules-load`.
- **Evaluated Solutions:**
  1. *Approach A:* Disable `systemd-modules-load.service` entirely. (Rejected: breaks other legitimate kernel module autoloading).
  2. *Approach B (Canonical Linux Solution):* Remove static module loading from `/etc/modules-load.d/` (mask `nvidia.conf` to `/dev/null` and delete `cuda-lite-nvidia.conf`). Implement **dynamic hardware-aware udev autoloading** via `/etc/udev/rules.d/99-nvidia.rules` matching NVIDIA PCI vendor `0x10de`.
- **Selected Resolution:** *Approach B*. When booted in QEMU, udev sees no `0x10de` device and never attempts `modprobe`. When booted on bare-metal hardware with the RTX 4050, udev instantly triggers `modprobe nvidia` and `modprobe nvidia-uvm`.
- **Verification Evidence:** QEMU serial boot log shows `systemd-modules-load.service` completed in 1.2s with `[  OK  ]`.
- **Status:** **RESOLVED & VERIFIED (PASS)**

---

### Issue 3: Ineffective PCI Vendor Check Causing Boot Latency
- **Severity:** **MEDIUM**
- **Symptom:** Startup diagnostic script executed redundant 15-second modprobe retries during QEMU boot, bloating boot time by over 58 seconds.
- **Root Cause Analysis:** The check `lspci -d 10de: >/dev/null 2>&1` returned exit code 0 even when zero devices matched because `lspci` filters device lists and considers "0 devices found" a successful query.
- **Evaluated Solutions:**
  1. *Approach A:* String-match output: `[ -n "$(lspci -d 10de: 2>/dev/null)" ]`.
  2. *Approach B:* Direct kernel sysfs inspection: `grep -qs "0x10de" /sys/bus/pci/devices/*/vendor 2>/dev/null`.
- **Selected Resolution:** *Approach B*. Sysfs is native to the Linux kernel, operates in sub-millisecond time without spawning child processes or requiring `pciutils` binary presence, and provides an authoritative hardware presence check.
- **Verification Evidence:** Startup script immediately logs `Notice: No NVIDIA PCI device detected on the bus (virtual/QEMU environment). CUDA diagnostic benchmark skipped.` in 0.02s. Boot time dropped from 142.6s to 84.6s (40.7% speedup).
- **Status:** **RESOLVED & VERIFIED (PASS)**

---

### Issue 4: Kernel `.config` Not Tracked in Repository
- **Severity:** **MEDIUM**
- **Symptom:** Kernel configuration `.config` existed inside rootfs `/boot/` but was not tracked in the `kernel/` source directory for git submission.
- **Root Cause Analysis:** The build script bootstrapped Debian kernels and maintained configuration files inside the temporary chroot rather than syncing back to the project repository.
- **Selected Resolution:** Extracted `/var/tmp/cuda-lite-build/rootfs/boot/config-6.12.117+deb13-amd64` to `kernel/config-6.12.117+deb13-amd64` and `kernel/.config`.
- **Verification Evidence:** File size 283,598 bytes confirmed in `kernel/` directory and verified in git status.
- **Status:** **RESOLVED & VERIFIED (PASS)**

---

### Issue 5: Missing Package Manifest in CSV Format
- **Severity:** **LOW**
- **Symptom:** Package inventory existed as text list in `packages/package_manifest.txt`, but a structured CSV manifest was missing.
- **Selected Resolution:** Authored automated parser for `/var/lib/dpkg/status`, extracting Package, Version, Section, InstalledSizeKB, License, Classification, and Purpose across all 267 packages into `documentation/PACKAGE_MANIFEST.csv`.
- **Verification Evidence:** 267 rows generated, verified, and cataloged.
- **Status:** **RESOLVED & VERIFIED (PASS)**

---

### Issue 6: Comprehensive License Inventory Documentation
- **Severity:** **LOW**
- **Symptom:** General license descriptions existed, but lacked an exhaustive redistribution audit covering NVIDIA EULA terms, GSP firmware blobs, and DFSG guidelines.
- **Selected Resolution:** Created `documentation/LICENCE_INVENTORY.md` detailing Section 2.1 CUDA EULA terms, Open GPU kernel module MIT/GPL dual licensing, and DFSG compliance across all package categories.
- **Verification Evidence:** Published in `documentation/LICENCE_INVENTORY.md`.
- **Status:** **RESOLVED & VERIFIED (PASS)**

---

## 3. Remediation Summary Table

| Issue # | Component | Severity | Resolution Summary | Final Status |
| :-: | :--- | :---: | :--- | :---: |
| **1** | `cuda-lite-autostart.service` | HIGH | Added explicit `/bin/bash` invocation and Unix LF shebang | **PASS** |
| **2** | `systemd-modules-load.service` | HIGH | Deployed dynamic udev rule `99-nvidia.rules`; masked static config | **PASS** |
| **3** | Hardware PCI Vendor Probing | MEDIUM | Sysfs vendor inspection (`0x10de`); 40.7% faster boot | **PASS** |
| **4** | Kernel `.config` Deliverable | MEDIUM | Extracted `.config` from rootfs into `kernel/` directory | **PASS** |
| **5** | Package Manifest CSV | LOW | Parsed 267 packages into `documentation/PACKAGE_MANIFEST.csv` | **PASS** |
| **6** | Software License Inventory | LOW | Published exhaustive audit in `documentation/LICENCE_INVENTORY.md` | **PASS** |
