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
echo -e "${CYAN}[1/3] Installing linux-firmware, pulseaudio-module-bluetooth, & BlueZ stack...${NC}"
sudo apt update
sudo apt install -y linux-firmware bluetooth bluez rfkill git pulseaudio-module-bluetooth
echo -e "${GREEN}✓ Firmware packages installed.${NC}"
echo ""

# Configure Automotive Car Stereo Device Class (0x200408) in BlueZ
echo -e "${CYAN}Configuring Automotive Car Stereo Bluetooth Profile (Class = 0x200408)...${NC}"
sudo tee /etc/bluetooth/main.conf > /dev/null << 'EOF'
[General]
Name = HeadUnit OS
Class = 0x200408
DiscoverableTimeout = 0
PairableTimeout = 0
AutoConnect = true
FastConnectable = true
JustWorksRepairing = always
EOF

# Clear stale pairing keys to prevent PIN mismatch errors
sudo systemctl stop bluetooth 2>/dev/null || true
sudo rm -rf /var/lib/bluetooth/* 2>/dev/null || true

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

# 3. Enable BlueZ Compatibility & Experimental SDP Profiles (-C --experimental)
echo -e "${CYAN}[3/3] Configuring bluetoothd compatibility & experimental SDP profiles...${NC}"
sudo mkdir -p /etc/systemd/system/bluetooth.service.d/
sudo tee /etc/systemd/system/bluetooth.service.d/override.conf > /dev/null << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/libexec/bluetooth/bluetoothd -C --experimental
EOF

sudo rfkill unblock bluetooth || true
sudo modprobe -r btusb 2>/dev/null || true
sudo modprobe btusb
sudo systemctl daemon-reload
sudo systemctl restart bluetooth

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} 🎉 Intel Bluetooth Firmware Installation Complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Checking Bluetooth Controller Status:"
bluetoothctl show || echo -e "${YELLOW}Note: Cold reboot may be required if Intel chip crashed previously.${NC}"
