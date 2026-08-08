#!/bin/bash
# ==============================================================================
# HeadUnit OS - Standalone Headless Kiosk Appliance Installation Script
# Configures Raspberry Pi OS Lite to boot directly into HeadUnit OS (No Desktop)
# ==============================================================================

set -e

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

# 5. Fast Boot Firmware Optimizations
echo "⚡ Applying Fast Boot optimizations to /boot/firmware/config.txt..."
if ! grep -q "disable_splash=1" /boot/firmware/config.txt 2>/dev/null; then
  sudo tee -a /boot/firmware/config.txt > /dev/null << 'EOF'

# HeadUnit OS Fast Boot
disable_splash=1
boot_delay=0
dtoverlay=vc4-kms-v3d
EOF
fi

echo ""
echo "=============================================================================="
echo "🎉 HeadUnit OS Standalone Kiosk Appliance Setup Complete!"
echo "Reboot your Raspberry Pi to boot directly into HeadUnit OS with NO DESKTOP:"
echo "  sudo reboot"
echo "=============================================================================="
