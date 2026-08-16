# Technical Specification & Integration Guide: FM Transmitter Subsystem
**Document ID**: DOC-HU-HW-005  
**Standard**: IEC/IEEE 82079-1:2019  
**Applies to**: HeadUnit OS (Raspberry Pi 4 / CM4, Radxa CM3S RK3566 Carrier Boards)  
**Revision**: 2.1  

---

## 1. Scope & Purpose
This document provides instructions and technical specifications for the FM transmitter subsystem of HeadUnit OS. It covers supported integrated circuits (ICs), dynamic I2C bus auto-discovery, register configuration formulas, and production carrier board bring-up procedures.

---

## 2. Supported Hardware Transmitters & Technical Data

| Component | Architecture / Bus | I2C Address | RF Power | Frequency Range | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **KT0803K / KT0803L / KT0803M** | On-Board I2C (`/dev/i2c-*`) | `0x3E` | ~108 dBµV | 70.0 – 108.0 MHz (50 kHz steps) | **Primary Production IC** |
| **Silicon Labs Si4713** | External / Breakout (`/dev/i2c-*`) | `0x63` | 115 dBµV | 76.0 – 108.0 MHz (50 kHz steps) | Development / RDS Support |
| **QN8027 / QN8066** | I2C HAT (`/dev/i2c-*`) | `0x2C` | ~105 dBµV | 76.0 – 108.0 MHz (50 kHz steps) | Secondary Development |
| **RPi GPCLK PWM** | Direct GPIO4 | N/A | Variable | 87.5 – 108.0 MHz | Software Emergency Fallback |

---

## 3. Dynamic Multi-Bus Auto-Discovery
HeadUnit OS includes a dynamic I2C discovery engine in `FmTransmitterService`:
- On **Raspberry Pi 4 / CM4**: Probes standard bus `/dev/i2c-1`.
- On **Radxa CM3S (Rockchip RK3566)**: Automatically enumerates `/dev/i2c-0` through `/dev/i2c-5` and dynamically binds to whichever bus acknowledges slave address `0x3E` (KT0803K) or `0x63` (Si4713).

---

## 4. KT0803K Register Configuration Protocol

### 4.1 Channel Selection Formula
$$\text{CHSEL} = (F_{\text{MHz}} - 64.0) \times 20$$

*Example for 88.3 MHz*:
$$\text{CHSEL} = (88.3 - 64.0) \times 20 = 486 = \text{0x01E6}$$
- **Register 0x00** (`CHSEL[7:0]`): `0xE6`
- **Register 0x01** (`CHSEL[9:8] | AU_EN | Pre-emphasis`): `0x01 | 0x10 | 0x08 = 0x19`

### 4.2 Initialization Register Sequence
1. **Reg 0x00**: `CHSEL[7:0]`
2. **Reg 0x01**: `CHSEL[9:8] | 0x18` (Enables Audio Input + 75µs Automotive Pre-emphasis)
3. **Reg 0x02**: `0xB0` (Maximum RF output level ~108 dBµV)
4. **Reg 0x04**: `0x00` (PGA audio stage unmuted)
5. **Reg 0x0B**: `0x00` (Stereo modulation with 19 kHz pilot tone enabled)
6. **Reg 0x13**: `0x00` (Active transmission power mode)

---

## 5. Production Carrier Board Wiring (Radxa CM3S)

| Signal | Radxa CM3S SODIMM / Pin | KT0803K IC Pin | Description |
| :--- | :--- | :--- | :--- |
| **3V3_SYS** | 3.3V Power Rail | VDD (Pins 3, 13) | Regulated 3.3V DC Power |
| **GND** | System Ground | GND (Pins 4, 12, Thermal Pad) | Common Ground |
| **I2C_SDA** | RK3566 I2C SDA (e.g. `i2c2_sda`) | SDA (Pin 6) | I2C Serial Data (4.7kΩ pull-up to 3.3V) |
| **I2C_SCL** | RK3566 I2C SCL (e.g. `i2c2_scl`) | SCL (Pin 5) | I2C Serial Clock (4.7kΩ pull-up to 3.3V) |
| **PWR_EN / RST**| RK3566 GPIO (Output) | RST_N (Pin 1) | Active-High Transmitter Enable |
| **RF_OUT** | Antenna Trace / U.FL | RFOUT (Pin 11) | 50Ω trace with LC harmonic filter |

---

## 6. Verification and Diagnostics

### 6.1 Command-Line Verification (Linux Terminal)
```bash
# 1. Enumerate and probe available I2C buses:
for bus in /dev/i2c-*; do
  echo "Scanning $bus:"
  i2cdetect -y "${bus##*-}"
done

# 2. Read Register 0x00 from KT0803K:
i2cget -y 2 0x3E 0x00
```

### 6.2 Application UI Verification
1. Navigate to **Settings** -> **Audio Output & Sound Routing**.
2. Select **FM Transmitter**.
3. Verify that the hardware badge displays **`KT0803K (0x3E) Detected`** in green.
4. Adjust the frequency via the tuner slider; verify that the frequency persists and the car stereo receives clear audio transmission.

