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

# 1. Determine platform and Host OS details
IS_PI=false
OS_NAME="Linux"
if [ -f /etc/os-release ]; then
  OS_NAME=$(grep "^PRETTY_NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
fi
ARCH=$(uname -m)

if grep -qiE "raspberry pi|bcm2[0-9]{3}" /proc/cpuinfo 2>/dev/null; then
  IS_PI=true
  echo -e "🖥️  Platform : ${GREEN}Raspberry Pi${NC}"
else
  echo -e "🖥️  Platform : ${YELLOW}Desktop/Server Linux${NC}"
fi
echo -e "🐧 Host OS   : ${CYAN}${OS_NAME} (${ARCH})${NC}"
echo ""

MISSING_DEPS=0
MISSING_PKGS=()

check_cmd() {
  local cmd=$1
  local name=${2:-$1}
  if command -v "$cmd" &> /dev/null; then
    echo -e "  [${GREEN}OK${NC}] $name"
  else
    echo -e "  [${RED}MISSING${NC}] $name"
    MISSING_DEPS=$((MISSING_DEPS + 1))
    if [ "$cmd" = "clang" ]; then
      MISSING_PKGS+=("clang")
    elif [ "$cmd" = "ninja" ]; then
      MISSING_PKGS+=("ninja-build")
    fi
  fi
}

check_pkg() {
  local pkg=$1
  if dpkg -s "$pkg" 2>/dev/null | grep -q "Status: install ok installed"; then
    echo -e "  [${GREEN}OK${NC}] $pkg"
  else
    echo -e "  [${RED}MISSING${NC}] $pkg"
    MISSING_DEPS=$((MISSING_DEPS + 1))
    # Prevent duplicates
    if [[ ! " ${MISSING_PKGS[*]} " =~ " ${pkg} " ]]; then
      MISSING_PKGS+=("$pkg")
    fi
  fi
}

# 2. Check Core Build Tools
echo -e "${CYAN}Checking Core Build Tools...${NC}"
check_cmd "flutter" "Flutter SDK (Optional if using prebuilt release bundle)"
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

# 5. Check Kiosk / DRM Dependencies (Mainly for Pi / Headless Server)
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
# 5. Check Native Android Auto Protocol Engine Dependencies
echo -e "${CYAN}Checking Native Android Auto Protocol Dependencies...${NC}"
check_cmd "nmcli" "NetworkManager (nmcli)"
check_cmd "python3" "Python 3 Runtime"
check_pkg "python3-usb"
echo ""
fi

# 6. Check System Groups
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
  echo "   This machine (${OS_NAME}) is ready for HeadUnit OS."
else
  echo -e "❌ ${RED}FAILED:${NC} Found $MISSING_DEPS missing items."
  echo ""
  
  if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "👉 ${YELLOW}Run this command to install all missing system packages:${NC}"
    echo -e "   ${GREEN}sudo apt update && sudo apt install -y ${MISSING_PKGS[*]}${NC}"
    echo ""
  fi

  if [ ! -f "/usr/local/bin/autoapp" ]; then
    echo -e "👉 ${YELLOW}Run this command to build OpenAuto:${NC}"
    echo -e "   ${GREEN}./scripts/install_openauto.sh${NC}"
    echo ""
  fi
fi
echo -e "${CYAN}====================================================${NC}"
