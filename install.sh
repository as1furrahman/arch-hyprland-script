#!/bin/bash
#===============================================================================
#
#   ███████╗███████╗███╗   ██╗██████╗  ██████╗  ██████╗ ██╗  ██╗    ███████╗ ██╗██████╗ 
#   ╚══███╔╝██╔════╝████╗  ██║██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝    ██╔════╝███║╚════██╗
#     ███╔╝ █████╗  ██╔██╗ ██║██████╔╝██║   ██║██║   ██║█████╔╝     ███████╗╚██║ █████╔╝
#    ███╔╝  ██╔══╝  ██║╚██╗██║██╔══██╗██║   ██║██║   ██║██╔═██╗     ╚════██║ ██║ ╚═══██╗
#   ███████╗███████╗██║ ╚████║██████╔╝╚██████╔╝╚██████╔╝██║  ██╗    ███████║ ██║██████╔╝
#   ╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝    ╚══════╝ ╚═╝╚═════╝ 
#
#   Arch Hyprland + Ax-Shell Automated Installation Script
#   For: ASUS Zenbook S 13 OLED (UM5302TA)
#   
#   Author: Asif
#   License: MIT
#
#===============================================================================

set -e          # Exit immediately if a command fails
set -u          # Treat unset variables as errors
set -o pipefail # Prevent errors in a pipeline from being masked

#===============================================================================
# COLORS & FORMATTING
#===============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

#===============================================================================
# LOGGING FUNCTIONS
#===============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${MAGENTA}[→]${NC} $1"
}

#===============================================================================
# GLOBAL VARIABLES
#===============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/install.log"
IS_VM=false
HARDWARE_MODEL=""

#===============================================================================
# HELPER FUNCTIONS
#===============================================================================
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║   █████╗ ██████╗  ██████╗██╗  ██╗    ██╗  ██╗██╗   ██╗██████╗ ██████╗ ║"
    echo "║  ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗║"
    echo "║  ███████║██████╔╝██║     ███████║    ███████║ ╚████╔╝ ██████╔╝██████╔╝║"
    echo "║  ██╔══██║██╔══██╗██║     ██╔══██║    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗║"
    echo "║  ██║  ██║██║  ██║╚██████╗██║  ██║    ██║  ██║   ██║   ██║     ██║  ██║║"
    echo "║  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝║"
    echo "║                                                                      ║"
    echo "║           Automated Installation for ASUS Zenbook S 13 OLED          ║"
    echo "║                         + Ax-Shell Integration                       ║"
    echo "║                                                                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

detect_environment() {
    log_step "Detecting environment..."
    
    # Check if running in VM
    if systemd-detect-virt -q 2>/dev/null; then
        IS_VM=true
        log_info "Running in: ${YELLOW}Virtual Machine${NC} ($(systemd-detect-virt))"
    else
        IS_VM=false
        log_info "Running on: ${GREEN}Bare Metal${NC}"
    fi
    
    # Detect hardware model
    if [ -f /sys/devices/virtual/dmi/id/product_name ]; then
        HARDWARE_MODEL=$(cat /sys/devices/virtual/dmi/id/product_name)
        log_info "Hardware: ${CYAN}${HARDWARE_MODEL}${NC}"
    fi
}

check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        log_error "Please do not run this script as root!"
        log_info "Run as a regular user. The script will ask for sudo when needed."
        exit 1
    fi
}

show_menu() {
    echo ""
    echo -e "${WHITE}${BOLD}Select Installation Option:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Full Installation     ${WHITE}(Recommended for fresh installs)${NC}"
    echo -e "  ${CYAN}2)${NC} Pre-Install Only      ${WHITE}(Base packages + Hyprland)${NC}"
    echo -e "  ${CYAN}3)${NC} Ax-Shell Setup        ${WHITE}(Install Ax-Shell only)${NC}"
    echo -e "  ${CYAN}4)${NC} Post-Install Only     ${WHITE}(Hardware optimizations)${NC}"
    echo -e "  ${CYAN}5)${NC} View System Info"
    echo -e "  ${CYAN}q)${NC} Quit"
    echo ""
    echo -n -e "${WHITE}Enter your choice [1-5/q]: ${NC}"
}

run_pre_install() {
    log_info "Starting Pre-Installation..."
    source "${SCRIPT_DIR}/scripts/00-pre-check.sh"
    source "${SCRIPT_DIR}/scripts/01-base-setup.sh"
    source "${SCRIPT_DIR}/scripts/02-hyprland-setup.sh"
    log_success "Pre-Installation completed!"
}

run_axshell_setup() {
    log_info "Starting Ax-Shell Setup..."
    source "${SCRIPT_DIR}/scripts/03-axshell-setup.sh"
    log_success "Ax-Shell Setup completed!"
}

run_post_install() {
    log_info "Starting Post-Installation..."
    source "${SCRIPT_DIR}/scripts/04-post-install.sh"
    log_success "Post-Installation completed!"
}

run_full_install() {
    log_info "Starting Full Installation..."
    run_pre_install
    run_axshell_setup
    run_post_install
    log_success "Full Installation completed!"
    echo ""
    log_info "Please reboot your system to apply all changes."
    echo -e "${GREEN}Enjoy your new setup! 🚀${NC}"
}

show_system_info() {
    echo ""
    echo -e "${WHITE}${BOLD}System Information:${NC}"
    echo -e "  ${CYAN}OS:${NC}         $(cat /etc/os-release 2>/dev/null | grep "^PRETTY_NAME" | cut -d'"' -f2)"
    echo -e "  ${CYAN}Kernel:${NC}     $(uname -r)"
    echo -e "  ${CYAN}Model:${NC}      ${HARDWARE_MODEL:-Unknown}"
    echo -e "  ${CYAN}CPU:${NC}        $(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)"
    echo -e "  ${CYAN}GPU:${NC}        $(lspci 2>/dev/null | grep -i vga | cut -d':' -f3 | xargs)"
    echo -e "  ${CYAN}Memory:${NC}     $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')"
    echo -e "  ${CYAN}Storage:${NC}    $(lsblk -d -o NAME,SIZE 2>/dev/null | grep -E "nvme|sd" | head -1 | awk '{print $2}')"
    echo -e "  ${CYAN}Environment:${NC} ${IS_VM:+VM ($(systemd-detect-virt 2>/dev/null || echo 'unknown'))}${IS_VM:-Bare Metal}"
    echo ""
}

#===============================================================================
# MAIN
#===============================================================================
main() {
    print_banner
    check_root
    detect_environment
    
    # Start logging
    exec > >(tee -a "$LOG_FILE") 2>&1
    log_info "Log file: ${LOG_FILE}"
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1)
                run_full_install
                break
                ;;
            2)
                run_pre_install
                break
                ;;
            3)
                run_axshell_setup
                break
                ;;
            4)
                run_post_install
                break
                ;;
            5)
                show_system_info
                ;;
            q|Q)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_warning "Invalid option. Please try again."
                ;;
        esac
    done
}

# Parse command line arguments
case "${1:-}" in
    --pre-install)
        print_banner
        check_root
        detect_environment
        run_pre_install
        ;;
    --axshell)
        print_banner
        check_root
        detect_environment
        run_axshell_setup
        ;;
    --post-install)
        print_banner
        check_root
        detect_environment
        run_post_install
        ;;
    --full)
        print_banner
        check_root
        detect_environment
        run_full_install
        ;;
    --help|-h)
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --pre-install    Run pre-installation only"
        echo "  --axshell        Install Ax-Shell only"
        echo "  --post-install   Run post-installation only"
        echo "  --full           Run full installation"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Without options, an interactive menu will be displayed."
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        log_info "Use --help for usage information."
        exit 1
        ;;
esac
