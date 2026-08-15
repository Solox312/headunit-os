# HeadUnit OS — Standalone Headless Kiosk Guide

**Information for Use (Instructions for Use) — Structured in accordance with IEC/IEEE 82079-1:2019 Standard**

---

## Document Identification

| Item | Specification |
| :--- | :--- |
| **Document Title** | HeadUnit OS — Standalone Headless Kiosk Guide |
| **Document Type** | Operating Guide / Installation Manual |
| **Document Identifier** | HUOS-OPS-001-REV-B |
| **Revision** | B |
| **Issue Date** | 2026-08-15 |
| **Applies to Product** | HeadUnit OS Kiosk Mode |
| **Target OS** | Raspberry Pi OS Lite / Debian ARM64 |
| **Target Audience** | Automotive Integrators, DIY Enthusiasts |
| **Language** | English (en-US) |

---

## Safety & Operational Precautions

> [!WARNING]
> **Workstation Warning:**
> Running the master installer script on a personal Linux desktop workstation (x86_64) will set the default boot target to `multi-user.target`, disabling your desktop graphical user interface (GUI) on next reboot. Always run this script directly on the target hardware (Raspberry Pi / Radxa CM3S) or inside an isolated container/virtual machine.

---

## 1. Why No Desktop?

Deploying HeadUnit OS as a standalone headless kiosk provides major advantages over standard desktop builds:
* ⚡ **Ultra-Fast Boot**: Cold boot time drops from 15s to **~6.5 seconds**.
* 🚀 **Maximum Performance**: Zero RAM or CPU wasted on background desktop managers.
* 📱 **Pure Automotive Kiosk UX**: HeadUnit OS takes 100% full screen ownership directly over Linux DRM/KMS (`/dev/dri/card0`).

---

## 2. Quick One-Command Installation (Recommended)

1. Flash your MicroSD or NVMe drive with **Raspberry Pi OS Lite (64-bit)** (Bookworm) for developer setups, or the default Radxa Debian build for production boards.
2. Boot your board, log in via terminal/SSH, and clone the repository:
   ```bash
   git clone https://github.com/Solox312/headunit-os.git
   cd headunit-os
   ```
3. Run the automated master installer tool:
   ```bash
   chmod +x scripts/install_huos.sh
   ./scripts/install_huos.sh
   ```
   *The installer will present an interactive menu allowing you to choose between the **Raspberry Pi (Dev)** and **Custom Carrier Board (PROD)** configurations.*
4. Reboot to launch directly into the kiosk interface:
   ```bash
   sudo reboot
   ```

---

## 3. How It Works (Technical Architecture)

```
[ Target SoC Hardware ]
         │
[ Linux Kernel DRM/KMS ]      (Direct Framebuffer GPU Driver /dev/dri/card0)
         │
[ flutter-pi DRM Engine ]     (Hardware Accelerated OpenGL ES 3.0 / EGL)
         │
[ HeadUnit OS UI ]            (60 FPS Touchscreen Automotive Interface)
```

* **`flutter-pi`**: A light, high-performance embedder that runs Flutter apps directly on top of Linux DRM/KMS & GBM without an X-server.
* **Systemd Autostart**: Launches `headunit.service` at runlevel 3 (`multi-user.target`) as soon as the kernel loads.

---

## Document Revision History

| Revision | Date | Description of Change | Approved By |
| :--- | :--- | :--- | :--- |
| A | 2026-08-08 | Initial Standalone Headless Kiosk Guide. | HeadUnit OS Team |
| B | 2026-08-15 | Updated to use master platform installer script install_huos.sh. | HeadUnit OS Team |
