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

# Print colored message
print_msg() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Log and print message
log_msg() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# Error handler
error_handler() {
    print_msg "$RED" "Error occurred on line $1"
    log_msg "ERROR: Script failed on line $1"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Check for root privileges
print_msg "$BLUE" "========================================"
print_msg "$BLUE" "    Kali Linux Full Update Script"
print_msg "$BLUE" "========================================"
echo ""

if [ "$EUID" -ne 0 ]; then
    print_msg "$RED" "Error: Please run this script as root or with sudo."
    exit 1
fi

print_msg "$GREEN" "Running as root - OK"
log_msg "Starting Kali Linux update"

# Check internet connectivity
print_msg "$YELLOW" "Checking internet connectivity..."
if ! ping -c 1 -W 5 kali.org &>/dev/null; then
    print_msg "$RED" "Error: No internet connection. Please check your network."
    log_msg "ERROR: No internet connectivity"
    exit 1
fi
print_msg "$GREEN" "Internet connection - OK"

# Show disk space before update
print_msg "$YELLOW" "Disk space before update:"
df -h / | tail -1

echo ""
log_msg "Updating package lists..."
print_msg "$BLUE" "[1/5] Updating package lists..."
if apt update 2>&1 | tee -a "$LOG_FILE"; then
    print_msg "$GREEN" "Package lists updated successfully"
else
    print_msg "$RED" "Failed to update package lists"
    exit 1
fi

echo ""
log_msg "Upgrading installed packages..."
print_msg "$BLUE" "[2/5] Upgrading installed packages..."
apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
print_msg "$GREEN" "Packages upgraded successfully"

echo ""
log_msg "Performing full distribution upgrade..."
print_msg "$BLUE" "[3/5] Performing full distribution upgrade..."
apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"
print_msg "$GREEN" "Distribution upgrade completed"

echo ""
log_msg "Removing unnecessary packages..."
print_msg "$BLUE" "[4/5] Removing unnecessary packages..."
apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
print_msg "$GREEN" "Unnecessary packages removed"

echo ""
log_msg "Cleaning package cache..."
print_msg "$BLUE" "[5/5] Cleaning package cache..."
apt clean 2>&1 | tee -a "$LOG_FILE"
apt autoclean 2>&1 | tee -a "$LOG_FILE"
print_msg "$GREEN" "Package cache cleaned"

# Show disk space after update
echo ""
print_msg "$YELLOW" "Disk space after update:"
df -h / | tail -1

# Check if reboot is required
echo ""
if [ -f /var/run/reboot-required ]; then
    print_msg "$YELLOW" "WARNING: A system reboot is required to complete the update."
    log_msg "Reboot required"
fi

echo ""
print_msg "$GREEN" "========================================"
print_msg "$GREEN" "    Kali Linux is fully updated!"
print_msg "$GREEN" "========================================"
log_msg "Update completed successfully"
print_msg "$BLUE" "Log saved to: $LOG_FILE"
