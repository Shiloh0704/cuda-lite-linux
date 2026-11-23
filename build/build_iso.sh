#!/usr/bin/env bash
# =============================================================================
# CUDA-Lite Linux - Debian 13 Trixie Live ISO Builder
# Track C: CUDA/GPU Compute Application-Specific Linux
# Architecture: AMD64 / x86-64
# Target GPU: NVIDIA GeForce RTX 4050 (Compute Capability 8.9)
# =============================================================================

set -Eeuo pipefail

# Limit parallel compilation to reduce WSL memory pressure.
export MAKEFLAGS="-j4"

# -----------------------------------------------------------------------------
# 0. Root privilege and required tools
# -----------------------------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run with sudo: sudo ./build/build_iso.sh" >&2
    exit 1
fi

REQUIRED_TOOLS=(
    debootstrap
    chroot
    mount
    umount
    mountpoint
    mksquashfs
    grub-mkrescue
    xorriso
    systemctl
    find
    sort
    sha256sum
    modinfo
    awk
    df
)

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool is missing: $tool" >&2
        exit 1
    fi
done

# -----------------------------------------------------------------------------
# 1. Project and build configuration
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# WSL's Linux filesystem is backed by the Ubuntu VHDX, which is now on D:.
# Keep the large temporary build tree there rather than on the Windows C: mount.
BUILD_DIR="/var/tmp/cuda-lite-build"
ROOTFS="$BUILD_DIR/rootfs"
LIVE_DIR="$BUILD_DIR/live_iso"

ISO_NAME="cuda-lite-linux.iso"
TEMP_ISO="$BUILD_DIR/$ISO_NAME"
OUTPUT_ISO="/mnt/d/$ISO_NAME"
CHECKSUM_FILE="/mnt/d/$ISO_NAME.sha256"

DEBIAN_SUITE="trixie"
DEBIAN_MIRROR="https://deb.debian.org/debian"

# debootstrap requires comma-separated components.
DEBIAN_COMPONENTS="main,contrib,non-free,non-free-firmware"

# APT sources require space-separated components.
DEBIAN_APT_COMPONENTS="main contrib non-free non-free-firmware"

# Check for resume mode to allow completing builds without deleting rootfs.
RESUME_MODE=0
for arg in "$@"; do
    if [[ "$arg" == "--resume" ]]; then
        RESUME_MODE=1
    fi
done
if [[ "${RESUME:-0}" == "1" ]]; then
    RESUME_MODE=1
fi

if [[ "$RESUME_MODE" -eq 1 ]]; then
    if [[ ! -d "$ROOTFS" || ! -f "$ROOTFS/bin/bash" || ! -f "$ROOTFS/var/lib/dpkg/status" ]]; then
        echo "ERROR: --resume requested but rootfs does not exist or is incomplete at $ROOTFS." >&2
        exit 1
    fi
    echo "==============================================================="
    echo "  RESUME MODE: Reusing existing rootfs ($ROOTFS)"
    echo "==============================================================="
fi

if [[ ! -d /mnt/d || ! -w /mnt/d ]]; then
    echo "ERROR: Windows Drive D: is not mounted or is not writable at /mnt/d." >&2
    exit 1
fi

# Require at least 50 GiB free on D: before starting this large build.
AVAILABLE_KB="$(df -Pk /mnt/d | awk 'NR == 2 {print $4}')"
MINIMUM_KB=$((50 * 1024 * 1024))

if [[ -z "$AVAILABLE_KB" || "$AVAILABLE_KB" -lt "$MINIMUM_KB" ]]; then
    echo "ERROR: At least 50 GiB of free space is required on Drive D:." >&2
    df -h /mnt/d
    exit 1
fi

# -----------------------------------------------------------------------------
# 2. Validate project files
# -----------------------------------------------------------------------------

echo "Checking project files..."

REQUIRED_FILES=(
    "$PROJECT_ROOT/cuda/matrix_mul"
    "$PROJECT_ROOT/cuda/device_query"
    "$PROJECT_ROOT/system/fstab.overlay"
    "$PROJECT_ROOT/system/hardening.conf"
    "$PROJECT_ROOT/system/cuda-lite-autostart.service"
    "$PROJECT_ROOT/system/cuda-lite-startup.sh"
    "$PROJECT_ROOT/system/99-nvidia.rules"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Required project file missing: $file" >&2
        exit 1
    fi
done

if [[ ! -x "$PROJECT_ROOT/cuda/matrix_mul" ]]; then
    echo "ERROR: matrix_mul is not executable." >&2
    exit 1
fi

if [[ ! -x "$PROJECT_ROOT/cuda/device_query" ]]; then
    echo "ERROR: device_query is not executable." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# 3. Ask for live user password (skipped in resume mode if user exists)
# -----------------------------------------------------------------------------

CUDA_PASSWORD=""
if [[ "$RESUME_MODE" -eq 1 ]] && grep -q '^cuda:' "$ROOTFS/etc/passwd" 2>/dev/null; then
    echo "Existing 'cuda' user found in rootfs. Skipping password prompt."
else
    echo
    echo "CUDA-Lite will create a normal user named: cuda"
    echo "Enter a password containing at least 10 characters."

    read -r -s -p "Enter password: " CUDA_PASSWORD
    echo

    if [[ -z "$CUDA_PASSWORD" || ${#CUDA_PASSWORD} -lt 10 ]]; then
        echo "ERROR: Password must contain at least 10 characters." >&2
        unset CUDA_PASSWORD
        exit 1
    fi

    read -r -s -p "Confirm password: " CUDA_PASSWORD_CONFIRM
    echo

    if [[ "$CUDA_PASSWORD" != "$CUDA_PASSWORD_CONFIRM" ]]; then
        echo "ERROR: Passwords do not match." >&2
        unset CUDA_PASSWORD CUDA_PASSWORD_CONFIRM
        exit 1
    fi

    unset CUDA_PASSWORD_CONFIRM
fi

# -----------------------------------------------------------------------------
# 4. Cleanup helpers
# -----------------------------------------------------------------------------

cleanup_mounts() {
    local target

    for target in \
        "$ROOTFS/dev/pts" \
        "$ROOTFS/dev" \
        "$ROOTFS/proc" \
        "$ROOTFS/sys"; do

        if mountpoint -q "$target" 2>/dev/null; then
            umount -lf "$target" || true
        fi
    done
}

trap cleanup_mounts EXIT

# -----------------------------------------------------------------------------
# 5. Display build configuration and prepare clean build environment
# -----------------------------------------------------------------------------

echo
echo "==============================================================="
echo "                 CUDA-Lite Linux ISO Builder"
echo "==============================================================="
echo "Distribution : Debian $DEBIAN_SUITE"
echo "Architecture : amd64"
echo "Target GPU   : NVIDIA RTX 4050"
echo "Build folder : $BUILD_DIR"
echo "Output ISO   : $OUTPUT_ISO"
echo "Checksum     : $CHECKSUM_FILE"
echo "Parallelism  : 4 jobs"
echo "D: free space:"
df -h /mnt/d
echo "==============================================================="
echo

if [[ "$RESUME_MODE" -eq 1 ]]; then
    echo "[1-8/12] RESUME: Reusing verified Debian rootfs and installed packages..."
    mkdir -p \
        "$ROOTFS" \
        "$LIVE_DIR/live" \
        "$LIVE_DIR/boot/grub"
else
    echo "[1/12] Preparing build environment..."

    cleanup_mounts

    # This removes only the dedicated temporary build directory, not project files.
    rm -rf -- "$BUILD_DIR"

    mkdir -p \
        "$ROOTFS" \
        "$LIVE_DIR/live" \
        "$LIVE_DIR/boot/grub"

    # -----------------------------------------------------------------------------
    # 6. Bootstrap Debian Trixie
    # -----------------------------------------------------------------------------

    echo "[2/12] Installing minimal Debian Trixie base..."

    debootstrap \
        --arch=amd64 \
        --variant=minbase \
        --components="$DEBIAN_COMPONENTS" \
        --include=ca-certificates,linux-image-amd64,linux-headers-amd64,live-boot,live-boot-initramfs-tools,systemd,systemd-sysv,dbus,udev,pciutils,kmod,iproute2,isc-dhcp-client,procps,less,nano,sudo \
        "$DEBIAN_SUITE" \
        "$ROOTFS" \
        "$DEBIAN_MIRROR"

    # -----------------------------------------------------------------------------
    # 7. Configure Debian repositories and system identity
    # -----------------------------------------------------------------------------

    echo "[3/12] Configuring Debian repositories..."

    mkdir -p "$ROOTFS/etc/apt/sources.list.d"

    # Remove existing deb822 source files to avoid duplicate repositories.
    find "$ROOTFS/etc/apt/sources.list.d" \
        -maxdepth 1 -type f -name '*.sources' -delete

    cat > "$ROOTFS/etc/apt/sources.list" <<EOF_APT
deb $DEBIAN_MIRROR trixie $DEBIAN_APT_COMPONENTS
deb $DEBIAN_MIRROR trixie-updates $DEBIAN_APT_COMPONENTS
deb https://security.debian.org/debian-security trixie-security $DEBIAN_APT_COMPONENTS
EOF_APT

    echo "cuda-lite" > "$ROOTFS/etc/hostname"

    cat > "$ROOTFS/etc/hosts" <<'EOF_HOSTS'
127.0.0.1 localhost
127.0.1.1 cuda-lite
::1 localhost ip6-localhost ip6-loopback
EOF_HOSTS

    # Configure live-boot-compatible filesystem mounts.
    cp "$PROJECT_ROOT/system/fstab.overlay" "$ROOTFS/etc/fstab"

    # Install project hardening configuration.
    mkdir -p "$ROOTFS/etc/sysctl.d"
    cp "$PROJECT_ROOT/system/hardening.conf" \
        "$ROOTFS/etc/sysctl.d/99-cuda-lite-hardening.conf"

    # -----------------------------------------------------------------------------
    # 8. Install CUDA applications and system service
    # -----------------------------------------------------------------------------

    echo "[4/12] Installing CUDA applications..."

    mkdir -p \
        "$ROOTFS/opt/cuda-lite/bin" \
        "$ROOTFS/usr/local/sbin" \
        "$ROOTFS/etc/systemd/system" \
        "$ROOTFS/etc/modules-load.d"

    install -m 0755 \
        "$PROJECT_ROOT/cuda/matrix_mul" \
        "$ROOTFS/opt/cuda-lite/bin/matrix_mul"

    install -m 0755 \
        "$PROJECT_ROOT/cuda/device_query" \
        "$ROOTFS/opt/cuda-lite/bin/device_query"

    install -m 0755 \
        "$PROJECT_ROOT/system/cuda-lite-startup.sh" \
        "$ROOTFS/usr/local/sbin/cuda-lite-startup"

    install -m 0644 \
        "$PROJECT_ROOT/system/cuda-lite-autostart.service" \
        "$ROOTFS/etc/systemd/system/cuda-lite-autostart.service"

    # Dynamic hardware-aware module loading via udev rule
    mkdir -p "$ROOTFS/etc/udev/rules.d"
    install -m 0644 \
        "$PROJECT_ROOT/system/99-nvidia.rules" \
        "$ROOTFS/etc/udev/rules.d/99-nvidia.rules"

    # Remove static module loads so systemd-modules-load succeeds in VMs/QEMU
    rm -f "$ROOTFS/etc/modules-load.d/cuda-lite-nvidia.conf"
    ln -sf /dev/null "$ROOTFS/etc/modules-load.d/nvidia.conf"

    # -----------------------------------------------------------------------------
    # 9. Mount virtual filesystems
    # -----------------------------------------------------------------------------

    echo "[5/12] Preparing chroot environment..."

    mkdir -p \
        "$ROOTFS/dev" \
        "$ROOTFS/dev/pts" \
        "$ROOTFS/proc" \
        "$ROOTFS/sys"

    mount --bind /dev "$ROOTFS/dev"
    mount --bind /dev/pts "$ROOTFS/dev/pts"
    mount -t proc proc "$ROOTFS/proc"
    mount -t sysfs sysfs "$ROOTFS/sys"

    # -----------------------------------------------------------------------------
    # 10. Install NVIDIA driver and CUDA toolkit
    # -----------------------------------------------------------------------------

    echo "[6/12] Updating Debian package lists..."

    chroot "$ROOTFS" /usr/bin/env \
        DEBIAN_FRONTEND=noninteractive \
        apt-get update

    echo
    echo "[7/12] Installing NVIDIA driver and CUDA toolkit..."
    echo "This operation may take considerable time and disk space."

    chroot "$ROOTFS" /usr/bin/env \
        DEBIAN_FRONTEND=noninteractive \
        apt-get install -y --no-install-recommends \
            build-essential \
            dkms \
            linux-headers-amd64 \
            firmware-nvidia-gsp \
            nvidia-kernel-dkms \
            nvidia-smi \
            libcuda1 \
            nvidia-cuda-toolkit

    # -----------------------------------------------------------------------------
    # 11. Configure user and system services
    # -----------------------------------------------------------------------------

    echo "[8/12] Configuring CUDA user and system services..."

    chroot "$ROOTFS" /bin/bash -c '
        set -e

        for group in sudo video render; do
            getent group "$group" >/dev/null || groupadd "$group"
        done

        useradd -m -s /bin/bash -G sudo,video,render cuda

        passwd -l root
    '

    # Set the user's password without putting it in the command line.
    printf 'cuda:%s\n' "$CUDA_PASSWORD" |
        chroot "$ROOTFS" chpasswd

    unset CUDA_PASSWORD

    # Enable automatic CUDA diagnostics at boot.
    systemctl --root="$ROOTFS" enable cuda-lite-autostart.service
fi

# Ensure project binaries, service units, and udev rules are up-to-date in target rootfs
mkdir -p "$ROOTFS/opt/cuda-lite/bin" "$ROOTFS/usr/local/sbin" "$ROOTFS/etc/systemd/system" "$ROOTFS/etc/udev/rules.d"
install -m 0755 "$PROJECT_ROOT/cuda/matrix_mul" "$ROOTFS/opt/cuda-lite/bin/matrix_mul"
install -m 0755 "$PROJECT_ROOT/cuda/device_query" "$ROOTFS/opt/cuda-lite/bin/device_query"
install -m 0755 "$PROJECT_ROOT/system/cuda-lite-startup.sh" "$ROOTFS/usr/local/sbin/cuda-lite-startup"
install -m 0644 "$PROJECT_ROOT/system/cuda-lite-autostart.service" "$ROOTFS/etc/systemd/system/cuda-lite-autostart.service"
install -m 0644 "$PROJECT_ROOT/system/99-nvidia.rules" "$ROOTFS/etc/udev/rules.d/99-nvidia.rules"
rm -f "$ROOTFS/etc/modules-load.d/cuda-lite-nvidia.conf"
ln -sf /dev/null "$ROOTFS/etc/modules-load.d/nvidia.conf"
systemctl --root="$ROOTFS" enable cuda-lite-autostart.service 2>/dev/null || true

# Ensure virtual filesystems are mounted for kernel/module operations
mkdir -p "$ROOTFS/dev" "$ROOTFS/dev/pts" "$ROOTFS/proc" "$ROOTFS/sys"
mountpoint -q "$ROOTFS/dev" || mount --bind /dev "$ROOTFS/dev"
mountpoint -q "$ROOTFS/dev/pts" || mount --bind /dev/pts "$ROOTFS/dev/pts"
mountpoint -q "$ROOTFS/proc" || mount -t proc proc "$ROOTFS/proc"
mountpoint -q "$ROOTFS/sys" || mount -t sysfs sysfs "$ROOTFS/sys"

# -----------------------------------------------------------------------------
# 12. Build and verify NVIDIA kernel modules
# -----------------------------------------------------------------------------

echo "[9/12] Building NVIDIA kernel modules..."

NVIDIA_MODULE_FOUND=0

for module_dir in "$ROOTFS"/lib/modules/*; do
    [[ -d "$module_dir" ]] || continue

    kernel_version="${module_dir##*/}"

    echo
echo "Processing Debian kernel: $kernel_version"

    # Explicitly request DKMS installation for the target Debian kernel.
    chroot "$ROOTFS" dkms autoinstall -k "$kernel_version"

    # Refresh the target kernel module dependency information.
    chroot "$ROOTFS" depmod -a "$kernel_version"

    # Verify that the NVIDIA module exists for this kernel (Debian packages it as nvidia-current).
    if chroot "$ROOTFS" modinfo -k "$kernel_version" nvidia-current >/dev/null 2>&1 || \
       chroot "$ROOTFS" modinfo -k "$kernel_version" nvidia >/dev/null 2>&1; then
        echo "NVIDIA module found for kernel: $kernel_version"

        if chroot "$ROOTFS" modinfo -k "$kernel_version" nvidia-current >/dev/null 2>&1; then
            chroot "$ROOTFS" modinfo -k "$kernel_version" nvidia-current |
                grep -E '^(filename|version|vermagic):' || true
        else
            chroot "$ROOTFS" modinfo -k "$kernel_version" nvidia |
                grep -E '^(filename|version|vermagic):' || true
        fi

        NVIDIA_MODULE_FOUND=1
    else
        echo "WARNING: NVIDIA module not found for $kernel_version"
    fi
done

echo
echo "========== NVIDIA DKMS STATUS =========="
chroot "$ROOTFS" dkms status

if [[ "$NVIDIA_MODULE_FOUND" -ne 1 ]]; then
    echo
echo "ERROR: NVIDIA kernel module was not found."
    echo "The ISO build is stopping."
    echo "Inspect the DKMS build logs before proceeding."
    exit 1
fi

# Update initramfs for each installed Debian kernel.
for module_dir in "$ROOTFS"/lib/modules/*; do
    [[ -d "$module_dir" ]] || continue

    kernel_version="${module_dir##*/}"

    echo "Updating initramfs for $kernel_version"
    chroot "$ROOTFS" update-initramfs -u -k "$kernel_version"
done

# Refresh linker cache inside target filesystem.
chroot "$ROOTFS" ldconfig

# Check CUDA driver library installation.
if ! find "$ROOTFS/usr/lib" "$ROOTFS/lib" \
    -name 'libcuda.so.1' -print -quit 2>/dev/null | grep -q .; then
    echo "ERROR: libcuda.so.1 was not found in the target filesystem."
    exit 1
fi

# -----------------------------------------------------------------------------
# 13. Clean target filesystem and unmount virtual filesystems
# -----------------------------------------------------------------------------

echo "[10/12] Cleaning target filesystem..."

chroot "$ROOTFS" apt-get clean
rm -rf "$ROOTFS/var/lib/apt/lists/"*

cleanup_mounts

# -----------------------------------------------------------------------------
# 14. Prepare live kernel and initramfs
# -----------------------------------------------------------------------------

echo "[11/12] Preparing kernel and initramfs..."

KERNEL_FILE="$(
    find "$ROOTFS/boot" -maxdepth 1 -type f -name 'vmlinuz-*' |
        sort -V |
        tail -n 1
)"

if [[ -z "$KERNEL_FILE" || ! -f "$KERNEL_FILE" ]]; then
    echo "ERROR: Kernel image not found." >&2
    exit 1
fi

KERNEL_VERSION="${KERNEL_FILE##*/vmlinuz-}"
INITRD_FILE="$ROOTFS/boot/initrd.img-$KERNEL_VERSION"

if [[ ! -f "$INITRD_FILE" ]]; then
    echo "ERROR: Matching initramfs not found: $INITRD_FILE" >&2
    exit 1
fi

echo "Selected kernel: $KERNEL_VERSION"
cp "$KERNEL_FILE" "$LIVE_DIR/live/vmlinuz"
cp "$INITRD_FILE" "$LIVE_DIR/live/initrd"

# -----------------------------------------------------------------------------
# 15. Create immutable SquashFS root filesystem
# -----------------------------------------------------------------------------

echo "Creating compressed SquashFS root filesystem..."

mksquashfs "$ROOTFS" "$LIVE_DIR/live/filesystem.squashfs" \
    -comp xz \
    -Xbcj x86 \
    -b 1048576 \
    -noappend \
    -processors 4

# -----------------------------------------------------------------------------
# 16. Configure GRUB BIOS and UEFI boot menu
# -----------------------------------------------------------------------------

echo "Creating GRUB boot configuration..."

cat > "$LIVE_DIR/boot/grub/grub.cfg" <<'EOF_GRUB'
set default=0
set timeout=5

menuentry "CUDA-Lite Linux - Normal Boot" {
    search --no-floppy --file --set=root /live/vmlinuz
    linux /live/vmlinuz boot=live components quiet
    initrd /live/initrd
}

menuentry "CUDA-Lite Linux - Verbose Boot" {
    search --no-floppy --file --set=root /live/vmlinuz
    linux /live/vmlinuz boot=live components verbose
    initrd /live/initrd
}
EOF_GRUB

# -----------------------------------------------------------------------------
# 17. Generate hybrid BIOS/UEFI ISO
# -----------------------------------------------------------------------------

echo "Creating BIOS/UEFI bootable ISO..."

grub-mkrescue \
    -o "$TEMP_ISO" \
    "$LIVE_DIR"

if [[ ! -s "$TEMP_ISO" ]]; then
    echo "ERROR: ISO generation failed." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# 18. Copy ISO and checksum to Drive D: only
# -----------------------------------------------------------------------------

echo "Copying generated ISO to Drive D:..."

if [[ ! -d /mnt/d || ! -w /mnt/d ]]; then
    echo "ERROR: Drive D: is unavailable or not writable." >&2
    exit 1
fi

cp "$TEMP_ISO" "$OUTPUT_ISO"

# -----------------------------------------------------------------------------
# 19. Final ISO verification and checksum
# -----------------------------------------------------------------------------

echo
echo "Verifying generated ISO..."

if [[ ! -s "$OUTPUT_ISO" ]]; then
    echo "ERROR: Final ISO is missing or empty." >&2
    exit 1
fi

xorriso -indev "$OUTPUT_ISO" -report_el_torito plain

sha256sum "$OUTPUT_ISO" | tee "$CHECKSUM_FILE"

echo
echo "==============================================================="
echo "                 ISO BUILD COMPLETED"
echo "==============================================================="
echo "Distribution : Debian $DEBIAN_SUITE"
echo "Kernel       : $KERNEL_VERSION"
echo "ISO          : $OUTPUT_ISO"
echo "Checksum     : $CHECKSUM_FILE"
ls -lh "$OUTPUT_ISO" "$CHECKSUM_FILE"
echo
echo "NOTE: QEMU boot and physical NVIDIA GPU testing are still required."
echo "A successful DKMS build does not by itself prove physical GPU operation."
echo "==============================================================="
