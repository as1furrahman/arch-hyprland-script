#!/bin/bash
#===============================================================================
# 04-post-install.sh - Post-Installation Optimizations
# Hardware-specific optimizations for ASUS Zenbook S 13 OLED (UM5302TA)
#===============================================================================

log_step "Starting post-installation optimizations..."

#===============================================================================
# CPU OPTIMIZATION
#===============================================================================
optimize_cpu() {
    log_step "Applying CPU optimizations..."
    
    # Check if amd_pstate is active
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]; then
        local current_driver
        current_driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)
        log_info "Current CPU driver: ${current_driver}"
        
        if [ "$current_driver" = "amd-pstate-epp" ] || [ "$current_driver" = "amd-pstate" ]; then
            log_success "AMD P-State driver is active"
        else
            log_warning "AMD P-State not active. Reboot may be required."
        fi
    fi
    
    # Configure CPU governor preference
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]; then
        log_info "Setting energy performance preference to 'balance_performance'..."
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            echo "balance_performance" | sudo tee "$cpu" > /dev/null 2>&1 || true
        done
        log_success "CPU energy preference configured"
    fi
}

#===============================================================================
# GPU OPTIMIZATION
#===============================================================================
optimize_gpu() {
    log_step "Applying GPU optimizations..."
    
    # Check for AMD GPU
    if lspci | grep -iq "AMD.*VGA\|Radeon"; then
        log_info "AMD GPU detected"
        
        # Check DPM status
        if [ -f /sys/class/drm/card0/device/power_dpm_state ]; then
            log_info "DPM State: $(cat /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || echo 'N/A')"
        fi
        
        # Configure VA-API for hardware video acceleration
        log_info "Configuring hardware video acceleration..."
        echo 'export LIBVA_DRIVER_NAME=radeonsi' | sudo tee /etc/profile.d/vaapi.sh > /dev/null
        echo 'export VDPAU_DRIVER=radeonsi' | sudo tee -a /etc/profile.d/vaapi.sh > /dev/null
        sudo chmod +x /etc/profile.d/vaapi.sh
        
        log_success "GPU optimizations applied"
    else
        log_info "Non-AMD GPU or VM environment detected, skipping GPU optimizations"
    fi
}

#===============================================================================
# SSD OPTIMIZATION (BTRFS)
#===============================================================================
optimize_ssd() {
    log_step "Applying SSD optimizations..."
    
    local root_fs
    root_fs=$(df -T / | awk 'NR==2 {print $2}')
    
    # TRIM timer
    if ! systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
        sudo systemctl enable --now fstrim.timer
        log_success "TRIM timer enabled"
    else
        log_info "TRIM timer already enabled"
    fi
    
    # Swappiness optimization
    log_info "Configuring swappiness..."
    if ! grep -q "vm.swappiness" /etc/sysctl.d/99-ssd-optimizations.conf 2>/dev/null; then
        sudo mkdir -p /etc/sysctl.d
        cat << 'EOF' | sudo tee /etc/sysctl.d/99-ssd-optimizations.conf > /dev/null
# SSD Optimizations for Samsung 990 Pro
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
        sudo sysctl --system > /dev/null 2>&1
        log_success "Sysctl optimizations applied"
    else
        log_info "Sysctl optimizations already configured"
    fi
    
    # Btrfs-specific optimizations
    if [ "$root_fs" = "btrfs" ]; then
        log_info "Applying Btrfs-specific optimizations..."
        
        # Configure Timeshift for Btrfs
        if command -v timeshift &>/dev/null; then
            log_info "Timeshift is available for Btrfs snapshots"
            log_info "Run 'sudo timeshift-gtk' to configure automatic snapshots"
        fi
        
        # Enable Btrfs scrub timer
        if ! systemctl is-enabled --quiet btrfs-scrub@-.timer 2>/dev/null; then
            sudo systemctl enable btrfs-scrub@-.timer 2>/dev/null || true
        fi
        
        log_success "Btrfs optimizations applied"
    fi
}

#===============================================================================
# OLED OPTIMIZATION
#===============================================================================
optimize_oled() {
    log_step "Applying OLED optimizations..."
    
    # Configure GTK to use dark theme
    log_info "Setting GTK dark theme..."
    mkdir -p "$HOME/.config/gtk-3.0"
    mkdir -p "$HOME/.config/gtk-4.0"
    
    # GTK 3
    cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Breeze
gtk-cursor-theme-size=24
gtk-font-name=Sans 10
EOF
    
    # GTK 4
    cat > "$HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=true
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Breeze
gtk-cursor-theme-size=24
gtk-font-name=Sans 10
EOF
    
    # Set gsettings if available
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    fi
    
    log_success "OLED dark theme configured"
    
    # Configure Qt to use dark theme
    log_info "Configuring Qt dark theme..."
    if command -v kvantummanager &>/dev/null; then
        log_info "Kvantum available for Qt theming"
    fi
    
    # Environment variables for Qt
    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/qt-dark.conf" << 'EOF'
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=Adwaita-Dark
EOF
    
    log_success "Qt dark theme configured"
}

#===============================================================================
# FUNCTION KEY CONFIGURATION
#===============================================================================
configure_function_keys() {
    log_step "Configuring function keys..."
    
    local hypr_config_dir="$HOME/.config/hypr"
    local axshell_dir="$HOME/.config/Ax-Shell"
    
    # Create keybinds config
    mkdir -p "$hypr_config_dir"
    
    cat > "$hypr_config_dir/keybinds-hardware.conf" << 'EOF'
#===============================================================================
# HARDWARE FUNCTION KEYS
# For ASUS Zenbook S 13 OLED (UM5302TA)
#===============================================================================

# Volume Control (Fn+F1, F2, F3)
bindle = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindle = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+

# Brightness Control (Fn+F5, F6)
bindle = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bindle = , XF86MonBrightnessUp, exec, brightnessctl set +5%

# Keyboard Backlight (Fn+F7)
bindle = , XF86KbdBrightnessDown, exec, brightnessctl -d *::kbd_backlight set 20%-
bindle = , XF86KbdBrightnessUp, exec, brightnessctl -d *::kbd_backlight set +20%

# Microphone Mute (Fn+F9)
bind = , XF86AudioMicMute, exec, ~/.config/Ax-Shell/scripts/mic-toggle.sh

# Camera Toggle (Fn+F10)
bind = , XF86CameraAccessToggle, exec, ~/.config/Ax-Shell/scripts/camera-toggle.sh
# Alternative binding if XF86CameraAccessToggle doesn't work
bind = , XF86WebCam, exec, ~/.config/Ax-Shell/scripts/camera-toggle.sh

# Display Toggle (Fn+F8)
bind = , XF86Display, exec, hyprctl dispatch dpms toggle

# Media Keys
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous
bind = , XF86AudioStop, exec, playerctl stop
EOF
    
    # Source keybinds in main config if not already done
    if [ -f "$hypr_config_dir/hyprland.conf" ]; then
        if ! grep -q "keybinds-hardware.conf" "$hypr_config_dir/hyprland.conf"; then
            echo "" >> "$hypr_config_dir/hyprland.conf"
            echo "# Hardware-specific keybindings" >> "$hypr_config_dir/hyprland.conf"
            echo "source = ~/.config/hypr/keybinds-hardware.conf" >> "$hypr_config_dir/hyprland.conf"
        fi
    fi
    
    log_success "Function keys configured"
}

#===============================================================================
# SETUP UTILITY SCRIPTS
#===============================================================================
setup_utility_scripts() {
    log_step "Setting up utility scripts..."
    
    local scripts_dir="$HOME/.config/Ax-Shell/scripts"
    mkdir -p "$scripts_dir"
    
    # Mic toggle script
    cat > "$scripts_dir/mic-toggle.sh" << 'EOF'
#!/bin/bash
# Toggle microphone mute and update LED indicator

# Toggle mute
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Get mute status
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
    MUTED=true
else
    MUTED=false
fi

# Update LED indicator
if [ -w "/sys/class/leds/platform::micmute/brightness" ]; then
    if $MUTED; then
        echo 1 | sudo tee /sys/class/leds/platform::micmute/brightness > /dev/null
    else
        echo 0 | sudo tee /sys/class/leds/platform::micmute/brightness > /dev/null
    fi
fi

# Send notification
if $MUTED; then
    notify-send -u low -i microphone-sensitivity-muted "Microphone" "Muted" -h string:x-canonical-private-synchronous:mic
else
    notify-send -u low -i microphone-sensitivity-high "Microphone" "Unmuted" -h string:x-canonical-private-synchronous:mic
fi
EOF
    
    # Camera toggle script
    cat > "$scripts_dir/camera-toggle.sh" << 'EOF'
#!/bin/bash
# Toggle camera access by loading/unloading uvcvideo module
# Also updates the camera LED indicator

CAMERA_LED="/sys/class/leds/platform::camera"

if lsmod | grep -q uvcvideo; then
    # Disable camera
    sudo modprobe -r uvcvideo
    
    # LED on = camera disabled (privacy mode)
    if [ -w "$CAMERA_LED/brightness" ]; then
        echo 1 | sudo tee "$CAMERA_LED/brightness" > /dev/null
    fi
    
    notify-send -u low -i camera-off "Camera" "Disabled" -h string:x-canonical-private-synchronous:camera
else
    # Enable camera
    sudo modprobe uvcvideo
    
    # LED off = camera enabled
    if [ -w "$CAMERA_LED/brightness" ]; then
        echo 0 | sudo tee "$CAMERA_LED/brightness" > /dev/null
    fi
    
    notify-send -u low -i camera-on "Camera" "Enabled" -h string:x-canonical-private-synchronous:camera
fi
EOF
    
    # Make scripts executable
    chmod +x "$scripts_dir/mic-toggle.sh"
    chmod +x "$scripts_dir/camera-toggle.sh"
    
    log_success "Utility scripts created"
    
    # Setup sudoers for LED control (optional)
    log_info "To allow LED control without password, run:"
    log_info "  sudo visudo -f /etc/sudoers.d/led-control"
    log_info "And add:"
    log_info "  $USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/leds/platform*/brightness"
}

#===============================================================================
# ASUS-SPECIFIC OPTIMIZATIONS
#===============================================================================
optimize_asus() {
    log_step "Applying ASUS-specific optimizations..."
    
    # Check if asus-wmi module is loaded
    if lsmod | grep -q asus_wmi; then
        log_info "asus-wmi module loaded"
    fi
    
    # Install asusctl if on compatible hardware
    local product_name=""
    if [ -f /sys/devices/virtual/dmi/id/product_name ]; then
        product_name=$(cat /sys/devices/virtual/dmi/id/product_name)
    fi
    
    if [[ "$product_name" == *"Zenbook"* ]] || [[ "$product_name" == *"ASUS"* ]]; then
        log_info "ASUS hardware detected"
        
        # Check if asusctl is available
        if ! command -v asusctl &>/dev/null; then
            log_info "Installing asusctl for ASUS hardware control..."
            $AUR_HELPER -S --needed --noconfirm asusctl 2>/dev/null || true
            
            if command -v asusctl &>/dev/null; then
                sudo systemctl enable --now asusd
                log_success "asusctl installed and enabled"
            fi
        else
            log_info "asusctl already installed"
        fi
    fi
}

#===============================================================================
# BLUETOOTH OPTIMIZATION
#===============================================================================
optimize_bluetooth() {
    log_step "Optimizing Bluetooth..."
    
    # Enable Bluetooth service
    if ! systemctl is-enabled --quiet bluetooth 2>/dev/null; then
        sudo systemctl enable --now bluetooth
        log_success "Bluetooth service enabled"
    else
        log_info "Bluetooth service already enabled"
    fi
    
    # Configure Bluetooth for better connectivity
    if [ -f /etc/bluetooth/main.conf ]; then
        # Enable auto-power on
        if ! grep -q "^AutoEnable=true" /etc/bluetooth/main.conf; then
            sudo sed -i 's/^#AutoEnable.*/AutoEnable=true/' /etc/bluetooth/main.conf
            log_info "Bluetooth auto-enable configured"
        fi
    fi
}

#===============================================================================
# RUN POST-INSTALLATION
#===============================================================================
run_post_install() {
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "                POST-INSTALLATION OPTIMIZATIONS                "
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""
    
    optimize_cpu
    optimize_gpu
    optimize_ssd
    optimize_oled
    configure_function_keys
    setup_utility_scripts
    optimize_asus
    optimize_bluetooth
    
    echo ""
    log_success "Post-installation optimizations completed!"
    log_info ""
    log_info "Recommended next steps:"
    log_info "  1. Reboot your system to apply all changes"
    log_info "  2. Run 'sudo timeshift-gtk' to configure Btrfs snapshots"
    log_info "  3. Test function keys after reboot"
    log_info ""
}

# Run if executed directly or sourced
run_post_install
