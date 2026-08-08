# HeadUnit OS — Ubuntu Server Setup Guide

**Information for use (instructions) — structured in accordance with IEC/IEEE 82079-1:2019**

---

## Document Identification

| Field | Value |
| :--- | :--- |
| **Document title** | HeadUnit OS — Ubuntu Server Setup Guide |
| **Document type** | Information for use (installation, commissioning, configuration) |
| **Document identifier** | HUOS-IFU-002 |
| **Revision** | A |
| **Issue date** | 2026-08-08 |
| **Applies to product** | HeadUnit OS — Dedicated Automotive Touchscreen Appliance |
| **Target OS** | Ubuntu Server 22.04 LTS / 24.04 LTS (x86_64 or ARM64) |
| **Language** | English (en) |

---

## 1. Overview

This guide provides step-by-step instructions for converting a fresh installation of **Ubuntu Server (Minimal)** into a dedicated, headless HeadUnit OS automotive appliance. 

Because Ubuntu Server does not include a desktop environment (No Xorg/Wayland), HeadUnit OS runs via `flutter-pi` using Linux **DRM/KMS direct rendering**, booting directly into the full-screen touch interface in under 5 seconds.

---

## 2. Post-Installation Initial Setup

Fresh Ubuntu Server installations do not ship with `git`. Update your package lists and install `git` first:

```bash
# 1. Update system package repositories
sudo apt update && sudo apt upgrade -y

# 2. Install Git and basic build tools
sudo apt install -y git curl wget build-essential cmake pkg-config snapd
```

### 2.1 Install Flutter SDK

Choose one of the two methods below to install Flutter:

**Method A — Via Snap (Easiest & Fastest on Ubuntu/Mint):**
```bash
sudo snap install flutter --classic
```

**Method B — Direct Manual Installation:**
```bash
cd ~$
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz
tar -xf flutter_linux_3.27.1-stable.tar.xz
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 3. Clone Repository & Grant Permissions

Now clone the HeadUnit OS repository, grant script permissions, and configure Git:

```bash
cd ~$
git clone https://github.com/Solox312/headunit-os.git
cd headunit-os

# Grant execute permissions to all install & utility scripts
chmod +x scripts/*.sh

# Configure Git autostash to avoid pull conflicts in the future
git config --global pull.rebase true
git config --global rebase.autoStash true
```

---

## 4. System Verification

Run the built-in environment verification tool to check your system requirements:

```bash
./scripts/verify_environment.sh
```

---

## 5. Install Dependencies & Build Engine

### 5.1 System DRM/KMS & Audio Dependencies
Install graphics, audio, and Bluetooth dependencies required for direct DRM rendering:

```bash
sudo apt install -y \
  libdrm-dev libgbm-dev libgles2-mesa-dev \
  libsystemd-dev libinput-dev libudev-dev libxkbcommon-dev \
  libasound2-dev pulseaudio libmpv-dev mpv \
  bluez bluetooth rfkill network-manager
```

### 5.2 Build flutter-pi Direct DRM Engine
`flutter-pi` is the lightweight engine that renders Flutter apps directly to the GPU framebuffer without X11 or Wayland:

```bash
cd /tmp
rm -rf flutter-pi
git clone --depth 1 https://github.com/ardera/flutter-pi.git
cd flutter-pi
mkdir build && cd build
cmake ..
make -j$(nproc)
sudo make install
cd ~/headunit-os
```

---

## 6. Install OpenAuto (Wireless Android Auto)

To support Wireless Android Auto projection:

```bash
./scripts/install_openauto.sh
```

> [!NOTE]
> The installer automatically patches legacy Boost and OpenSSL 3.0 compatibility issues, compiles `aasdk` and `openauto`, and sets up the `HeadUnit-OS` Wi-Fi hotspot profile in NetworkManager.

---

## 7. User Group Permissions

Add your user (e.g. `carl` or `ubuntu`) to the required hardware access groups (USB dongles, serial, input, rendering):

```bash
sudo usermod -aG plugdev,input,video,render,dialout $USER
```

> [!IMPORTANT]
> Log out and log back in (or restart SSH) for group permissions to take effect.

---

## 8. Setup Auto-Boot Kiosk Service

Create a `systemd` service to launch HeadUnit OS automatically on boot:

```bash
sudo tee /etc/systemd/system/headunit.service > /dev/null << EOF
[Unit]
Description=HeadUnit OS Automotive Touchscreen UI
After=systemd-user-sessions.service network-online.target sound.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME/headunit-os
ExecStart=/usr/local/bin/flutter-pi --release $HOME/headunit-os/build/elm
Restart=always
RestartSec=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable headunit.service
```

---

## 9. Final Verification & Launch

Re-run the verification script to confirm 100% completion:

```bash
./scripts/verify_environment.sh
```

Reboot your machine to boot directly into HeadUnit OS:

```bash
sudo reboot
```

---

## 10. Service Management Commands

To manage the running appliance service via SSH:

* **View live logs:** `sudo journalctl -u headunit.service -f`
* **Restart app:** `sudo systemctl restart headunit.service`
* **Stop app:** `sudo systemctl stop headunit.service`
