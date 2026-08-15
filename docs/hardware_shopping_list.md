# HeadUnit OS — Master Bill of Materials (BOM) & Hardware List

**Information for Use (Instructions for Use) — Structured in accordance with IEC/IEEE 82079-1:2019 Standard**

---

## Document Identification

| Item | Specification |
| :--- | :--- |
| **Document Title** | HeadUnit OS — Master Bill of Materials (BOM) & Hardware List |
| **Document Type** | Hardware Reference / Specification |
| **Document Identifier** | HUOS-HW-001-REV-B |
| **Revision** | B |
| **Issue Date** | 2026-08-15 |
| **Applies to Product** | HeadUnit OS Custom Carrier Board (Rev B) |
| **Target Audience** | Hardware Engineers, Manufacturing Partners, Sourcing Specialists |
| **Language** | English (en-US) |

---

## Safety & Sourcing Warnings

> [!WARNING]
> **PCB / Schematic Rebuild Required for U8 (FM Transmitter):**
> The current schematic still retains the Si4713 placeholder footprint (QFN-20). The selected KT0803K transmitter is housed in a 16-pin SOP package which is **not** pin- or footprint-compatible. The schematic and layout must be modified before order placement.

> [!IMPORTANT]
> **OverlayFS Read-Only Requirement:**
> Because there is no constant-power backup line (BATT) in USB-C Power Delivery, a hard unplug cuts power immediately. Although bulk cap C1 (470µF) provides milliseconds of holdup for the comparator to trigger a shutdown sequence, **OverlayFS must be enabled** in Raspberry Pi OS / Radxa OS to prevent SD card corruption.

---

## 1. Bill of Materials (BOM) Breakdown

### 1.1 Power Input & Protection
Total Block Cost: **$2.39**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **U10** | USB-C PD sink/trigger controller | `CH224K` | Negotiates fixed 12V from USB-C charger. | 1 | $0.28 | $0.28 | WCH | LCSC C970725 | ESSOP-10 package. LCSC exclusive. |
| **R6** | VBUS-sense series resistor | `RC0402FR-0710KL` | Repurposed for VBUS-loss sense line divider input. | 1 | $0.02 | $0.02 | Yageo | Digi-Key 726523 | 10.0k ohm 1% 0402 thick-film, AEC-Q200. |
| **R4** | CC1 pull-up resistor | `RC0402FR-075K1L` | CC-line detection pull-up to VBUS_IN. | 1 | $0.02 | $0.02 | Yageo | Digi-Key 726624 | Matched pair with R5. Solder clearance check needed. |
| **R5** | CC2 pull-up resistor | `RC0402FR-075K1L` | CC-line detection pull-up to VBUS_IN. | 1 | $0.02 | $0.02 | Yageo | Digi-Key 726624 | Same as R4 above. |
| **D1** | TVS transient clamp diode | `SMAJ26A` | Transients clamp on post-negotiation 12V rail. | 1 | $0.13 | $0.13 | Littelfuse | Digi-Key 762290 / LCSC C148225 | DO-214AC (SMA) package. |
| **F1** | Resettable PTC fuse (3A) | `MF-MSMF300X-2` | Overcurrent protection downstream of PD sink. | 1 | $0.35 | $0.35 | Bourns | Digi-Key 16357596 | Confirmed active part. |
| **C1-C2** | Bulk input caps | `generic` | C1 (470µF electrolytic) + C2 (0.1µF ceramic). | 2 | $0.45 | $0.90 | any | generic | C1 gives holdup window after VBUS loss. |
| **J8** | USB-C receptacle (16-pin) | `USB4105-GF-A` | Sole power input + debug OTG port. | 1 | $0.67 | $0.67 | GCT | Digi-Key 11198510 | Right-angle mid-mount footprint. |

### 1.2 DC-DC Power Conversion
Total Block Cost: **$3.84**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **U1** | Synchronous buck converter | `LMR33630BQRNXRQ1` | Main 5V rail for SoM + peripherals. | 1 | $2.08 | $2.08 | Texas Instruments | Mouser (LMR33630BQRNXRQ1) | VQFN-HR 12-pin package. Confirm footprint. |
| **U2** | Buck converter (5V to 3.3V) | `TPS62203DBVR` | 3.3V rail for touch/FM/codec. | 1 | $0.91 | $0.91 | Texas Instruments | Digi-Key 296-39452-1-ND / LCSC C9051 | SOT-23-5 (5-pin). Confirm footprint. |
| **L1** | Power inductor (4.7µH, 3A) | `XAL4030-472MEB` | LMR33630 buck inductor. | 1 | $0.65 | $0.65 | Coilcraft | Digi-Key/Mouser | Do NOT substitute under-rated alternatives. |
| **L2** | Power inductor (2.2µH, ~0.5A) | `LPS3015-222MRC` | TPS62203 buck inductor. | 1 | $0.20 | $0.20 | Coilcraft | Digi-Key 12714700 / LCSC C2844756 | Confirmed active part. |

### 1.3 VBUS-Loss Sense & Safe Shutdown
Total Block Cost: **$1.58**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **U4** | Comparator | `TLV3201AIDBVR` | Converts 12V divider to GPIO LOW logic on VBUS loss. | 1 | $0.45 | $0.45 | Texas Instruments | LCSC C105188 | SOT-23-5 package. |
| **R1-R2** | Sense divider resistors | `R1: RC0402FR-07100KL` / `R2: RC0402FR-0722KL` | Dividers for protected 12V comparator sensing. | 2 | $0.02 | $0.04 | Yageo | Digi-Key (both) | 100k/22k 1% 0402 thick-film, AEC-Q200. |
| **R3, C7** | RC debounce (10k / 10µF) | `R3: RC0402FR-0710KL` / `C7: generic` | Debounces connector wiggle / brief VBUS dips. | 2 | $0.05 | $0.10 | Yageo (R3) | Digi-Key (R3) | R3 locked. C7 generic 10uF ceramic. |
| **U5** | Load switch (4A) | `TPS22965TDSGTQ1` | Disconnects 5V rail after clean OS halt. | 1 | $0.99 | $0.99 | Texas Instruments | Digi-Key 5176234 | 8-WSON 2x2mm. Extended-temp industrial grade. |

### 1.4 Compute (SoM)
Total Block Cost: **$102.98**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **SOM1** | 200-pin SODIMM socket | `1473005-4` | Socket for RK3566/RK3568 SODIMM SoM. | 1 | $2.98 | $2.98 | TE Connectivity | LCSC C428482 / Digi-Key 2187756 | Spec-matched DDR2 JEDEC MO-224 connector. |
| **SOM-MOD**| Radxa CM3S System-on-Module | `RM117-D8E32W` | Core compute module (8GB LPDDR4 / 32GB eMMC / WiFi & BT). | 1 | $100.00 | $100.00 | Radxa | Allnet China | Hard locked config. Check lead times for stock. |

### 1.5 Display Interface
Total Block Cost: **$39.97**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **J2** | 40-pin 0.5mm FPC connector | `TBD` | MIPI-DSI / I2C touch / Backlight connector. | 1 | $0.50 | $0.50 | TBD | TBD | Awaiting panel datasheet to lock mapping. |
| **PANEL1**| 10.1" IPS Touch Panel | `TBD` | 800x1280 4-lane MIPI-DSI display cell. | 1 | $38.00 | $38.00 | TBD | TBD | Bare panel. Awaiting panel datasheet to lock. |
| **U6** | Backlight boost LED driver | `TPS61165DRVR` | Backlight driver, PWM-dimmed from SoM. | 1 | $0.62 | $0.62 | Texas Instruments | LCSC C122568 | 6-pin WSON 2x2mm package. |
| **U9** | Ambient light sensor (I2C) | `VEML7700-TR` | Auto-brightness cabin lux sensor. | 1 | $0.85 | $0.85 | Vishay | Mouser 78-VEML7700-TR | Shared I2C bus. |

### 1.6 Audio Path
Total Block Cost: **$4.45**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **U7** | Stereo audio codec (I2S) | `WM8960CGEFL/RV` | Onboard DAC/ADC replaces external USB audio. | 1 | $1.60 | $1.60 | Cirrus Logic | Digi-Key 5409955 | Active QFN package. |
| **T1-T2** | Audio isolation transformer | `LM-NP-1001-B1L` | 1:1 stereo ground isolator (kills alternator whine). | 2 | $1.10 | $2.20 | Bourns | Digi-Key 3193348 | Swapped from obsolete LM-1547. THT footprint. |
| **J3** | 3.5mm TRS AUX jack | `SJ1-3523N` | Stereo line output to car AUX. | 1 | $0.35 | $0.35 | Same Sky | Digi-Key 738689 | CUI rebrand. Matches board mechanicals. |
| **J4** | 3.5mm mic jack | `SJ1-3524N` | Mic input jack/electret footprint. | 1 | $0.30 | $0.30 | Same Sky | Digi-Key 738688 | Matches J3 housing dimensions. |

### 1.7 FM Transmitter
Total Block Cost: **$1.65**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **U8** | FM transmitter (no RDS) | `KT0803K` | Broadcasts audio to vehicle FM radio receiver. | 1 | $0.90 | $0.90 | KTMicro | LCSC / Broker | SOP-16 package. Requires schematic rebuild. |
| **Y1** | 32.768kHz crystal | `ABS07-32.768KHZ-T` | Reference clock crystal for U8 transmitter. | 1 | $0.45 | $0.45 | Abracon | Digi-Key 1237009 | Confirm load-cap against KT0803K spec. |
| **J5** | U.FL antenna connector | `U-FL-R-SMT-1(10)` | Interface to external FM whip antenna. | 1 | $0.30 | $0.30 | Hirose | Digi-Key 2391570 / LCSC C88373 | Ultra-miniature SMT connector. |

### 1.8 USB Host / Debug
Total Block Cost: **$1.54**

| Ref Des | Component | Part Number (Locked) | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Distributor / SKU | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **J6-J7** | USB 2.0 Type-A connector | `UE27AC5410H` | Connectors for external CarPlay/AA dongles / mic. | 2 | $0.62 | $1.24 | Amphenol ICC | Digi-Key 1971914 / LCSC C3197982 | Through-hole right-angle. |
| **J9** | 4-pin UART debug header | `0022232041` | Console serial debugging access. | 1 | $0.20 | $0.20 | Molex | Digi-Key 26671 | KK 254 series 0.1" pitch. |
| **SD1** | microSD card slot | `TF-PUSH` | Recovery image flashing slot. | 1 | $0.10 | $0.10 | Shou Han | LCSC C393941 | Push-push design. No card-detect switch. |

### 1.9 PCB & Assembly
Total Block Cost: **$14.00**

| Component | Part / Service | Function | Qty | Est. Unit Cost (USD) | Est. Line Cost (USD) | Manufacturer | Sourcing Notes & Flags |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **PCB** | 6-layer carrier PCB | Controlled impedance board fab. | 1 | $8.00 | $8.00 | JLCPCB/PCBWay | Signal/GND/Power stackup. DSI differential routing. |
| **ASSY** | SMT assembly + testing | Per-unit assembly labor contract. | 1 | $6.00 | $6.00 | contract fab | Priced at 100+ unit quantities. |

---

## 2. Budget and Cost Summary

* **Estimated Total BOM Cost (Per Unit at 100+ qty):** **$172.40 USD**
* Custom PCB assembly consolidates RPi, DAC, and FM breakout into a single integrated board, reducing overall size and cabling dependencies.

---

## Document Revision History

| Revision | Date | Description of Change | Approved By |
| :--- | :--- | :--- | :--- |
| A | 2026-08-08 | Initial Master Hardware Shopping List (RPi 4/5 + Hat DIY). | HeadUnit OS Team |
| B | 2026-08-15 | Updated to custom Rev B carrier board Bill of Materials (BOM). Structured to IEC/IEEE 82079-1 standard. | HeadUnit OS Team |
