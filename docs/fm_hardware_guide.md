# Raspberry Pi FM Transmitter Hardware & Setup Guide

This guide details supported hardware transmitter modules, pinouts, I2C bus configuration, and software drivers for broadcasting FM audio from HeadUnit OS to any car radio.

---

## 1. Supported Hardware Modules & Chipsets

| Hardware Module | Connection Type | I2C Address | RDS Support | Notes & Features |
| :--- | :--- | :--- | :--- | :--- |
| **Silicon Labs Si4713** (Adafruit Breakout) | I2C Bus (`/dev/i2c-1`) | `0x63` | ✅ **Yes** | **Recommended.** Broadcasts RDS station name & song title to car radio display. |
| **KT0803L / KT0803M** | I2C Bus (`/dev/i2c-1`) | `0x3E` | ❌ No | Monolithic low-power stereo transmitter IC. |
| **QN8027 / QN8066** | I2C Bus (`/dev/i2c-1`) | `0x2C` | ❌ No | RPi 40-pin GPIO HAT module. |
| **Elechouse FM Transmitter V2** | I2C / UART | `0x10` | ❌ No | Arduino & RPi compatible board with 3.5mm line-in. |
| **USB FM Transmitter Dongle** | USB Audio Class | ALSA / HID | ❌ No | Plug-and-play USB audio interface. |
| **Software Direct GPIO PWM** | GPIO4 (Pin 7) | N/A | ✅ **Yes** (`Pi-FM-RDS`) | Zero additional hardware IC cost ($0). Requires 20cm wire antenna. |

---

## 2. Raspberry Pi Hardware Wiring (Si4713 Example)

Connect the Si4713 breakout board to the Raspberry Pi 40-pin GPIO header:

- **VIN** -> RPi Pin 1 (3.3V) or Pin 2 (5V)
- **GND** -> RPi Pin 6 (Ground)
- **SDA** -> RPi Pin 3 (GPIO2 / I2C1_SDA)
- **SCL** -> RPi Pin 5 (GPIO3 / I2C1_SCL)
- **RST** -> RPi Pin 11 (GPIO17 - Optional Reset)
- **LIN / RIN** -> RPi 3.5mm DAC Audio Out (Left / Right channel line input)
- **ANT** -> 75cm wire antenna (or car antenna coaxial adapter)

---

## 3. Enabling I2C Bus on Raspberry Pi OS / Linux Mint

1. Enable the I2C kernel interface:
   ```bash
   sudo raspi-config
   # Select Interfacing Options -> I2C -> Enable
   ```

2. Install `i2c-tools` for bus scanning and frequency register control:
   ```bash
   sudo apt-get update
   sudo apt-get install -y i2c-tools
   ```

3. Verify connected I2C transmitter address:
   ```bash
   sudo i2cdetect -y 1
   ```
   *The Si4713 will show up at address `63`.*

---

## 4. HeadUnit OS Automatic Tuning Interface

In HeadUnit OS:
1. Navigate to **Settings** -> **Audio Output & Sound Routing**.
2. Select **FM Transmitter**.
3. Use the **FM Frequency Tuner** slider or **+0.1 / -0.1 MHz** buttons to tune to any clear frequency (e.g. `88.3 MHz`).
4. Select quick preset frequency chips (`88.1`, `88.3`, `88.5`, `107.9 MHz`) for instant switching.
5. Tap **Hardware Specs** anytime to inspect module pinouts.
