#!/bin/sh
# =============================================================================
# EdgeML Linux OS: Target RootFS Post-Build Script
# Sets correct permissions on service scripts and binaries
# =============================================================================

set -e

TARGET_DIR="$1"

# Ensure init scripts have execute permissions
if [ -d "${TARGET_DIR}/etc/init.d" ]; then
    chmod 755 "${TARGET_DIR}/etc/init.d/"* 2>/dev/null || true
fi

# Ensure application binary has execute permissions
if [ -f "${TARGET_DIR}/usr/bin/edgeml-infer" ]; then
    chmod 755 "${TARGET_DIR}/usr/bin/edgeml-infer" 2>/dev/null || true
fi

# Ensure data and models directories exist and have proper permissions
mkdir -p "${TARGET_DIR}/data" "${TARGET_DIR}/usr/share/models" "${TARGET_DIR}/tmp" "${TARGET_DIR}/var"
chmod 1777 "${TARGET_DIR}/tmp" 2>/dev/null || true
chmod 755 "${TARGET_DIR}/data" "${TARGET_DIR}/usr/share/models" 2>/dev/null || true
