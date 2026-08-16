#!/bin/bash
# ==============================================================================
# HeadUnit OS — Wireless Android Auto Interactive Diagnostic & Testing Tool
# Tests Bluetooth SDP Profile, RFCOMM Handoff, 5 GHz Hotspot, and TCP 50001
# ==============================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     HeadUnit OS — Wireless Android Auto Diagnostic Tool      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Dependency Checks ───────────────────────────────────────────────────────
echo -e "${BOLD}[Step 1/5] Verifying System Dependencies...${NC}"

check_pkg() {
  if ! dpkg -s "$1" 2>/dev/null | grep -q "Status: install ok installed"; then
    echo -e "  ${YELLOW}Installing missing package: $1...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y "$1"
  else
    echo -e "  [${GREEN}OK${NC}] $1"
  fi
}

check_pkg "python3-dbus"
check_pkg "python3-gi"
check_pkg "bluez"
check_pkg "network-manager"

# ── 2. Bluetooth Adapter & Class Verification ─────────────────────────────────
echo ""
echo -e "${BOLD}[Step 2/5] Checking Bluetooth Controller & Device Class...${NC}"

sudo rfkill unblock bluetooth 2>/dev/null || true
sudo systemctl start bluetooth

BT_CONTROLLER=$(bluetoothctl list | head -n 1 | awk '{print $2}')
if [ -z "$BT_CONTROLLER" ]; then
  echo -e "  [${RED}FAIL${NC}] No Bluetooth controller found! Connect a Bluetooth adapter or check rfkill."
  exit 1
fi

echo -e "  [${GREEN}OK${NC}] Bluetooth Controller: ${BT_CONTROLLER}"

# Ensure Device Class is Automotive Stereo (0x200408)
if grep -q "Class = 0x200408" /etc/bluetooth/main.conf 2>/dev/null; then
  echo -e "  [${GREEN}OK${NC}] Bluetooth Class is set to Automotive Car Audio (0x200408)"
else
  echo -e "  ${YELLOW}Configuring Automotive Bluetooth Class (0x200408)...${NC}"
  sudo sed -i 's/^#*Class = .*/Class = 0x200408/' /etc/bluetooth/main.conf 2>/dev/null || true
  if ! grep -q "Class = 0x200408" /etc/bluetooth/main.conf 2>/dev/null; then
    echo -e "[General]\nClass = 0x200408" | sudo tee -a /etc/bluetooth/main.conf >/dev/null
  fi
  sudo systemctl restart bluetooth
  sleep 1
fi

# Set BT Alias and Discoverability
bluetoothctl system-alias "HeadUnit-OS" >/dev/null 2>&1 || true
bluetoothctl power on >/dev/null 2>&1 || true
bluetoothctl discoverable on >/dev/null 2>&1 || true
bluetoothctl pairable on >/dev/null 2>&1 || true
echo -e "  [${GREEN}OK${NC}] Bluetooth discoverable as: ${CYAN}HeadUnit-OS${NC}"

# ── 3. Wi-Fi Hotspot Verification ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}[Step 3/5] Bringing up 5 GHz Wi-Fi Hotspot (HeadUnit-OS)...${NC}"

HOTSPOT_NAME="HeadUnit-OS"
HOTSPOT_SSID="HeadUnit-OS"
HOTSPOT_PASS="headunit2024"

if ! nmcli connection show "$HOTSPOT_NAME" >/dev/null 2>&1; then
  echo -e "  Creating Wi-Fi AP profile '$HOTSPOT_NAME'..."
  sudo nmcli connection add \
    type wifi \
    con-name "$HOTSPOT_NAME" \
    ssid "$HOTSPOT_SSID" \
    mode ap \
    802-11-wireless.band a \
    802-11-wireless.channel 36 \
    ipv4.method shared \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$HOTSPOT_PASS" \
    autoconnect no
fi

echo -e "  Starting hotspot..."
sudo nmcli connection up "$HOTSPOT_NAME" || {
  echo -e "  ${YELLOW}Falling back to auto-band AP...${NC}"
  sudo nmcli connection modify "$HOTSPOT_NAME" 802-11-wireless.band "" 802-11-wireless.channel ""
  sudo nmcli connection up "$HOTSPOT_NAME"
}

# Detect live IP
HOTSPOT_IFACE=$(ls -1 /sys/class/net | grep -E '^wl' | head -n 1 || echo "")
HOTSPOT_IP=""
if [ -n "$HOTSPOT_IFACE" ]; then
  HOTSPOT_IP=$(ip -4 -o addr show "$HOTSPOT_IFACE" | awk '{print $4}' | cut -d/ -f1 | head -n 1)
fi

echo -e "  [${GREEN}OK${NC}] Wi-Fi Hotspot Active: SSID='${HOTSPOT_SSID}', Pass='${HOTSPOT_PASS}', IP='${HOTSPOT_IP:-10.42.0.1}'"

# ── 4. Android Auto TCP Listener Check ────────────────────────────────────────
echo ""
echo -e "${BOLD}[Step 4/5] Checking Android Auto TCP Port 50001...${NC}"
if ss -tuln | grep -q ":50001 "; then
  echo -e "  [${GREEN}OK${NC}] TCP port 50001 is already listening."
else
  echo -e "  [${CYAN}INFO${NC}] Port 50001 is ready for Flutter / OpenAuto engine."
fi

# ── 5. Live Handoff Daemon Test ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}[Step 5/5] Launching Live Bluetooth RFCOMM Handoff Daemon...${NC}"
echo -e "${MAGENTA}👉 INSTRUCTIONS:${NC}"
echo -e "   1. On your Android phone, turn on Bluetooth and Wi-Fi."
echo -e "   2. In Android Settings -> Bluetooth, tap ${CYAN}'HeadUnit-OS'${NC} to pair."
echo -e "   3. Confirm any pairing prompts on the phone."
echo -e "   4. Watch the live packet exchange below!"
echo ""
echo -e "${CYAN}--------------------------- LIVE TRACE ---------------------------${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/aa_wireless_handoff.py"

if [ ! -f "$PYTHON_SCRIPT" ]; then
  echo -e "[${RED}ERROR${NC}] Could not find $PYTHON_SCRIPT"
  exit 1
fi

python3 "$PYTHON_SCRIPT" --ssid "$HOTSPOT_SSID" --psk "$HOTSPOT_PASS" --port 50001
