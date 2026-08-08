#!/bin/bash
# ==============================================================================
# HeadUnit OS — Intel Bluetooth Firmware & Driver Installer
# Target platform: Ubuntu Server / Linux Mint (Intel AX200/AX210/9260)
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     HeadUnit OS — Intel Bluetooth Firmware Installer         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Install packages
echo -e "${CYAN}[1/3] Installing linux-firmware & BlueZ stack...${NC}"
sudo apt update
sudo apt install -y linux-firmware bluetooth bluez rfkill git
echo -e "${GREEN}✓ Firmware packages installed.${NC}"
echo ""

# 2. Copy latest Intel Bluetooth firmware
echo -e "${CYAN}[2/3] Fetching latest Intel Bluetooth firmware (ibt-*)...${NC}"
TMP_FW="/tmp/linux-firmware-intel"
rm -rf "$TMP_FW"
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git "$TMP_FW"
sudo mkdir -p /lib/firmware/intel
sudo cp "$TMP_FW"/intel/ibt-* /lib/firmware/intel/ 2>/dev/null || true
rm -rf "$TMP_FW"
echo -e "${GREEN}✓ Intel Bluetooth firmware files copied to /lib/firmware/intel/.${NC}"
echo ""

# 3. Reload kernel driver module & restart Bluetooth daemon
echo -e "${CYAN}[3/3] Reloading btusb kernel module & bluetoothd service...${NC}"
sudo rfkill unblock bluetooth || true
sudo modprobe -r btusb 2>/dev/null || true
sudo modprobe btusb
sudo systemctl restart bluetooth

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} 🎉 Intel Bluetooth Firmware Installation Complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Checking Bluetooth Controller Status:"
bluetoothctl show || echo -e "${YELLOW}Note: Cold reboot may be required if Intel chip crashed previously.${NC}"
