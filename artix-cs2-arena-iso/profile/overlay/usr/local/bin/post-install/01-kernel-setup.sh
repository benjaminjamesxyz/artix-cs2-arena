#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Setting up kernels..."

# linux-zen is already installed via Packages-Core
# Rebuild initramfs to ensure it's current
mkinitcpio -P

echo "==> [CS2-Arena] linux-zen kernel ready."

# Add CachyOS repository for alternative kernel
if ! grep -q "\[cachyos\]" /etc/pacman.conf; then
    echo "==> [CS2-Arena] Adding CachyOS repository..."
    cat >> /etc/pacman.conf << 'REPOEOF'

[cachyos]
SigLevel = Never
Server = https://mirror.cachyos.org/\$repo/\$arch
REPOEOF

    echo "==> [CS2-Arena] Installing linux-cachyos-bore..."
    pacman -Sy --noconfirm linux-cachyos-bore linux-cachyos-bore-headers 2>/dev/null || {
        echo "  [WARN] CachyOS kernel install failed. Can be installed later with:"
        echo "         pacman -S linux-cachyos-bore linux-cachyos-bore-headers"
    }
else
    echo "==> [CS2-Arena] CachyOS repo already configured."
fi

# Rebuild initramfs for all kernels
mkinitcpio -P 2>/dev/null || true

echo "==> [CS2-Arena] Kernel setup complete."
echo "    Default: linux-zen (PREEMPT)"
echo "    Alternative: linux-cachyos-bore (BORE scheduler)"
echo "    Switch at boot via GRUB menu or: kernel-switch cachyos"
