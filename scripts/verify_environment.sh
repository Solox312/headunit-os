#!/bin/bash
# ==============================================================================
# HeadUnit OS — Environment Verification Script
# Checks if the current machine (Linux Mint or Raspberry Pi) has all the 
# required dependencies, groups, and tools installed to build and run the app.
# ==============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   HeadUnit OS - Environment Verification Tool      ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo ""

# 1. Determine platform
IS_PI=false
if grep -qiE "raspberry pi|bcm2[0-9]{3}" /proc/cpuinfo 2>/dev/null; then
  IS_PI=true
  echo -e "🖥️  Platform: ${GREEN}Raspberry Pi${NC}"
else
  echo -e "🖥️  Platform: ${YELLOW}Desktop Linux (Mint/Ubuntu)${NC}"
fi
echo ""

MISSING_DEPS=0

check_cmd() {
  local cmd=$1
  local name=${2:-$1}
  if command -v "$cmd" &> /dev/null; then
    echo -e "  [${GREEN}OK${NC}] $name"
  else
    echo -e "  [${RED}MISSING${NC}] $name"
    MISSING_DEPS=$((MISSING_DEPS + 1))
  fi
}

check_pkg() {
  local pkg=$1
  if dpkg -s "$pkg" 2>/dev/null | grep -q "Status: install ok installed"; then
    echo -e "  [${GREEN}OK${NC}] $pkg"
  else
    echo -e "  [${RED}MISSING${NC}] $pkg"
    MISSING_DEPS=$((MISSING_DEPS + 1))
  fi
}

# 2. Check Core Build Tools
echo -e "${CYAN}Checking Core Build Tools...${NC}"
check_cmd "flutter" "Flutter SDK"
check_cmd "clang"
check_cmd "cmake"
check_cmd "ninja"
check_cmd "pkg-config"
echo ""

# 3. Check C++ & Desktop Libraries (needed for media_kit & mimalloc)
echo -e "${CYAN}Checking System Libraries...${NC}"
check_pkg "build-essential"
check_pkg "libgtk-3-dev"
check_pkg "liblzma-dev"
check_pkg "libgl1-mesa-dev"
check_pkg "libglu1-mesa-dev"
check_pkg "libusb-1.0-0-dev"
check_pkg "libasound2-dev"
check_pkg "pulseaudio"
check_pkg "libmpv-dev"
check_pkg "mpv"
echo ""

# 4. Check Bluetooth Stack
echo -e "${CYAN}Checking Bluetooth Stack...${NC}"
check_cmd "bluetoothctl" "BlueZ (bluetoothctl)"
check_cmd "rfkill"
if [ "$IS_PI" = false ]; then
  check_pkg "linux-firmware"
fi
echo ""

# 5. Check Kiosk / DRM Dependencies (Mainly for Pi, but good to have)
if [ "$IS_PI" = true ]; then
  echo -e "${CYAN}Checking Raspberry Pi Kiosk Dependencies...${NC}"
  check_cmd "flutter-pi" "flutter-pi DRM engine"
  check_pkg "libdrm-dev"
  check_pkg "libgbm-dev"
  check_pkg "libgles2-mesa-dev"
  check_pkg "libsystemd-dev"
  check_pkg "libinput-dev"
  check_pkg "libudev-dev"
  check_pkg "libxkbcommon-dev"
  
  echo ""
  echo -e "${CYAN}Checking Wireless Projection (Android Auto) Dependencies...${NC}"
  check_cmd "hostapd"
  check_cmd "dnsmasq"
  echo ""
fi

# 6. Check Groups (for Carlinkit USB dongle)
echo -e "${CYAN}Checking System Groups...${NC}"
if groups $USER | grep -q "\bplugdev\b"; then
  echo -e "  [${GREEN}OK${NC}] User '$USER' is in 'plugdev' group (required for USB dongles)"
else
  echo -e "  [${YELLOW}WARNING${NC}] User '$USER' is NOT in 'plugdev' group."
  echo "            Run: sudo usermod -aG plugdev $USER (then logout & login)"
fi
echo ""

# Summary
echo -e "${CYAN}====================================================${NC}"
if [ $MISSING_DEPS -eq 0 ]; then
  echo -e "✅ ${GREEN}SUCCESS:${NC} All required dependencies are installed!"
  echo "   This machine is ready for HeadUnit OS."
else
  echo -e "❌ ${RED}FAILED:${NC} Missing $MISSING_DEPS dependencies."
  echo "   Please review the missing items above and install them using apt."
fi
echo -e "${CYAN}====================================================${NC}"
