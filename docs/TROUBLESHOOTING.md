# Troubleshooting Guide

Common issues and solutions for the Arch Hyprland setup on ASUS Zenbook S 13 OLED.

---

## 🔊 Audio Issues

### No Sound from Speakers

```bash
# Check if PipeWire is running
systemctl --user status pipewire pipewire-pulse wireplumber

# Restart audio services
systemctl --user restart pipewire pipewire-pulse wireplumber

# Check audio devices
wpctl status
```

### Microphone Not Working

```bash
# Check default source
wpctl status | grep -A5 "Sources"

# Set microphone as default
wpctl set-default <source-id>

# Unmute microphone
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
```

---

## 💤 Suspend/Resume Issues

### System Freezes on Suspend

Add kernel parameter to disable C6 state:

```bash
# Edit bootloader config and add:
amd-disable-c6=1

# Or install the AUR package
yay -S amd-disable-c6
sudo systemctl enable amd-disable-c6
```

### Wakes Up Immediately

```bash
# Check wake sources
cat /proc/acpi/wakeup

# Disable problematic device
echo "GPP0" | sudo tee /proc/acpi/wakeup
```

---

## 📶 Bluetooth Issues

### No Bluetooth Adapter Found

```bash
# Check if Bluetooth service is running
sudo systemctl status bluetooth

# Restart Bluetooth
sudo systemctl restart bluetooth

# Check for blocked
rfkill list
rfkill unblock bluetooth
```

### Device Won't Pair

```bash
# Use bluetoothctl
bluetoothctl
> power on
> agent on
> default-agent
> scan on
> pair <MAC>
> trust <MAC>
> connect <MAC>
```

---

## 🌐 Wi-Fi Issues

### Slow or Unstable Connection

```bash
# Check for power saving
iw dev wlan0 get power_save

# Disable power saving
sudo iw dev wlan0 set power_save off

# Make permanent
echo 'options mt7921e power_save=N' | sudo tee /etc/modprobe.d/mt7921e.conf
```

---

## 🖥️ Display Issues

### OLED Flickering

Kernel parameter should fix this:

```bash
# Verify parameter is set
cat /proc/cmdline | grep amdgpu.dcdebugmask
```

### Screen Tearing

```bash
# Check VRR
hyprctl monitors

# Enable VRR in hyprland.conf
misc {
    vrr = 1
}
```

---

## ⌨️ Function Keys Not Working

### Keys Not Detected

```bash
# Check key events
sudo libinput debug-events | grep key

# Check for unknown keys in dmesg
dmesg | grep -i "asus.*unknown"
```

### Microphone LED Not Updating

```bash
# Check LED path exists
ls /sys/class/leds/platform::micmute/

# Add sudo permission (see post-install script)
sudo visudo -f /etc/sudoers.d/led-control
```

---

## 📷 Camera Issues

### Camera Not Detected

```bash
# Check if module is loaded
lsmod | grep uvcvideo

# Load module
sudo modprobe uvcvideo

# Check devices
v4l2-ctl --list-devices
```

---

## 🔋 Battery Issues

### Poor Battery Life

```bash
# Check power profile
powerprofilesctl get

# Set power saver
powerprofilesctl set power-saver

# Check CPU frequency
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
```

### Check Power Draw

```bash
# Install powertop
sudo pacman -S powertop

# Run analysis
sudo powertop
```

---

## 🔄 Btrfs/Timeshift - Snapshot Recovery

### Understanding Snapshots

Your system is configured with automatic snapshots:
- **Boot snapshots** (B): Created at every boot (keeps 5)
- **Daily snapshots** (D): Created daily (keeps 5)
- **Weekly snapshots** (W): Created weekly (keeps 3)
- **Pre-update snapshots**: Created before pacman updates (via timeshift-autosnap)

### List Available Snapshots

```bash
# Using Timeshift CLI
sudo timeshift --list

# Example output:
# Num  Name                          Tags  Description
# 0    2024-12-25_22-30-00           B     Boot snapshot
# 1    2024-12-25_12-00-00           D     Daily snapshot
# 2    2024-12-24_12-00-00           O     pacman pre-update
```

### Restore from Running System

If your system is still bootable but broken:

```bash
# List snapshots
sudo timeshift --list

# Restore specific snapshot (interactive)
sudo timeshift --restore

# Or restore specific snapshot by name
sudo timeshift --restore --snapshot '2024-12-25_22-30-00'

# Reboot after restore
sudo reboot
```

### Restore from GRUB Menu (Bootable Snapshots)

If your system boots to GRUB but Hyprland/desktop is broken:

1. **At GRUB menu**, look for **"Arch Linux Snapshots"** submenu
2. Select a working snapshot to boot from
3. Once booted into snapshot, make it permanent:

```bash
# After booting into snapshot, restore it permanently
sudo timeshift --restore --snapshot-device /dev/nvme0n1p2
```

### Restore from Live USB (Broken System)

If your system won't boot at all:

1. **Boot from Arch Live USB**

2. **Connect to internet:**
```bash
iwctl
station wlan0 connect YOUR_WIFI
```

3. **Mount Btrfs root:**
```bash
# Find your Btrfs partition
lsblk -f

# Mount the Btrfs partition (not subvolume)
mount /dev/nvme0n1p2 /mnt

# List subvolumes
btrfs subvolume list /mnt
```

4. **Identify snapshots:**
```bash
# Snapshots are in /mnt/timeshift-btrfs/snapshots/
ls /mnt/timeshift-btrfs/snapshots/
```

5. **Manual restore (replace @ with snapshot):**
```bash
# Backup current broken root
mv /mnt/@ /mnt/@_broken

# Copy snapshot to new root
btrfs subvolume snapshot /mnt/timeshift-btrfs/snapshots/2024-12-25_22-30-00/@ /mnt/@

# Optional: Also restore home
mv /mnt/@home /mnt/@home_broken
btrfs subvolume snapshot /mnt/timeshift-btrfs/snapshots/2024-12-25_22-30-00/@home /mnt/@home

# Unmount and reboot
umount /mnt
reboot
```

### Create Manual Snapshot Before Risky Changes

```bash
# Create tagged snapshot with description
sudo timeshift --create --comments "Before major update" --tags D

# Verify it was created
sudo timeshift --list
```

### Timeshift Not Working

```bash
# Check if Timeshift config exists
cat /etc/timeshift/timeshift.json

# Check if Btrfs subvolumes are correct
sudo btrfs subvolume list /

# Expected output should include:
# @ (or @root) - for root
# @home - for home

# Check Timeshift service status
sudo timeshift --check

# Reconfigure if needed
sudo timeshift-gtk
```

### Delete Old Snapshots

```bash
# List snapshots
sudo timeshift --list

# Delete specific snapshot
sudo timeshift --delete --snapshot '2024-12-20_12-00-00'

# Delete all snapshots (careful!)
sudo timeshift --delete-all
```

---

## 📝 General Debug Commands

```bash
# System logs
journalctl -b -p err

# Hyprland logs
cat ~/.local/share/hyprland/hyprland.log

# Check kernel parameters
cat /proc/cmdline

# Hardware info
inxi -Fxz
```
