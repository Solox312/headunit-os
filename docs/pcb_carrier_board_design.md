# HeadUnit OS — Custom Carrier Board Schematic (Rev A)

Design target: a mass-producible carrier PCB that replaces the Raspberry Pi + HAT + USB DAC + USB FM dongle stack with one board built around a Rockchip RK3566/RK3568 System-on-Module (SoM). This is a schematic-level design (block diagrams, IC selections, BOM) — not routed Gerbers. Ready to hand to a layout engineer or bring into KiCad.

---

## 1. Architecture Overview

```
                              ┌───────────────────────────────────────────┐
                              │         CARRIER BOARD (Rev A)              │
                              │                                             │
  12V Vehicle ──▶ [PWR-IN] ──▶│ Reverse-Polarity + Load-Dump Protection    │
  (ACC + BATT + GND)          │        │                                    │
                              │        ▼                                    │
                              │  Buck Converter (12V → 5V/3A)               │
                              │        │                                    │
                              │        ├──▶ 5V rail ──▶ SoM VIN             │
                              │        └──▶ 3V3 rail ──▶ peripherals        │
                              │                                             │
                              │  Ignition-Sense Comparator ──▶ SoM GPIO     │
                              │  (ACC line) + RC debounce                   │
                              │                                             │
                              │  ┌───────────────────────────────────┐      │
                              │  │   SODIMM SoM SLOT (200-pin)       │      │
                              │  │   Rockchip RK3566/RK3568 SoM      │      │
                              │  │   (e.g. Radxa CM3S)                │      │
                              │  │   CPU + DDR + eMMC + WiFi/BT       │      │
                              │  └──────────┬─────────────┬──────────┘      │
                              │             │             │                 │
                              │      MIPI-DSI (4-lane)   I2C0/I2C1          │
                              │             │             │                 │
                              │             ▼             ├──▶ FM Tx (Si4713)│
                              │   [DISPLAY FPC CONN]       └──▶ Audio Codec  │
                              │   10.1" 800x1280 DSI            (I2S)       │
                              │   + I2C touch (GT911)            │          │
                              │                                   ▼          │
                              │                          Line-out isolation │
                              │                          transformer stage  │
                              │                                   │          │
                              │                              [AUX OUT JACK] │
                              │                                             │
                              │  USB 2.0 Host x2 ──▶ [USB-A] Mic / Dongle   │
                              │  USB OTG ──▶ [USB-C] Debug/flash            │
                              │  UART debug header                          │
                              └───────────────────────────────────────────┘
```

---

## 2. Block-by-Block Design

### 2.1 Power Input & Protection

Input: 3-wire automotive harness — **BATT (constant 12V)**, **ACC (switched 12V / ignition)**, **GND**.

| Stage | Component | Function |
| :--- | :--- | :--- |
| Reverse polarity | P-channel MOSFET (e.g. **DMP3098L**) in series on BATT rail, gate tied to GND | Blocks reverse-battery connection per ISO 16750-2; lower loss than a series diode |
| Load-dump / transient clamp | TVS diode **SMAJ15A** (15V standoff / 24.4V clamp) across BATT-GND, close to connector | Absorbs ISO 7637-2 pulse 5a/5b alternator load-dump spikes |
| Input fuse | 3A automotive blade fuse (off-board, harness-side) or 3A PTC resettable fuse on-board | Overcurrent protection |
| Bulk input filtering | 100 µF electrolytic + 0.1 µF ceramic across BATT-GND post-protection | Smooths cranking noise ahead of the buck regulator |

### 2.2 DC-DC Power Conversion

| Rail | IC | Notes |
| :--- | :--- | :--- |
| 12V → 5V @ 3A | **TPS54331** (or **MP2315** for cost-down) synchronous buck, 40V-rated input | Powers SoM VIN, display backlight, USB ports |
| 5V → 3V3 @ 1A | **AMS1117-3.3** LDO or small buck (**TPS62203**) | Powers touch controller, FM chip, audio codec, level shifters |
| Always-on standby rail | Separate low-quiescent LDO off BATT (not ACC) sized for SoM's RTC/wake circuitry only | Lets the SoM/board wake or hold state during the shutdown-debounce window without draining the battery |

### 2.3 Ignition Sense & Safe-Shutdown Logic

Replaces the CarPiHAT/StromPi/Mausberry HAT function, now onboard:

1. ACC line is divided down (100kΩ/22kΩ divider) and fed into a comparator (**TLV3201**) referenced at 2.5V, producing a clean 3V3 logic signal — HIGH while ignition is on.
2. That logic signal connects directly to an SoM GPIO (matches the existing `scripts/shutdown_listener.py` design: GPIO reads LOW → begins shutdown timer).
3. An RC debounce (10kΩ + 1µF) on the comparator output prevents false shutdown triggers during engine cranking voltage sag.
4. A second GPIO-controlled load switch (**AP2331** or similar), driven by the SoM just before it halts, disconnects the 5V rail from the SoM/display after Linux has cleanly shut down — mirroring the HAT's "cut power after halt" behavior, so the standby rail isn't the only thing keeping the board "on" indefinitely.

### 2.4 Compute: SoM Socket

- **Socket**: standard 200-pin DDR2 SODIMM connector (matches Radxa CM3S mechanical/pin spec) so the carrier board can accept any pin-compatible RK3566/RK3568 SODIMM SoM — keeps you from being locked to a single vendor at volume.
- **Recommended SoM**: Radxa CM3S (RK3566, up to 8GB LPDDR4, up to 128GB eMMC, WiFi 4/BT 4.2 onboard) — publicly documented pinout/schematic, available in volume, no Raspberry Pi silicon.
- Exposed on the SODIMM edge to the carrier: 4-lane MIPI-DSI, I2C0-I2C3, 2x USB2.0 host, 1x USB OTG, SDMMC (for a microSD debug slot), UART2 (console), PWM (backlight dimming), GPIO bank for ignition-sense/power-switch signals.

### 2.5 Display Interface (MIPI-DSI, no HDMI board)

- **Panel**: 10.1" IPS capacitive touch, 800×1280, 4-lane MIPI-DSI (Waveshare 10.1-DSI-TOUCH-A class panel or equivalent OEM panel of the same spec) — rotate 90° in the Flutter app's display settings for landscape dash orientation, since these panels are natively portrait.
- **Touch controller**: Goodix **GT911** capacitive touch IC on the panel FPC, connected to SoM I2C + a touch-interrupt GPIO.
- **Connector**: 40-pin 0.5mm-pitch FPC connector on the carrier board matching the panel's ribbon (DSI lanes + I2C touch + backlight power/enable, all on one ribbon — this is what eliminates the separate HDMI driver board).
- **Backlight**: PWM-dimmable LED driver (**TPS61165** or similar boost driver) fed from the SoM's PWM output, so in-app brightness control (already in the `display_provider.dart`/`display_service.dart` code) maps directly to hardware dimming instead of software-only.

### 2.6 Audio Path (onboard DAC + ground loop isolation)

- **Codec**: **WM8960** (or **ES8388**) stereo audio codec, I2S to the SoM, replacing the external USB DAC dongle.
- **Line-out isolation**: audio-grade isolation transformer (**Bourns LM-1547** class, 1:1 stereo pair) placed inline between the codec's line-out and the AUX output jack. This is the onboard equivalent of the inline 3.5mm ground-loop isolator in the current build — it galvanically isolates the audio ground from the car's electrical ground, which is what actually kills alternator whine (not the connector type).
- **Mic input**: codec's onboard mic-in / ADC path exposed to a 3.5mm mic jack or electret mic footprint, replacing the USB mic — frees a USB port and removes one USB audio class driver dependency.
- **Output connector**: standard 3.5mm TRS AUX jack, post-isolation-transformer.

### 2.7 FM Transmitter (Si4713, onboard)

- **IC**: Silicon Labs **Si4713-B30**, same chip as the Adafruit breakout currently referenced in `docs/fm_hardware_guide.md`, now placed directly on the carrier board.
- **I2C**: shares the SoM's I2C bus with the touch controller (different address: Si4713 at `0x63`, GT911 typically at `0x5D`/`0x14` — no conflict).
- **Audio in**: fed directly from the codec's line-out (post-DAC, pre-isolation-transformer — the FM chip doesn't need the ground isolation the AUX jack does since it broadcasts wirelessly).
- **Reference crystal**: 32.768kHz crystal per Si4713 datasheet reference design.
- **Antenna**: SMA or U.FL connector for a short whip/wire antenna, matching the existing 75cm wire-antenna guidance in the FM hardware guide.
- **RST**: tied to an SoM GPIO for power-on reset control (mirrors the current `RST -> GPIO17` wiring).

### 2.8 USB & Debug

- 2x USB 2.0 Type-A host ports: one for the USB mic (if the onboard mic-in isn't used) and/or the Carlinkit wireless Android Auto/CarPlay dongle.
- 1x USB-C (OTG/debug): firmware flashing, eMMC provisioning, and serial-over-USB debug during bring-up/production test.
- 4-pin UART debug header (GND/TX/RX/3V3) for console access, standard on Rockchip bring-up boards.
- microSD slot wired to SoM SDMMC1 for A/B image flashing or field recovery.

---

## 3. Open Items / Recommendations for Layout Phase

- MIPI-DSI is a high-speed differential interface — route as controlled-impedance differential pairs with length-matching per the Rockchip RK356x Hardware Design Guide before finalizing panel connector placement.
- Confirm the panel's actual FPC pin map once you've picked a specific SKU — panel vendors are not fully standardized on DSI pinout despite similar connector pitch.
- Recommend a 6-layer stackup (signal/GND/power/power/GND/signal) given DDR-adjacent routing off the SODIMM edge and the DSI differential pairs.
- This document assumes the SoM handles all DDR/eMMC/power-sequencing complexity — if you later want to eliminate the SODIMM socket for a lower per-unit BOM cost at very high volume, that requires a second design pass to place the RK356x BGA directly on this board (raw SoC bring-up), which is a materially larger effort.

See the companion BOM: `docs/pcb_carrier_board_bom.xlsx`.
