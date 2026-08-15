#!/bin/bash
# ==============================================================================
# HeadUnit OS — Fast PC-to-Pi Deployment Tool (Bash)
# ==============================================================================

set -e

PI_HOST="${1:-10.42.0.109}"
PI_USER="${2:-webcap}"
PI_PORT="${3:-22}"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "================================================================="
echo "  HeadUnit OS — Fast PC-to-Pi Deployment Tool"
echo "  Target: ${PI_USER}@${PI_HOST}:${PI_PORT}"
echo "================================================================="

# 1. Update Build Number
echo "[1/4] Calculating build number..."
chmod +x "$PROJECT_DIR/scripts/generate_build_number.sh" 2>/dev/null || true
"$PROJECT_DIR/scripts/generate_build_number.sh"

# 2. Build Flutter Bundle on Host
echo ""
echo "[2/4] Building Flutter asset bundle..."
cd "$PROJECT_DIR"
flutter build bundle

# 3. Transfer Bundle and Matching ARM64 Engine to Raspberry Pi
echo ""
echo "[3/4] Transferring bundle to Raspberry Pi (${PI_HOST})..."
ssh -p "$PI_PORT" "${PI_USER}@${PI_HOST}" "mkdir -p ~/headunit-os/build/flutter_assets"

ARM64_ENGINE="$PROJECT_DIR/arm64_engine/libflutter_engine.so"
if [ -f "$ARM64_ENGINE" ]; then
  echo "Copying native matching ARM64 libflutter_engine.so..."
  scp -P "$PI_PORT" "$ARM64_ENGINE" "${PI_USER}@${PI_HOST}:/tmp/libflutter_engine.so"
  ssh -p "$PI_PORT" "${PI_USER}@${PI_HOST}" "sudo cp /tmp/libflutter_engine.so /usr/lib/libflutter_engine.so; sudo cp /tmp/libflutter_engine.so /usr/local/lib/libflutter_engine.so; sudo cp /tmp/libflutter_engine.so ~/headunit-os/build/flutter_assets/; sudo ldconfig; rm -f /tmp/libflutter_engine.so"
fi

echo "Copying assets folder..."
scp -P "$PI_PORT" -r "$PROJECT_DIR/build/flutter_assets/"* "${PI_USER}@${PI_HOST}:~/headunit-os/build/flutter_assets/"

# 4. Restart HeadUnit OS Kiosk Service
echo ""
echo "[4/4] Restarting HeadUnit OS Kiosk Service on Pi..."
ssh -p "$PI_PORT" "${PI_USER}@${PI_HOST}" "sudo systemctl restart headunit.service"

echo ""
echo "================================================================="
echo "🎉 Successfully Deployed to Raspberry Pi!"
echo "================================================================="
