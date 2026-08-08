# Carlinkit USB Dongle Protocol & Integration Guide

This guide explains how to connect and configure a **Carlinkit / AutoKit USB Dongle** (CPC200-CCPA / CPC200-AutoKit) to enable native **Apple CarPlay** (Wireless & Wired) and **Android Auto** on your Raspberry Pi.

---

## 1. How the Carlinkit USB Dongle Works
The Carlinkit CPC200 USB dongle acts as a hardware bridge between your phone and your Raspberry Pi:
* **Wireless Handshake**: The dongle advertises a Bluetooth AP to negotiate initial Wi-Fi credentials with your iPhone or Android phone.
* **Stream Transcoding**: The dongle receives H.264 video streams and PCM audio from iOS/Android and outputs raw video/audio chunks over USB.
* **Touch Event Pass-through**: The Raspberry Pi sends normalized touch event coordinates `(x, y, action)` back to the USB dongle, which relays them to the phone as native multi-touch screen inputs.

---

## 2. Setting Up USB Permissions (`udev` rules)

On Linux / Raspberry Pi, raw USB access requires appropriate device permissions.

1. Create a custom udev rule for Carlinkit dongles:
```bash
sudo nano /etc/udev/rules.d/99-carlinkit.rules
```

2. Add the following rule (Vendor ID `13fd` / `0b05` / `2e8a`):
```ini
# Carlinkit / AutoKit CPC200 USB Dongle Permissions
SUBSYSTEM=="usb", ATTR{idVendor}=="13fd", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", MODE="0666", GROUP="plugdev"
```

3. Reload udev rules and add your user to the `plugdev` group:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG plugdev $USER
```

---

## 3. Communication Bridge Architecture

```
 ┌────────────────────────┐         WebSocket / IPC         ┌─────────────────────────┐
 │   Flutter Head Unit    │ ◄─────────────────────────────► │ Carlinkit Daemon Service│
 │  (ProjectionScreen UI) │   JSON Events & Video Texture   │   (node-carplay/aasdk)  │
 └────────────────────────┘                                 └────────────┬────────────┘
                                                                         │ USB libusb
                                                                ┌────────▼────────────┐
                                                                │ Carlinkit USB Dongle│
                                                                └─────────────────────┘
```

### Video Rendering & Audio Routing:
1. **Video Stream**: The USB daemon extracts H.264 NAL units from the USB endpoint and streams them via a local WebSocket or Unix domain socket into the Flutter app texture widget.
2. **Audio Routing**: Audio PCM frames are passed to PulseAudio / ALSA on the Raspberry Pi, routing calls, navigation prompts, and music directly to your vehicle's speakers.
3. **Hardware Mic**: Connect a USB microphone or 3.5mm mic to the RPi to send voice commands (Siri / Google Assistant) back to the phone.

---

## 4. Simulator Mode vs. Physical Hardware

In our Flutter app, you can switch seamlessly between:
* **Simulator Mode**: Allows you to test the complete head unit layout, dashboard, navigation, and audio player on Windows, Mac, or Linux without needing a physical dongle plugged in.
* **Active Stream Mode**: Displays the real-time feed received from your connected iPhone or Android phone.
