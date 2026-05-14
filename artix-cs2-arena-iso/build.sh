#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_NAME="artix-cs2-arena"
PROFILES_DIR="/usr/share/artools/iso-profiles"
ISO_OUTPUT="${SCRIPT_DIR}/output"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    echo -e "${CYAN}"
    echo "  artix-cs2-arena ISO Builder"
    echo "  CS2 Gaming Distro"
    echo "  Kernel:  linux-zen + linux-cachyos-bore"
    echo "  GPU:     NVIDIA RTX 3060 Ti"
    echo "  Target:  CS2 @ 1080p/165Hz"
    echo -e "${NC}"
}

step() {
    echo -e "${YELLOW}[$1] $2${NC}"
}

die() {
    echo -e "${RED}  ERROR: $1${NC}"
    exit 1
}

ok() {
    echo -e "${GREEN}  OK: $1${NC}"
}

check_prerequisites() {
    step 1 4 "Checking prerequisites..."

    [ "$(id -u)" -eq 0 ] || die "Run as root: sudo ./build.sh"
    command -v buildiso &>/dev/null || die "buildiso not found. Install: pacman -S artools-iso"
    [ -d "$PROFILES_DIR" ] || die "iso-profiles missing at $PROFILES_DIR"
    [ -f "${SCRIPT_DIR}/profile.yaml" ] || die "profile.yaml not found"

    AVAILABLE=$(df -BG "${SCRIPT_DIR}" | tail -1 | awk '{print $4}' | tr -d 'G')
    [ "$AVAILABLE" -ge 15 ] || die "Need ~15GB, have ${AVAILABLE}GB"

    ok "All prerequisites met (${AVAILABLE}GB free)"
}

install_profile() {
    step 2 4 "Installing profile to artools..."

    local DEST="${PROFILES_DIR}/${PROFILE_NAME}"
    rm -rf "$DEST"
    mkdir -p "$DEST"

    cp "${SCRIPT_DIR}/profile.yaml" "$DEST/"

    if [ -d "${SCRIPT_DIR}/root-overlay" ]; then
        cp -r "${SCRIPT_DIR}/root-overlay" "$DEST/"
        chmod +x "$DEST/root-overlay/usr/local/bin/post-install/"*.sh 2>/dev/null || true
        chmod +x "$DEST/root-overlay/usr/local/bin/kernel-switch" 2>/dev/null || true
        chmod +x "$DEST/root-overlay/usr/local/bin/verify-setup" 2>/dev/null || true
        chmod +x "$DEST/root-overlay/usr/local/bin/gaming-mode" 2>/dev/null || true
        ok "root-overlay installed"
    fi

    if [ -d "${SCRIPT_DIR}/live-overlay" ]; then
        cp -r "${SCRIPT_DIR}/live-overlay" "$DEST/"
        ok "live-overlay installed"
    fi

    ok "Profile installed to ${DEST}"
}

build_iso() {
    step 3 4 "Building ISO (15-30 min)..."

    mkdir -p "$ISO_OUTPUT"

    buildiso -p "$PROFILE_NAME" -i runit 2>&1 | tee /tmp/buildiso.log || die "Build failed. Check /tmp/buildiso.log for details"

    ok "ISO build complete"
}

copy_output() {
    step 4 4 "Copying ISO to output..."

    mkdir -p "$ISO_OUTPUT"

    local ISO_SEARCH="/home/${SUDO_USER:-$USER}/artools-workspace/iso/"
    local ISO_FILE=""
    for f in $(find "$ISO_SEARCH" -name "*.iso" 2>/dev/null); do
        ISO_FILE="$f"
        break
    done

    if [ -z "$ISO_FILE" ]; then
        for f in $(find /var/lib/artools/buildiso/ -name "*.iso" 2>/dev/null); do
            ISO_FILE="$f"
            break
        done
    fi

    if [ -n "$ISO_FILE" ]; then
        local TIMESTAMP=$(date +%Y%m%d)
        local DEST_NAME="artix-cs2-arena-${TIMESTAMP}.iso"
        cp -v "$ISO_FILE" "${ISO_OUTPUT}/${DEST_NAME}"
        local SIZE=$(du -h "${ISO_OUTPUT}/${DEST_NAME}" | cut -f1)
        echo ""
        echo -e "${GREEN}  BUILD COMPLETE${NC}"
        echo "  ISO: ${ISO_OUTPUT}/${DEST_NAME}"
        echo "  Size: ${SIZE}"
        echo ""
        echo "  Flash to USB:"
        echo "    sudo dd if=${ISO_OUTPUT}/${DEST_NAME} of=/dev/sdX bs=4M status=progress && sync"
    else
        die "ISO file not found. Check /tmp/buildiso.log for errors"
    fi
}

banner
check_prerequisites
install_profile
build_iso
copy_output
