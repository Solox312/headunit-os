# HeadUnit OS — System Architecture & Scalability Guide

**Information for Use (Instructions for Use) — Structured in accordance with IEC/IEEE 82079-1:2019 Standard**

---

## Document Identification

| Item | Specification |
| :--- | :--- |
| **Document Title** | HeadUnit OS — System Architecture & Scalability Guide |
| **Document Type** | Architectural Specification |
| **Document Identifier** | HUOS-ARCH-001-REV-B |
| **Revision** | B |
| **Issue Date** | 2026-08-15 |
| **Applies to Product** | HeadUnit OS Software Architecture |
| **Target Audience** | Software Architects, System Integrators, Developers |
| **Language** | English (en-US) |

---

## Safety & Operational Precautions

> [!NOTE]
> **Modularity Strategy:**
> HeadUnit OS isolates UI presentation code from OS-level driver interfaces using generic Services. Simulator fallbacks are hardcoded for debugging on developer hosts (Windows, macOS) without crashes.

---

## 1. Modular Hardware Abstraction Layer (HAL)

HeadUnit OS enforces strict separation between hardware driver I/O and the Flutter presentation layer:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER AUTOMOTIVE UI                           │
│     (Dashboard • Media • Projection Stream • Bluetooth • Settings)      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │  Reactive State (Provider)
┌───────────────────────────────────▼────────────────────────────────────┐
│                       STATE MANAGERS (PROVIDERS)                       │
│ (VehicleProvider, MediaProvider, WifiProvider, BluetoothProvider, etc)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │  Abstracted Async API
┌───────────────────────────────────▼────────────────────────────────────┐
│                    HARDWARE SERVICES & LINUX DRIVERS                   │
│   (WifiService, BluetoothService, FmTransmitterService, DisplayService)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │  Direct OS Kernel / CLI / I2C
┌───────────────────────────────────▼────────────────────────────────────┐
│                  LINUX SUBSYSTEMS & HARDWARE BUSES                     │
│  (NetworkManager, BlueZ 5.x, I2C /dev/i2c-1, DRM/KMS, SocketCAN can0)  │
└────────────────────────────────────────────────────────────────────────┘
```

### Why This Scalability Architecture Matters:
* **Zero UI Rewrite for New Hardware**: Swapping an FM transmitter IC (e.g. from Si4713 to KT0803K), or changing Wi-Fi chips requires adding a driver class in `lib/services/` without altering UI code.
* **Cross-System Portability**: Runs natively on Raspberry Pi 4/5, Rockchip RK3588, NXP i.MX8, x86_64 automotive PCs, Linux Mint/Ubuntu test beds, and Windows/macOS simulators.

---

## 2. Display Resolution & Screen Form Factor Scalability

* **Dynamic Vector Design System**: Uses Google Fonts (`Space Grotesk`, `Inter`, `JetBrains Mono`) and SVG vector graphics (`headunit_os_splash.svg`) for pixel-perfect scaling across:
  * 7" Touchscreen (1024x600)
  * 10.1" Touchscreen (1280x800)
  * 12.3" Ultrawide Automotive Dash Displays (1920x720)
  * 4K High-DPI Automotive Touchscreens
* **Touch-First Ergonomics**: All buttons, cards, list tiles, and virtual keyboard keys enforce a minimum **44px–56px touch target size** designed for finger navigation while driving.

---

## 3. State Management & Feature Expansion Scalability

State is managed via Flutter's `MultiProvider` architecture ([lib/app.dart](file:///C:/Users/cnieves.wmg/Desktop/Projects/headunit-os/lib/app.dart)). Adding new vehicle subsystems is completely modular:
* **OBD-II / CAN-Bus Telemetry**: Add `CanBusProvider` and bind to Linux `socketcan` (`can0`) for live engine RPM, speed, temperature, and steering wheel control buttons.
* **DSP / Audio Equalizer**: Add `AudioDspProvider` to command ALSA / PulseAudio 10-band equalizer sinks.
* **TPMS Tire Pressure / Reverse Camera**: Add `CameraStreamProvider` binding to V4L2 USB / CSI camera nodes (`/dev/video0`).

---

## 4. Kiosk Fleet & Production Deployment Scalability

* **Automated Master Platform Installer** ([scripts/install_huos.sh](file:///C:/Users/cnieves.wmg/Desktop/Projects/headunit-os/scripts/install_huos.sh)): Installs and provisions target platforms (Raspberry Pi Dev or Custom Carrier Board PROD) in less than two minutes.
* **Yocto / Buildroot / Docker Ready**: HeadUnit OS can be packaged into custom immutable Yocto Linux images or Docker containers for mass OEM car fleet deployment.
* **Atomic Config Storage** ([lib/services/settings_storage_service.dart](file:///C:/Users/cnieves.wmg/Desktop/Projects/headunit-os/lib/services/settings_storage_service.dart)): JSON configuration file storage (`settings.json`) supports debounced atomic writes (`.tmp` file swapping) to prevent corruption during unexpected vehicle ignition power-offs.

---

## Document Revision History

| Revision | Date | Description of Change | Approved By |
| :--- | :--- | :--- | :--- |
| A | 2026-08-08 | Initial System Architecture & Scalability Guide. | HeadUnit OS Team |
| B | 2026-08-15 | Updated reference from install_kiosk_service.sh to install_huos.sh. | HeadUnit OS Team |
