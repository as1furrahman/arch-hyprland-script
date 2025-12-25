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

## 🔄 Btrfs/Timeshift Issues

### Timeshift Not Detecting Btrfs

```bash
# Check mount options
mount | grep btrfs

# Ensure subvolumes are correct
# @ for root, @home for home
```

### Restore from Snapshot

```bash
# List snapshots
sudo timeshift --list

# Restore
sudo timeshift --restore
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
