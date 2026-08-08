# Raspberry Pi & Linux Bluetooth Setup Guide 📶⚡

This guide documents how **HeadUnit OS** interfaces with Linux BlueZ (`bluetoothctl`) and PulseAudio / PipeWire to enable Bluetooth device scanning, pairing, A2DP audio streaming, and hands-free phone connection.

---

## 1. Linux BlueZ Prerequisites

Verify that the BlueZ daemon (`bluetoothd`) and `bluetoothctl` CLI are active on your system:

```bash
sudo systemctl status bluetooth
bluetoothctl show
```

Output should indicate:
```
Powered: yes
Discoverable: yes
Pairable: yes
```

---

## 2. A2DP Audio Sink Setup (PulseAudio / PipeWire)

To allow phones (Android / iPhone) to stream high-quality A2DP stereo audio directly to HeadUnit OS, ensure `pulseaudio-module-bluetooth` or `pipewire-audio-client-libraries` is installed:

```bash
sudo apt update
sudo apt install -y pulseaudio-module-bluetooth bluez-tools
```

Restart PulseAudio:
```bash
pulseaudio -k
pulseaudio --start
```

---

## 3. Bluetooth Pairability & Wireless Android Auto / CarPlay Handshake

1. Open **Bluetooth Manager** from the HeadUnit OS dock navigation bar.
2. Ensure **Make Discoverable** is toggled **ON**.
3. On your phone, go to **Settings -> Bluetooth** and tap **RPi-HeadUnit** to initiate pairing.
4. Once paired, HeadUnit OS automatically establishes:
   * **A2DP Audio Sink**: Streams music from your phone to car audio targets (AUX / Bluetooth / FM Transmitter).
   * **RFCOMM Channel**: Transmits Wi-Fi Access Point credentials for Wireless Android Auto / Apple CarPlay.

---

## 4. Troubleshooting Bluetooth Issues

* **Bluetooth Adapter Soft-Locked**: Run `sudo rfkill unblock bluetooth`.
* **Pairing Rejected**: Remove old pairing keys on Linux by running `bluetoothctl remove <PHONE_MAC>` and retry pairing.
* **Audio Not Playing**: Check `pavucontrol` or set active audio sink using `pacmd set-default-sink`.
