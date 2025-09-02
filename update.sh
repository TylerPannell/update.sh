#!/bin/bash

# Kali Linux Full Update Script
# Requires: sudo privileges

# Exit on error
set -e

echo "Checking for sudo/root privileges..."
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "Updating package lists..."
apt update

echo "Upgrading installed packages..."
apt upgrade -y

echo "Performing full distribution upgrade..."
apt full-upgrade -y

echo "Removing unnecessary packages..."
apt autoremove -y
apt clean

echo "Kali Linux is fully updated."
