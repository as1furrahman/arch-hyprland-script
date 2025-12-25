#!/bin/bash
#===============================================================================
# 00-pre-check.sh - System Validation
# Validates system requirements before installation
#===============================================================================

log_step "Running system pre-checks..."

#===============================================================================
# CHECK ARCH LINUX
#===============================================================================
check_arch_linux() {
    log_step "Checking for Arch Linux..."
    
    if [ ! -f /etc/arch-release ]; then
        log_error "This script is designed for Arch Linux only!"
        log_info "Detected OS: $(cat /etc/os-release 2>/dev/null | grep "^ID=" | cut -d'=' -f2)"
        exit 1
    fi
    
    log_success "Arch Linux detected"
}

#===============================================================================
# CHECK UEFI BOOT MODE
#===============================================================================
check_uefi() {
    log_step "Checking boot mode..."
    
    if [ ! -d /sys/firmware/efi ]; then
        log_warning "System not booted in UEFI mode"
        log_info "UEFI is recommended for ASUS Zenbook S 13 OLED"
        read -p "Continue anyway? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "UEFI boot mode detected"
    fi
}

#===============================================================================
# CHECK/SETUP NETWORK CONNECTIVITY
#===============================================================================
setup_network() {
    log_step "Setting up network connectivity..."
    
    # Find the first non-loopback interface that is UP or can be brought UP
    local interface=""
    
    # Get list of interfaces
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
        # Check if interface exists and is not loopback
        if [ -n "$iface" ]; then
            interface="$iface"
            break
        fi
    done
    
    if [ -z "$interface" ]; then
        log_error "No network interface found!"
        return 1
    fi
    
    log_info "Found network interface: $interface"
    
    # Bring interface up if not already
    if ! ip link show "$interface" | grep -q "state UP"; then
        log_info "Bringing up interface $interface..."
        sudo ip link set "$interface" up
        sleep 2
    fi
    
    # Try dhcpcd first (most common on Arch)
    if command -v dhcpcd &>/dev/null; then
        log_info "Configuring network with dhcpcd..."
        sudo dhcpcd "$interface" -w 2>/dev/null &
        sleep 5
        
        # Check if we got an IP
        if ip addr show "$interface" | grep -q "inet "; then
            log_success "Network configured via dhcpcd"
            return 0
        fi
    fi
    
    # Try systemd-networkd
    if systemctl list-unit-files | grep -q systemd-networkd; then
        log_info "Trying systemd-networkd..."
        
        # Create a basic DHCP config if it doesn't exist
        if [ ! -f /etc/systemd/network/20-wired.network ]; then
            cat << EOF | sudo tee /etc/systemd/network/20-wired.network > /dev/null
[Match]
Name=$interface

[Network]
DHCP=yes
EOF
        fi
        
        sudo systemctl start systemd-networkd 2>/dev/null
        sudo systemctl start systemd-resolved 2>/dev/null
        sleep 5
        
        if ip addr show "$interface" | grep -q "inet "; then
            log_success "Network configured via systemd-networkd"
            return 0
        fi
    fi
    
    # Try dhclient as fallback
    if command -v dhclient &>/dev/null; then
        log_info "Trying dhclient..."
        sudo dhclient "$interface" 2>/dev/null
        sleep 3
        
        if ip addr show "$interface" | grep -q "inet "; then
            log_success "Network configured via dhclient"
            return 0
        fi
    fi
    
    return 1
}

check_network() {
    log_step "Checking network connectivity..."
    
    # First check if we already have connectivity
    if ping -c 1 -W 3 archlinux.org &>/dev/null; then
        log_success "Network connectivity OK"
        return 0
    fi
    
    log_warning "No network connectivity detected. Attempting to configure..."
    
    # Try to setup network
    if setup_network; then
        # Wait a moment for network to stabilize
        sleep 2
        
        # Verify connectivity
        if ping -c 1 -W 5 archlinux.org &>/dev/null; then
            log_success "Network connectivity established!"
            return 0
        fi
    fi
    
    # Still no network - offer manual options
    log_error "Could not establish network connectivity automatically."
    echo ""
    log_info "Please try one of these manual options:"
    echo ""
    echo "  For wired connection:"
    echo "    sudo dhcpcd <interface>     # e.g., sudo dhcpcd enp1s0"
    echo ""
    echo "  For WiFi:"
    echo "    iwctl"
    echo "    > station wlan0 connect <SSID>"
    echo ""
    echo "  To see available interfaces:"
    echo "    ip link"
    echo ""
    
    read -p "Retry network check? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        check_network
        return $?
    fi
    
    read -p "Continue without network (for testing only)? [y/N]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Continuing without network - package installation will fail!"
        return 0
    fi
    
    exit 1
}

#===============================================================================
# CHECK DISK SPACE
#===============================================================================
check_disk_space() {
    log_step "Checking available disk space..."
    
    local available_space
    available_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    
    if [ "$available_space" -lt 10 ]; then
        log_error "Insufficient disk space! At least 10GB required."
        log_info "Available: ${available_space}GB"
        exit 1
    fi
    
    log_success "Disk space OK (${available_space}GB available)"
}

#===============================================================================
# DETECT HARDWARE
#===============================================================================
detect_hardware() {
    log_step "Detecting hardware..."
    
    local product_name=""
    local cpu_model=""
    local gpu_model=""
    
    # Get product name
    if [ -f /sys/devices/virtual/dmi/id/product_name ]; then
        product_name=$(cat /sys/devices/virtual/dmi/id/product_name)
    fi
    
    # Get CPU model
    cpu_model=$(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)
    
    # Get GPU model
    gpu_model=$(lspci 2>/dev/null | grep -i vga | cut -d':' -f3 | xargs)
    
    # Check if this is the target hardware
    if [[ "$product_name" == *"Zenbook"* ]] || [[ "$product_name" == *"UM5302"* ]]; then
        log_success "ASUS Zenbook S 13 OLED detected!"
        log_info "Full hardware optimizations will be applied."
    elif $IS_VM; then
        log_info "Running in VM - Hardware optimizations will be simulated"
    else
        log_warning "Unknown hardware: ${product_name:-Not detected}"
        log_info "Generic optimizations will be applied."
    fi
    
    # Check for AMD CPU
    if [[ "$cpu_model" == *"AMD"* ]] || [[ "$cpu_model" == *"Ryzen"* ]]; then
        log_success "AMD CPU detected: ${cpu_model}"
    else
        log_warning "Non-AMD CPU detected. Some optimizations may not apply."
    fi
    
    # Check for AMD GPU
    if [[ "$gpu_model" == *"AMD"* ]] || [[ "$gpu_model" == *"Radeon"* ]]; then
        log_success "AMD GPU detected: ${gpu_model}"
    elif [[ "$gpu_model" == *"Red Hat"* ]] || [[ "$gpu_model" == *"Virtio"* ]]; then
        log_info "Virtual GPU detected (VM environment)"
    else
        log_warning "Non-AMD GPU detected. Some optimizations may not apply."
    fi
}

#===============================================================================
# CHECK REQUIRED COMMANDS
#===============================================================================
check_requirements() {
    log_step "Checking required commands..."
    
    local missing=()
    local required_cmds=("pacman" "curl" "git" "sudo")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        exit 1
    fi
    
    log_success "All required commands available"
}

#===============================================================================
# CHECK FILESYSTEM
#===============================================================================
check_filesystem() {
    log_step "Checking filesystem..."
    
    local root_fs
    root_fs=$(df -T / | awk 'NR==2 {print $2}')
    
    if [ "$root_fs" = "btrfs" ]; then
        log_success "Btrfs filesystem detected - Full Btrfs optimizations will be applied"
    elif [ "$root_fs" = "ext4" ]; then
        log_info "ext4 filesystem detected - Standard optimizations will be applied"
        log_info "Consider using Btrfs for snapshots with Timeshift"
    else
        log_info "Filesystem: ${root_fs}"
    fi
}

#===============================================================================
# RUN ALL CHECKS
#===============================================================================
run_prechecks() {
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "                    SYSTEM PRE-CHECKS                          "
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""
    
    check_arch_linux
    check_uefi
    check_network
    check_disk_space
    check_requirements
    check_filesystem
    detect_hardware
    
    echo ""
    log_success "All pre-checks passed! Ready to proceed."
    echo ""
}

# Run if executed directly or sourced
run_prechecks
