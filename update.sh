#!/bin/bash

# Kali Linux Full Update Script
# Requires: sudo privileges

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/kali-update-$(date +%Y%m%d-%H%M%S).log"

# Print colored status messages
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Update failed with exit code $exit_code. Check log: $LOG_FILE"
    fi
    exit $exit_code
}

trap cleanup EXIT

# Check for root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run this script as root or with sudo."
        exit 1
    fi
}

# Check internet connectivity
check_internet() {
    info "Checking internet connectivity..."
    if ! ping -c 1 -W 5 google.com &>/dev/null && ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        error "No internet connection detected. Please check your network."
        exit 1
    fi
    success "Internet connection verified."
}

# Check available disk space (minimum 1GB free)
check_disk_space() {
    info "Checking available disk space..."
    local free_space
    free_space=$(df / | awk 'NR==2 {print $4}')
    local min_space=$((1024 * 1024)) # 1GB in KB

    if [ "$free_space" -lt "$min_space" ]; then
        warning "Low disk space detected ($(numfmt --to=iec-i --suffix=B $((free_space * 1024))) free)."
        read -p "Continue anyway? [y/N]: " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        success "Sufficient disk space available."
    fi
}

# Update package lists
update_package_lists() {
    info "Updating package lists..."
    if apt update 2>&1 | tee -a "$LOG_FILE"; then
        success "Package lists updated."
    else
        error "Failed to update package lists."
        return 1
    fi
}

# Upgrade packages
upgrade_packages() {
    info "Upgrading installed packages..."
    if apt upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
        success "Packages upgraded."
    else
        error "Failed to upgrade packages."
        return 1
    fi
}

# Full distribution upgrade
full_upgrade() {
    info "Performing full distribution upgrade..."
    if apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
        success "Full distribution upgrade completed."
    else
        error "Failed to perform full distribution upgrade."
        return 1
    fi
}

# Clean up
cleanup_packages() {
    info "Removing unnecessary packages..."
    apt autoremove -y 2>&1 | tee -a "$LOG_FILE"

    info "Cleaning package cache..."
    apt clean 2>&1 | tee -a "$LOG_FILE"

    success "Cleanup completed."
}

# Check if reboot is required
check_reboot() {
    if [ -f /var/run/reboot-required ]; then
        warning "A system reboot is required to complete the update."
        read -p "Reboot now? [y/N]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Rebooting system..."
            reboot
        fi
    fi
}

# Display summary
show_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     Kali Linux Update Complete!       ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    info "Log file saved to: $LOG_FILE"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Kali Linux Full Update Script     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    check_root
    check_internet
    check_disk_space

    echo "" | tee -a "$LOG_FILE"
    echo "Update started at $(date)" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    update_package_lists
    upgrade_packages
    full_upgrade
    cleanup_packages

    echo "" | tee -a "$LOG_FILE"
    echo "Update completed at $(date)" | tee -a "$LOG_FILE"

    show_summary
    check_reboot
}

main "$@"
