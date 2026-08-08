# Standalone Headless Kiosk Appliance Setup (No Desktop) 🚗⚡

This guide details how to turn your **Raspberry Pi 4 / 5** into a dedicated **HeadUnit OS Automotive Kiosk Appliance** that boots directly into HeadUnit OS without installing or running any Linux Desktop Environment (no X11, no Wayland, no taskbars, no desktop overhead).

---

## 1. Why No Desktop?

- ⚡ **Ultra-Fast Boot**: Cold boot time drops from 15s to **~6.5 seconds**.
- 🚀 **Maximum Performance**: Zero RAM or CPU wasted on background desktop managers.
- 📱 **Pure Automotive Kiosk UX**: HeadUnit OS takes 100% full screen ownership directly over Linux DRM/KMS (`/dev/dri/card0`).

---

## 2. Quick 1-Click Installation (Recommended)

1. Install **Raspberry Pi OS Lite (64-bit)** (Bookworm) onto your MicroSD/NVMe drive using Raspberry Pi Imager.
2. Boot your Raspberry Pi and clone the repository:

```bash
git clone https://github.com/Solox312/headunit-os.git
cd headunit-os
```

3. Run the automated headless kiosk installation script:

```bash
chmod +x scripts/install_kiosk_service.sh
./scripts/install_kiosk_service.sh
```

4. Reboot:
```bash
sudo reboot
```

Your Raspberry Pi will now boot **directly into HeadUnit OS** with zero desktop!

---

## 3. How It Works (Technical Architecture)

```
[ Raspberry Pi Hardware ]
         │
[ Linux Kernel 6.6 DRM/KMS ]  (Direct Framebuffer GPU Driver /dev/dri/card0)
         │
[ flutter-pi DRM Engine ]     (Hardware Accelerated OpenGL ES 3.0 / EGL)
         │
[ HeadUnit OS UI ]            (60 FPS Touchscreen Automotive Interface)
```

- **`flutter-pi`**: A light, high-performance embedder that runs Flutter apps directly on top of Linux DRM/KMS & GBM without an X-server.
- **Systemd Autostart**: Launches `headunit.service` at runlevel 3 (`multi-user.target`) as soon as the kernel loads.
