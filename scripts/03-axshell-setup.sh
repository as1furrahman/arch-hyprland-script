#!/bin/bash
#===============================================================================
# 03-axshell-setup.sh - Ax-Shell Installation
# Installs Ax-Shell using the official installation method
#===============================================================================

log_step "Starting Ax-Shell setup..."

#===============================================================================
# AX-SHELL DEPENDENCIES (PRE-INSTALL)
#===============================================================================
# These packages are installed before running the official Ax-Shell installer
# to ensure a smooth installation process

PACKAGES_AXSHELL_DEPS=(
    # Core dependencies
    "python"
    "python-pip"
    "gobject-introspection"
    
    # System utilities
    "ddcutil"
    "gpu-screen-recorder"
    "nvtop"
    "imagemagick"
    "tmux"
    "vte3"
    "webp-pixbuf-loader"
    
    # Power management
    "power-profiles-daemon"
    
    # Bluetooth
    "gnome-bluetooth-3.0"
    
    # OCR
    "tesseract"
    "tesseract-data-eng"
)

#===============================================================================
# PRE-INSTALL DEPENDENCIES
#===============================================================================
install_axshell_deps() {
    log_step "Installing Ax-Shell dependencies..."
    
    # Install official repo packages
    sudo pacman -S --needed --noconfirm "${PACKAGES_AXSHELL_DEPS[@]}" || true
    
    log_success "Ax-Shell dependencies installed"
}

#===============================================================================
# INSTALL AX-SHELL (OFFICIAL METHOD)
#===============================================================================
install_axshell() {
    log_step "Installing Ax-Shell using official installer..."
    
    local axshell_dir="$HOME/.config/Ax-Shell"
    
    # Check if already installed
    if [ -d "$axshell_dir" ]; then
        log_info "Ax-Shell directory exists. Updating..."
        
        # Pull latest changes
        if [ -d "$axshell_dir/.git" ]; then
            git -C "$axshell_dir" pull
            log_success "Ax-Shell updated"
        else
            log_warning "Not a git repository. Reinstalling..."
            rm -rf "$axshell_dir"
        fi
    fi
    
    # Run official installer
    if [ ! -d "$axshell_dir" ]; then
        log_info "Running official Ax-Shell installer..."
        log_info "This will install Ax-Shell and its dependencies..."
        echo ""
        
        # Use the official installation method
        curl -fsSL https://raw.githubusercontent.com/Axenide/Ax-Shell/main/install.sh | bash
        
        echo ""
        log_success "Ax-Shell installed successfully!"
    fi
}

#===============================================================================
# CONFIGURE AX-SHELL INTEGRATION
#===============================================================================
configure_axshell() {
    log_step "Configuring Ax-Shell integration with Hyprland..."
    
    local hypr_config_dir="$HOME/.config/hypr"
    local axshell_dir="$HOME/.config/Ax-Shell"
    
    # Check if Ax-Shell autostart is already configured
    if [ -f "$hypr_config_dir/hyprland.conf" ]; then
        if ! grep -q "Ax-Shell" "$hypr_config_dir/hyprland.conf"; then
            log_info "Adding Ax-Shell to Hyprland autostart..."
            
            # Add autostart entry
            cat >> "$hypr_config_dir/hyprland.conf" << 'EOF'

#-------------------------------------------------------------------------------
# AX-SHELL AUTOSTART
#-------------------------------------------------------------------------------
exec-once = uwsm app -- python ~/.config/Ax-Shell/main.py > /dev/null 2>&1 &
EOF
            log_success "Ax-Shell autostart configured"
        else
            log_info "Ax-Shell autostart already configured"
        fi
    fi
    
    # Copy custom scripts to Ax-Shell
    if [ -d "$axshell_dir" ]; then
        mkdir -p "$axshell_dir/scripts"
        
        # Copy our custom scripts
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        
        if [ -d "$script_dir/utils" ]; then
            cp -f "$script_dir/utils/mic-toggle.sh" "$axshell_dir/scripts/" 2>/dev/null || true
            cp -f "$script_dir/utils/camera-toggle.sh" "$axshell_dir/scripts/" 2>/dev/null || true
            chmod +x "$axshell_dir/scripts/"*.sh 2>/dev/null || true
            log_success "Custom scripts copied to Ax-Shell"
        fi
    fi
}

#===============================================================================
# ENABLE POWER PROFILES DAEMON
#===============================================================================
enable_ppd() {
    log_step "Enabling power-profiles-daemon..."
    
    # Check for conflicts
    if systemctl is-enabled --quiet tlp 2>/dev/null; then
        log_warning "TLP is enabled. Disabling to prevent conflicts..."
        sudo systemctl disable --now tlp
    fi
    
    if systemctl is-enabled --quiet auto-cpufreq 2>/dev/null; then
        log_warning "auto-cpufreq is enabled. Disabling to prevent conflicts..."
        sudo systemctl disable --now auto-cpufreq
    fi
    
    # Enable PPD
    if ! systemctl is-enabled --quiet power-profiles-daemon 2>/dev/null; then
        sudo systemctl enable --now power-profiles-daemon
        log_success "power-profiles-daemon enabled"
    else
        log_info "power-profiles-daemon already enabled"
    fi
    
    # Set default profile
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced
        log_info "Power profile set to: balanced"
    fi
}

#===============================================================================
# RUN AX-SHELL SETUP
#===============================================================================
run_axshell_setup() {
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "                    AX-SHELL SETUP                             "
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""
    
    install_axshell_deps
    install_axshell
    configure_axshell
    enable_ppd
    
    echo ""
    log_success "Ax-Shell setup completed!"
    log_info "Ax-Shell will start automatically with Hyprland."
    echo ""
}

# Run if executed directly or sourced
run_axshell_setup
