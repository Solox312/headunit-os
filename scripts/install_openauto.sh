#!/usr/bin/env bash
# ==============================================================================
#  HeadUnit OS — OpenAuto + AASDK Wireless Android Auto Installer
#  Supported: Raspberry Pi OS (Bookworm/Bullseye), Ubuntu 22.04, Linux Mint 21+
#  Usage: bash scripts/install_openauto.sh
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
echo -e "${CYAN}║     HeadUnit OS — OpenAuto Wireless Android Auto Installer  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 0. Checks ─────────────────────────────────────────────────────────────────

if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  error "This script is for Linux only. On Windows, use the Windows simulation mode."
fi

if [[ $EUID -eq 0 ]]; then
  warn "Running as root. Consider running as a regular user (sudo is called internally)."
fi

BUILD_DIR="/tmp/headunit_openauto_build"
INSTALL_PREFIX="/usr/local"
CONFIG_DIR="$HOME/.config/openauto"
HOTSPOT_SSID="HeadUnit-OS"
HOTSPOT_PASS="headunit2024"
HOTSPOT_CONN_NAME="HeadUnit-OS"
BT_ALIAS="HeadUnit-OS"
AA_VIDEO_PORT="5556"
AA_WIRELESS_PORT="5288"

mkdir -p "$BUILD_DIR"

# ── 1. System dependencies ────────────────────────────────────────────────────
info "Step 1/6 — Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  build-essential cmake git pkg-config \
  libusb-1.0-0-dev libssl-dev \
  libprotobuf-dev protobuf-compiler \
  libpulse-dev pulseaudio \
  libboost-all-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav \
  libbluetooth-dev bluez rfkill \
  network-manager \
  librtaudio-dev \
  qtbase5-dev qtmultimedia5-dev \
  qtconnectivity5-dev \
  libavcodec-dev libavformat-dev libavutil-dev libswscale-dev
success "Build dependencies installed."

# ── 2. Build aasdk ────────────────────────────────────────────────────────────
info "Step 2/6 — Building aasdk (Android Auto SDK)..."
cd "$BUILD_DIR"
# Always re-clone fresh rather than reusing a directory left behind by a
# previous run: an existing checkout from before a patch was added here
# would silently skip re-cloning *and* re-patching, and "make" would just
# resume building the stale, unpatched tree (this is exactly what caused
# the LIBUSB_HOTPLUG_NO_FLAGS build failure below to persist across runs).
rm -rf aasdk
git clone --depth=1 https://github.com/f1xpl/aasdk.git

info "Patching aasdk for Boost 1.70+, OpenSSL 3.0, and API compatibility..."
find aasdk -type f -name "*.cpp" -exec sed -i 's/get_io_service()/context()/g' {} \;
sed -i '1s/^/#include <boost\/core\/noncopyable.hpp>\n/' aasdk/include/f1x/aasdk/IO/Promise.hpp
sed -i 's/FIPS_mode_set(0);//g' aasdk/src/Transport/SSLWrapper.cpp

# Make onAVChannelStopIndication a default virtual function instead of pure virtual (= 0)
find aasdk -type f -name "*.hpp" -exec sed -i 's/onAVChannelStopIndication(\([^)]*\)) = 0;/onAVChannelStopIndication(\1) {}/g' {} \;

# libusb 1.0.27 made libusb_hotplug_flag a real enum; aasdk passes the bare
# LIBUSB_HOTPLUG_NO_FLAGS macro (an int) into that parameter with no cast,
# which newer GCC rejects outright. Cast it explicitly rather than relying
# on -fpermissive alone.
sed -i 's/LIBUSB_HOTPLUG_NO_FLAGS/static_cast<libusb_hotplug_flag>(LIBUSB_HOTPLUG_NO_FLAGS)/g' \
  aasdk/src/USB/USBHub.cpp
cd aasdk
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fpermissive" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX"
make -j"$(nproc)"

# aasdk's CMakeLists.txt defines no install() rules at all — "make install"
# fails with "No rule to make target 'install'" every time. Stage the known
# build output locations manually instead: shared libs land in ../lib/,
# hand-written headers in ../include/f1x/, and the protoc-generated
# aasdk_proto headers land in aasdk_proto/ inside this build directory.
if ! sudo make install 2>/dev/null; then
  warn "aasdk has no 'make install' target — staging build output into $INSTALL_PREFIX manually."
  sudo install -d "$INSTALL_PREFIX/include" "$INSTALL_PREFIX/include/aasdk_proto" "$INSTALL_PREFIX/lib"
  sudo cp -r ../include/f1x "$INSTALL_PREFIX/include/"
  sudo cp aasdk_proto/*.pb.h "$INSTALL_PREFIX/include/aasdk_proto/"
  sudo cp -P ../lib/libaasdk.so ../lib/libaasdk_proto.so "$INSTALL_PREFIX/lib/"
fi
sudo ldconfig
success "aasdk installed to $INSTALL_PREFIX."

# ── 3. Build openauto ─────────────────────────────────────────────────────────
info "Step 3/6 — Building openauto..."
cd "$BUILD_DIR"
if [[ ! -d "openauto" ]]; then
  git clone --depth=1 https://github.com/f1xpl/openauto.git
  
  info "Patching openauto for Boost 1.70+ compatibility..."
  find openauto -type f -name "*.cpp" -exec sed -i 's/get_io_service()/context()/g' {} +
fi
cd openauto
mkdir -p build && cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fpermissive" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
  -DAASDK_INCLUDE_DIRS="$INSTALL_PREFIX/include" \
  -DAASDK_LIBRARIES="$INSTALL_PREFIX/lib/libaasdk.so"
make -j"$(nproc)"

# Same author, same era as aasdk — assume it may also lack install() rules
# rather than guess its layout. If "make install" doesn't exist, locate the
# built autoapp binary directly instead of hardcoding a path that might be
# wrong for this checkout.
if ! sudo make install 2>/dev/null; then
  warn "openauto has no 'make install' target — locating the built autoapp binary manually."
  AUTOAPP_BIN=$(find . -maxdepth 4 -type f -name autoapp -perm -u+x | head -1)
  if [[ -z "$AUTOAPP_BIN" ]]; then
    error "Could not locate a built 'autoapp' binary under $(pwd). Check the build output above for errors."
  fi
  sudo install -d "$INSTALL_PREFIX/bin"
  sudo install -m 755 "$AUTOAPP_BIN" "$INSTALL_PREFIX/bin/autoapp"
fi
success "openauto installed — binary at $INSTALL_PREFIX/bin/autoapp"

# ── 4. OpenAuto configuration ─────────────────────────────────────────────────
info "Step 4/6 — Writing OpenAuto configuration..."
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/openauto_properties.cfg" << EOF
[Main]
WirelessEnabled=true
WirelessPort=${AA_WIRELESS_PORT}
VideoWidth=1280
VideoHeight=720
VideoFPS=60
VideoCodec=H264
VideoOutputPort=${AA_VIDEO_PORT}
AudioPort=5557
AudioOutputBackend=pulseaudio
BluetoothEnabled=true
BluetoothServiceName=${BT_ALIAS}
TouchStdin=true
EOF
success "Config written to $CONFIG_DIR/openauto_properties.cfg"

# ── 5. Wi-Fi hotspot profile (nmcli) ─────────────────────────────────────────
info "Step 5/6 — Creating Wi-Fi hotspot profile (nmcli)..."
nmcli connection delete "$HOTSPOT_CONN_NAME" 2>/dev/null || true
nmcli connection add \
  type wifi \
  con-name "$HOTSPOT_CONN_NAME" \
  ssid "$HOTSPOT_SSID" \
  mode ap \
  ipv4.method shared \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "$HOTSPOT_PASS" \
  autoconnect no
success "Hotspot profile created: SSID='$HOTSPOT_SSID' password='$HOTSPOT_PASS'"

# ── 6. Bluetooth setup ────────────────────────────────────────────────────────
info "Step 6/6 — Configuring Bluetooth..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
bluetoothctl system-alias "$BT_ALIAS" 2>/dev/null || warn "Could not set BT alias (device may not be present)"
success "Bluetooth configured as: $BT_ALIAS"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   Installation Complete!                    ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  OpenAuto binary : $INSTALL_PREFIX/bin/autoapp               ${NC}"
echo -e "${GREEN}║  Config file     : $CONFIG_DIR/                              ${NC}"
echo -e "${GREEN}║  Wi-Fi SSID      : $HOTSPOT_SSID                             ${NC}"
echo -e "${GREEN}║  Wi-Fi Password  : $HOTSPOT_PASS                         ${NC}"
echo -e "${GREEN}║  BT Device Name  : $BT_ALIAS                                ${NC}"
echo -e "${GREEN}║  Video UDP port  : $AA_VIDEO_PORT                            ${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Launch HeadUnit OS and tap 'Android Auto' to connect.      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
