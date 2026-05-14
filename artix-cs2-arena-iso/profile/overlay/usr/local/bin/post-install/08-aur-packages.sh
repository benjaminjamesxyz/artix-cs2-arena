#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Installing additional packages..."

# ─── Ensure lib32 repo is enabled ───
# Required for 32-bit compatibility (CS2/Proton)
if ! grep -q "^\[lib32\]" /etc/pacman.conf; then
    echo "  Adding lib32 repo to pacman.conf..."
    sed -i '/^\[galaxy\]/i\[lib32]\nInclude = /etc/pacman.d/mirrorlist' /etc/pacman.conf 2>/dev/null || true
fi

# ─── Ensure base-devel is available (needed for AUR) ───
pacman -Sy --noconfirm --needed base-devel git 2>/dev/null || true

# ─── Refresh databases ───
pacman -Sy --noconfirm 2>/dev/null || true

# ─── Try repo packages first (available in Artix repos with lib32 enabled) ───
REPO_PACKAGES=(
    nitrogen
    steam
    lib32-pipewire
    lib32-pipewire-jack
    lib32-gamemode
    lib32-mangohud
    lib32-vulkan-icd-loader
    irqbalance
)

REPO_FAILED=()

for pkg in "${REPO_PACKAGES[@]}"; do
    if pacman -S --noconfirm --needed "$pkg" 2>/dev/null; then
        echo "  [OK] $pkg installed from repos"
    else
        echo "  [SKIP] $pkg not in repos, will try AUR"
        REPO_FAILED+=("$pkg")
    fi
done

# ─── AUR packages (not available in any Artix repo) ───
AUR_PACKAGES=(
    discord
    protonup-qt
    protontricks
    openrazer-daemon
    openrazer-driver-dkms
    polychromatic
)

# Combine failed repo packages with AUR-only packages
ALL_AUR=("${REPO_FAILED[@]}" "${AUR_PACKAGES[@]}")

if [ ${#ALL_AUR[@]} -eq 0 ]; then
    echo "==> [CS2-Arena] All packages installed from repos."
else
    echo "  Installing ${#ALL_AUR[@]} packages from AUR..."

    # ─── Install yay AUR helper ───
    if ! command -v yay &>/dev/null; then
        echo "  Installing yay AUR helper..."
        YAY_TMP=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/yay.git "$YAY_TMP" 2>/dev/null || {
            echo "  [WARN] Cannot clone yay. Network may be unavailable."
            echo "         Install manually after first boot:"
            for p in "${ALL_AUR[@]}"; do echo "           - $p"; done
            echo ""
            echo "         Steps:"
            echo "           1. sudo pacman -S --needed base-devel git"
            echo "           2. git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
            echo "           3. yay -S ${ALL_AUR[*]}"
            exit 0
        }
        cd "$YAY_TMP"
        makepkg -si --noconfirm 2>/dev/null || {
            echo "  [WARN] yay build failed. Install AUR packages manually after first boot."
            cd /
            rm -rf "$YAY_TMP"
            for p in "${ALL_AUR[@]}"; do echo "    - $p"; done
            exit 0
        }
        cd /
        rm -rf "$YAY_TMP"
    fi

    # ─── Install AUR packages ───
    for pkg in "${ALL_AUR[@]}"; do
        if yay -S --noconfirm --needed "$pkg" 2>/dev/null; then
            echo "  [OK] $pkg installed from AUR"
        else
            echo "  [WARN] $pkg failed. Install manually: yay -S $pkg"
        fi
    done
fi

# ─── Enable irqbalance service if installed ───
if command -v irqbalance &>/dev/null; then
    if [ -d /etc/runit/sv/irqbalance ]; then
        ln -sf /etc/runit/sv/irqbalance /etc/runit/runsvdir/default/irqbalance 2>/dev/null || true
    fi
fi

# ─── Summary ───
echo "==> [CS2-Arena] Additional packages install complete."
echo "    If any packages failed, install after first boot with:"
echo "      yay -S <package-name>"
