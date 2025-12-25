#!/bin/bash
#===============================================================================
# 01-base-setup.sh - Base System Setup
# Installs AUR helper, kernel, drivers, and core packages
#===============================================================================

log_step "Starting base system setup..."

#===============================================================================
# PACKAGE LISTS
#===============================================================================

# AUR Helper
AUR_HELPER=""

# Core packages (official repos)
PACKAGES_CORE=(
    # Kernel
    "linux-zen"
    "linux-zen-headers"
    "amd-ucode"
    
    # Build essentials
    "base-devel"
    "git"
    "wget"
    "curl"
    "unzip"
    
    # GPU Drivers (AMD)
    "mesa"
    "lib32-mesa"
    "vulkan-radeon"
    "lib32-vulkan-radeon"
    "libva-mesa-driver"
    
    # Audio (PipeWire)
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "pipewire-jack"
    "wireplumber"
    
    # Networking
    "networkmanager"
    "network-manager-applet"
    "nm-connection-editor"
    "bluez"
    "bluez-utils"
    
    # Fonts
    "ttf-jetbrains-mono-nerd"
    "ttf-nerd-fonts-symbols-mono"
    "noto-fonts"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    
    # Utilities
    "htop"
    "fastfetch"
    "tree"
    "man-db"
    "man-pages"
    
    # File systems
    "btrfs-progs"
    "dosfstools"
    "ntfs-3g"
    
    # System
    "polkit"
    "upower"
    "acpi"
    "acpid"
)

# Btrfs-specific packages
PACKAGES_BTRFS=(
    "timeshift"
    "grub-btrfs"
)

#===============================================================================
# AUR HELPER INSTALLATION
#===============================================================================
install_aur_helper() {
    log_step "Setting up AUR helper..."
    
    # Check for existing AUR helper
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
        log_success "paru already installed"
        return
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
        log_success "yay already installed"
        return
    fi
    
    # Install yay
    log_info "Installing yay..."
    local tmpdir
    tmpdir=$(mktemp -d)
    
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    
    AUR_HELPER="yay"
    log_success "yay installed successfully"
}

#===============================================================================
# PACKAGE INSTALLATION
#===============================================================================
install_packages() {
    log_step "Installing core packages..."
    
    # Update system first
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm
    
    # Install core packages
    log_info "Installing core packages (this may take a while)..."
    sudo pacman -S --needed --noconfirm "${PACKAGES_CORE[@]}"
    
    # Check filesystem and install Btrfs packages if needed
    local root_fs
    root_fs=$(df -T / | awk 'NR==2 {print $2}')
    
    if [ "$root_fs" = "btrfs" ]; then
        log_info "Installing Btrfs utilities..."
        sudo pacman -S --needed --noconfirm "${PACKAGES_BTRFS[@]}"
        
        # Install timeshift-autosnap from AUR
        log_info "Installing timeshift-autosnap..."
        $AUR_HELPER -S --needed --noconfirm timeshift-autosnap || true
    fi
    
    log_success "Core packages installed"
}

#===============================================================================
# ENABLE SERVICES
#===============================================================================
enable_services() {
    log_step "Enabling system services..."
    
    # NetworkManager
    if ! systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
        sudo systemctl enable NetworkManager
        log_success "NetworkManager enabled"
    else
        log_info "NetworkManager already enabled"
    fi
    
    # Start NetworkManager if not running
    if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
        sudo systemctl start NetworkManager
        log_success "NetworkManager started"
    fi
    
    # Bluetooth
    if ! systemctl is-enabled --quiet bluetooth 2>/dev/null; then
        sudo systemctl enable bluetooth
        log_success "Bluetooth enabled"
    else
        log_info "Bluetooth already enabled"
    fi
    
    # ACPI daemon
    if ! systemctl is-enabled --quiet acpid 2>/dev/null; then
        sudo systemctl enable acpid
        log_success "ACPID enabled"
    else
        log_info "ACPID already enabled"
    fi
    
    # TRIM timer
    if ! systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
        sudo systemctl enable fstrim.timer
        log_success "TRIM timer enabled"
    else
        log_info "TRIM timer already enabled"
    fi
}

#===============================================================================
# CONFIGURE KERNEL PARAMETERS
#===============================================================================
configure_kernel_params() {
    log_step "Configuring kernel parameters..."
    
    local kernel_params="amd_pstate=active amdgpu.dpm=1 amdgpu.dcdebugmask=0x10 nowatchdog"
    
    # Check if using systemd-boot or GRUB
    if [ -d /boot/loader/entries ]; then
        # systemd-boot
        log_info "Detected systemd-boot"
        
        local entry_file
        entry_file=$(ls /boot/loader/entries/*.conf 2>/dev/null | head -1)
        
        if [ -n "$entry_file" ]; then
            if ! grep -q "amd_pstate=active" "$entry_file"; then
                log_info "Adding kernel parameters to systemd-boot..."
                sudo sed -i "s|^options.*|& ${kernel_params}|" "$entry_file"
                log_success "Kernel parameters updated"
            else
                log_info "Kernel parameters already configured"
            fi
        else
            log_warning "No systemd-boot entry found. Please configure manually."
            log_info "Add these parameters: ${kernel_params}"
        fi
        
    elif [ -f /etc/default/grub ]; then
        # GRUB
        log_info "Detected GRUB"
        
        if ! grep -q "amd_pstate=active" /etc/default/grub; then
            log_info "Adding kernel parameters to GRUB..."
            sudo sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 ${kernel_params}\"|" /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            log_success "GRUB configuration updated"
        else
            log_info "Kernel parameters already configured"
        fi
    else
        log_warning "Unknown bootloader. Please configure kernel parameters manually."
        log_info "Recommended parameters: ${kernel_params}"
    fi
}

#===============================================================================
# ENABLE MULTILIB
#===============================================================================
enable_multilib() {
    log_step "Checking multilib repository..."
    
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_info "multilib already enabled"
    else
        log_info "Enabling multilib repository..."
        sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
        sudo pacman -Sy
        log_success "multilib enabled"
    fi
}

#===============================================================================
# OPTIMIZE FOR VM (CHAOTIC AUR)
#===============================================================================
enable_chaotic_aur() {
    if [ "$IS_VM" = true ]; then
        log_step "VM detected: Enabling Chaotic AUR for faster installation..."
        
        # Import keys
        log_info "Importing Chaotic AUR keys..."
        sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
        sudo pacman-key --lsign-key 3056513887B78AEB
        
        # Install keyring and mirrorlist
        log_info "Installing keyring..."
        sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
        
        # Add to pacman.conf
        if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
            log_info "Adding repository to pacman.conf..."
            echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
            
            # Refresh databases
            sudo pacman -Sy
            log_success "Chaotic AUR enabled"
        else
            log_info "Chaotic AUR already enabled"
        fi
    fi
}

#===============================================================================
# RUN BASE SETUP
#===============================================================================
run_base_setup() {
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "                      BASE SYSTEM SETUP                        "
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""
    
    enable_multilib
    enable_chaotic_aur
    install_aur_helper
    install_packages
    enable_services
    configure_kernel_params
    
    echo ""
    log_success "Base system setup completed!"
    echo ""
}

# Run if executed directly or sourced
run_base_setup
