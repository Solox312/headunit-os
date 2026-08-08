# Raspberry Pi 4 Boot Performance & Optimization Guide ⚡

This document details expected boot times for **HeadUnit OS** on a **Raspberry Pi 4 Model B** (Quad-Core ARM64 @ 1.8 GHz) and provides step-by-step instructions to optimize cold boot time down to **~6–8 seconds** (or **< 1.2s** using an ignition HAT sleep/wake circuit).

---

## 1. Boot Time Benchmarks (Raspberry Pi 4)

| Configuration / Setup | Cold Boot Time (Ignition ON -> UI Ready) | Notes & Details |
| :--- | :--- | :--- |
| **Standard Raspberry Pi OS (Desktop + X11)** | **12.5 - 15.0 seconds** | Default Raspberry Pi OS Bookworm 64-bit with full desktop environment. |
| **Optimized HeadUnit OS (Minimal systemd + DRM/KMS)** | **6.5 - 8.5 seconds** | Disabled desktop manager; Flutter runs via direct Linux DRM/KMS (`flutter-pi` / EGL). |
| **3-Wire Ignition HAT (Deep Sleep / Acc Resume)** | **< 1.2 seconds** | RPi enters low-power suspend mode when key is turned OFF; resumes instantly on key turn ON. |

---

## 2. Boot Stage Breakdown (Cold Boot)

```
[0.0s] Key Turned ON (12V Switched Ignition)
   ├── RPi 4 EEPROM Bootloader           : 1.8s
   ├── Linux Kernel 6.6 Loading (ARM64)  : 2.2s
   ├── Systemd & NetworkManager Init     : 2.1s
   └── HeadUnit OS Flutter Engine Launch : 1.4s
[7.5s] DASHBOARD FULLY INTERACTIVE & CONNECTED
```

---

## 3. Fast Boot Optimization Instructions

### Step 1: Analyze Current Boot Time
Run `systemd-analyze` to measure exact boot duration on your Raspberry Pi:

```bash
systemd-analyze
systemd-analyze blame
```

### Step 2: Optimize `/boot/firmware/config.txt`
Add the following flags to disable bootloader delays and rainbow splash screens:

```ini
# Fast Boot Adjustments
disable_splash=1
boot_delay=0
dtparam=audio=on
dtoverlay=vc4-kms-v3d
```

### Step 3: Disable Unnecessary Background Services
Disable unused Linux services to save ~3–4 seconds during boot:

```bash
sudo systemctl disable cups.service
sudo systemctl disable ModemManager.service
sudo systemctl disable avahi-daemon.service
sudo systemctl disable bluetooth-mesh.service
```

### Step 4: Direct Flutter DRM/KMS Autostart
To bypass X11/Wayland desktop overhead completely, configure HeadUnit OS to autostart directly via DRM/KMS on boot:

Create `/etc/systemd/system/headunit.service`:
```ini
[Unit]
Description=HeadUnit OS Automotive Touchscreen UI
After=network.target sound.target

[Service]
Type=simple
User=pi
ExecStart=/usr/bin/flutter-pi /home/pi/headunit-os/build/elm
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable autostart:
```bash
sudo systemctl enable headunit.service
```

---

## 4. Hardware Instant-On (3-Wire Ignition HAT)

For true factory OEM behavior (instant-on display when you turn your car key), pair HeadUnit OS with a **3-Wire Ignition HAT**:

- **Ignition Switch (ACC)** triggers GPIO pin interrupt (`GPIO 17`) to initiate low-power suspend (`sudo systemctl suspend` or RTC sleep mode).
- Turning the car key **ON** sends a 12V pulse to wake the Raspberry Pi instantly (**< 1.2 seconds** display wake time).
