#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Configuring GRUB for dual-kernel boot..."

# ─── GRUB defaults ───
if [ -f /etc/default/grub ]; then
    # Save default — remember last chosen kernel
    sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
    grep -q "GRUB_SAVEDEFAULT" /etc/default/grub || echo 'GRUB_SAVEDEFAULT=true' >> /etc/default/grub

    # 5 second timeout — enough to pick kernel
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub

    # Kernel parameters
    sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet nvidia-drm.modeset=1 nvidia-drm.fbdev=1 usbhid.jspoll=1 pcie_aspm=off"|' /etc/default/grub

    # Visual theme (optional)
    grep -q "GRUB_THEME" /etc/default/grub || echo '# GRUB_THEME=/boot/grub/themes/artix/theme.txt' >> /etc/default/grub
fi

# ─── Regenerate GRUB config ───
if [ -d /boot/grub ]; then
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || {
        echo "  [WARN] grub-mkconfig failed. Run manually after first boot:"
        echo "         sudo grub-mkconfig -o /boot/grub/grub.cfg"
    }
fi

# ─── Create release file ───
cat > /etc/artix-cs2-arena-release << 'RELEASEEOF'
artix-cs2-arena v1.0
=====================
Custom Artix Linux gaming distro
Optimized for Counter-Strike 2

Hardware Target:
  CPU: AMD Ryzen 7 5700G
  GPU: NVIDIA RTX 3060 Ti
  RAM: 32GB DDR4 3200MHz
  Display: 1080p@165Hz DisplayPort

Kernels:
  Default: linux-zen (PREEMPT)
  Alternative: linux-cachyos-bore (BORE scheduler)
  Switch: kernel-switch zen|cachyos|status

Quick Start:
  1. Login → Steam → Install CS2
  2. Set CS2 launch options (see ~/cs2-launch-options.txt)
  3. Run verify-setup to check all systems
  4. Play

Tools:
  verify-setup    — health check all gaming subsystems
  kernel-switch   — switch default kernel
  gaming-mode     — apply gaming optimizations
RELEASEEOF

echo "==> [CS2-Arena] GRUB configured."
echo "    Timeout: 5 seconds"
echo "    Default: linux-zen"
echo "    Alternative: linux-cachyos-bore"
echo "    Kernel params: nvidia-drm.modeset=1, usbhid.jspoll=1, pcie_aspm=off"
echo ""
echo "    ╔══════════════════════════════════════╗"
echo "    ║   artix-cs2-arena install complete!  ║"
echo "    ╚══════════════════════════════════════╝"
echo ""
echo "    Reboot and enjoy CS2!"
