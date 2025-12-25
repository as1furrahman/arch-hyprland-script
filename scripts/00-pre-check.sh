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
# CHECK NETWORK CONNECTIVITY
#===============================================================================
check_network() {
    log_step "Checking network connectivity..."
    
    if ! ping -c 1 archlinux.org &>/dev/null; then
        log_error "No network connectivity!"
        log_info "Please connect to the internet and try again."
        exit 1
    fi
    
    log_success "Network connectivity OK"
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
