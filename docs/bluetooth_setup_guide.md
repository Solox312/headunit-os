# Linux Mint & Raspberry Pi Bluetooth Setup Guide 📶

This guide details how **HeadUnit OS** interfaces with Linux BlueZ (`bluetoothctl`), `rfkill`, and PulseAudio/Pipewire on **Linux Mint** (desktop testing host) and **Raspberry Pi OS** for A2DP audio streaming and wireless projection.

---

## 1. Linux Bluetooth Prerequisites

Both **Linux Mint** and **Raspberry Pi OS** use the official Linux **BlueZ 5.x** Bluetooth daemon.

Ensure BlueZ and `bluetoothctl` are installed and active:

```bash
sudo apt update
sudo apt install -y bluez rfkill pulseaudio-module-bluetooth
sudo systemctl enable --now bluetooth
```

Verify Bluetooth adapter status:
```bash
rfkill list bluetooth
bluetoothctl show
```

---

## 2. Linux Mint Desktop Testing & Raspberry Pi OS Setup

### Step 1: Unblock & Power On Bluetooth Adapter
```bash
sudo rfkill unblock bluetooth
bluetoothctl power on
```

### Step 2: Set Bluetooth Chip Broadcast Name to "HeadUnit OS"

HeadUnit OS automatically sets the adapter name on boot. To configure the system-wide Bluetooth name persistently in the Linux kernel:

Edit `/etc/bluetooth/main.conf`:
```ini
[General]
Name = HeadUnit OS
Class = 0x200408
DiscoverableTimeout = 0
```

Or via CLI:
```bash
bluetoothctl system-alias "HeadUnit OS"
sudo hciconfig hci0 name "HeadUnit OS"
```

### Step 3: Set HeadUnit OS as Discoverable & Pairable Receiver
```bash
bluetoothctl discoverable on
bluetoothctl pairable on
bluetoothctl agent NoInputNoOutput
bluetoothctl default-agent
```

### Step 3: Connect Car Receiver / Phone
You can scan, pair, and connect directly inside the **HeadUnit OS Settings** screen or via CLI:
```bash
bluetoothctl scan on
bluetoothctl pair <MAC_ADDRESS>
bluetoothctl trust <MAC_ADDRESS>
bluetoothctl connect <MAC_ADDRESS>
```

---

## 3. PulseAudio / PipeWire A2DP Audio Sink Configuration

When connected to a Car Bluetooth stereo or phone, set the Bluetooth audio profile to A2DP Sink:

```bash
pactl set-card-profile bluez_card.<MAC_WITH_UNDERSCORES> a2dp_sink
```

HeadUnit OS automatically routes all audio output through the active A2DP Bluetooth sink when **Car Bluetooth Stereo (A2DP)** is selected in Settings.
