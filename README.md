# Arch Hyprland + Ax-Shell Installation Script

<div align="center">

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)
![AMD](https://img.shields.io/badge/AMD-ED1C24?style=for-the-badge&logo=amd&logoColor=white)

**Automated installation script for ASUS Zenbook S 13 OLED (UM5302TA)**

*Optimized for maximum performance, stability, functionality, and minimalism*

</div>

---

## ✨ Features

- 🚀 **Maximum Optimization** - AMD CPU/GPU tuning, SSD optimization, power management
- 🔒 **Stability** - Zen kernel with proper kernel parameters
- ⚡ **Functionality** - All function keys, camera, Bluetooth, Wi-Fi working out of the box
- 🎯 **Minimalism** - Zero bloat, only essential packages
- 🖥️ **OLED Care** - Dark themes, aggressive idle timeouts, burn-in prevention
- 📸 **Ax-Shell** - Beautiful, hackable shell for Hyprland

---

## 🎯 Target Hardware

| Component | Specification |
|-----------|---------------|
| **Model** | ASUS Zenbook S 13 OLED (UM5302TA) |
| **CPU** | AMD Ryzen 7 6800U (Zen 3+) |
| **GPU** | AMD Radeon 680M (RDNA 2) |
| **Display** | 13.3" 2880×1800 OLED @ 60Hz |
| **SSD** | Samsung 990 Pro 1TB (Btrfs recommended) |

---

## 📋 Prerequisites

- Fresh Arch Linux minimal installation
- UEFI boot mode
- Network connectivity
- Non-root user with sudo access

---

## 🚀 Quick Start

### Option 1: Full Installation (Recommended)

```bash
git clone https://github.com/as1furrahman/arch-hyprland-script.git
cd arch-hyprland-script
chmod +x install.sh
./install.sh
```

### Option 2: Step-by-Step

```bash
# Pre-installation (base packages + Hyprland)
./install.sh --pre-install

# Install Ax-Shell
./install.sh --axshell

# Apply hardware optimizations
./install.sh --post-install
```

---

## 📁 Project Structure

```
arch-hyprland-script/
├── install.sh              # Main entry point
├── scripts/
│   ├── 00-pre-check.sh    # System validation
│   ├── 01-base-setup.sh   # Core packages
│   ├── 02-hyprland-setup.sh # Hyprland + config
│   ├── 03-axshell-setup.sh  # Ax-Shell installation
│   └── 04-post-install.sh   # Hardware optimizations
├── config/
│   └── hyprland/          # Hyprland configs
├── utils/
│   ├── mic-toggle.sh      # Microphone toggle
│   └── camera-toggle.sh   # Camera toggle
└── docs/
    └── TROUBLESHOOTING.md # Common issues
```

---

## ⌨️ Function Keys

| Key | Function |
|-----|----------|
| `Fn+F1` | Mute/Unmute Speaker |
| `Fn+F2` | Volume Down |
| `Fn+F3` | Volume Up |
| `Fn+F5` | Brightness Down |
| `Fn+F6` | Brightness Up |
| `Fn+F7` | Keyboard Backlight |
| `Fn+F9` | Microphone Toggle |
| `Fn+F10` | Camera Toggle |

---

## 🔧 Kernel Parameters

Applied for optimal AMD performance:

```
amd_pstate=active
amdgpu.dpm=1
amdgpu.dcdebugmask=0x10
nowatchdog
```

---

## 🔋 Power Management

Uses `power-profiles-daemon` (recommended for Ryzen 6000+):

```bash
# Check current profile
powerprofilesctl get

# Set profile
powerprofilesctl set balanced    # Balanced (default)
powerprofilesctl set power-saver # Battery saving
powerprofilesctl set performance # Maximum performance
```

---

## 📸 Screenshots

*Coming soon after installation testing*

---

## 🐛 Troubleshooting

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 🙏 Credits

- [Ax-Shell](https://github.com/Axenide/Ax-Shell) by Axenide
- [Hyprland](https://hyprland.org/) by vaxry
- [ASUS Linux](https://asus-linux.org/) community
