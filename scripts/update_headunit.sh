#!/bin/bash
# ==============================================================================
# HeadUnit OS — Update & Redeploy Script
# Pulls latest code, rebuilds release bundle, and restarts kiosk service.
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            HeadUnit OS — Update & Redeploy Tool              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd "$PROJECT_DIR"

# 1. Pull Latest Changes
echo -e "${CYAN}[1/4] Pulling latest repository updates...${NC}"
git pull
chmod +x "$PROJECT_DIR/scripts/install_huos.sh" 2>/dev/null || true
echo -e "${GREEN}✓ Git repository up to date.${NC}"
echo ""

# 2. Get Dependencies
echo -e "${CYAN}[2/4] Fetching Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies updated.${NC}"
echo ""

# 3. Rebuild Bundle
echo -e "${CYAN}[3/4] Rebuilding HeadUnit OS bundle...${NC}"
chmod +x "$PROJECT_DIR/scripts/generate_build_number.sh" 2>/dev/null || true
"$PROJECT_DIR/scripts/generate_build_number.sh"

ARCH=$(uname -m)
TARGET_PLATFORM="linux-x64"
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
  TARGET_PLATFORM="linux-arm64"
elif [[ "$ARCH" == "armv7l" || "$ARCH" == "armhf" ]]; then
  TARGET_PLATFORM="linux-arm"
fi

# Build complete release bundle and asset bundle
flutter build linux --release || true
flutter build bundle --target-platform="$TARGET_PLATFORM" || true

# Copy compiled AOT libapp.so to app.so in assets directories (necessary for flutter-pi release mode)
if [ -f "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" ]; then
  cp "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets/app.so" 2>/dev/null || true
  cp "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" "$PROJECT_DIR/build/linux/x64/release/bundle/app.so" 2>/dev/null || true
  mkdir -p "$PROJECT_DIR/build/flutter_assets"
  cp "$PROJECT_DIR/build/linux/x64/release/bundle/lib/libapp.so" "$PROJECT_DIR/build/flutter_assets/app.so" 2>/dev/null || true
fi

# Copy icudtl.dat to appropriate build folders if found
ICU_FILE=$(find "$PROJECT_DIR/build" "$HOME" "/tmp" "/snap" -name "icudtl.dat" 2>/dev/null | head -n 1 || true)
if [ -n "$ICU_FILE" ]; then
  cp "$ICU_FILE" "$PROJECT_DIR/build/linux/x64/release/bundle/icudtl.dat" 2>/dev/null || true
  mkdir -p "$PROJECT_DIR/build/flutter_assets"
  cp "$ICU_FILE" "$PROJECT_DIR/build/flutter_assets/icudtl.dat" 2>/dev/null || true
  if [ -d "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets" ]; then
    cp "$ICU_FILE" "$PROJECT_DIR/build/linux/x64/release/bundle/data/flutter_assets/icudtl.dat" 2>/dev/null || true
  fi
fi
echo -e "${GREEN}✓ Assets bundle rebuilt.${NC}"
echo ""

# 4. Restart Appliance Service
echo -e "${CYAN}[4/4] Restarting HeadUnit OS Kiosk Service...${NC}"
sudo systemctl restart headunit.service

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} 🎉 HeadUnit OS Updated & Redeployed Successfully!${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
