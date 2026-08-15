# HeadUnit OS — Ubuntu Server Setup & Installation Guide

**Information for Use (Instructions for Use) — Structured in accordance with IEC/IEEE 82079-1:2019 Standard**

---

## Document Identification

| Item | Specification |
| :--- | :--- |
| **Document Title** | HeadUnit OS — Ubuntu Server Installation & Commissioning Manual |
| **Document Type** | Technical Manual / Information for Use (IFU) |
| **Document Identifier** | HUOS-IFU-002-REV-C |
| **Revision** | C (Master Platform Installer Edition) |
| **Issue Date** | 2026-08-15 |
| **Applies to Product** | HeadUnit OS — Dedicated Automotive Touchscreen Appliance |
| **Target OS** | Ubuntu Server 22.04 LTS / 24.04 LTS (x86_64 or ARM64) |
| **Target Audience** | Automotive Electronics Installers, Developers, System Integrators |
| **Language** | English (en-US) |

---

## Safety & Hazard Warnings

> [!CAUTION]
> **Electrical Safety & Vehicle Voltage:**
> Ensure vehicle power supplies are properly fused (3A–5A inline fuse). Automotive power buses fluctuate between 12V and 14.4V; use a regulated 5V/3A DC-DC buck converter to power the headunit hardware.

> [!WARNING]
> **Driving Safety:**
> Do not attempt configuration or system maintenance while operating a moving vehicle.

---

## 1. System Overview & Rendering Architecture

HeadUnit OS converts a minimal Ubuntu Server installation into a dedicated, headless automotive headunit appliance. 

Because Ubuntu Server operates without an X11 or Wayland desktop display manager, HeadUnit OS renders directly to kernel graphics framebuffers via `flutter-pi` using **Linux DRM/KMS (Direct Rendering Manager / Kernel Mode Setting)**. Boot time is under 5 seconds directly into the full-screen touch interface.

Android Auto functionality is provided by the **Native Android Auto Protocol Engine** built directly into HeadUnit OS—eliminating external legacy C++ binary compilation requirements.

---

## 2. Post-Installation Initial Setup

Update system repositories and install core utility packages:

```bash
# 1. Update system package index
sudo apt update && sudo apt upgrade -y

# 2. Install Git, build tools, and Snap
sudo apt install -y git curl wget build-essential cmake pkg-config snapd
```

### 2.1 Install Flutter SDK

Select one of the installation methods below:

**Method A — Via Snap (Recommended for Ubuntu):**
```bash
sudo snap install flutter --classic
```

**Method B — Direct Manual Archive:**
```bash
cd ~$
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.1-stable.tar.xz
tar -xf flutter_linux_3.27.1-stable.tar.xz
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 3. Clone Repository & Configure Environment

Clone the repository and set executable permissions on installation scripts:

```bash
cd ~$
git clone https://github.com/Solox312/headunit-os.git
cd headunit-os

# Grant script execute permissions
chmod +x scripts/*.sh

# Configure Git autostash to avoid pull conflicts
git config --global pull.rebase true
git config --global rebase.autoStash true
```

---

## 4. Environment Verification

Run the automated verification script to validate required dependencies:

```bash
./scripts/verify_environment.sh
```

Expected Output:
```
🖥️  Platform: Desktop Linux (Ubuntu Server)
Checking Core Build Tools... [OK]
Checking System Libraries... [OK]
Checking Bluetooth Stack...  [OK]
Checking Native Android Auto Protocol Dependencies... [OK]
```

---

## 5. Install Hardware & DRM Rendering Engine

### 5.1 System DRM/KMS & Audio Dependencies
Install graphics rendering, audio, and Bluetooth development libraries:

```bash
sudo apt install -y \
  libdrm-dev libgbm-dev libgles2-mesa-dev \
  libsystemd-dev libinput-dev libudev-dev libxkbcommon-dev \
  libasound2-dev pulseaudio libmpv-dev mpv \
  bluez bluetooth rfkill network-manager python3-usb
```

### 5.2 Build flutter-pi DRM Direct Engine
`flutter-pi` renders the Flutter UI directly to GPU framebuffers:

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

## 6. User Group & Hardware Permissions

Add your user account (e.g., `carl` or `ubuntu`) to hardware access groups (USB, input, rendering, audio):

```bash
sudo usermod -aG plugdev,input,video,render,dialout $USER
```

> [!IMPORTANT]
> Log out and log back in (or restart SSH) for group permissions to take effect.

---

## 7. Auto-Boot Kiosk Service Configuration

### Option A — Automated One-Command Setup (Recommended)
Run the automated master installer tool to install system dependencies, download/compile the kiosk engine, register hardware-specific shutdown listener daemons, set up system permissions, and enable kiosk mode:

```bash
# Launch interactive installation:
./scripts/install_huos.sh

# Or run silently for a specific target hardware:
# For Raspberry Pi Dev: ./scripts/install_huos.sh --target pi
# For Custom Carrier Board PROD: ./scripts/install_huos.sh --target prod
```

---

### Option B — Manual Systemd Service Setup
Create a `systemd` service manually to launch HeadUnit OS automatically on system startup:

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
ExecStart=/usr/local/bin/flutter-pi --release $HOME/headunit-os/build/flutter_assets
Restart=always
RestartSec=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable and activate kiosk service
sudo systemctl daemon-reload
sudo systemctl enable headunit.service
```

---

## 8. Final Verification & Commissioning

Run the verification tool to confirm installation status:

```bash
./scripts/verify_environment.sh
```

Reboot system to initiate direct kiosk boot:

```bash
sudo reboot
```

---

## 9. Service Operations & Diagnostics

System control commands via SSH:

| Action | Command |
| :--- | :--- |
| **View Live Appliance Logs** | `sudo journalctl -u headunit.service -f` |
| **Restart Application** | `sudo systemctl restart headunit.service` |
| **Stop Application** | `sudo systemctl stop headunit.service` |
| **Check Bluetooth Status** | `bluetoothctl show` |
| **Check Wi-Fi Hotspot Status** | `nmcli connection show HeadUnit-OS` |

---

## Document Revision History

| Revision | Date | Description of Change | Approved By |
| :--- | :--- | :--- | :--- |
| A | 2026-08-08 | Initial Ubuntu Server DRM/KMS Installation Guide | HeadUnit OS Team |
| B | 2026-08-08 | Transitioned to Native Android Auto Protocol Engine (Option C) | HeadUnit OS Team |
| C | 2026-08-15 | Swapped old scripts for master installer tool scripts/install_huos.sh | HeadUnit OS Team |
