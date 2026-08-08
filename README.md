# HeadUnit OS 🚗📱

An open-source, automotive-grade touchscreen **HeadUnit OS** built for **Raspberry Pi 4 & 5** using **Flutter**, featuring support for **Wireless Android Auto**, **Apple CarPlay**, and multi-target audio routing.

---

## 🌟 Key Features

* **🏎️ Automotive Dark Glassmorphism UI**: High-contrast, night-mode interface with large tap targets built for 10.1" and 7" automotive touchscreens.
* **📱 Dual Projection Engine Architecture**:
  * **100% Native Software Engine ($0)**: Native Raspberry Pi Bluetooth RFCOMM + 5GHz Wi-Fi Access Point protocol stack for wireless Android Auto without dongles.
  * **Carlinkit Hardware Dongle Support**: Hardware bridge support for dual Wireless CarPlay & Wireless Android Auto.
  * **Auto-Detect Mode**: Automatically uses hardware USB dongles when plugged in, otherwise falling back to native software wireless.
* **📻 Multi-Target Audio Routing**: Instant UI switching between **AUX Cable / 3.5mm DAC**, **Car Bluetooth Stereo (A2DP)**, **FM Transmitter (88.3 MHz)**, and **HDMI Speakers**.
* **⚡ Intelligent Ignition Power Management**: Auto-boots on car key turn via 3-wire Intelligent Power HAT (Constant 12V + Switched ACC) and executes graceful `sudo shutdown -h now` via GPIO upon key removal to protect SD card integrity.
* **📶 Wi-Fi & Network Management**: Integrated Linux NetworkManager (`nmcli`) scanner and touchscreen password modal to connect to home/mobile Wi-Fi access points on Raspberry Pi and Linux desktop.
* **⚡ Bluetooth Device Manager**: Linux BlueZ (`bluetoothctl`) manager for scanning, pairing, A2DP stereo streaming, and hands-free phone connections.
* **🖥️ Responsive Display Scaling**: Adaptive scaling for **10.1" 1280x800**, **10.1" 1024x600**, **10.1" 1280x720**, and **7"** displays.

---

## 📚 Complete Guides & Documentation

| Document | Description |
| :--- | :--- |
| **[⭐ Complete Setup Guide](docs/setup_guide.md)** | **Start here.** All-in-one instructions per IEC/IEEE 82079-1 — safety, parts, assembly, 12V wiring, OS install, kiosk, projection, troubleshooting, maintenance, disposal, and technical data. |
| **[Brand Identity & Design Guide](docs/brand_identity_guide.md)** | Complete visual identity, brand essence, color tokens, Space Grotesk typography, and UI specs. |
| **[Hardware Shopping List](docs/hardware_shopping_list.md)** | Complete parts breakdown, prices, cables, and 12V power accessories. |
| **[Hardware Assembly Guide](docs/hardware_assembly_guide.md)** | Step-by-step physical build, bench testing, 12V wiring, and dash mounting. |
| **[Raspberry Pi Setup Guide](docs/rpi_setup_guide.md)** | Raspberry Pi OS 64-bit setup, Flutter ARM64 build, display resolution, and systemd kiosk autostart. |
| **[Wi-Fi Setup Guide](docs/wifi_setup_guide.md)** | Raspberry Pi and Linux NetworkManager (`nmcli`) Wi-Fi scanning, connection, and Polkit setup. |
| **[Bluetooth Setup Guide](docs/bluetooth_setup_guide.md)** | Linux BlueZ (`bluetoothctl`) pairing, A2DP audio sink, and discoverable mode configuration. |
| **[Native Android Auto Protocol Guide](docs/native_android_auto_protocol.md)** | Architecture breakdown of AOA 2.0, Bluetooth RFCOMM, 5GHz Wi-Fi Direct, and Protobuf channels. |
| **[Carlinkit Dongle Guide](docs/carlinkit_dongle_guide.md)** | Setting up USB `udev` permissions, `libusb` drivers, and video/audio stream bridging. |

---

## 🚀 Development & Local Setup

### 1. Run on Desktop (Windows / Mac / Linux)
To test HeadUnit OS locally on your computer:

```bash
# Clone the repository
git clone https://github.com/your-username/headunit_os.git
cd headunit_os

# Get Flutter dependencies
flutter pub get

# Run on desktop
flutter run -d windows
# or
flutter run -d linux
```

### 2. Build for Raspberry Pi (Linux ARM64)
On your Raspberry Pi 4/5 running Raspberry Pi OS (64-bit):

```bash
# Install Linux desktop build dependencies
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libgl1-mesa-dev libglu1-mesa-dev libusb-1.0-0-dev libasound2-dev pulseaudio

# Build release bundle
flutter build linux --release
```

The compiled Linux executable will be located at:
`~/headunit_os/build/linux/arm64/release/bundle/headunit_os`

---

## 📂 Project Structure

```
rpi_headunit/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── app.dart                       # MultiProvider & MaterialApp setup
│   ├── theme/
│   │   ├── automotive_theme.dart      # Dark glassmorphism theme & typography
│   │   └── automotive_colors.dart     # Neon accents & carbon palette
│   ├── models/
│   │   ├── media_item.dart            # Audio track metadata
│   │   ├── vehicle_status.dart        # Vehicle telemetry model
│   │   └── projection_state.dart      # CarPlay / AA connection state & engine types
│   ├── providers/
│   │   ├── media_provider.dart        # Audio playback state controller
│   │   ├── vehicle_provider.dart      # Vehicle telemetry simulator
│   │   └── projection_provider.dart   # Projection session & engine controller
│   ├── services/
│   │   ├── projection_bridge.dart     # Carlinkit dongle USB bridge service
│   │   └── android_auto_engine.dart   # Native wireless AOA 2.0 + Bluetooth/Wi-Fi engine
│   ├── screens/
│   │   ├── main_navigation_screen.dart# Master layout with left dock bar
│   │   ├── dashboard_screen.dart      # Home driver screen (Clock, Weather, Quick Launchers, Stream, Media)
│   │   ├── projection_screen.dart     # CarPlay & Android Auto stream viewport
│   │   ├── media_screen.dart          # Audio player & visualizer screen
│   │   ├── vehicle_screen.dart        # Gauges & climate screen
│   │   └── settings_screen.dart       # Receiver Engine & Audio Target settings
│   └── widgets/
│       ├── nav_dock.dart              # Left dock bar with voice assistant button
│       ├── glass_card.dart            # Glassmorphism container widget
│       ├── gauge_widget.dart          # Radial circular speed & RPM gauge painter
│       └── projection_simulator_canvas.dart # Interactive projection stream viewport
├── docs/                              # Hardware, assembly, and protocol guides
└── pubspec.yaml                       # Flutter package dependencies
```
