# HeadUnit OS — Native Android Auto Protocol Receiver Specification

**Information for Use (Technical Specification & Architecture) — Structured in accordance with IEC/IEEE 82079-1:2019 Standard**

---

## Document Identification

| Item | Specification |
| :--- | :--- |
| **Document Title** | Native Android Auto Protocol Engine Specification & Architecture |
| **Document Type** | Technical Specification & Protocol Architecture Guide |
| **Document Identifier** | HUOS-SPEC-003-REV-B |
| **Revision** | B (Native Protocol Stack Edition) |
| **Issue Date** | 2026-08-08 |
| **Applies to Product** | HeadUnit OS Android Auto Receiver Subsystem |
| **Target OS** | Linux (Ubuntu Server / Linux Mint / Raspberry Pi OS) |
| **Target Audience** | Embedded Systems Engineers, Protocol Developers |
| **Language** | English (en-US) |

---

## Safety & Operational Precautions

> [!IMPORTANT]
> **Wireless Interference & 5GHz Wi-Fi Band Selection:**
> Use Wi-Fi 5GHz Band (UNII-1 Channels 36–48) for high-bandwidth H.264 video streaming. 2.4GHz Wi-Fi is subject to severe interference from Bluetooth RFCOMM handshakes.

---

## 1. System Architecture Overview

HeadUnit OS implements a **100% native Android Auto protocol receiver stack** directly in Dart and Linux system libraries—completely eliminating external C++ binary dependencies (`autoapp`, Boost 1.67, Qt5).

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                      FLUTTER HEAD UNIT DISPLAY LAYER                        │
 │  ┌───────────────────────────────────────────────────────────────────────┐  │
 │  │ Flutter AndroidAutoView Widget (H.264 Frame) & Gesture Listener        │  │
 │  └───────────────────────────────────▲───────────────────────────────────┘  │
 └──────────────────────────────────────┼──────────────────────────────────────┘
                                        │ Packets / Stream (Port 50001)
 ┌──────────────────────────────────────┴──────────────────────────────────────┐
 │                NATIVE ANDROID AUTO PROTOCOL ENGINE (DART/C)                 │
 │                                                                             │
 │  ┌───────────────────────────┐           ┌──────────────────────────────┐  │
 │  │ 1. Bluetooth RFCOMM       │           │ 2. 5GHz Wi-Fi Direct / AP    │  │
 │  │    UUID: 0000fdf0-...     │           │    `nmcli` / `hostapd`       │  │
 │  └─────────────┬─────────────┘           └──────────────┬───────────────┘  │
 │                │                                        │                  │
 │  ┌─────────────▼────────────────────────────────────────▼───────────────┐  │
 │  │ 3. Protocol Buffer (Protobuf) Channel Multiplexer (Port 50001)       │  │
 │  │    ├─ Channel 0: Control Service & Handshake                         │  │
 │  │    ├─ Channel 1: Wireless Media Audio (PCM 48kHz to PulseAudio)       │  │
 │  │    ├─ Channel 2: Speech Audio (Voice Guidance & Mic)                 │  │
 │  │    ├─ Channel 3: System Audio (Notifications)                        │  │
 │  │    ├─ Channel 4: Touch Input Channel (Multi-touch & Hardware Keys)   │  │
 │  │    ├─ Channel 5: H.264 Video Stream                                  │  │
 │  │    └─ Channel 6: Vehicle Sensor Channel (Driving status & Night mode)│  │
 │  └──────────────────────────────────────────────────────────────────────┘  │
 └──────────────────────────────────────▲──────────────────────────────────────┘
                                        │ 5GHz Wi-Fi / USB AOA Connection
 ┌──────────────────────────────────────┴──────────────────────────────────────┐
 │                            ANDROID SMARTPHONE                               │
 └─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Protocol Channel Specification

| Channel ID | Name | Protocol Data Unit (PDU) Description |
| :--- | :--- | :--- |
| **Channel 0** | Control Service | `VersionRequest`, `VersionResponse`, `ServiceDiscoveryRequest`, `ServiceDiscoveryResponse`, `Ping` |
| **Channel 1** | Media Audio | PCM 48kHz Stereo Audio Stream (Music/Navigation Audio) |
| **Channel 2** | Speech Audio | PCM 16kHz Mono Voice Guidance & Microphone Input |
| **Channel 3** | System Audio | PCM System Beeps & Notification Sounds |
| **Channel 4** | Input Service | Normalized Touch Coordinates `(x, y)` & Touch Actions (Press=0, Move=1, Release=2) |
| **Channel 5** | Video Service | H.264 NAL Video Stream (720p / 1080p @ 30/60 FPS) |
| **Channel 6** | Sensor Service | Night Mode Status, Driving Status, Vehicle GPS Coordinates |

---

## 3. Protocol Sequence & Commissioning

### Phase 1: USB AOAP / Bluetooth Discovery
1. **USB Mode:** Scans for USB vendor devices and sends AOA 2.0 control requests (`GET_PROTOCOL`, `SEND_STRING`, `START_ACCESSORY`), switching device Vendor ID to `0x18d1:0x2d00`.
2. **Wireless Mode:** Bluetooth RFCOMM advertises UUID `0000fdf0-0000-1000-8000-00805f9b34fb` and exchanges 5GHz Wi-Fi credentials (`SSID`, `BSSID`, `passphrase`, `port`).

### Phase 2: Channel Multiplexing & Video Rendering
1. The smartphone establishes a TCP socket connection on Port 50001.
2. `AAPacket` binary codec demuxes incoming streams by Channel ID.
3. Channel 5 (H.264 Video) renders directly on `AndroidAutoView`.
4. Touch gestures captured on `AndroidAutoView` are serialized and transmitted on Channel 4.

---

## Document Revision History

| Revision | Date | Description of Change | Approved By |
| :--- | :--- | :--- | :--- |
| A | 2026-08-08 | Initial Native Protocol Architecture Specification | HeadUnit OS Team |
| B | 2026-08-08 | Updated to IEC/IEEE 82079-1 standard with full channel spec | HeadUnit OS Team |
