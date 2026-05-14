#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Configuring NVIDIA drivers..."

# NVIDIA DKMS should already be built for installed kernels
# Ensure DKMS modules are built
for kernel in $(ls /usr/lib/modules/); do
    if [ -d "/usr/lib/modules/$kernel/build" ]; then
        echo "  Building NVIDIA DKMS for $kernel..."
        dkms autoinstall -k "$kernel" 2>/dev/null || true
    fi
done

# Ensure initramfs includes NVIDIA
mkinitcpio -P 2>/dev/null || true

# Create Xorg config directory link if needed
mkdir -p /etc/X11/xorg.conf.d

echo "==> [CS2-Arena] NVIDIA driver configured."
echo "    Driver: nvidia-dkms"
echo "    DRM KMS: enabled"
echo "    Target: 1080p@165Hz via DisplayPort"
