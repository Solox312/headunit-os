#!/usr/bin/env bash
# ==============================================================================
#  HeadUnit OS — USB Hotplug Detection Installer
#  Wires a udev rule to the running app so plugging a phone in drives the
#  Android Auto UI immediately, instead of waiting for a manual button tap.
#  Supported: Raspberry Pi OS (Bookworm/Bullseye), Ubuntu 22.04, Linux Mint 21+
#  Usage: bash scripts/install_usb_hotplug.sh
# ==============================================================================
set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC}  $*"; exit 1; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        HeadUnit OS — USB Hotplug Detection Installer        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  error "This script is for Linux only."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Step 1/3 — Installing socat (forwards udev events to the running app)..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends socat
success "socat installed."

info "Step 2/3 — Installing USB notifier script..."
sudo install -m 755 "$SCRIPT_DIR/headunit-usb-notify.sh" /usr/local/bin/headunit-usb-notify.sh
success "Installed /usr/local/bin/headunit-usb-notify.sh"

info "Step 3/3 — Installing udev rule..."
sudo install -m 644 "$SCRIPT_DIR/udev/99-headunit-usb-hotplug.rules" /etc/udev/rules.d/99-headunit-usb-hotplug.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
success "udev rule active."

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   Installation Complete!                    ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Plugging in a phone now notifies any running HeadUnit OS    ║${NC}"
echo -e "${GREEN}║  instance over \$XDG_RUNTIME_DIR/headunit-os/usb-hotplug.sock ║${NC}"
echo -e "${GREEN}║  — no app restart required. Requires openauto to be          ║${NC}"
echo -e "${GREEN}║  installed (scripts/install_openauto.sh) to actually stream. ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
