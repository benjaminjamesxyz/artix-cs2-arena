#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Setting up peripherals..."

# ─── OpenRazer ───
# Add user to plugdev group (will be created by users.conf)
# The udev rules come with openrazer-driver-dkms package

# Load openrazer modules
for mod in razermouse razerkbd razermousemat razeraccessory; do
    modprobe "$mod" 2>/dev/null || true
done

# ─── udev rules for gaming mouse ───
cat > /etc/udev/rules.d/99-razer-deathadder.rules << 'RAZEREOF'
# Razer DeathAdder Essential — 1000Hz polling
# OpenRazer handles DPI and lighting

KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1532", MODE="0666"
RAZEREOF

# ─── Xorg input config ───
cat > /etc/X11/xorg.conf.d/90-input.conf << 'INPUTEOF'
# Input configuration for gaming mouse + keyboard

Section "InputClass"
    Identifier "Mouse"
    MatchIsPointer "yes"
    Option "AccelerationProfile" "-1"
    Option "AccelerationScheme" "none"
    Option "AccelSpeed" "-1"
    # Raw input — no mouse acceleration
    Driver "libinput"
EndSection

Section "InputClass"
    Identifier "Keyboard"
    MatchIsKeyboard "yes"
    Driver "libinput"
    Option "XkbLayout" "us"
    Option "XkbModel" "pc105"
EndSection
INPUTEOF

echo "==> [CS2-Arena] Peripherals configured."
echo "    Mouse: Razer DeathAdder Essential @ 1000Hz"
echo "    Mouse acceleration: DISABLED (raw input)"
echo "    OpenRazer: installed (configure via Polychromatic)"
