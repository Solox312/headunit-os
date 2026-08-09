#!/usr/bin/env bash
# ==============================================================================
#  HeadUnit OS — Wired Android Auto (Display Handover) Installer
#
#  Installs the systemd plumbing that lets the Flutter kiosk UI hand the
#  screen to openauto's autoapp for a wired Android Auto session, and take
#  it back when the session ends.
#
#  Why a handover: the kiosk runs flutter-pi directly on DRM/KMS (no window
#  system), and autoapp needs the same display. Only one process can be DRM
#  master, so projection works Crankshaft-style: starting openauto.service
#  stops headunit.service (systemd Conflicts=), and when autoapp exits the
#  unit's ExecStopPost brings headunit.service back.
#
#  Prerequisite: scripts/install_openauto.sh has been run (autoapp exists).
#  Usage: bash scripts/install_wired_aa.sh
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

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  error "This script is for Linux only."
fi

AUTOAPP_BIN="/usr/local/bin/autoapp"
if [[ ! -x "$AUTOAPP_BIN" ]]; then
  error "autoapp not found at $AUTOAPP_BIN — run scripts/install_openauto.sh first."
fi

CURRENT_USER="${SUDO_USER:-$USER}"

info "Step 1/3 — Installing openauto.service (display handover unit)..."
sudo tee /etc/systemd/system/openauto.service > /dev/null << EOF
[Unit]
Description=OpenAuto Wired Android Auto Projection (display handover)
# Starting this unit stops the Flutter kiosk UI — only one process can own
# the DRM display. ExecStopPost brings the kiosk back when autoapp exits.
Conflicts=headunit.service
After=headunit.service

[Service]
Type=simple
# Qt renders directly on KMS/GBM without a window system, same as flutter-pi.
Environment=QT_QPA_PLATFORM=eglfs
ExecStart=$AUTOAPP_BIN
Restart=no
ExecStopPost=/usr/bin/systemctl start headunit.service

[Install]
# Intentionally not enabled at boot — started on demand by the app (USB
# hotplug) or manually via: sudo systemctl start openauto.service
EOF
sudo systemctl daemon-reload
success "openauto.service installed."

info "Step 2/3 — Granting the app permission to trigger the handover..."
sudo tee /etc/sudoers.d/headunit-projection > /dev/null << EOF
$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl start openauto.service, /usr/bin/systemctl stop openauto.service, /usr/bin/systemctl start headunit.service
EOF
sudo chmod 440 /etc/sudoers.d/headunit-projection
success "Sudoers rule installed for user '$CURRENT_USER'."

info "Step 3/3 — Sanity checks..."
systemctl cat openauto.service > /dev/null || error "Unit not readable after install."
sudo -n systemctl start headunit.service --dry-run 2> /dev/null \
  || warn "Passwordless systemctl check inconclusive (dry-run unsupported on this systemd) — continuing."
success "Wired AA handover installed."

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Test manually:   sudo systemctl start openauto.service      ${NC}"
echo -e "${GREEN}  (kiosk UI stops, autoapp takes the screen; plug phone in)   ${NC}"
echo -e "${GREEN}  End session:     sudo systemctl stop openauto.service       ${NC}"
echo -e "${GREEN}  (kiosk UI restarts automatically)                           ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
