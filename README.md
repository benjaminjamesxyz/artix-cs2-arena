# artix-cs2-arena

Custom Artix Linux ISO builder for a CS2-optimized gaming distro. Built on runit + X11 + i3 + NVIDIA, tuned for competitive Counter-Strike 2 at 1080p/165Hz.

## Why This Exists

Stock Linux distros aren't tuned for competitive gaming. This project automates the creation of a bootable ISO that installs a fully configured gaming system — low-latency audio, optimized kernel, NVIDIA DRM KMS, gaming-mode toggles, and every config file in place so you can go from USB boot to playing CS2 in minutes.

## Target Hardware

| Component   | Detail                              |
|-------------|-------------------------------------|
| CPU         | AMD Ryzen 7 5700G (8C/16T)         |
| GPU         | NVIDIA RTX 3060 Ti 8GB              |
| RAM         | 32GB DDR4 3200MHz (XMP ON)         |
| Storage     | 512GB NVMe M.2 SSD                  |
| Monitor     | 1080p@165Hz via DisplayPort         |
| Mouse       | Razer DeathAdder Essential @ 1000Hz |

> **Note:** Configs are hardware-specific. Change NVIDIA, display, and audio settings if your hardware differs. See `artix-cs2-arena-iso/root-overlay/` for all tunable configs.

## What's Inside

### Stack

- **Init:** runit (no systemd)
- **Display server:** X11 with LightDM
- **Window manager:** i3 with polybar, rofi, picom
- **GPU:** NVIDIA DKMS with DRM KMS, 165Hz DisplayPort
- **Audio:** PipeWire at quantum=64/48kHz (~1.3ms latency) with ALSA bridge for Proton/Wine
- **Kernel:** linux-zen (PREEMPT) + linux-cachyos-bore (BORE scheduler)
- **Gaming:** Steam, GameMode (auto-preload), MangoHud, gamescope, Proton support

### Performance Tuning (applied automatically)

| Tuning                 | Config                                       | Value                              |
|------------------------|----------------------------------------------|------------------------------------|
| Audio latency          | `pipewire/pipewire.conf.d/10-gaming.conf`   | quantum=64 @ 48kHz (~1.3ms)       |
| CPU governor           | `default/cpupower`                           | performance                        |
| VM dirty ratio         | `sysctl.d/99-gaming.conf`                    | 10/5 (aggressive flush)            |
| Max map count          | `sysctl.d/99-gaming.conf`                    | 2147483642 (Proton requirement)    |
| Swappiness             | `sysctl.d/99-gaming.conf`                    | 100 (prefer zram over disk)        |
| zram swap              | `post-install/05-performance-tuning.sh`      | 8GB lz4, priority 100              |
| Network qdisc          | `sysctl.d/99-network-gaming.conf`            | fq_codel (kills bufferbloat)       |
| TCP congestion         | `sysctl.d/99-network-gaming.conf`            | BBR                                |
| NVMe scheduler         | `udev/rules.d/60-nvme.rules`                | none (native NVMe queueing)        |
| USB polling            | `modprobe.d/usbhid.conf` + kernel param      | 1000Hz                             |
| NVIDIA DRM KMS         | `modprobe.d/nvidia.conf`                     | modeset=1, fbdev=1                 |

## Project Structure

```
artix-cs2-arena-iso/
├── build.sh                  # Full build pipeline
├── build-iso.sh              # Alternative build wrapper with logging
├── profile.yaml              # artools profile: packages, services, live session
├── BUILD-GUIDE.md            # Detailed build guide and diagnostics
├── profile/                  # Calamares installer configuration
│   └── calamares/modules/    # 15 installer module configs
├── root-overlay/             # Files copied to the installed system
│   ├── etc/                  # System configs (NVIDIA, sysctl, PipeWire, X11, pacman)
│   └── usr/local/bin/
│       ├── post-install/     # 8 numbered setup scripts (run during installation)
│       ├── gaming-mode       # Per-session gaming optimizer
│       ├── verify-setup      # System health check
│       └── kernel-switch     # Switch between linux-zen and cachyos-bore
├── live-overlay/             # Files for the live ISO session only
└── output/                   # Built ISO output (gitignored)
```

## Build Instructions

### Prerequisites

- **Artix Linux** host with `buildiso` available
- ~15GB free disk space
- Root access

### Setup (one-time)

```bash
# Install build tools
sudo pacman -S artools-base artools-iso artools-pkg yq

# Enable lib32 repo for the build process
mkdir -p ~/.config/artools/pacman.conf.d/
cp /usr/share/artools/pacman.conf.d/iso-x86_64.conf ~/.config/artools/pacman.conf.d/
# Uncomment the [lib32] section in that file

# Remove stock linux kernel from common profile (we use linux-zen)
mkdir -p ~/artools-workspace/iso-profiles/common/
cp /usr/share/artools/iso-profiles/common/common.yaml ~/artools-workspace/iso-profiles/common/
# Remove "linux" and "linux-headers" from packages-base in that file
```

### Build

```bash
sudo ./artix-cs2-arena-iso/build.sh
```

The build takes 15-30 minutes. The ISO is copied to `artix-cs2-arena-iso/output/`.

### Flash to USB

```bash
sudo dd if=artix-cs2-arena-iso/output/artix-cs2-arena-*.iso of=/dev/sdX bs=4M status=progress && sync
```

Replace `/dev/sdX` with your USB device. Use `lsblk` to identify it.

## Installation

1. Boot from USB
2. Live environment loads — auto-login as `artix` user
3. Double-click **Install Artix** (Calamares) on desktop
4. Follow the installer: timezone, keyboard, partitioning (GPT/XFS recommended)
5. Post-install scripts run automatically during installation:
   - `01-kernel-setup.sh` — installs linux-zen + linux-cachyos-bore
   - `02-nvidia-setup.sh` — builds NVIDIA DKMS for all kernels
   - `03-gaming-stack.sh` — MangoHud, GameMode, CS2 launch options
   - `04-audio-setup.sh` — PipeWire + Proton audio bridge
   - `05-performance-tuning.sh` — zram, sysctl, CPU governor
   - `06-peripherals.sh` — OpenRazer, raw mouse input
   - `07-grub-setup.sh` — dual-kernel GRUB config
   - `08-aur-packages.sh` — Steam, Discord, AUR packages via yay
6. Reboot → installed system ready

### Post-Install

```bash
# Verify everything is configured
sudo verify-setup

# Switch to alternative kernel
sudo kernel-switch cachyos

# Apply per-session gaming optimizations
gaming-mode
```

### CS2 Setup

1. Open Steam → install Counter-Strike 2
2. Right-click CS2 → Properties → Launch Options, paste:
   ```
   -gamepadui -vulkan -high -threads 16 +fps_max 0 -nojoy -novid -noaafonts mangohud %command%
   ```
3. Toggle MangoHud overlay: **Right Shift + F12**

## On-System Tools

| Command           | Description                                    |
|-------------------|------------------------------------------------|
| `sudo verify-setup`   | Health check all gaming subsystems          |
| `sudo kernel-switch zen` | Switch to linux-zen (PREEMPT)           |
| `sudo kernel-switch cachyos` | Switch to linux-cachyos-bore (BORE) |
| `sudo kernel-switch status` | Show current and installed kernels     |
| `gaming-mode`         | Apply per-session gaming optimizations      |

## Requirements

- Artix Linux host for building
- artools 0.38.5+
- Target: x86_64 with NVIDIA GPU and DP/HDMI display

## License

This project is licensed under the GNU General Public License v2.0 (GPLv2). See [LICENSE](LICENSE) for details.
