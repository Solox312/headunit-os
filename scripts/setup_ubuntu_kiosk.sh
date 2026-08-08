#!/bin/bash
# ==============================================================================
# HeadUnit OS — Ubuntu Server Headless Kiosk Setup & Installer Script
# Target platform: Ubuntu Server 22.04 LTS / 24.04 LTS (x86_64 / ARM64)
# ==============================================================================

set -euo pipefail

CYAN='\031[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$CURRENT_USER")
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    HeadUnit OS — Ubuntu Server DRM/KMS Kiosk Installer       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  User:         ${GREEN}${CURRENT_USER}${NC}"
echo -e "  Project Path: ${GREEN}${PROJECT_DIR}${NC}"
echo ""

# ── 1. Install System Dependencies ───────────────────────────────────────────
echo -e "${CYAN}[1/5] Installing DRM/KMS, Audio, & Network dependencies...${NC}"
sudo apt update
sudo apt install -y \
  git curl wget build-essential cmake pkg-config snapd \
  libdrm-dev libgbm-dev libgles2-mesa-dev \
  libsystemd-dev libinput-dev libudev-dev libxkbcommon-dev \
  libasound2-dev pulseaudio libmpv-dev mpv \
  bluez bluetooth rfkill network-manager python3-usb

echo -e "${GREEN}✓ System dependencies installed.${NC}"
echo ""

# ── 2. Build flutter-pi DRM Direct Engine ─────────────────────────────────────
echo -e "${CYAN}[2/5] Checking flutter-pi DRM direct rendering engine...${NC}"
if ! command -v flutter-pi &> /dev/null; then
  echo "Building flutter-pi engine from source..."
  BUILD_TMP="/tmp/flutter-pi-build"
  rm -rf "$BUILD_TMP"
  git clone --depth 1 https://github.com/ardera/flutter-pi.git "$BUILD_TMP"
  cd "$BUILD_TMP"
  mkdir build && cd build
  cmake ..
  make -j"$(nproc)"
  sudo make install
  cd "$PROJECT_DIR"
  rm -rf "$BUILD_TMP"
  echo -e "${GREEN}✓ flutter-pi installed to /usr/local/bin/flutter-pi.${NC}"
else
  echo -e "${GREEN}✓ flutter-pi is already installed.${NC}"
fi
echo ""

# ── 3. Build HeadUnit OS Bundle ───────────────────────────────────────────────
echo -e "${CYAN}[3/5] Building HeadUnit OS release bundle...${NC}"
cd "$PROJECT_DIR"
if command -v flutter &> /dev/null; then
  flutter pub get
  flutter build linux --release || true
  flutter build bundle --target-platform=linux-x64
  
  # Copy icudtl.dat from Flutter engine cache or release bundle into flutter_assets
  ICU_FILE=$(find "$PROJECT_DIR/build" -name "icudtl.dat" 2>/dev/null | head -n 1)
  if [ -n "$ICU_FILE" ]; then
    cp "$ICU_FILE" "$PROJECT_DIR/build/flutter_assets/" 2>/dev/null || true
  else
    FLUTTER_BIN=$(which flutter)
    FLUTTER_DIR=$(dirname $(dirname "$FLUTTER_BIN"))
    ICU_ENGINE=$(find "$FLUTTER_DIR" -name "icudtl.dat" 2>/dev/null | head -n 1)
    if [ -n "$ICU_ENGINE" ]; then
      cp "$ICU_ENGINE" "$PROJECT_DIR/build/flutter_assets/" 2>/dev/null || true
    fi
  fi
  echo -e "${GREEN}✓ Flutter assets bundle & icudtl.dat prepared successfully.${NC}"
else
  echo -e "${YELLOW}⚠️  Flutter SDK not found in PATH. Skipping build step (assuming pre-built bundle).${NC}"
fi
echo ""

# ── 4. User Group Permissions ────────────────────────────────────────────────
echo -e "${CYAN}[4/5] Configuring user permissions...${NC}"
sudo usermod -aG plugdev,input,video,render,dialout "$CURRENT_USER"
echo -e "${GREEN}✓ User '$CURRENT_USER' added to hardware access groups.${NC}"
echo ""

# ── 5. Install & Start Systemd Kiosk Service ─────────────────────────────────
echo -e "${CYAN}[5/5] Installing /etc/systemd/system/headunit.service...${NC}"

ASSETS_PATH="$PROJECT_DIR/build/linux/x64/release/bundle"
if [ ! -d "$ASSETS_PATH" ]; then
  ASSETS_PATH="$PROJECT_DIR/build/flutter_assets"
fi

sudo tee /etc/systemd/system/headunit.service > /dev/null << EOF
[Unit]
Description=HeadUnit OS Automotive Touchscreen UI
After=systemd-user-sessions.service network-online.target sound.target
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/flutter-pi --release $ASSETS_PATH
Restart=always
RestartSec=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable headunit.service

echo -e "${GREEN}✓ Kiosk service enabled.${NC}"
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} 🎉 HeadUnit OS Ubuntu Kiosk Setup Complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Starting HeadUnit OS kiosk service now..."
sudo systemctl restart headunit.service
echo ""
echo -e "To view live logs: ${CYAN}sudo journalctl -u headunit.service -f${NC}"
