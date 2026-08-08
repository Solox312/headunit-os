# HeadUnit OS — Linux Developer Setup Guide

This guide is for developers setting up a Linux desktop environment (specifically **Linux Mint** or **Ubuntu**) to build, test, and debug HeadUnit OS locally before deploying to the Raspberry Pi.

---

## 1. Prerequisites & System Updates

Start by ensuring your system is up to date:

```bash
sudo apt update && sudo apt upgrade -y
```

## 2. Install Build Dependencies

HeadUnit OS uses Flutter Linux desktop, native media playback (mpv), and requires a full C++ build chain to compile embedded dependencies like `mimalloc`.

Run the following to install all required libraries:

```bash
sudo apt install -y \
  build-essential cmake clang libstdc++-12-dev \
  pkg-config libgtk-3-dev liblzma-dev \
  libgl1-mesa-dev libglu1-mesa-dev \
  libusb-1.0-0-dev libasound2-dev pulseaudio \
  libmpv-dev mpv \
  git curl unzip
```

> [!TIP]
> **Why `libmpv-dev`?**
> The `media_kit` video player relies on `libmpv`. If you get a CMake error stating `Target "media_kit_video_plugin" links to: PkgConfig::mpv but the target was not found`, it means `libmpv-dev` is missing from your system.

## 3. Bluetooth Stack Setup (Intel Hardware)

HeadUnit OS uses Linux `bluetoothctl` and `rfkill` to manage device connections for the native wireless projection engine. 

Install the Bluetooth stack:
```bash
sudo apt install -y linux-firmware bluetooth bluez rfkill
```

### 3.1 Intel Bluetooth Firmware Troubleshooting
If you are using a PC or laptop with an Intel wireless card (e.g., AX200/AX210) and Bluetooth is failing to initialize, check the kernel logs:

```bash
sudo dmesg | grep -i bluetooth
```

If you see an error like `Reading supported features failed (-16)` or `Direct firmware load for intel/ibt-*.sfi failed`, the hardware is in a bad state or missing firmware.

**To fix missing firmware:**
```bash
git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git /tmp/linux-firmware
sudo cp /tmp/linux-firmware/intel/ibt-* /lib/firmware/intel/
```

**To reset a crashed Bluetooth adapter:**
```bash
# Reload the kernel module
sudo modprobe -r btusb
sudo modprobe btusb
sudo systemctl restart bluetooth
```
> [!NOTE]
> If reloading the module doesn't work, perform a **cold reboot** (shut down completely, remove power for 10 seconds, and turn it back on). Warm reboots from Windows into Linux often leave Intel Bluetooth chips in a crashed state.

## 4. Building the Project

Clone the repository and build the Linux desktop release:

```bash
git clone https://github.com/Solox312/headunit-os.git
cd headunit-os

flutter pub get
flutter build linux --release
```

### 4.1 Resolving Build Failures (`mimalloc` object missing)
If your build fails with an error like:
`ninja: error: 'mimalloc/out/release/mimalloc.o' missing and no known rule to make it`

This means CMake generated a corrupt build cache. Fix it by cleaning the project:

```bash
flutter clean
rm -rf build/
flutter pub get
flutter build linux --release
```

## 5. Running the App

Once built, you can run the executable directly. Note that the output binary name is defined in your Linux CMake config (usually `rpi_headunit` or `headunit_os`).

```bash
# Run in debug mode for hot-reload
flutter run -d linux

# Or run the compiled release bundle directly
./build/linux/x64/release/bundle/headunit_os
```

> [!WARNING]
> **Do not run `install_kiosk_service.sh` on your desktop machine.**
> The kiosk script is strictly for the Raspberry Pi. Running it on Linux Mint or Ubuntu will change your system's default boot target to `multi-user.target` and disable your graphical desktop environment. If you ran it by accident, restore your desktop with: `sudo systemctl set-default graphical.target`

## 6. OpenAuto Setup (Optional)

If you are developing or testing the projection engine features locally, you may need to install the OpenAuto dependencies. Ensure the script is executable before running:

```bash
chmod +x scripts/install_openauto.sh
./scripts/install_openauto.sh
```
