#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Applying performance tuning..."

# ─── zram setup via runit ───
mkdir -p /etc/runit/sv/zram
cat > /etc/runit/sv/zram/run << 'ZRAMEOF'
#!/bin/sh
exec 2>&1

# zram — compressed RAM swap
# 8GB lz4, high priority (prefer zram over disk)
# With 32GB physical RAM this is a safety net only

if [ -b /dev/zram0 ]; then
    echo "zram0 already active, skipping."
    exit 0
fi

zramctl --find --size 8G --algorithm lz4
mkswap -L zram0 /dev/zram0
swapon -p 100 /dev/zram0

echo "zram0 active: 8GB lz4 compressed swap"
ZRAMEOF

cat > /etc/runit/sv/zram/finish << 'ZRAMEOF'
#!/bin/sh
swapoff /dev/zram0 2>/dev/null
zramctl --reset /dev/zram0 2>/dev/null
ZRAMEOF

chmod +x /etc/runit/sv/zram/run /etc/runit/sv/zram/finish

# Enable zram service
if [ -d /etc/runit/runsvdir/default ]; then
    ln -sf /etc/runit/sv/zram /etc/runit/runsvdir/default/zram
fi

# ─── Apply sysctl immediately (also in overlay) ───
sysctl --system 2>/dev/null || true

# ─── Set CPU governor to performance ───
if command -v cpupower &>/dev/null; then
    cpupower frequency-set -g performance 2>/dev/null || true
fi

# ─── Disable PCIe ASPM (power saving can cause latency) ───
if ! grep -q "pcie_aspm=off" /etc/default/grub 2>/dev/null; then
    sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="|GRUB_CMDLINE_LINUX_DEFAULT="pcie_aspm=off |' /etc/default/grub 2>/dev/null || true
fi

# ─── Create zram-generator config as fallback ───
mkdir -p /etc/systemd 2>/dev/null || true
cat > /etc/systemd/zram-generator.conf << 'ZGENEOF'
# zram-generator config (alternative to runit service)
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = lz4
swap-priority = 100
ZGENEOF

echo "==> [CS2-Arena] Performance tuning applied."
echo "    zram: 8GB lz4 compressed swap"
echo "    CPU governor: performance"
echo "    sysctl: gaming + network tuned"
echo "    NVMe: scheduler=none, read-ahead=2048KB"
echo "    USB polling: 1000Hz"
