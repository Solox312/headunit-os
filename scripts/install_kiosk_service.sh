#!/bin/bash
# ==============================================================================
# HeadUnit OS — Kiosk Appliance Installation Script
# Target platform: Raspberry Pi OS (Bookworm or Bullseye), 64-bit
#
# NOTICE: This script MUST be run on a Raspberry Pi.
#         Running it on any other Linux distribution (e.g. Ubuntu, Linux Mint)
#         will break that machine's desktop environment and boot target.
#         The script will abort automatically if it detects non-Pi hardware.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Guard: Abort immediately if not running on a Raspberry Pi
# ------------------------------------------------------------------------------
if ! grep -qiE "raspberry pi|bcm2[0-9]{3}" /proc/cpuinfo 2>/dev/null; then
  echo ""
  echo "❌ ERROR: This script must be run on a Raspberry Pi." >&2
  echo "" >&2
  echo "   This machine does not appear to be a Raspberry Pi" >&2
  echo "   (/proc/cpuinfo contains no Raspberry Pi hardware identifier)." >&2
  echo "" >&2
  echo "   Running this script on a desktop Linux system (e.g. Ubuntu," >&2
  echo "   Linux Mint) will change the boot target to multi-user.target," >&2
  echo "   disabling the desktop GUI on next reboot." >&2
  echo "" >&2
  echo "   Transfer the repository to your Raspberry Pi and re-run there." >&2
  echo "" >&2
  exit 1
fi

echo "✅ Raspberry Pi hardware confirmed. Proceeding with installation..."
echo ""

# Resolve the correct boot config path (Bookworm vs Bullseye)
if [ -f /boot/firmware/config.txt ]; then
  BOOT_CONFIG=/boot/firmware/config.txt
elif [ -f /boot/config.txt ]; then
  BOOT_CONFIG=/boot/config.txt
else
  echo "⚠️  WARNING: No boot config.txt found at /boot/firmware/config.txt" >&2
  echo "   or /boot/config.txt. Fast-boot optimizations will be skipped." >&2
  BOOT_CONFIG=""
fi

echo "🚗 Installing HeadUnit OS Kiosk Appliance Service..."

# 1. Install DRM/GBM Dependencies & Engine
sudo apt update
sudo apt install -y \
  libdrm-dev \
  libgbm-dev \
  libgles2-mesa-dev \
  libsystemd-dev \
  libinput-dev \
  libudev-dev \
  libxkbcommon-dev \
  cmake \
  build-essential \
  git \
  network-manager \
  bluez \
  rfkill

# 2. Build/Install flutter-pi direct DRM/KMS engine if missing
if ! command -v flutter-pi &> /dev/null; then
  echo "📦 Building flutter-pi direct DRM/KMS engine..."
  cd /tmp
  rm -rf flutter-pi
  git clone --depth 1 https://github.com/ardera/flutter-pi.git
  cd flutter-pi
  mkdir build && cd build
  cmake ..
  make -j$(nproc)
  sudo make install
  echo "✅ flutter-pi installed successfully."
fi

# 3. Create Systemd Kiosk Service
echo "⚙️ Creating /etc/systemd/system/headunit.service..."
sudo tee /etc/systemd/system/headunit.service > /dev/null << 'EOF'
[Unit]
Description=HeadUnit OS Automotive Touchscreen UI
After=systemd-user-sessions.service network-online.target sound.target
Wants=network-online.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/headunit-os
ExecStart=/usr/local/bin/flutter-pi --release /home/pi/headunit-os/build/elm
Restart=always
RestartSec=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 4. Set Boot Target to Multi-User (Headless Console / Kiosk Mode)
sudo systemctl set-default multi-user.target
sudo systemctl daemon-reload
sudo systemctl enable headunit.service

# 5. Fast Boot Firmware Optimizations (skipped if no config found)
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
    echo "ℹ️  Fast Boot config already present in ${BOOT_CONFIG}. Skipping."
  fi
else
  echo "⚠️  Skipping Fast Boot config (no config.txt found)."
fi

echo ""
echo "=============================================================================="
echo "🎉 HeadUnit OS Standalone Kiosk Appliance Setup Complete!"
echo "Reboot your Raspberry Pi to boot directly into HeadUnit OS with NO DESKTOP:"
echo "  sudo reboot"
echo "=============================================================================="
