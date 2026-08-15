#!/bin/bash
# ==============================================================================
# HeadUnit OS — Master Platform Installer & Provisioning Tool
# Supporting Raspberry Pi (Dev), Custom Carrier Board (PROD), & Generic Linux Box
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$CURRENT_USER")
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH=$(uname -m)

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            HeadUnit OS — Master Platform Installer           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  User:         ${GREEN}${CURRENT_USER}${NC}"
echo -e "  Project Path: ${GREEN}${PROJECT_DIR}${NC}"
echo -e "  Architecture: ${GREEN}${ARCH}${NC}"
echo ""

# ── 1. Target Hardware Selection ─────────────────────────────────────────────
TARGET=""

# Parse flags if provided
while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--target)
      if [[ "$2" == "pi" || "$2" == "prod" || "$2" == "generic" ]]; then
        TARGET="$2"
      else
        echo -e "${RED}Error: Invalid target '$2'. Must be 'pi', 'prod', or 'generic'.${NC}"
        exit 1
      fi
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown argument: $1${NC}"
      exit 1
      ;;
  esac
done

# Prompt interactively if target not specified by flags
if [ -z "$TARGET" ]; then
  echo -e "${CYAN}Select the target hardware platform:${NC}"
  echo "  1) Raspberry Pi (Dev)"
  echo "  2) Custom Carrier Board (PROD)"
  echo "  3) Generic Linux PC / VM / Dev Box"
  echo ""
  read -p "Enter selection [1-3]: " choice
  case $choice in
    1) TARGET="pi" ;;
    2) TARGET="prod" ;;
    3) TARGET="generic" ;;
    *)
      echo -e "${RED}Invalid selection. Aborting.${NC}"
      exit 1
      ;;
  esac
fi

echo ""
if [ "$TARGET" == "pi" ]; then
  echo -e "👉 Selected Target: ${GREEN}Raspberry Pi (Dev)${NC}"
elif [ "$TARGET" == "prod" ]; then
  echo -e "👉 Selected Target: ${GREEN}Custom Carrier Board (PROD)${NC}"
else
  echo -e "👉 Selected Target: ${GREEN}Generic Linux PC / VM / Dev Box${NC}"
fi
echo ""

# ── 2. Safety / Workstation Guard ────────────────────────────────────────────
if [ "$ARCH" = "x86_64" ] && [ "$TARGET" != "generic" ]; then
  echo -e "${YELLOW}⚠️  WARNING: You are running a dedicated kiosk installer on an x86_64 workstation.${NC}"
  echo "   This script sets the system default boot target to multi-user.target (headless console),"
  echo "   which will disable your desktop GUI on next reboot."
  echo ""
  read -p "Are you sure you want to proceed with installing kiosk services here? [y/N]: " confirm
  if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
    echo "Installation aborted by user."
    exit 0
  fi
  echo ""
fi

# ── 3. Install System Dependencies ───────────────────────────────────────────
echo -e "${CYAN}[1/6] Installing system package dependencies...${NC}"
sudo apt update

# Core packages required by both environments
CORE_PACKAGES=(
  git curl wget unzip jq build-essential cmake pkg-config snapd
  libdrm-dev libgbm-dev libgles2-mesa-dev
  libsystemd-dev libinput-dev libudev-dev libxkbcommon-dev
  libasound2-dev pulseaudio libmpv-dev mpv
  bluez bluetooth rfkill network-manager python3-usb
)

sudo apt install -y "${CORE_PACKAGES[@]}"

# Install platform-specific python GPIO bindings
if [ "$TARGET" == "pi" ]; then
  echo -e "${CYAN}Installing gpiozero for Raspberry Pi...${NC}"
  sudo apt install -y python3-gpiozero
elif [ "$TARGET" == "prod" ]; then
  echo -e "${CYAN}Installing libgpiod for Custom Carrier Board...${NC}"
  sudo apt install -y python3-libgpiod
fi

echo -e "${GREEN}✓ System dependencies installed successfully.${NC}"
echo ""

# ── 4. Compile & Install flutter-pi Engine ────────────────────────────────────
echo -e "${CYAN}[2/6] Checking flutter-pi DRM direct rendering engine...${NC}"
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

# ── 5. Build HeadUnit OS Bundle (Optional Dev Compilation) ─────────────────────
echo -e "${CYAN}[3/6] Building HeadUnit OS release bundle...${NC}"
cd "$PROJECT_DIR"
if command -v flutter &> /dev/null; then
  flutter pub get
  flutter precache --linux || true
  flutter build linux --release || true
  chmod +x "$PROJECT_DIR/scripts/generate_build_number.sh" 2>/dev/null || true
  "$PROJECT_DIR/scripts/generate_build_number.sh"
  flutter build bundle --target-platform=linux-x64
  
  mkdir -p "$PROJECT_DIR/build/flutter_assets"
  mkdir -p "$PROJECT_DIR/build/linux/x64/release/bundle"

  ICU_LOCATIONS=$(find "$PROJECT_DIR/build" "$HOME" "/tmp" "/snap" -name "icudtl.dat" 2>/dev/null || true)
  ICU_FILE=$(echo "$ICU_LOCATIONS" | head -n 1)
  
  if [ -n "$ICU_FILE" ]; then
    echo "Found icudtl.dat at $ICU_FILE"
    cp "$ICU_FILE" "$PROJECT_DIR/build/flutter_assets/icudtl.dat" 2>/dev/null || true
    cp "$ICU_FILE" "$PROJECT_DIR/build/linux/x64/release/bundle/icudtl.dat" 2>/dev/null || true
    if [ -d "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets" ]; then
      cp "$ICU_FILE" "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets/icudtl.dat" 2>/dev/null || true
    fi
  fi

  echo -e "${CYAN}Downloading official AOT release libflutter_engine.so from Google Storage...${NC}"
  ENGINE_REV="5a2a6a42cce67f965cf540fcecf616faca624aa1"
  FOUND_REV=$(cat $(which flutter 2>/dev/null | xargs readlink -f 2>/dev/null | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null)/bin/internal/engine.version 2>/dev/null || echo "")
  if [ -n "$FOUND_REV" ]; then
    ENGINE_REV="$FOUND_REV"
  fi
  curl -sSL "https://storage.googleapis.com/flutter_infra_release/flutter/${ENGINE_REV}/linux-x64/linux-x64-embedder.zip" -o /tmp/flutter_embedder.zip || true
  if [ -f /tmp/flutter_embedder.zip ]; then
    unzip -o -q /tmp/flutter_embedder.zip -d /tmp/flutter_embedder
    cp /tmp/flutter_embedder/libflutter_engine.so "$PROJECT_DIR/build/flutter_assets/" 2>/dev/null || true
    cp /tmp/flutter_embedder/libflutter_engine.so "$PROJECT_DIR/build/linux/x64/release/bundle/" 2>/dev/null || true
    if [ -d "$PROJECT_DIR/build/linux/x64/release/bundle/lib" ]; then
      cp /tmp/flutter_embedder/libflutter_engine.so "$PROJECT_DIR/build/linux/x64/release/bundle/lib/" 2>/dev/null || true
    fi
    sudo cp /tmp/flutter_embedder/libflutter_engine.so /usr/lib/libflutter_engine.so 2>/dev/null || true
    sudo cp /tmp/flutter_embedder/libflutter_engine.so /usr/local/lib/libflutter_engine.so 2>/dev/null || true
    sudo ldconfig 2>/dev/null || true
    rm -rf /tmp/flutter_embedder /tmp/flutter_embedder.zip
    echo -e "${GREEN}✓ Release libflutter_engine.so installed to system and bundle libraries.${NC}"
  fi

  # Copy compiled AOT libapp.so to app.so in assets directories (necessary for flutter-pi release mode)
  if [ -f "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" ]; then
    cp "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets/app.so" 2>/dev/null || true
    cp "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" "$PROJECT_DIR/build/linux/x64/release/bundle/app.so" 2>/dev/null || true
    cp "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" "$PROJECT_DIR/build/flutter_assets/app.so" 2>/dev/null || true
  fi

  echo -e "${GREEN}✓ Local bundle compiled.${NC}"
else
  echo -e "${YELLOW}ℹ️  Flutter SDK is not found. Skipping local bundle compilation.${NC}"
  echo "   Ensure a prebuilt assets bundle is copied to '$PROJECT_DIR/build/flutter_assets'"
  echo "   before running the application kiosk service."
fi
echo ""

# ── 6. Deploy Safe Shutdown Daemon ────────────────────────────────────────────
if [ "$TARGET" != "generic" ]; then
  echo -e "${CYAN}[4/6] Installing safe shutdown service...${NC}"
  SHUTDOWN_SCRIPT=""
  if [ "$TARGET" == "pi" ]; then
    SHUTDOWN_SCRIPT="$PROJECT_DIR/scripts/shutdown_listener.py"
  else
    SHUTDOWN_SCRIPT="$PROJECT_DIR/scripts/shutdown_listener_carrier.py"
  fi

  sudo tee /etc/systemd/system/car-shutdown.service > /dev/null << EOF
[Unit]
Description=Automotive Safe Shutdown Service for HeadUnit OS
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $SHUTDOWN_SCRIPT
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable car-shutdown.service
  sudo systemctl restart car-shutdown.service
  echo -e "${GREEN}✓ Safe shutdown daemon installed and started.${NC}"
else
  echo -e "${CYAN}[4/6] Skipping safe shutdown service (Generic Linux target)...${NC}"
fi
echo ""

# ── 7. Install & Start Systemd Kiosk Service ─────────────────────────────────
echo -e "${CYAN}[5/6] Installing /etc/systemd/system/headunit.service...${NC}"

ASSETS_PATH="$PROJECT_DIR/build/flutter_assets"
FLUTTER_PI_FLAGS=""

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
Environment=LD_LIBRARY_PATH=$PROJECT_DIR/build/linux/x64/release/bundle/lib:$PROJECT_DIR/build/linux/x64/release/bundle:$ASSETS_PATH
ExecStartPre=/bin/mkdir -p /tmp/flutter-pi-runtime
ExecStart=/usr/local/bin/flutter-pi $FLUTTER_PI_FLAGS $ASSETS_PATH
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Silence console messages on TTY1 during transition gaps
echo 'kernel.printk = 3 4 1 7' | sudo tee /etc/sysctl.d/99-headunit-console.conf > /dev/null
sudo sysctl --system > /dev/null

sudo systemctl set-default multi-user.target
sudo systemctl daemon-reload
sudo systemctl enable headunit.service
echo -e "${GREEN}✓ Kiosk service headunit.service configured and enabled.${NC}"
echo ""

# ── 8. Apply Boot Optimizations / Warnings ───────────────────────────────────
echo -e "${CYAN}[6/6] Applying target boot configurations...${NC}"

if [ "$TARGET" == "pi" ]; then
  BOOT_CONFIG=""
  if [ -f /boot/firmware/config.txt ]; then
    BOOT_CONFIG=/boot/firmware/config.txt
  elif [ -f /boot/config.txt ]; then
    BOOT_CONFIG=/boot/config.txt
  fi

  if [ -n "$BOOT_CONFIG" ]; then
    echo "⚡ Applying Fast Boot optimizations to ${BOOT_CONFIG}..."
    if ! grep -q "disable_splash=1" "$BOOT_CONFIG" 2>/dev/null; then
      sudo tee -a "$BOOT_CONFIG" > /dev/null << 'EOF'

# HeadUnit OS Fast Boot
disable_splash=1
boot_delay=0
dtoverlay=vc4-kms-v3d
EOF
      echo "✅ Fast Boot config applied to ${BOOT_CONFIG}."
    else
      echo "ℹ️  Fast Boot config already present in ${BOOT_CONFIG}."
    fi
  else
    echo "⚠️  Skipping boot config edits (no config.txt found)."
  fi
elif [ "$TARGET" == "prod" ]; then
  # PROD Board - Warn about OverlayFS requirement
  echo -e "${YELLOW}⚠️  PROD BOARD CONFIGURATION REMINDER:${NC}"
  echo "   Since the custom carrier board runs off USB-C PD power, a hard unplug"
  echo "   will cut power immediately with no battery backup buffer."
  echo "   To protect the SD card from filesystem corruption, you MUST enable"
  echo "   OverlayFS (Read-Only Mode) in your OS settings (e.g. raspi-config"
  echo "   or Radxa Config utility) before deploying to vehicle dashboard."
  echo ""
else
  echo -e "${GREEN}✓ Generic Linux boot config: No adjustments needed.${NC}"
fi

# Add current user to essential hardware and accessory groups (DRM/GPU, touchscreen input, TTY, networking)
sudo usermod -aG plugdev,video,render,input,tty,dialout "$CURRENT_USER" || true

# Configure passwordless sudo for core utilities needed by HeadUnit OS UI settings and daemons
echo "⚡ Configuring passwordless sudo rules for HeadUnit OS services..."
sudo tee /etc/sudoers.d/headunit-os > /dev/null << 'EOF'
# HeadUnit OS passwordless controls for plugdev group
%plugdev ALL=(ALL) NOPASSWD: /usr/bin/nmcli, /usr/sbin/reboot, /usr/sbin/shutdown, /usr/sbin/poweroff, /usr/bin/systemctl
EOF
sudo chmod 0440 /etc/sudoers.d/headunit-os

echo ""
echo -e "${GREEN}==============================================================================${NC}"
echo -e "${GREEN}🎉 HeadUnit OS Provisioning Complete!${NC}"
echo "To boot directly into the kiosk interface, reboot your system:"
echo -e "   ${CYAN}sudo reboot${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo ""
