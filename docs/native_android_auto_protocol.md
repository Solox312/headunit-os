# Native Wireless Android Auto Protocol Receiver Architecture (No Dongle Required)

This guide documents how to build a **100% native WIRELESS Android Auto receiver software stack** directly on Linux / Raspberry Pi using the Pi's built-in Bluetooth and 5GHz Wi-Fi — completely eliminating hardware dongles.

---

## 🏗️ Architectural Overview

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                      FLUTTER HEAD UNIT DISPLAY LAYER                        │
 │  ┌───────────────────────────────────────────────────────────────────────┐  │
 │  │ Flutter Texture Widget (Video Frame) & Gesture Listener (Touch Input) │  │
 │  └───────────────────────────────────▲───────────────────────────────────┘  │
 └──────────────────────────────────────┼──────────────────────────────────────┘
                                        │ FFI / TCP Sockets (192.168.43.1:50001)
 ┌──────────────────────────────────────┴──────────────────────────────────────┐
 │                  NATIVE WIRELESS ANDROID AUTO RECEIVER DAEMON               │
 │                                                                             │
 │  ┌───────────────────────────┐           ┌──────────────────────────────┐  │
 │  │ 1. Bluetooth RFCOMM       │           │ 2. 5GHz Wi-Fi Direct / AP    │  │
 │  │    UUID: 0000fdf0-...     │           │    `hostapd` + `dnsmasq`     │  │
 │  └─────────────┬─────────────┘           └──────────────┬───────────────┘  │
 │                │                                        │                  │
 │  ┌─────────────▼────────────────────────────────────────▼───────────────┐  │
 │  │ 3. Protocol Buffer (Protobuf) Channel Multiplexer (Port 50001)       │  │
 │  │    ├─ Channel 0: System Control & Heartbeat                          │  │
 │  │    ├─ Channel 1: Wireless Video Stream (H.264 / AV1 via FFmpeg/V4L2)  │  │
 │  │    ├─ Channel 2: Wireless Media Audio (PCM 48kHz to PulseAudio)       │  │
 │  │    ├─ Channel 3: Wireless Speech Audio (Microphone Input)            │  │
 │  │    ├─ Channel 4: Input Channel (Multi-touch & Hardware Keys)         │  │
 │  │    └─ Channel 5: Sensor Channel (Driving status & Night mode)        │  │
 │  └──────────────────────────────────────────────────────────────────────┘  │
 └──────────────────────────────────────▲──────────────────────────────────────┘
                                        │ 5GHz Wi-Fi Direct Stream
 ┌──────────────────────────────────────┴──────────────────────────────────────┐
 │                      YOUR ANDROID PHONE (In Pocket/Purse)                   │
 └─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Step-by-Step Wireless Protocol Implementation

### Step 1: Bluetooth RFCOMM Handshake (`BlueZ`)
1. When you get into your car and start the RPi, the Raspberry Pi's onboard Bluetooth daemon (`BlueZ`) advertises the Android Auto Bluetooth UUID:
   `0000fdf0-0000-1000-8000-00805f9b34fb`
2. Your Android phone automatically connects to the RPi over Bluetooth.
3. The RPi sends a JSON payload over Bluetooth RFCOMM containing the RPi's **5GHz Wi-Fi Access Point credentials**:
   ```json
   {
     "ssid": "RPi_HeadUnit_5G",
     "bssid": "B8:27:EB:AA:BB:CC",
     "passphrase": "AutomotiveWiFiSecretKey",
     "port": 50001,
     "ip": "192.168.43.1"
   }
   ```

### Step 2: High-Speed 5GHz Wi-Fi Handoff (`hostapd`)
1. Upon receiving the Wi-Fi credentials over Bluetooth, your phone turns on Wi-Fi and connects to `RPi_HeadUnit_5G` (5GHz WPA2 Access Point).
2. The phone initiates a TCP socket connection to `192.168.43.1:50001`.

### Step 3: SSL Encrypted Wireless Stream
Once connected over 5GHz Wi-Fi, the receiver opens 6 dedicated Protocol Buffer (`protobuf`) channels:
* **Channel 1**: Streams H.264 video wirelessly at 60fps directly into Flutter's `Texture` widget.
* **Channel 2**: Streams PCM 48kHz audio wirelessly to RPi speakers.
* **Channel 4**: Relays touch inputs from the screen back over the air to your phone.

---

## 📦 Setting Up 5GHz Wi-Fi AP on Raspberry Pi (`hostapd`)

On your Raspberry Pi, install `hostapd` and `dnsmasq` to host the 5GHz Wireless Android Auto hotspot:

```bash
# 1. Install Access Point packages
sudo apt update
sudo apt install -y hostapd dnsmasq bluez

# 2. Configure 5GHz Access Point (/etc/hostapd/hostapd.conf)
# ssid=RPi_HeadUnit_5G
# hw_mode=a
# channel=36  (5GHz Band)
# wpa=2
```
