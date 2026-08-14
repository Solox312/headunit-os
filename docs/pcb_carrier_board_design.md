# HeadUnit OS — Custom Carrier Board Schematic (Rev B)

Design target: a mass-producible carrier PCB that replaces the Raspberry Pi + HAT + USB DAC + USB FM dongle stack with one board built around a Rockchip RK3566/RK3568 System-on-Module (SoM). This is a schematic-level design (block diagrams, IC selections, BOM) — not routed Gerbers. Ready to hand to a layout engineer or bring into KiCad.

**Rev B (this revision): portable, no-dash-mount form factor.** This board is no longer designed around a double-DIN dash installation — it's a standalone/portable unit. Power input changed from a 3-pin automotive harness (BATT/ACC/GND, wired permanently into the vehicle) to USB-C Power Delivery, so the unit runs off any 12V-accessory-socket USB-C PD car charger with no wiring into the vehicle required. See §2.1/§2.3 below for the resulting power and safe-shutdown changes, and the project handoff doc's §5 for the decision record this implements.

---

## 1. Architecture Overview

```
                              ┌───────────────────────────────────────────┐
                              │         CARRIER BOARD (Rev B)              │
                              │                                             │
  USB-C PD Charger ──▶[USB-C]│ PD Sink IC (CH224K, req. 12V)              │
  (12V accessory socket)     │        │                                    │
                              │        ▼                                    │
                              │  Fuse + TVS Clamp + Bulk Filtering          │
                              │        │                                    │
                              │        ▼                                    │
                              │  Buck Converter (12V → 5V/3A)               │
                              │        │                                    │
                              │        ├──▶ 5V rail ──▶ SoM VIN             │
                              │        └──▶ 3V3 rail ──▶ peripherals        │
                              │                                             │
                              │  VBUS-Loss-Sense Comparator ──▶ SoM GPIO    │
                              │  (tracks +12V_PROT) + RC debounce           │
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
                              │  (USB-C above also carries OTG/debug D+/D-) │
                              │  UART debug header                          │
                              └───────────────────────────────────────────┘
```

---

## 2. Block-by-Block Design

### 2.1 Power Input & Protection

Input: **USB-C Power Delivery**, single connector (J8), also carrying OTG/debug D+/D-. Replaces the 3-wire automotive harness (BATT/ACC/GND) used through Rev A — see the handoff doc's §5 for why (this is Option 1 of the three options considered there: drop the harness, sense VBUS loss instead of the ACC line).

| Stage | Component | Function |
| :--- | :--- | :--- |
| PD negotiation | **CH224K**-class PD sink/trigger IC (U10), CFG pin resistor-selects the requested voltage (12V) | Negotiates a fixed 12V from the charger with no I2C/firmware needed; hands it to the same protection/regulation stage below |
| Load-dump / transient clamp | TVS diode **SMAJ26A** (26V standoff) across the post-negotiation 12V rail | Clamps transients/fault conditions; 26V standoff keeps margin above the 20V USB-PD ceiling |
| Input fuse | 3A PTC resettable fuse on-board, downstream of the PD sink IC | Overcurrent protection |
| Bulk input filtering | 470 µF electrolytic (bumped from 100 µF) + 0.1 µF ceramic across the protected 12V rail | Filters PD-negotiation transients, and gives the rail a brief holdup window after VBUS loss so the sense comparator + SoM have time to begin clean shutdown before the rail collapses — holdup time is an estimate, verify on the bench |

No reverse-polarity protection stage: USB-C VBUS/GND are fixed, keyed pins (unlike the old bare 3-pin screw terminal), so the Rev A reverse-polarity P-MOSFET (Q1) is removed.

### 2.2 DC-DC Power Conversion

| Rail | IC | Notes |
| :--- | :--- | :--- |
| 12V → 5V @ 3A | **LMR33630-Q1** synchronous buck, 36V-rated input | Powers SoM VIN, display backlight, USB ports; input now comes from the PD sink IC's negotiated output instead of the raw battery line |
| 5V → 3V3 @ 1A | Synchronous buck (**TPS62203**) | Powers touch controller, FM chip, audio codec, level shifters |

Rev A's separate always-on standby LDO (off the permanently-present BATT line) is removed in Rev B: there's no longer a separate always-on power line to draw it from — USB-C VBUS is either present or the board is unpowered, like any other portable USB device. The VBUS-loss sense comparator below was already running off +3V3 (itself derived from the protected 12V rail), not the standby LDO, so removing it doesn't touch the shutdown-sense path.

### 2.3 VBUS-Loss Sense & Safe-Shutdown Logic

Replaces the CarPiHAT/StromPi/Mausberry HAT function, now onboard. Same comparator + RC-debounce + GPIO concept as Rev A's ACC-line ignition sense, re-pointed at the protected 12V rail (which now tracks USB-C VBUS presence) since there's no separate ignition wire on a USB-C-only power input:

1. The protected 12V rail is divided down (100kΩ/22kΩ divider) and fed into a comparator (**TLV3201**) referenced at 2.5V, producing a clean 3V3 logic signal — HIGH while USB-C VBUS is present.
2. That logic signal connects directly to an SoM GPIO (matches the existing `scripts/shutdown_listener.py` design: GPIO reads LOW → begins shutdown timer).
3. An RC debounce (10kΩ + 10µF, bumped from 1µF) on the comparator output prevents false shutdown triggers from a brief VBUS dip or a wiggled connector — retune this against real USB-C connector behavior; the old 1µF value was sized for engine-cranking voltage sag, which no longer applies here.
4. A second GPIO-controlled load switch (**TPS22965**), driven by the SoM just before it halts, disconnects the 5V rail from the SoM/display after Linux has cleanly shut down.

### 2.4 Compute: SoM Socket

- **Socket**: standard 200-pin DDR2 SODIMM connector (matches Radxa CM3S mechanical/pin spec) so the carrier board can accept any pin-compatible RK3566/RK3568 SODIMM SoM — keeps you from being locked to a single vendor at volume.
- **Recommended SoM**: Radxa CM3S (RK3566, up to 8GB LPDDR4, up to 128GB eMMC, WiFi 4/BT 4.2 onboard) — publicly documented pinout/schematic, available in volume, no Raspberry Pi silicon.
- Exposed on the SODIMM edge to the carrier: 4-lane MIPI-DSI, I2C0-I2C3, 2x USB2.0 host, 1x USB OTG, SDMMC (for a microSD debug slot), UART2 (console), PWM (backlight dimming), GPIO bank for VBUS-loss-sense/power-switch signals.

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
- The USB-C port (J8, §2.1) doubles as OTG/debug: firmware flashing, eMMC provisioning, and serial-over-USB debug during bring-up/production test, alongside its power-delivery role.
- 4-pin UART debug header (GND/TX/RX/3V3) for console access, standard on Rockchip bring-up boards.
- microSD slot wired to SoM SDMMC1 for A/B image flashing or field recovery.

---

## 3. Open Items / Recommendations for Layout Phase

- MIPI-DSI is a high-speed differential interface — route as controlled-impedance differential pairs with length-matching per the Rockchip RK356x Hardware Design Guide before finalizing panel connector placement.
- Confirm the panel's actual FPC pin map once you've picked a specific SKU — panel vendors are not fully standardized on DSI pinout despite similar connector pitch.
- Recommend a 6-layer stackup (signal/GND/power/power/GND/signal) given DDR-adjacent routing off the SODIMM edge and the DSI differential pairs.
- This document assumes the SoM handles all DDR/eMMC/power-sequencing complexity — if you later want to eliminate the SODIMM socket for a lower per-unit BOM cost at very high volume, that requires a second design pass to place the RK356x BGA directly on this board (raw SoC bring-up), which is a materially larger effort.
- **Rev B additions, still open:**
  - Verify the CFG resistor value against the exact PD sink IC's datasheet CFG/voltage-select table (a placeholder value, not calculated, is in the schematic/BOM).
  - Bench-verify the +12V_PROT holdup time after VBUS loss (bumped C1 to 470µF as a starting estimate) is actually long enough for the SoM to detect the sense GPIO going low and begin a clean shutdown before the 5V rail collapses.
  - Confirm the PD sink IC actually lands on 12V with real chargers — some USB-C PD sources don't offer every fixed voltage, and CH224K-class ICs fall back to a lower voltage (often 5V) if the requested one isn't available; if that fallback is common in practice, U1's buck converter and the downstream rails need to tolerate a 5V input too, or a higher-priority PDO request should be chosen.
  - Since this is now a standalone/portable unit rather than a dash-mounted one (no double-DIN assumption), the existing "mechanical/enclosure check" open item applies to a handheld/portable enclosure instead — connector placement (USB-C, USB-A, AUX/mic jacks, SMA antenna) should be re-verified against real enclosure dimensions once one is chosen.

See the companion BOM: `docs/pcb_carrier_board_bom.xlsx`.
