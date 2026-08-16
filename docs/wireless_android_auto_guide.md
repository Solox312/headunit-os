# TECHNICAL MANUAL & INTEGRATION GUIDE: WIRELESS ANDROID AUTO
## Standard Compliance: IEC/IEEE 82079-1:2019 (Preparation of Information for Use)

---

### DOCUMENT CONTROL INFORMATION
- **Document Identifier**: DOC-HUOS-AAW-001
- **Edition**: 1.0.0
- **Release Date**: 2026-08-16
- **System**: HeadUnit OS / Automotive Embedded Linux
- **Target Hardware**: Radxa CM3S (Rockchip RK3566) / Raspberry Pi 4 / Raspberry Pi 5
- **Subsystems**: Bluetooth 5.0 (BlueZ / AP6256), Wi-Fi 5 (802.11ac 5 GHz AP), Native AOA 2.0 / TCP 50001 Engine

---

## 1. PRINCIPLE OF OPERATION

### 1.1 Architecture Overview
Wireless Android Auto operates via a **Head-Unit-Initiated Out-of-Band (OOB) Handshake Protocol**:

```
[Android Phone]                                           [HeadUnit OS]
       |                                                        |
       | <============= 1. Bluetooth 5.0 ACL Link ============> | (HeadUnit-OS / 0x200408)
       |                                                        |
       | <--- 2. ConnectProfile(4de17a00-52cb-11e6-...) ------- | (BlueZ RFCOMM)
       |                                                        |
       | <--- 3. WifiVersionRequest (Msg ID: 4) --------------- |
       | --- 4. WifiVersionResponse (Msg ID: 5) --------------> |
       |                                                        |
       | <--- 5. WifiStartRequest (Msg ID: 1, IP, Port 50001) - |
       | --- 6. WifiInfoRequest (Msg ID: 2) ------------------> |
       | <--- 7. WifiInfoResponse (Msg ID: 3, SSID, WPA2 PSK) - |
       |                                                        |
       | ============= 8. 5 GHz Wi-Fi Connection ============> | (SSID: HeadUnit-OS, Ch 36)
       |                                                        |
       | ============= 9. TCP Socket Stream (Port 50001) =====> | (Video, Audio, Touch)
```

### 1.2 Protocol Stages
1. **Bluetooth Pairing & Discovery**:
   - The head unit advertises the **Automotive Audio Device Class (`0x200408`)** and the **Android Auto Wireless SDP Profile (`4de17a00-52cb-11e6-bdf4-0800200c9a66`)**.
2. **RFCOMM Credential Handoff**:
   - Upon Bluetooth connection, `aa_wireless_handoff.py` establishes an RFCOMM channel.
   - It negotiates versions and sends the live IP and port of the head unit (`WifiStartRequest`).
   - The phone requests credentials (`WifiInfoRequest`), and the head unit supplies the Wi-Fi SSID (`HeadUnit-OS`) and WPA2 passphrase (`headunit2024`).
3. **Wi-Fi AP Association**:
   - The phone automatically joins the 5 GHz Wi-Fi access point hosted on the Radxa CM3S / Raspberry Pi.
4. **TCP Protocol Projection**:
   - The phone connects to `TCP 50001`.
   - Video (H.264), Audio (PCM 16-bit 48kHz Stereo), and Touch input events are multiplexed.

---

## 2. PRE-REQUISITES & ENVIRONMENT CONFIGURATION

### 2.1 Linux Kernel & System Dependencies
The host operating system requires the following runtime dependencies:
```bash
sudo apt-get update
sudo apt-get install -y python3-dbus python3-gi bluez network-manager rfkill
```

### 2.2 Bluetooth Controller & BlueZ Configuration
Verify that `/etc/bluetooth/main.conf` specifies the automotive class:
```ini
[General]
Class = 0x200408
DiscoverableTimeout = 0
PairableTimeout = 0
```

Restart BlueZ service:
```bash
sudo systemctl restart bluetooth
```

### 2.3 5 GHz Wi-Fi Hotspot Configuration
The Wi-Fi access point must be configured for **5 GHz (Band A / Channel 36)** to avoid 2.4 GHz co-channel interference with the Bluetooth audio/RFCOMM stream:
```bash
sudo nmcli connection add \
  type wifi \
  con-name "HeadUnit-OS" \
  ssid "HeadUnit-OS" \
  mode ap \
  802-11-wireless.band a \
  802-11-wireless.channel 36 \
  ipv4.method shared \
  wifi-sec.key-mgmt wpa-psk \
  wifi-sec.psk "headunit2024" \
  autoconnect no
```

---

## 3. STEP-BY-STEP TESTING & COMMISSIONING PROCEDURE

### 3.1 Step 1: Run Interactive Diagnostic Tool
On the Linux target or Raspberry Pi, launch the diagnostic suite:
```bash
bash scripts/test_aa_wireless.sh
```

### 3.2 Step 2: Prepare Android Phone
1. Open **Settings $\rightarrow$ Apps $\rightarrow$ Android Auto $\rightarrow$ Additional settings in the app**.
2. Scroll to the bottom and tap **Version** 10 times to enable **Developer settings**.
3. Tap the three dots (top right) $\rightarrow$ **Developer settings**.
4. Ensure **Wireless Android Auto** is enabled.
5. Turn on **Bluetooth** and **Wi-Fi** on the phone.

### 3.3 Step 3: Pair Bluetooth
1. On the phone, scan for Bluetooth devices and select **HeadUnit-OS**.
2. Confirm the passkey on both devices.
3. Observe the live terminal trace in `scripts/test_aa_wireless.sh`:
   - `EVENT:PROFILE_REGISTERED uuid=4de17a00-52cb-11e6-bdf4-0800200c9a66`
   - `EVENT:PHONE_CONNECTED`
   - `EVENT:WIFI_START_SENT ip=10.42.0.1 port=50001`
   - `EVENT:CREDENTIALS_SENT ssid=HeadUnit-OS`
4. The phone will display an Android Auto notification and launch projection!

---

## 4. TROUBLESHOOTING & FAULT RESOLUTION

| Symptom | Probable Cause | Corrective Action |
| :--- | :--- | :--- |
| Phone pairs as "Headphones", no Android Auto prompt appears | Bluetooth class is set to Computer or Phone | Run `sudo sed -i 's/^#*Class = .*/Class = 0x200408/' /etc/bluetooth/main.conf && sudo systemctl restart bluetooth` |
| `CONNECT_PROFILE_FAILED` in handoff logs | Phone did not expose AA Wireless UUID | Ensure Wireless Android Auto is enabled in phone's Android Auto developer settings |
| `ERROR could not determine hotspot IP` | Wi-Fi hotspot interface is not active | Run `sudo nmcli connection up HeadUnit-OS` and verify IP via `ip addr show wlan0` |
| Phone connects to Wi-Fi but disconnects after 5s | Port 50001 blocked or 2.4 GHz channel collision | Ensure `AndroidAutoEngine` is listening on port 50001 and Wi-Fi is locked to 5 GHz (channel 36) |

---

## 5. MAINTENANCE & SYSTEM VERIFICATION
- **Diagnostic Tool**: [`scripts/test_aa_wireless.sh`](file:///c:/Users/cnieves.wmg/Desktop/Projects/headunit-os/scripts/test_aa_wireless.sh)
- **Handoff Daemon**: [`scripts/aa_wireless_handoff.py`](file:///c:/Users/cnieves.wmg/Desktop/Projects/headunit-os/scripts/aa_wireless_handoff.py)
- **Engine Protocol Receiver**: [`lib/services/android_auto_engine.dart`](file:///c:/Users/cnieves.wmg/Desktop/Projects/headunit-os/lib/services/android_auto_engine.dart)
- **Connection Bridge**: [`lib/services/wireless_aa_bridge.dart`](file:///c:/Users/cnieves.wmg/Desktop/Projects/headunit-os/lib/services/wireless_aa_bridge.dart)
