# artix-cs2-arena: Build & Diagnostics Guide

## Hardware Target

| Component   | Detail                                    |
|-------------|-------------------------------------------|
| CPU         | AMD Ryzen 7 5700G (8C/16T)               |
| GPU         | NVIDIA RTX 3060 Ti 8GB                    |
| RAM         | 32GB DDR4 3200MHz (XMP ON)                |
| Storage     | 512GB NVMe M.2 SSD                        |
| Motherboard | ASUS TUF B550M-Plus WiFi                  |
| Monitor     | 1080p@165Hz via DisplayPort               |
| Network     | Ethernet (RTL8125 2.5G)                   |
| Audio       | 3.5mm jack, Realtek ALC S1200A            |
| Mouse       | Razer DeathAdder Essential @ 1000Hz       |

---

## 1. Build Prerequisites

Run on **Artix Linux** with these packages installed:

```bash
sudo pacman -S artools-base artools-iso artools-pkg yq
```

Verify:

```bash
buildiso --help
yq --version
pacman -Q artools-base
```

Disk space required: **~15GB free** for the build chroot.

---

## 2. Project Structure

```
artix-cs2-arena-iso/
├── build-iso.sh                    # Build script (run this)
├── build.sh                        # Alternative build script
├── profile.yaml                    # artools profile (packages, services)
├── root-overlay/                   # Files copied to installed system
│   ├── etc/
│   │   ├── modprobe.d/
│   │   │   ├── nvidia.conf         # NVIDIA DRM KMS, power management
│   │   │   └── usbhid.conf         # 1000Hz USB polling
│   │   ├── sysctl.d/
│   │   │   ├── 99-gaming.conf      # vm.dirty, max_map_count, perf_event
│   │   │   └── 99-network-gaming.conf  # fq_codel, BBR, TCP tuning
│   │   ├── X11/xorg.conf.d/
│   │   │   └── 20-nvidia-165hz.conf    # 1080p@165Hz DisplayPort
│   │   ├── pipewire/pipewire.conf.d/
│   │   │   └── 10-gaming.conf      # 1.3ms latency (quantum=64)
│   │   ├── udev/rules.d/
│   │   │   └── 60-nvme.rules       # NVMe scheduler=none, read-ahead
│   │   ├── default/
│   │   │   └── cpupower            # Performance governor
│   │   ├── environment             # NVIDIA env vars, GameMode preload
│   │   ├── asound.conf             # Realtek ALSA → PipeWire bridge
│   │   ├── pacman.conf             # Artix + CachyOS repos
│   │   └── xdg/autostart/
│   │       └── gamemode.desktop    # Auto-apply gaming mode on login
│   └── usr/
│       ├── local/bin/
│       │   ├── kernel-switch       # Switch default kernel
│       │   ├── verify-setup        # Health check all subsystems
│       │   ├── gaming-mode         # Apply session gaming optimizations
│       │   └── post-install/
│       │       ├── 01-kernel-setup.sh    # Install cachyos-bore, GRUB
│       │       ├── 02-nvidia-setup.sh    # NVIDIA DKMS build
│       │       ├── 03-gaming-stack.sh    # MangoHud, GameMode configs
│       │       ├── 04-audio-setup.sh     # PipeWire + Proton audio
│       │       ├── 05-performance-tuning.sh  # zram, sysctl, NVMe
    │       │       ├── 06-peripherals.sh     # OpenRazer, raw mouse input
    │       │       ├── 07-grub-setup.sh      # Dual-kernel GRUB config
    │       │       └── 08-aur-packages.sh    # Steam, Discord, AUR packages
│       └── share/i3/
│           └── config              # i3wm gaming layout
├── live-overlay/                   # Files copied to live ISO
│   └── etc/
│       ├── calamares/modules/
│       │   ├── partition.conf      # XFS default, GPT, no swap
│       │   └── services-artix.conf # Services to enable
│       ├── lightdm/lightdm.conf    # Auto-login for live session
│       └── skel/.xinitrc           # Start i3 on X init
└── output/                         # ISO output directory
```

---

## 3. Build Process

### Step 1: Install Profile

The profile must be at `~/artools-workspace/iso-profiles/artix-cs2-arena/`.
artools checks this path before `/usr/share/artools/iso-profiles/` (no sudo needed).

```bash
mkdir -p ~/artools-workspace/iso-profiles/artix-cs2-arena
cp -r /path/to/artix-cs2-arena-iso/{profile.yaml,root-overlay,live-overlay} \
    ~/artools-workspace/iso-profiles/artix-cs2-arena/
chmod +x ~/artools-workspace/iso-profiles/artix-cs2-arena/root-overlay/usr/local/bin/*
chmod +x ~/artools-workspace/iso-profiles/artix-cs2-arena/root-overlay/usr/local/bin/post-install/*.sh
```

### Step 2: Run Build

```bash
sudo ./build-iso.sh
```

Or manually:

```bash
sudo buildiso -p artix-cs2-arena -i runit
```

**Duration:** 15-30 minutes depending on network speed and disk I/O.

**Log location:** `~/artools-workspace/logs/build-YYYYMMDD-HHMMSS.log`

### Step 3: Find the ISO

```bash
ls -lh ~/artools-workspace/iso/*.iso
```

Expected size: ~1.5-1.8GB

### Step 4: Flash to USB

```bash
sudo dd if=~/artools-workspace/iso/artix-cs2-arena-*.iso \
    of=/dev/sdX bs=4M status=progress && sync
```

Replace `/dev/sdX` with your USB device. Use `lsblk` to identify it.

---

## 4. Installation Flow

1. Boot from USB
2. Live environment loads → auto-login as `artix` user
3. Double-click **Install Artix** (Calamares) on desktop
4. Select timezone, keyboard, create user
5. Partitioning: GPT, XFS default, EFI 512MB
6. Calamares installs base system + all packages from profile.yaml
7. root-overlay configs are applied automatically
8. Post-install scripts run (01-08), installing AUR packages via yay
9. Reboot → installed system ready

### Post-Install (first boot)

The `root-overlay` configs are already in place. Run the health check:

```bash
verify-setup
```

If you want to install the CachyOS BORE kernel and run all post-install scripts:

```bash
sudo /usr/local/bin/post-install/01-kernel-setup.sh
sudo /usr/local/bin/post-install/02-nvidia-setup.sh
sudo /usr/local/bin/post-install/03-gaming-stack.sh
sudo /usr/local/bin/post-install/04-audio-setup.sh
sudo /usr/local/bin/post-install/05-performance-tuning.sh
sudo /usr/local/bin/post-install/06-peripherals.sh
sudo /usr/local/bin/post-install/07-grub-setup.sh
sudo /usr/local/bin/post-install/08-aur-packages.sh
```

Or run them all:

```bash
for script in /usr/local/bin/post-install/*.sh; do
    echo "Running $script..."
    sudo "$script"
done
```

### CS2 Setup

1. Open Steam → log in → install Counter-Strike 2
2. Right-click CS2 → Properties → Launch Options, paste:
```
-gamepadui -vulkan -high -threads 16 +fps_max 0 -nojoy -novid -noaafonts mangohud %command%
```
3. Launch CS2 — it runs fullscreen via Proton, Discord stays in background

---

## 5. Package Split

Packages not available in standard Artix repos (system/world/galaxy) are installed during post-install via `08-aur-packages.sh`:

| Phase           | Source       | Packages                                                  |
|-----------------|--------------|-----------------------------------------------------------|
| `profile.yaml`  | Artix repos  | Kernel, NVIDIA, X11, i3, PipeWire, gamemode, gamescope   |
| `08-aur-packages.sh` | Artix repos + AUR | Steam, Discord, nitrogen, lib32-*, protonup-qt, openrazer, irqbalance |

`08-aur-packages.sh` tries pacman first, falls back to yay for AUR-only packages.
If the AUR helper build fails (e.g., no network during install), it prints instructions for first boot.

---

## 6. Diagnostics

### Build Failures

**Check the build log:**

```bash
# Most recent log
ls -t ~/artools-workspace/logs/ | head -1

# Filter errors
grep -iE 'error|fail|warn' ~/artools-workspace/logs/build-*.log

# Common failures:
# - Package not found → check package name in profile.yaml
# - Dependency conflict → remove conflicting package from profile.yaml
# - Network timeout → retry, mirrors may be slow
# - Disk full → df -h /var/lib/artools/
```

**Resume a failed build:**

```bash
# buildiso has resume flags:
sudo buildiso -p artix-cs2-arena -i runit -sc    # resume squash + continue
sudo buildiso -p artix-cs2-arena -i runit -zc    # resume ISO creation
sudo buildiso -p artix-cs2-arena -i runit -bc    # resume boot creation
```

**Clean build (start fresh):**

```bash
sudo rm -rf /var/lib/artools/buildiso/artix-cs2-arena
sudo buildiso -p artix-cs2-arena -i runit
```

### Post-Install System Check

```bash
verify-setup
```

This checks: kernel, NVIDIA driver, 165Hz, PipeWire, zram, CPU governor,
fq_codel, NVMe scheduler, GameMode, USB polling, Steam, MangoHud, Discord.

### Individual Diagnostics

**Kernel:**
```bash
uname -r                           # should show "zen" or "cachyos"
kernel-switch status               # show installed kernels
ls /usr/lib/modules/               # list all installed kernels
```

**NVIDIA:**
```bash
nvidia-smi                         # driver loaded, GPU temp/utilization
cat /sys/module/nvidia_drm/parameters/modeset  # should be Y
xrandr --query | grep '*'         # should show 165.00Hz
dmesg | grep -i nvidia | tail -5  # kernel messages
```

**Audio:**
```bash
pactl info                         # PipeWire server running?
wpctl status                       # WirePlumber devices/ports
cat /etc/pipewire/pipewire.conf.d/10-gaming.conf  # latency config
pw-top                             # real-time audio graph
```

**Performance Tuning:**
```bash
cat /proc/sys/vm/max_map_count    # should be 2147483642
cat /proc/sys/net/core/default_qdisc  # should be fq_codel
sysctl net.ipv4.tcp_congestion_control   # should be bbr
zramctl                            # 8GB zram0 active?
cat /sys/block/nvme0n1/queue/scheduler  # should be [none]
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor  # performance
```

**Mouse:**
```bash
cat /sys/module/usbhid/parameters/jspoll   # should be 1
lsmod | grep razer                          # openrazer loaded
polychromatic                               # GUI config
```

**Gaming:**
```bash
gamemoded -s                       # GameMode status
MANGOHUD_CONFIG=help               # MangoHud options
steam                              # launch Steam
vulkaninfo | head -5               # Vulkan working?
```

---

## 7. Kernel Switching

Two kernels are available. Default: `linux-zen` (PREEMPT).

```bash
# View current kernel
uname -r

# Switch to CachyOS BORE scheduler
sudo kernel-switch cachyos

# Switch back to linux-zen
sudo kernel-switch zen

# Check status
kernel-switch status
```

Reboot after switching.

| Kernel              | Scheduler | Best For                    |
|---------------------|-----------|-----------------------------|
| linux-zen           | PREEMPT   | General gaming, stable      |
| linux-cachyos-bore  | BORE      | Better frame-time consistency |

---

## 8. Common Issues & Fixes

| Symptom                          | Check                              | Fix                                              |
|----------------------------------|------------------------------------|--------------------------------------------------|
| CS2 won't launch                 | `protonup-qt` → install GE-Proton  | Steam → CS2 → Properties → Compatibility → Proton Experimental |
| No 165Hz option                  | `xrandr --query`                   | Verify DisplayPort cable (not HDMI), check `20-nvidia-165hz.conf` |
| Audio crackling                  | `pw-top` latency                   | Increase quantum in `10-gaming.conf` (64→128)    |
| High ping variance               | `tc qdisc show`                    | Verify fq_codel: `sudo sysctl -w net.core.default_qdisc=fq_codel` |
| Mouse feels laggy                | `cat /sys/module/usbhid/parameters/jspoll` | Should be 1. If not: `echo options usbhid jspoll=1 > /tmp/usbhid.conf` |
| Steam won't open (32-bit libs)   | `pacman -Q lib32-nvidia-utils`     | Install: `sudo pacman -S lib32-nvidia-utils lib32-vulkan-icd-loader` |
| CachyOS kernel won't install     | Check CachyOS repo in pacman.conf  | `sudo pacman -Sy && sudo pacman -S linux-cachyos-bore` |
| GRUB shows only one kernel       | `ls /usr/lib/modules/`             | Both must be installed. Run `01-kernel-setup.sh`  |
| NVIDIA blank screen after boot   | `nvidia-drm.modeset=1` in GRUB     | Edit `/etc/default/grub` → `grub-mkconfig`       |
| GameMode not activating          | `gamemoded -s`                     | Ensure `lib32-gamemode` installed, check LD_PRELOAD in `/etc/environment` |
| Discord no mic                   | `pavucontrol` → input tab          | Set correct input device, check WirePlumber default node |

---

## 9. File Quick Reference

### Profile (artools reads this)
- `~/artools-workspace/iso-profiles/artix-cs2-arena/profile.yaml`

### System Configs (installed system)
- `/etc/modprobe.d/nvidia.conf` — NVIDIA driver options
- `/etc/modprobe.d/usbhid.conf` — USB 1000Hz polling
- `/etc/sysctl.d/99-gaming.conf` — VM, scheduler tuning
- `/etc/sysctl.d/99-network-gaming.conf` — Network latency
- `/etc/X11/xorg.conf.d/20-nvidia-165hz.conf` — Display config
- `/etc/pipewire/pipewire.conf.d/10-gaming.conf` — Audio latency
- `/etc/udev/rules.d/60-nvme.rules` — NVMe optimization
- `/etc/default/cpupower` — CPU governor
- `/etc/environment` — NVIDIA/GameMode env vars
- `/etc/asound.conf` — ALSA routing
- `/etc/pacman.conf` — CachyOS repo

### Utility Scripts (installed system)
- `/usr/local/bin/kernel-switch` — Switch kernels
- `/usr/local/bin/verify-setup` — Health check
- `/usr/local/bin/gaming-mode` — Session optimizer

### Post-Install Scripts (run manually or via Calamares)
- `/usr/local/bin/post-install/01-kernel-setup.sh` through `07-grub-setup.sh`

### Build Logs
- `~/artools-workspace/logs/build-*.log`

### Build Output
- `~/artools-workspace/iso/artix-cs2-arena-*.iso`
- `~/opencode-projects/gaming-distro/artix-cs2-arena-iso/output/`
