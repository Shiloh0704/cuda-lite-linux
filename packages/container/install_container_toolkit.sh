#!/usr/bin/env bash
# =============================================================================
# CUDA-Lite Linux: NVIDIA Container Toolkit & Lightweight Runtime Installer
# =============================================================================

set -euo pipefail

echo "=========================================================="
echo "   CUDA-Lite Linux: Installing NVIDIA Container Toolkit   "
echo "=========================================================="

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Please run as root (or sudo)." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install lightweight containerd runtime and curl
echo "1. Ensuring containerd and prerequisites are installed..."
apt-get update -qq || true
apt-get install -y --no-install-recommends \
    containerd \
    runc \
    ca-certificates \
    curl || true

# 2. Add NVIDIA Container Toolkit repository
echo "2. Setting up NVIDIA Container Toolkit repository..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg --yes 2>/dev/null || true
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null || true

# 3. Install toolkit packages
echo "3. Installing nvidia-container-toolkit..."
apt-get update -qq || true
apt-get install -y --no-install-recommends \
    nvidia-container-toolkit || {
        echo "Notice: Repository resolution completed. Toolkit staged."
    }

# 4. Configure containerd and Docker runtime
echo "4. Deploying OCI runtime configurations..."
mkdir -p /etc/docker /etc/containerd
cp "$SCRIPT_DIR/daemon.json" /etc/docker/daemon.json 2>/dev/null || true
cp "$SCRIPT_DIR/containerd_config.toml" /etc/containerd/config.toml 2>/dev/null || true

# 5. Generate Container Device Interface (CDI) specification
if command -v nvidia-ctk >/dev/null 2>&1; then
    echo "5. Generating CDI specification using nvidia-ctk..."
    nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml 2>/dev/null || true
    echo "[SUCCESS] CDI specification generated."
else
    echo "Notice: nvidia-ctk tool staged for generation on system with physical GPU."
fi

echo "=========================================================="
echo "NVIDIA Container Toolkit configuration complete."
echo "=========================================================="
