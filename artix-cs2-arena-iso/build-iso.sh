#!/bin/bash
# artix-cs2-arena ISO build script
# Usage: ./build-iso.sh
# Logs: ~/artools-workspace/logs/build-$(date).log

set -uo pipefail

LOGDIR="$HOME/artools-workspace/logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/build-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "=== artix-cs2-arena ISO build ==="
echo "Started: $(date)"
echo "Log: $LOGFILE"
echo ""

echo "[1/3] Verifying profile..."
PROFILE_DIR="$HOME/artools-workspace/iso-profiles/artix-cs2-arena"
if [ ! -f "$PROFILE_DIR/profile.yaml" ]; then
    echo "FAIL: profile.yaml not found at $PROFILE_DIR"
    exit 1
fi
if [ ! -d "$PROFILE_DIR/root-overlay" ]; then
    echo "FAIL: root-overlay not found"
    exit 1
fi
yq -P '.live-session.user' "$PROFILE_DIR/profile.yaml" > /dev/null 2>&1 || {
    echo "FAIL: profile.yaml parse error"
    exit 1
}
PKG_COUNT=$(yq -P '.rootfs.packages | length' "$PROFILE_DIR/profile.yaml")
echo "OK: profile valid ($PKG_COUNT rootfs packages)"

echo ""
echo "[2/3] Building ISO..."
echo "Command: buildiso -p artix-cs2-arena -i runit"
echo ""

buildiso -p artix-cs2-arena -i runit
RC=$?

echo ""
echo "[3/3] Checking output..."
ISO_DIR="$HOME/artools-workspace/iso"
if ls "$ISO_DIR"/*.iso 1>/dev/null 2>&1; then
    ISO_FILE=$(ls -t "$ISO_DIR"/*.iso | head -1)
    ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
    echo "OK: ISO built successfully"
    echo "  File: $ISO_FILE"
    echo "  Size: $ISO_SIZE"
    cp "$ISO_FILE" "$HOME/opencode-projects/gaming-distro/artix-cs2-arena-iso/output/" 2>/dev/null || true
else
    echo "FAIL: No ISO file found in $ISO_DIR"
    RC=1
fi

echo ""
echo "Finished: $(date)"
echo "Exit code: $RC"
echo "Log saved: $LOGFILE"

if [ $RC -ne 0 ]; then
    echo ""
    echo "BUILD FAILED. Check log for errors:"
    echo "  cat $LOGFILE | grep -iE 'error|fail|warn'"
fi

exit $RC
