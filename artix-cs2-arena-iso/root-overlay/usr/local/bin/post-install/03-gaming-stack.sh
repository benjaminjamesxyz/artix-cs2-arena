#!/bin/bash
set -euo pipefail

echo "==> [CS2-Arena] Setting up gaming stack..."

# ─── Steam directory structure ───
mkdir -p /home/*/Steam 2>/dev/null || true

# ─── Proton-GE setup directory ───
mkdir -p /etc/skel/.steam/root/compatibilitytools.d

# ─── MangoHud default config ───
cat > /etc/mangohud.conf << 'MANGOEOF'
# MangoHud — artix-cs2-arena default config
# Toggle: Right Shift + F12

preset=1
horizontal=1
gpu_stats
cpu_stats
cpu_temp
gpu_temp
ram
vram
fps
frametime
frame_timing
histogram

# Position
position=top-left

# Colors
gpu_color=2E9762
cpu_color=2E97CB
vram_color=AD64C1
ram_color=C26693

# Font
font_size=18

# Background
background_alpha=0.3
MANGOEOF

# ─── GameMode config ───
mkdir -p /etc/skel/.config/gamemode.ini
cat > /etc/skel/.config/gamemode.ini << 'GAMEEOF'
[general]
renice = 10
ioprio = off

[gpu]
apply_gpu_optimisations = accept-nvidia-only
gpu_device = 0

[cpu]
park_cores = no
pin_cores = no

[custom]
start = notify-send "GameMode" "Started"
end = notify-send "GameMode" "Ended"
GAMEEOF

# ─── CS2 Steam launch options ───
cat > /etc/skel/.config/cs2-launch-options.txt << 'CS2EOF'
CS2 Steam Launch Options (copy into Steam > CS2 > Properties > Launch Options):
-gamepadui -vulkan -high -threads 16 +fps_max 0 -nojoy -novid -noaafonts mangohud %command%
CS2EOF

echo "==> [CS2-Arena] Gaming stack configured."
echo "    Steam: installed"
echo "    GameMode: configured"
echo "    MangoHud: configured (toggle: Right Shift+F12)"
echo "    CS2 launch options saved to ~/cs2-launch-options.txt"
