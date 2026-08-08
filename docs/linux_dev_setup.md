# HeadUnit OS — Linux Developer Setup & Workstation Guide

**Information for Use (Instructions for Use) — Structured in accordance with IEC/IEEE 82079-1:2019 Standard**

---

## Document Identification

| Item | Specification |
| :--- | :--- |
| **Document Title** | HeadUnit OS — Linux Developer Setup Manual |
| **Document Type** | Developer Technical Manual / Information for Use |
| **Document Identifier** | HUOS-DEV-001-REV-B |
| **Revision** | B |
| **Issue Date** | 2026-08-08 |
| **Applies to Product** | HeadUnit OS Software Development Kit |
| **Target OS** | Linux Mint 21/22 / Ubuntu 22.04/24.04 LTS (x86_64) |
| **Target Audience** | Software Developers, Systems Engineers |
| **Language** | English (en-US) |

---

## Safety & Operational Precautions

> [!NOTE]
> **Desktop Simulation vs Target Appliance:**
> Desktop Linux development uses GTK3 windowed execution for rapid UI iteration and hot-reload. Target hardware deployment (Raspberry Pi / Headless Server) executes via `flutter-pi` using direct DRM/KMS framebuffer rendering.

---

## 1. System Update & Development Toolchain

Ensure host package lists are updated and essential build tools are installed:

```bash
# 1. Update system package repositories
sudo apt update && sudo apt upgrade -y

# 2. Install Linux desktop build chain and C++ dependencies
sudo apt install -y \
  build-essential cmake clang libstdc++-12-dev \
  pkg-config libgtk-3-dev liblzma-dev \
  libgl1-mesa-dev libglu1-mesa-dev \
  libusb-1.0-0-dev libasound2-dev pulseaudio \
  libmpv-dev mpv \
  git curl unzip python3-usb
```

> [!TIP]
> **Why `libmpv-dev` is required:**
> The `media_kit` audio/video subsystem links against `libmpv`. If CMake reports `Target "media_kit_video_plugin" links to: PkgConfig::mpv but the target was not found`, install `libmpv-dev`.

---

## 2. Bluetooth Hardware Configuration (Intel Controllers)

HeadUnit OS uses `bluetoothctl` and `rfkill` for device discovery and connection status polling.

### 2.1 Install Bluetooth Stack
```bash
sudo apt install -y linux-firmware bluetooth bluez rfkill
```

### 2.2 Intel Bluetooth Firmware Troubleshooting
On PCs equipped with Intel Wireless/Bluetooth chipsets (e.g., AX200 / AX210 / 9260), check kernel logs if Bluetooth fails to initialize:

```bash
sudo dmesg | grep -i bluetooth
```

If logs display `Reading supported features failed (-16)` or `Direct firmware load for intel/ibt-*.sfi failed`:

**Install Firmware Binaries:**
```bash
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git /tmp/linux-firmware
sudo cp /tmp/linux-firmware/intel/ibt-* /lib/firmware/intel/
```

**Reset Bluetooth Controller:**
```bash
sudo modprobe -r btusb
sudo modprobe btusb
sudo systemctl restart bluetooth
```

---

## 3. Repository Checkout & Execution

Clone the repository, verify permissions, and run the developer build:

```bash
cd ~$
git clone https://github.com/Solox312/headunit-os.git
cd headunit-os

# Grant script execute permissions
chmod +x scripts/*.sh

# Run environment verification
./scripts/verify_environment.sh

# Fetch dependencies and run in debug mode
flutter pub get
flutter run -d linux
```

---

## 4. Build Troubleshooting & Resolution

### 4.1 `mimalloc` Object Missing Error
If compilation fails with `ninja: error: 'mimalloc/out/release/mimalloc.o' missing`:

```bash
flutter clean
rm -rf build/
flutter pub get
flutter build linux --release
```

---

## Document Revision History

| Revision | Date | Description of Change | Approved By |
| :--- | :--- | :--- | :--- |
| A | 2026-08-08 | Initial Linux Mint / Ubuntu Developer Setup Manual | HeadUnit OS Team |
| B | 2026-08-08 | Updated to IEC/IEEE 82079-1 format & Native AA Engine | HeadUnit OS Team |
