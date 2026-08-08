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
  git curl wget unzip jq build-essential cmake pkg-config snapd \
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
  flutter precache --linux || true
  flutter build linux --release || true
  flutter build bundle --target-platform=linux-x64
  
  mkdir -p "$PROJECT_DIR/build/flutter_assets"
  mkdir -p "$PROJECT_DIR/build/linux/x64/release/bundle"

  # Broadly locate icudtl.dat in system, build output, or Flutter SDK cache
  ICU_LOCATIONS=$(find "$PROJECT_DIR/build" "$HOME" "/tmp" "/snap" -name "icudtl.dat" 2>/dev/null || true)
  ICU_FILE=$(echo "$ICU_LOCATIONS" | head -n 1)
  
  if [ -n "$ICU_FILE" ]; then
    echo "Found icudtl.dat at $ICU_FILE"
    cp "$ICU_FILE" "$PROJECT_DIR/build/flutter_assets/icudtl.dat" 2>/dev/null || true
    cp "$ICU_FILE" "$PROJECT_DIR/build/linux/x64/release/bundle/icudtl.dat" 2>/dev/null || true
    if [ -d "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets" ]; then
      cp "$ICU_FILE" "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets/icudtl.dat" 2>/dev/null || true
    fi
  else
    echo -e "${YELLOW}⚠️  Could not locate icudtl.dat automatically.${NC}"
  fi

  # Broadly locate libflutter_engine.so or download direct from Google Flutter Infra
  ENGINE_LOCATIONS=$(find "$PROJECT_DIR/build" "$HOME" "/tmp" "/snap" -name "libflutter_engine.so" 2>/dev/null || true)
  ENGINE_FILE=$(echo "$ENGINE_LOCATIONS" | head -n 1)
  
  if [ -z "$ENGINE_FILE" ]; then
    echo -e "${YELLOW}Downloading matching libflutter_engine.so directly from Google Flutter storage...${NC}"
    ENGINE_REV="5a2a6a42cce67f965cf540fcecf616faca624aa1"
    FOUND_REV=$(cat $(which flutter 2>/dev/null | xargs readlink -f 2>/dev/null | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null)/bin/internal/engine.version 2>/dev/null || echo "")
    if [ -n "$FOUND_REV" ]; then
      ENGINE_REV="$FOUND_REV"
    fi
    echo "Engine Revision: $ENGINE_REV"
    curl -sSL "https://storage.googleapis.com/flutter_infra_release/flutter/${ENGINE_REV}/linux-x64/linux-x64-embedder.zip" -o /tmp/flutter_embedder.zip || true
    if [ -f /tmp/flutter_embedder.zip ]; then
      unzip -o /tmp/flutter_embedder.zip libflutter_engine.so -d /tmp/ 2>/dev/null || true
      if [ -f /tmp/libflutter_engine.so ]; then
        ENGINE_FILE="/tmp/libflutter_engine.so"
      fi
    fi
  fi

  if [ -n "$ENGINE_FILE" ] && [ -f "$ENGINE_FILE" ]; then
    echo "Installing libflutter_engine.so from $ENGINE_FILE..."
    sudo cp "$ENGINE_FILE" "/usr/local/lib/libflutter_engine.so"
    sudo cp "$ENGINE_FILE" "/usr/lib/libflutter_engine.so" 2>/dev/null || true
    sudo ldconfig
    echo -e "${GREEN}✓ libflutter_engine.so installed successfully to /usr/local/lib.${NC}"
  else
    echo -e "${RED}❌ Could not locate or download libflutter_engine.so.${NC}"
  fi

  echo -e "${GREEN}✓ Flutter assets bundle, icudtl.dat, & libflutter_engine.so prepared successfully.${NC}"
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

ASSETS_PATH="$PROJECT_DIR/build/flutter_assets"
if [ ! -f "$ASSETS_PATH/icudtl.dat" ] && [ -d "$PROJECT_DIR/build/linux/x64/release/bundle" ]; then
  ASSETS_PATH="$PROJECT_DIR/build/linux/x64/release/bundle"
fi

FLUTTER_PI_FLAGS=""
if [ -f "$ASSETS_PATH/app.so" ] || [ -f "$ASSETS_PATH/lib/libapp.so" ]; then
  FLUTTER_PI_FLAGS="--release"
fi

sudo tee /etc/systemd/system/headunit.service > /dev/null << EOF
[Unit]
Description=HeadUnit OS Automotive Touchscreen UI
After=systemd-user-sessions.service network-online.target sound.target systemd-udevd.service
Wants=network-online.target

[Service]
Type=simple
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$PROJECT_DIR
Environment=XDG_RUNTIME_DIR=/tmp/flutter-pi-runtime
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStartPre=/bin/mkdir -p /tmp/flutter-pi-runtime
ExecStart=/usr/local/bin/flutter-pi $FLUTTER_PI_FLAGS $ASSETS_PATH
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Silence low-level kernel and DRM console warnings on TTY1
sudo dmesg -n 1 2>/dev/null || true

sudo systemctl set-default multi-user.target
sudo systemctl daemon-reload
sudo systemctl enable headunit.service

# Configure TTY1 auto-login so Ubuntu Server boots directly into HeadUnit OS without login prompts
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin $CURRENT_USER %I \$TERM
Type=idle
EOF

sudo systemctl daemon-reload

echo -e "${GREEN}✓ Kiosk service & auto-boot enabled.${NC}"
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} 🎉 HeadUnit OS Ubuntu Kiosk Setup Complete!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Starting HeadUnit OS kiosk service now..."
sudo systemctl restart headunit.service
echo ""
echo -e "To test auto-boot on key turn/startup, simply reboot: ${CYAN}sudo reboot${NC}"
echo -e "To view live logs: ${CYAN}sudo journalctl -u headunit.service -f${NC}"
