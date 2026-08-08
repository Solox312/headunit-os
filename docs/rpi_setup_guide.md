# Raspberry Pi DIY Head Unit Setup & Kiosk Guide

This guide walks you through setting up a **Raspberry Pi 4 or Raspberry Pi 5** with a touchscreen to run the Flutter Automotive Head Unit in kiosk mode.

---

## 1. Prerequisites & Hardware Requirements
* **Raspberry Pi 4 (4GB/8GB)** or **Raspberry Pi 5**.
* **Touchscreen Display**: Official Raspberry Pi 7" Touchscreen (DSI), Waveshare HDMI/DSI Touchscreen (1024x600 or 1280x720), or 10.1" Automotive Display.
* **MicroSD Card**: 32GB+ Class 10 / A2 rated high-speed card.
* **Power Supply**: Official 5V 3A (RPi 4) or 5V 5A (RPi 5) USB-C power supply (or 12V to 5V 5A automotive step-down converter).
* **Carlinkit / AutoKit USB Dongle**: CPC200-CCPA or CPC200-AutoKit for Apple CarPlay & Android Auto.

---

## 2. Installing Raspberry Pi OS
1. Download and open **Raspberry Pi Importer**.
2. Select OS: **Raspberry Pi OS (64-bit)** (Bookworm or Bullseye with Desktop).
3. Open OS Customization settings:
   - Set hostname (e.g. `rpi-headunit`).
   - Enable SSH (`Password authentication`).
   - Set username & password.
   - Configure your home Wi-Fi network for initial setup.
4. Flash the MicroSD card and boot up the Pi.

---

## 3. Installing Flutter Dependencies on Raspberry Pi
Open a terminal on the Pi (or SSH into it) and execute:

```bash
# Update System Packages
sudo apt update && sudo apt upgrade -y

# Install Build Essentials & Flutter Linux Desktop Dependencies
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libgl1-mesa-dev libglu1-mesa-dev libusb-1.0-0-dev libasound2-dev pulseaudio

# Verify Git & Curl
sudo apt install -y git curl unzip redshift
```

---

## 4. Building the Flutter App for Linux (ARM64)
Clone or copy this repository to your Raspberry Pi:

```bash
cd ~
git clone https://github.com/your-username/rpi_headunit.git
cd rpi_headunit

# Get Flutter dependencies
flutter pub get

# Build the release bundle for Linux ARM64
flutter build linux --release
```

The compiled executable will be located at:
`~/rpi_headunit/build/linux/arm64/release/bundle/rpi_headunit`

---

## 5. Setting Up Auto-Boot Kiosk Mode (Systemd Service)

To make the Raspberry Pi automatically boot directly into your Flutter Head Unit UI:

1. Create a `systemd` user service file:
```bash
mkdir -p ~/.config/systemd/user/
nano ~/.config/systemd/user/headunit.service
```

2. Add the following content:
```ini
[Unit]
Description=Flutter Automotive Head Unit Kiosk
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
WorkingDirectory=/home/pi/rpi_headunit/build/linux/arm64/release/bundle
ExecStart=/home/pi/rpi_headunit/build/linux/arm64/release/bundle/rpi_headunit
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
```

3. Enable and start the kiosk service:
```bash
systemctl --user daemon-reload
systemctl --user enable headunit.service
```

---

## 6. Disabling Screen Blanking & Sleep
To prevent the head unit screen from sleeping while driving:

1. Edit X11 autostart config:
```bash
mkdir -p ~/.config/autostart
nano ~/.config/autostart/noblank.desktop
```

2. Paste the following configuration:
```ini
[Desktop Entry]
Type=Application
Name=Disable Screen Saver
Exec=xset s off -dpms s noblank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

---

## 7. Display Resolution Tuning for 10.1" Touchscreens

For 10.1" HDMI Capacitive Touch LCD panels (like Waveshare / AliExpress driver board monitors):

Edit `/boot/firmware/config.txt` (or `/boot/config.txt` on older OS):

```ini
# Force HDMI Output for 10.1" Capacitive Touch Display
hdmi_force_hotplug=1
max_usb_current=1
hdmi_group=2
hdmi_mode=87

# OPTION 1: 10.1" Screen (1280x800 Resolution - Recommended)
hdmi_cvt=1280 800 60 6 0 0 0

# OPTION 2: 10.1" / 7" Screen (1024x600 Resolution)
# hdmi_cvt=1024 600 60 6 0 0 0

# OPTION 3: 10.1" Screen (1280x720 HD Resolution)
# hdmi_cvt=1280 720 60 6 0 0 0
```

### USB Capacitive Touch Driver Note:
Connect the screen's **USB Touch cable** directly to one of the Raspberry Pi's USB ports. Raspberry Pi OS automatically detects capacitive touch panels as standard HID input devices without needing external touch drivers.

Save and reboot your Raspberry Pi!

---

## 8. SD Card Corruption Protection & Safe Ignition Shutdown

> [!WARNING]
> **Preventing Filesystem Corruption:** Abruptly cutting power to a Raspberry Pi while the car ignition is turned off is the **#1 cause of failed car Pi projects**. Because Linux constantly writes logs and state files in the background, cutting power mid-write corrupts the MicroSD card.

Use one of the two solutions below to ensure long-term reliability:

### Method 1: Intelligent Hardware Power Supply HAT (Primary Standard)

Use a dedicated automotive power supply HAT (such as **CarPiHAT**, **StromPi 3**, or **Mausberry Car Switch**).

#### **3-Wire Wiring Connection (Fuse Box)**:
1. **Constant 12V (Battery)**: Wired to an unswitched fuse for continuous power while sleeping.
2. **Switched 12V (ACC / Ignition)**: Wired to an ignition-switched fuse (detects car key status).
3. **Ground (GND)**: Connected to bare chassis metal bolt.

#### **How Graceful Shutdown Works**:
* Turning key **ON** ──► Switched 12V powers up HAT ──► HAT boots Raspberry Pi via Constant 12V line.
* Turning key **OFF** ──► Switched 12V cuts ──► HAT sends GPIO LOW signal on pin (default: GPIO 26) to Pi while keeping 5V power alive.
* Background `gpiozero` listener daemon on Pi waits 3 seconds (to debounce engine cranking / voltage dips) and executes `sudo shutdown -h now`.
* Pi safely halts, and HAT detects halt state and cuts 5V power completely, avoiding battery drain!

#### **Installing the Automotive Shutdown Service**:

1. **Install `gpiozero` Python Library**:
   ```bash
   sudo apt update && sudo apt install -y python3-gpiozero
   ```

2. **Python Listener Script (`scripts/shutdown_listener.py`)**:
   The repo includes an automated Python listener at `scripts/shutdown_listener.py`:
   ```python
   #!/usr/bin/env python3
   import os
   import time
   from gpiozero import Button

   IGNITION_PIN = 26 # Check your HAT manual for the BCM pin number

   def trigger_shutdown():
       print("Ignition loss detected (3s hold). Halting system safely...")
       os.system("sudo shutdown -h now")

   if __name__ == '__main__':
       # hold_time=3 requires car key off for 3s (prevents accidental shutdown while cranking)
       ignition_signal = Button(IGNITION_PIN, pull_up=True, hold_time=3)
       ignition_signal.when_held = trigger_shutdown
       
       try:
           while True:
               time.sleep(1)
       except KeyboardInterrupt:
           pass
   ```

3. **Configure & Enable `systemd` Service**:
   Copy the provided service file to `/etc/systemd/system/`:
   ```bash
   sudo cp /home/pi/rpi_headunit/scripts/car-shutdown.service /etc/systemd/system/car-shutdown.service
   sudo systemctl daemon-reload
   sudo systemctl enable car-shutdown.service
   sudo systemctl start car-shutdown.service
   ```

> [!TIP]
> **Kernel Overlay Alternative (Zero-Code Method):** If using a basic power HAT or step-down board that pulls a GPIO pin low, you can also enable safe kernel-level shutdown without Python by adding this line to `/boot/firmware/config.txt`:
> ```ini
> dtoverlay=gpio-shutdown,gpio_pin=26,active_low=1
> ```

---

### Method 2: Read-Only Filesystem (OverlayFS - Bulletproof Software Method)

If you use a simple 12V-to-5V step-down converter without a smart HAT, lock the SD card into **Read-Only** mode using built-in Linux OverlayFS.

#### **Setup via `raspi-config`**:
1. Run `sudo raspi-config` in terminal.
2. Navigate to **4 Performance Options** ──► **P3 Overlay File System**.
3. Select **YES** to enable the overlay filesystem (makes overlay read-only).
4. Select **YES** to lock the boot partition as read-only.
5. Reboot the Pi (`sudo reboot`).

#### **How OverlayFS Works**:
All OS log writes and temp files are written to a virtual RAM disk instead of physical flash storage. When power cuts abruptly when turning off the car key, RAM clears instantly with **zero risk of physical SD card corruption**.

> [!NOTE]
> **Read-Only Trade-off**: Changes made while OverlayFS is enabled (paired Bluetooth devices, new Wi-Fi networks, settings) will reset on reboot. To make permanent system configuration updates, disable OverlayFS via `sudo raspi-config`, make your edits, and re-enable OverlayFS.
