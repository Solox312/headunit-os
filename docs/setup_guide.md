# HeadUnit OS — Complete Setup Guide

**Information for use (instructions) — structured in accordance with IEC/IEEE 82079‑1:2019**

---

## Document identification

| Field | Value |
| :--- | :--- |
| **Document title** | HeadUnit OS — Complete Setup Guide |
| **Document type** | Information for use (installation, commissioning, operation, maintenance) |
| **Document identifier** | HUOS‑IFU‑001 |
| **Revision** | A (initial issue) |
| **Issue date** | 2026‑08‑08 |
| **Applies to product** | HeadUnit OS — DIY Raspberry Pi automotive head unit |
| **Applies to versions** | HeadUnit OS `master` branch; Raspberry Pi OS 64‑bit (Bookworm or Bullseye, Desktop) |
| **Language** | English (en) |
| **Publisher** | HeadUnit OS project (open source) |
| **Supersedes** | Consolidates `hardware_shopping_list.md`, `hardware_assembly_guide.md`, `rpi_setup_guide.md`, `carlinkit_dongle_guide.md`, `native_android_auto_protocol.md` |
| **Retention** | Keep this document for the service life of the product. |

---

## Table of contents

- [1. About this document](#1-about-this-document)
- [2. Safety](#2-safety)
- [3. Product description](#3-product-description)
- [4. Scope of delivery and required parts](#4-scope-of-delivery-and-required-parts)
- [5. Transport and storage](#5-transport-and-storage)
- [6. Assembly and installation](#6-assembly-and-installation)
- [7. Commissioning — software setup](#7-commissioning--software-setup)
- [8. Operation](#8-operation)
- [9. Troubleshooting](#9-troubleshooting)
- [10. Maintenance](#10-maintenance)
- [11. Decommissioning and disposal](#11-decommissioning-and-disposal)
- [12. Technical data](#12-technical-data)
- [13. Terms and abbreviations](#13-terms-and-abbreviations)
- [14. Related documents and feedback](#14-related-documents-and-feedback)

---

## 1. About this document

### 1.1 Purpose and scope

This document is the single, complete set of instructions for building, installing, commissioning, operating, maintaining and disposing of a **HeadUnit OS** automotive touchscreen head unit based on a Raspberry Pi 4 or Raspberry Pi 5.

It covers the full life cycle:

- selection and procurement of parts (Clause 4),
- mechanical assembly and 12 V vehicle electrical connection (Clause 6),
- operating system installation, application build and kiosk configuration (Clause 7),
- phone projection setup — native wireless Android Auto and Carlinkit dongle (Clause 7.7 and 7.8),
- normal use, fault clearance, maintenance and disposal (Clauses 8 to 11).

**Out of scope:** modification of vehicle safety systems (airbags, SRS wiring, CAN bus, steering‑wheel control decoding), development of the Flutter application source code, and legal/regulatory approval of the installation in your jurisdiction.

### 1.2 Intended user groups and required competence

| User group | Tasks | Required competence |
| :--- | :--- | :--- |
| **Builder / installer** | Clauses 4, 6, 7 | Able to use a multimeter, strip and crimp automotive wire, identify a fuse box, remove and refit dashboard trim, and follow Linux command‑line instructions. Basic electrical safety knowledge. |
| **Commissioner** | Clause 7 | Comfortable with a Linux shell, `systemd`, text editors (`nano`), and SSH. |
| **Operator / driver** | Clause 8 | No special competence. Must hold a valid driving licence and know local distracted‑driving law. |
| **Maintainer** | Clauses 9, 10, 11 | As for builder/installer. |

> [!IMPORTANT]
> If you are not confident working on your vehicle's 12 V electrical system, have Clause 6.3 (power supply wiring) performed by a qualified automotive electrician. Everything else in this guide can be done by a competent hobbyist.

### 1.3 How to use this document

1. Read **Clause 2 (Safety) in full before starting.** It is not optional.
2. Procure parts using Clause 4.
3. Perform the **bench test (6.2) before anything is installed in the vehicle.** Do not skip it.
4. Work through Clauses 6 and 7 in order. Each clause states its prerequisites.
5. Keep Clause 9 (Troubleshooting) to hand during first start‑up.

### 1.4 Conventions used

| Convention | Meaning |
| :--- | :--- |
| `monospace` | Text you type, file paths, commands, file contents. |
| **Bold** | Physical components, UI controls, menu items. |
| ▸ | A sequence through menus, e.g. **Performance Options ▸ Overlay File System**. |
| ☐ | A checklist item to be verified before proceeding. |

### 1.5 Structure of safety messages

Safety messages in this document follow the four‑part structure required by IEC/IEEE 82079‑1: **signal word — type of hazard — consequence of ignoring — how to avoid.**

| Signal word | Meaning |
| :--- | :--- |
| **DANGER** | Hazardous situation which, if not avoided, **will** result in death or serious injury. |
| **WARNING** | Hazardous situation which, if not avoided, **could** result in death or serious injury. |
| **CAUTION** | Hazardous situation which, if not avoided, could result in minor or moderate injury. |
| **NOTICE** | Practice not related to personal injury — property damage, data loss, or equipment damage. |

---

## 2. Safety

### 2.1 Intended use

HeadUnit OS is intended for use as an **aftermarket infotainment display** in a private road vehicle, mounted in a standard Double‑DIN dashboard aperture, powered from the vehicle's 12 V DC electrical system, and providing media playback, vehicle status display and smartphone projection (Android Auto / Apple CarPlay).

### 2.2 Reasonably foreseeable misuse

This product is **not** intended for and must **not** be used for:

- displaying video content visible to the driver while the vehicle is in motion;
- replacing, bridging or interfering with any factory safety, warning or instrument system;
- connection to the vehicle CAN bus, SRS/airbag circuits, or ABS wiring;
- use as a source of safety‑critical information (speed, fuel level, warning lamps) — the on‑screen gauges are informational only;
- use in commercial, marine, aviation, or off‑road competition vehicles without separate assessment;
- powering any load other than the components listed in Clause 4.

### 2.3 General safety messages

> [!CAUTION]
> **CAUTION — Driver distraction.**
> Operating a touchscreen while driving diverts attention from the road and can cause a collision resulting in injury or death.
> Complete all configuration while the vehicle is **parked with the parking brake applied**. While driving, use only voice control or a single‑tap action. Obey all local laws on device use while driving.

> [!WARNING]
> **WARNING — Obstruction of airbags, controls or view.**
> A display or bracket installed over an airbag deployment path, over a control, or in the driver's forward field of view can prevent airbag deployment or obstruct vehicle control, causing serious injury.
> Mount the display only in the factory Double‑DIN radio aperture or an equivalent location approved by your vehicle manufacturer. Never mount over an "SRS AIRBAG" marked panel. Verify that all dashboard controls, vents and the windscreen view remain unobstructed.

> [!WARNING]
> **WARNING — Vehicle electrical short circuit and fire.**
> The vehicle battery can deliver hundreds of amperes into a short circuit. An unfused or incorrectly grounded connection can melt wiring and start a fire.
> Disconnect the vehicle battery negative terminal before any wiring work. Use an **Add‑a‑Fuse tap** with a fuse rated no higher than the converter's rating (typically 5 A) on every 12 V feed. Ground only to a bare, unpainted chassis bolt. Insulate every splice with heat‑shrink. Never tap a fuse feeding an airbag, ABS or engine‑management circuit.

> [!CAUTION]
> **CAUTION — Hot surfaces and burns.**
> A Raspberry Pi 5 under sustained load, and a DC‑DC converter, reach temperatures that can burn skin. Enclosed dashboards in hot climates make this worse.
> Allow 10 minutes for cooling before handling after use. Ensure at least 10 mm of free air around the Pi and converter, and do not wrap them in foam or fabric.

> [!CAUTION]
> **CAUTION — Sharp edges and glass.**
> The bare LCD panel has exposed glass edges and a fragile FPC ribbon cable. Handling can cause cuts.
> Handle the panel by its frame. Wear gloves when routing the panel. Do not flex the ribbon cable.

> [!NOTICE]
> **NOTICE — MicroSD card corruption from abrupt power loss.**
> Cutting 5 V power to the Raspberry Pi while Linux is writing to the card corrupts the filesystem. This is the single most common cause of failed car‑Pi projects.
> Implement **exactly one** of the protection methods in Clause 6.3 before daily use. Do not defer this step.

> [!NOTICE]
> **NOTICE — Battery discharge.**
> A Raspberry Pi connected to a permanently live (constant 12 V) circuit without a shutdown mechanism will flatten the vehicle battery in a few days.
> Use the intelligent power HAT method (6.3.1), which cuts 5 V after halt, or connect only to an ignition‑switched (ACC) circuit.

### 2.4 Regulatory note — FM transmitter

> [!NOTICE]
> **NOTICE — Radio transmission compliance.**
> The optional FM transmitter audio path (Clause 7.6, Option C) is a radio transmitter. Legal power limits and permitted frequencies vary by country, and some jurisdictions prohibit these devices entirely.
> Use only a transmitter certified for your country, and select an unused frequency. Compliance is the installer's responsibility.

### 2.5 Personal protective equipment and tools

- Safety glasses (when working under the dashboard).
- Cut‑resistant gloves (when handling the bare LCD panel).
- Insulated wire strippers, ratcheting crimp tool, heat‑shrink and heat gun.
- Digital multimeter (for identifying constant vs. switched 12 V circuits).
- Plastic trim removal tools (to avoid damaging dashboard panels).
- Vehicle owner's manual and fuse box legend.

---

## 3. Product description

### 3.1 Function

HeadUnit OS is a Flutter application running full‑screen ("kiosk mode") on Raspberry Pi OS. It provides:

- **Dark glassmorphism automotive UI** with large tap targets (64 px primary, 48 px secondary), designed for legibility at night.
- **Dual projection engine** — a native software receiver (Bluetooth RFCOMM + 5 GHz Wi‑Fi AP, no dongle) and a Carlinkit USB hardware bridge; auto‑detect selects the dongle when present and otherwise falls back to native wireless.
- **Multi‑target audio routing** — 3.5 mm DAC/AUX, vehicle Bluetooth A2DP, FM transmitter, or HDMI.
- **Ignition power management** — auto‑boot on key‑on, graceful halt on key‑off via GPIO.
- **Responsive display scaling** for 1280×800, 1024×600, 1280×720 and 7″ panels.

### 3.2 System block diagram

```
                          ┌────────────────────────────────────────────────────────┐
                          │                YOUR CAR DASHBOARD                      │
                          └───────────────────────────┬────────────────────────────┘
                                                      │
 ┌────────────────────────────────────────────────────▼────────────────────────────────────────────────────┐
 │ 10.1" TOUCHSCREEN DISPLAY (Front Dash)                                                                  │
 │  ┌──────────────────────────────────┐        HDMI Cable        ┌──────────────────────────────────────┐ │
 │  │ 10.1" LCD Panel (235mm x 143mm)  ├─────────────────────────►│ Raspberry Pi 4 / 5                   │ │
 │  │ & Driver Control Board           │     USB Touch Cable      │ (Mounted behind screen)              │ │
 │  │                                  ├─────────────────────────►│                                      │ │
 │  └──────────────────────────────────┘                          └──────┬────────────┬───────────┬──────┘ │
 └───────────────────────────────────────────────────────────────────────┼────────────┼───────────┼────────┘
                                                                         │            │           │
                          ┌──────────────────────────────────────────────┘            │           └─────────────────────────────────────────────┐
                          │ USB Audio                                                 │ USB Power                                               │ USB Dongle
                          ▼                                                           ▼                                                         ▼
        ┌─────────────────────────────────────┐                     ┌────────────────────────────────────┐                    ┌─────────────────────────────────────┐
        │ USB 3.5mm Hi-Fi DAC Audio Adapter   │                     │ 12V-to-5V Power Supply Converter   │                    │ Carlinkit Wireless USB Dongle       │
        └──────────────────┬──────────────────┘                     │ (Car Outlet or Fuse Tap)           │                    │ (Tucked behind dashboard)           │
                           │ 3.5mm Aux Cable                        └────────────────────────────────────┘                    └─────────────────────────────────────┘
                           ▼
        ┌─────────────────────────────────────┐
        │ 3.5mm Ground Loop Noise Isolator    │ ⚡ (Eliminates Alternator Whine)
        └──────────────────┬──────────────────┘
                           │ 3.5mm Jack
                           ▼
        ┌─────────────────────────────────────┐
        │ Car's AUX Input Port                │
        └─────────────────────────────────────┘
```

### 3.3 Software architecture

```
lib/
├── main.dart / app.dart          # Entry point, MultiProvider + MaterialApp
├── theme/                        # automotive_theme.dart, automotive_colors.dart
├── models/                       # media_item, vehicle_status, projection_state
├── providers/                    # media_provider, vehicle_provider, projection_provider
├── services/
│   ├── projection_bridge.dart    # Carlinkit dongle USB bridge
│   └── android_auto_engine.dart  # Native wireless AOA 2.0 + BT/Wi-Fi engine
├── screens/                      # main_navigation, dashboard, projection, media, vehicle, settings
└── widgets/                      # nav_dock, glass_card, gauge_widget, projection_simulator_canvas
scripts/
├── shutdown_listener.py          # GPIO ignition monitor daemon
└── car-shutdown.service          # systemd unit for the above
```

### 3.4 Projection engine selection

| Engine | Hardware cost | Phones supported | Notes |
| :--- | :--- | :--- | :--- |
| **Native wireless** | $0 | Android (wireless Android Auto) | Uses the Pi's own Bluetooth + 5 GHz Wi‑Fi AP. See 7.8. |
| **Carlinkit CPC200 dongle** | $38 – $48 | iPhone (CarPlay) and Android (Android Auto), wireless or wired | Hardware bridge over USB. See 7.7. |
| **Auto‑detect** | — | Both | Uses the dongle when plugged in, otherwise native wireless. Default. |
| **Simulator mode** | — | — | Test the full UI on Windows/macOS/Linux with no dongle or phone. |

---

## 4. Scope of delivery and required parts

HeadUnit OS is distributed as source code only. All hardware must be procured separately.

### 4.1 Core parts list

| # | Component | Est. price | Notes and recommendations |
| :--- | :--- | :--- | :--- |
| 1 | **Raspberry Pi 4 (4 GB/8 GB)** or **Raspberry Pi 5** | $55 – $80 | RPi 4 4 GB or RPi 5 4 GB gives smooth 60 fps performance. |
| 2 | **10.1″ LCD capacitive touch monitor + HDMI driver board** | $32 – $45 | 235 mm × 143 mm, HDMI driver board plus USB touch cable (Waveshare or equivalent). |
| 3 | **Intelligent automotive power HAT** (CarPiHAT / StromPi 3 / Mausberry) | $20 – $40 | **Recommended (Method 1, 6.3.1):** 3‑wire ignition setup for safe shutdown and zero SD corruption. |
| 4 | **32 GB or 64 GB MicroSD card (A2, Class 10)** | $8 – $12 | SanDisk Extreme or Samsung EVO Select. A2 rating matters for boot speed. |
| 5 | **USB 3.5 mm Hi‑Fi DAC + 3.5 mm ground loop isolator** | $15 – $22 | **Essential for AUX audio.** Prevents ground loop / alternator whine when the Pi is powered from vehicle 12 V. |
| 6 | **Carlinkit CPC200‑CCPA wireless USB dongle** | $38 – $48 | *Optional.* Dual wireless CarPlay + wireless Android Auto hardware bridge. |
| 7 | **USB mini microphone** | $6 – $10 | For hands‑free Google Assistant / Siri. |
| 8 | **Universal 10.1″ Double‑DIN dash mount kit** | $12 – $20 | Universal 2‑DIN frame to fit the display into the dash. |

### 4.2 Cables and wiring accessories

1. **Short HDMI cable or ribbon** (0.3 m / 1 ft) — Pi HDMI to display driver board.
2. **Micro‑USB to USB‑A cable** — driver board `TOUCH` port to a Pi USB port.
3. **3.5 mm AUX stereo audio cable** (≈1 m / 3 ft) — DAC to vehicle AUX input.
4. **3.5 mm ground loop noise isolator** ($8 – $10) — inline between DAC output and vehicle AUX jack. Do not omit.
5. **Inline Add‑a‑Fuse tap (12 V)** — for safe fuse‑box power delivery.
6. **Heat‑shrink tubing, crimp terminals, ring terminal** for the chassis ground.

### 4.3 Budget summary

- **Minimum build** (native wireless, AUX audio): **≈ $125 – $150**
- **Deluxe build** (RPi 5, Carlinkit dongle, USB DAC, mount kit): **≈ $185 – $220**

For comparison, commercial equivalents run $600 – $1,200.

### 4.4 Incoming inspection

Before assembly, confirm:

- ☐ MicroSD card is genuine and reports its stated capacity.
- ☐ LCD panel glass is free of cracks and the FPC ribbon is undamaged.
- ☐ Power HAT or DC‑DC converter is rated **5 V, 5 A (25 W) minimum**.
- ☐ Ground loop isolator is present (this is the part most often forgotten).

---

## 5. Transport and storage

- Store the LCD panel flat, in antistatic packaging, away from pressure on the glass.
- Handle the Raspberry Pi and HAT by their edges; observe ESD precautions.
- Storage temperature: −20 °C to +60 °C, non‑condensing.
- Do not leave a MicroSD card in a vehicle in direct sun above +70 °C.

---

## 6. Assembly and installation

> **Prerequisite:** Clause 2 read in full. Parts from Clause 4 to hand. Vehicle parked on level ground, engine off, parking brake applied.

### 6.1 Installation overview

| Step | Clause | Location | Approx. time |
| :--- | :--- | :--- | :--- |
| 1 | 6.2 | Workbench | 30 min |
| 2 | 6.3 | Vehicle fuse box | 60 – 120 min |
| 3 | 6.4 | Vehicle audio | 20 min |
| 4 | 6.5 | Vehicle cabin | 20 min |
| 5 | 6.6 | Dashboard | 45 – 90 min |
| 6 | 6.7 | Vehicle | 15 min |

### 6.2 Step 1 — Workbench bench test

> [!IMPORTANT]
> Always test every component on a bench **before** installing anything behind the dashboard. Diagnosing a faulty ribbon cable is a five‑minute job on a desk and a two‑hour job under a dash.

1. **Connect the display driver board.**
   Connect the FPC ribbon cable from the 10.1″ LCD panel to the HDMI driver control board and lock the ZIF connector latch.

   > [!CAUTION]
   > **CAUTION — Fragile ribbon cable.** Forcing or flexing the FPC ribbon tears its conductors, permanently destroying the panel. Insert the ribbon square, contacts facing the correct way, then close the latch with light finger pressure only.

2. **Connect video (HDMI).**
   Plug the short HDMI cable from the Raspberry Pi `HDMI‑0` port to the HDMI input on the driver board.

3. **Connect touch input (USB).**
   Plug the Micro‑USB cable from the `TOUCH` port on the driver board to any USB port on the Raspberry Pi.

4. **Power test.**
   Power the Pi and the screen from a bench USB supply.

   Verify:
   - ☐ Backlight illuminates.
   - ☐ Raspberry Pi OS boots to desktop.
   - ☐ Touch taps register at the correct on‑screen position.

   If the display stays dark, go to Clause 9, symptom "Display remains black".

### 6.3 Step 2 — Power supply installation and safe shutdown

> [!WARNING]
> **WARNING — Short circuit and fire during wiring.**
> Working on live 12 V circuits can cause a short circuit, melted wiring and fire.
> **Disconnect the vehicle battery negative terminal before starting**, and reconnect it only after all splices are insulated.

Choose **one** of the three methods below. Methods B and C additionally **require** OverlayFS (Clause 7.9).

#### 6.3.1 Method 1 — Intelligent automotive power HAT (recommended, corruption‑proof)

Use a dedicated automotive power HAT: **CarPiHAT**, **StromPi 3** or **Mausberry Switch**.

**3‑wire connection at the fuse box:**

| Wire | Connect to | Purpose |
| :--- | :--- | :--- |
| **Constant 12 V** | Unswitched (always‑live) fuse, via Add‑a‑Fuse tap | Keeps the HAT alive during the shutdown sequence |
| **Switched 12 V (ACC/ignition)** | Ignition‑switched fuse, via Add‑a‑Fuse tap | Detects key position; triggers boot and shutdown |
| **Ground (GND)** | Bare metal chassis bolt (paint scraped back) | Return path |

Use a multimeter to confirm which fuses are constant and which are switched: a switched fuse reads ≈12 V with the key at ACC and ≈0 V with the key out.

**Graceful shutdown sequence:**

```
Key ON  ──► Switched 12V energises HAT ──► HAT powers Pi from Constant 12V ──► Pi boots (~10-12 s)

Key OFF ──► Switched 12V drops
        ──► HAT pulls GPIO 26 LOW, 5V still alive
        ──► car-shutdown.service detects LOW, waits 3 s (debounces cranking)
        ──► executes `sudo shutdown -h now`
        ──► Pi halts; HAT detects halt and cuts 5V completely (no battery drain)
```

Software for this method is installed in Clause 7.10.

#### 6.3.2 Method B — Hardwired 12 V‑to‑5 V step‑down converter (clean hidden install)

1. Locate the interior fuse box (under dashboard or glove box).
2. Insert an **Add‑a‑Fuse tap** into an **ACC (ignition‑switched)** fuse slot.
3. Crimp the **RED (+)** wire of a 12 V→5 V 5 A DC‑DC converter to the fuse tap.
4. Connect the **BLACK (−)** wire to a bare metal chassis bolt.
5. **Mandatory:** enable **OverlayFS** per Clause 7.9.

#### 6.3.3 Method C — 12 V accessory (cigarette lighter) outlet (easiest)

1. Plug a **30 W+ dual USB‑C car charger** into the 12 V outlet.
2. Run a **USB‑C cable** to the Raspberry Pi power port.
3. Run a **Micro‑USB cable** to the display driver board power port.
4. **Mandatory:** enable **OverlayFS** per Clause 7.9.

#### 6.3.4 Comparison

| | Method 1 (HAT) | Method B (hardwired) | Method C (12 V outlet) |
| :--- | :--- | :--- | :--- |
| Added cost | $20 – $40 | ≈$12 | ≈$10 |
| Wiring effort | High (3 wires) | Medium (2 wires) | None |
| SD protection | Graceful halt | OverlayFS required | OverlayFS required |
| Settings persist across reboot | **Yes** | No (OverlayFS) | No (OverlayFS) |
| Battery drain risk | None (HAT cuts 5 V) | None (ACC only) | None (outlet usually ACC) |

### 6.4 Step 3 — Audio wiring and ground loop isolation

Choose one audio path:

**Option A — AUX cable (best quality).**
Plug the **USB 3.5 mm DAC** into a Pi USB port → **3.5 mm ground loop isolator** inline → vehicle **AUX** input.

> [!IMPORTANT]
> **Ground loop isolator is essential for AUX audio.** When the Pi is powered from the vehicle's electrical system and also connected to the vehicle's AUX jack, a ground loop forms between the power ground and the audio ground. The result is a high‑pitched whine that rises and falls with engine RPM (**alternator whine**). An inexpensive ($8 – $10) 3.5 mm isolator uses audio transformers to break the loop and eliminates the noise completely.

**Option B — Bluetooth A2DP.** Pair the Pi to the vehicle's factory Bluetooth stereo, then select it in **Settings ▸ Audio Target**.

**Option C — FM transmitter.** Plug a USB FM transmitter into the Pi and tune the car radio to the matching frequency (e.g. 88.3 MHz). See the regulatory notice in Clause 2.4.

### 6.5 Step 4 — Microphone installation

1. Plug a **USB mini microphone** into a free Pi USB port.
2. For best voice pickup, route an extension up the driver‑side A‑pillar trim, or clip the mic near the steering column or sun visor.

> [!CAUTION]
> **CAUTION — Cable routing near airbags.** Cable run through an A‑pillar can be thrown by a deploying curtain airbag, causing injury. Route cables **behind** trim clips, never across an airbag seam, and never remove an airbag cover to route a wire.

### 6.6 Step 5 — Dashboard mounting

1. **Mounting bracket.** Secure the 10.1″ screen in a **Universal 2‑DIN (Double‑DIN)** floating trim bezel or a 3D‑printed dash bracket.
2. **Securing the Pi.** Fix the Raspberry Pi and cabling behind the Double‑DIN aperture with heavy‑duty dual‑lock hook fastener or zip ties. Nothing may be left loose.
3. **Thermal clearance.** Leave at least 10 mm of free air around the Pi and the DC converter.
4. **Refit trim.** Snap dashboard trim panels back into place, checking that no cable is pinched.

> [!WARNING]
> **WARNING — Loose objects in a collision.**
> An unsecured Raspberry Pi or converter becomes a projectile in a crash and can cause serious injury.
> Mechanically fasten every component. Do not rely on friction or gravity.

### 6.7 Step 6 — Final verification checklist

- ☐ Turn key to ACC — Raspberry Pi boots automatically (~10 – 12 s).
- ☐ HeadUnit OS launches full‑screen in kiosk mode.
- ☐ Touchscreen responds accurately across the whole panel.
- ☐ Phone connects wirelessly — Android Auto / CarPlay launches.
- ☐ Music plays cleanly through the vehicle speakers, with no whine at raised RPM.
- ☐ Turn key off — Pi halts cleanly and 5 V is removed.
- ☐ Driver's view, controls, vents and airbag paths are unobstructed.
- ☐ No warning lamps appeared on the instrument cluster after battery reconnection.

---

## 7. Commissioning — software setup

> **Prerequisite:** Bench test (6.2) passed. Work through 7.1 to 7.6 for every build; then 7.7 or 7.8 depending on projection engine; then 7.9 or 7.10 depending on the power method chosen in 6.3.

### 7.1 Prerequisites

- Raspberry Pi 4 (4 GB/8 GB) or Raspberry Pi 5.
- Touchscreen: official RPi 7″ DSI, Waveshare HDMI/DSI (1024×600 or 1280×720), or 10.1″ automotive display.
- MicroSD card 32 GB+, Class 10 / A2.
- Power supply: official 5 V 3 A (RPi 4) or 5 V 5 A (RPi 5) USB‑C — or a 12 V→5 V 5 A automotive converter.
- *(Optional)* Carlinkit / AutoKit CPC200‑CCPA or CPC200‑AutoKit dongle.
- A second computer with a card reader, and a home Wi‑Fi network for initial setup.

### 7.2 Install Raspberry Pi OS

1. Download and open **Raspberry Pi Imager**.
2. Select OS: **Raspberry Pi OS (64‑bit)** — Bookworm or Bullseye, **with Desktop**.
3. Open **OS Customisation** settings and set:
   - hostname, e.g. `rpi-headunit`
   - **Enable SSH** (password authentication)
   - username and password
   - your home Wi‑Fi SSID and password (for initial setup only)
4. Write the image to the MicroSD card, insert it in the Pi and boot.

> [!NOTICE]
> **NOTICE — Data loss on the target card.** Writing the image erases the selected drive completely. Confirm the drive letter/device before writing; selecting the wrong device destroys its contents irrecoverably.

### 7.3 Install build dependencies

On the Pi, in a terminal or over SSH:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Build essentials and Flutter Linux desktop dependencies
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
  libgl1-mesa-dev libglu1-mesa-dev libusb-1.0-0-dev libasound2-dev pulseaudio

# Utilities
sudo apt install -y git curl unzip redshift
```

### 7.4 Build the application (Linux ARM64)

```bash
cd ~
git clone https://github.com/your-username/headunit_os.git
cd headunit_os

flutter pub get
flutter build linux --release
```

The executable is produced at:

```
~/headunit_os/build/linux/arm64/release/bundle/headunit_os
```

Run it once manually to confirm it starts before configuring the kiosk service.

> [!NOTICE]
> **NOTICE — Path consistency.** Every path in Clauses 7.5 and 7.10 assumes the repository is cloned to `~/headunit_os` and the user is `pi`. If you clone elsewhere or use a different username, update the `WorkingDirectory`, `ExecStart` and script paths in the unit files to match, or the services will fail to start.

### 7.5 Configure kiosk auto‑start

1. Create a `systemd` **user** service:

```bash
mkdir -p ~/.config/systemd/user/
nano ~/.config/systemd/user/headunit.service
```

2. Contents:

```ini
[Unit]
Description=HeadUnit OS Kiosk
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
WorkingDirectory=/home/pi/headunit_os/build/linux/arm64/release/bundle
ExecStart=/home/pi/headunit_os/build/linux/arm64/release/bundle/headunit_os
Restart=always
RestartSec=3

[Install]
WantedBy=graphical-session.target
```

3. Enable it:

```bash
systemctl --user daemon-reload
systemctl --user enable headunit.service
```

4. Disable screen blanking, so the display never sleeps while driving:

```bash
mkdir -p ~/.config/autostart
nano ~/.config/autostart/noblank.desktop
```

```ini
[Desktop Entry]
Type=Application
Name=Disable Screen Saver
Exec=xset s off -dpms s noblank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
```

### 7.6 Tune display resolution

Edit `/boot/firmware/config.txt` (or `/boot/config.txt` on older OS releases):

```ini
# Force HDMI output for 10.1" capacitive touch display
hdmi_force_hotplug=1
max_usb_current=1
hdmi_group=2
hdmi_mode=87

# OPTION 1: 10.1" screen, 1280x800 (recommended)
hdmi_cvt=1280 800 60 6 0 0 0

# OPTION 2: 10.1" / 7" screen, 1024x600
# hdmi_cvt=1024 600 60 6 0 0 0

# OPTION 3: 10.1" screen, 1280x720 HD
# hdmi_cvt=1280 720 60 6 0 0 0
```

Enable exactly one `hdmi_cvt` line. Save and reboot.

**Touch driver:** connect the screen's USB touch cable directly to a Pi USB port. Raspberry Pi OS detects capacitive touch panels as standard HID input devices — no external driver is required.

### 7.7 Configure the Carlinkit USB dongle (hardware projection engine)

*Skip this clause if you are using the native wireless engine only.*

**How it works:** the CPC200 dongle bridges phone to Pi — it advertises a Bluetooth AP to negotiate Wi‑Fi credentials with the phone, receives H.264 video and PCM audio from iOS/Android, and outputs raw video/audio chunks over USB. The Pi returns normalised touch events `(x, y, action)`, which the dongle relays to the phone as native multi‑touch input.

```
 ┌────────────────────────┐         WebSocket / IPC         ┌─────────────────────────┐
 │   Flutter Head Unit    │ ◄─────────────────────────────► │ Carlinkit Daemon Service│
 │  (ProjectionScreen UI) │   JSON Events & Video Texture   │   (node-carplay/aasdk)  │
 └────────────────────────┘                                 └────────────┬────────────┘
                                                                         │ USB libusb
                                                                ┌────────▼────────────┐
                                                                │ Carlinkit USB Dongle│
                                                                └─────────────────────┘
```

**Grant raw USB access via `udev`:**

1. Create the rule file:

```bash
sudo nano /etc/udev/rules.d/99-carlinkit.rules
```

2. Add:

```ini
# Carlinkit / AutoKit CPC200 USB dongle permissions
SUBSYSTEM=="usb", ATTR{idVendor}=="13fd", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", MODE="0666", GROUP="plugdev"
```

3. Reload and join the `plugdev` group:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG plugdev $USER
```

Log out and back in for the group change to take effect.

> [!NOTICE]
> **NOTICE — Permissive USB rule.** `MODE="0666"` grants every local user read/write access to any device from those vendor IDs. On a single‑user head unit this is normally acceptable; if the Pi is shared, narrow the rule with a matching `ATTR{idProduct}` and drop the mode to `0660`.

**Video and audio routing:** the USB daemon extracts H.264 NAL units from the USB endpoint and streams them over a local WebSocket or Unix domain socket into the Flutter texture widget. PCM audio frames are handed to PulseAudio/ALSA, routing calls, navigation prompts and music to the vehicle speakers. A USB or 3.5 mm microphone carries Siri / Google Assistant voice back to the phone.

### 7.8 Configure the native wireless Android Auto engine (no dongle)

*Skip this clause if you are using a Carlinkit dongle only.*

This engine implements a wireless Android Auto receiver on the Pi's own Bluetooth and 5 GHz Wi‑Fi.

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
 │  ┌───────────────────────────┐           ┌──────────────────────────────┐   │
 │  │ 1. Bluetooth RFCOMM       │           │ 2. 5GHz Wi-Fi Direct / AP    │   │
 │  │    UUID: 0000fdf0-...     │           │    `hostapd` + `dnsmasq`     │   │
 │  └─────────────┬─────────────┘           └──────────────┬───────────────┘   │
 │                │                                        │                   │
 │  ┌─────────────▼────────────────────────────────────────▼───────────────┐   │
 │  │ 3. Protocol Buffer (Protobuf) Channel Multiplexer (Port 50001)       │   │
 │  │    ├─ Channel 0: System Control & Heartbeat                          │   │
 │  │    ├─ Channel 1: Wireless Video Stream (H.264 / AV1 via FFmpeg/V4L2) │   │
 │  │    ├─ Channel 2: Wireless Media Audio (PCM 48kHz to PulseAudio)      │   │
 │  │    ├─ Channel 3: Wireless Speech Audio (Microphone Input)            │   │
 │  │    ├─ Channel 4: Input Channel (Multi-touch & Hardware Keys)         │   │
 │  │    └─ Channel 5: Sensor Channel (Driving status & Night mode)        │   │
 │  └──────────────────────────────────────────────────────────────────────┘   │
 └──────────────────────────────────────▲──────────────────────────────────────┘
                                        │ 5GHz Wi-Fi Direct Stream
 ┌──────────────────────────────────────┴──────────────────────────────────────┐
 │                      YOUR ANDROID PHONE (In Pocket/Purse)                   │
 └─────────────────────────────────────────────────────────────────────────────┘
```

**Connection sequence:**

1. **Bluetooth RFCOMM handshake (BlueZ).** On start‑up the Pi advertises the Android Auto UUID `0000fdf0-0000-1000-8000-00805f9b34fb`. The phone connects over Bluetooth, and the Pi sends its 5 GHz AP credentials as JSON:

   ```json
   {
     "ssid": "RPi_HeadUnit_5G",
     "bssid": "B8:27:EB:AA:BB:CC",
     "passphrase": "AutomotiveWiFiSecretKey",
     "port": 50001,
     "ip": "192.168.43.1"
   }
   ```

2. **5 GHz Wi‑Fi handoff (hostapd).** The phone joins `RPi_HeadUnit_5G` and opens a TCP socket to `192.168.43.1:50001`.

3. **Encrypted stream.** Six Protobuf channels open: Channel 1 carries H.264 video at 60 fps into the Flutter `Texture` widget, Channel 2 carries 48 kHz PCM audio, and Channel 4 relays touch input back to the phone.

**Install the access point packages:**

```bash
sudo apt update
sudo apt install -y hostapd dnsmasq bluez
```

Configure the 5 GHz AP in `/etc/hostapd/hostapd.conf`:

```ini
ssid=RPi_HeadUnit_5G
hw_mode=a
channel=36
wpa=2
```

> [!IMPORTANT]
> **Change the default passphrase.** `AutomotiveWiFiSecretKey` is a published example value. Anyone within Wi‑Fi range who knows it can join the head unit's network. Set a unique WPA2 passphrase of at least 12 characters in `hostapd.conf` and in the JSON handshake payload before driving with this engine enabled.

### 7.9 SD card protection — OverlayFS (required for power Methods B and C)

Locks the card read‑only, so abrupt power loss cannot corrupt it.

1. Run `sudo raspi-config`.
2. Go to **4 Performance Options ▸ P3 Overlay File System**.
3. Select **YES** to enable the overlay filesystem.
4. Select **YES** to lock the boot partition read‑only.
5. `sudo reboot`.

**How it works:** all OS log writes and temporary files go to a RAM disk instead of physical flash. When power is cut at key‑off, RAM simply clears — with no risk of physical card corruption.

> [!NOTICE]
> **NOTICE — Read‑only trade‑off.** With OverlayFS enabled, *every* change made at runtime — paired Bluetooth devices, new Wi‑Fi networks, app settings — is lost on reboot. To make permanent changes, disable OverlayFS via `raspi-config`, reboot, make the edits, then re‑enable OverlayFS and reboot again.

### 7.10 Ignition shutdown service (required for power Method 1)

1. Install the GPIO library:

```bash
sudo apt update && sudo apt install -y python3-gpiozero
```

2. The repository provides the listener at `scripts/shutdown_listener.py`. It monitors BCM **GPIO 26** and, when the pin is held low for 3 continuous seconds (which debounces the voltage dip during engine cranking), executes `sudo shutdown -h now`.

> [!IMPORTANT]
> **Confirm the GPIO pin against your HAT's manual.** GPIO 26 is a common default, not a universal one. A wrong pin number means the Pi either never shuts down (battery drain, card corruption) or shuts down at random. Edit `IGNITION_PIN` in `scripts/shutdown_listener.py` if your HAT uses a different pin.

3. Install and enable the service:

```bash
sudo cp ~/headunit_os/scripts/car-shutdown.service /etc/systemd/system/car-shutdown.service
sudo systemctl daemon-reload
sudo systemctl enable car-shutdown.service
sudo systemctl start car-shutdown.service
```

Check the `ExecStart=` path inside `car-shutdown.service` matches your clone location before enabling.

4. **Verify before relying on it.** With the Pi on the bench, briefly ground GPIO 26 for more than 3 seconds and confirm the Pi halts.

> [!TIP]
> **Kernel overlay alternative (no Python).** If your HAT simply pulls a GPIO pin low, you can get kernel‑level shutdown with one line in `/boot/firmware/config.txt` instead of the service:
> ```ini
> dtoverlay=gpio-shutdown,gpio_pin=26,active_low=1
> ```
> Use either this **or** `car-shutdown.service` — not both.

### 7.11 Commissioning acceptance test

- ☐ Pi boots to HeadUnit OS kiosk without keyboard or mouse.
- ☐ Screen does not blank after 10 minutes idle.
- ☐ Display resolution matches the panel's native resolution with no black bars.
- ☐ Touch coordinates align with on‑screen controls at all four corners.
- ☐ Audio plays through the selected target in **Settings ▸ Audio Target**.
- ☐ Projection engine connects (dongle and/or native wireless as configured).
- ☐ Shutdown method verified (GPIO halt test, or OverlayFS confirmed active).

---

## 8. Operation

### 8.1 Start‑up and shutdown

| Action | Result |
| :--- | :--- |
| Turn key to ACC / start engine | Pi boots and HeadUnit OS opens full‑screen in ~10 – 12 s |
| Turn key off (Method 1) | GPIO signal triggers graceful halt after 3 s; HAT then cuts 5 V |
| Turn key off (Methods B/C) | Power is cut immediately; OverlayFS protects the card |

### 8.2 Screens

| Screen | Purpose |
| :--- | :--- |
| **Dashboard** | Home screen — clock, weather, quick launchers, projection stream, media |
| **Projection** | CarPlay / Android Auto viewport |
| **Media** | Audio player and visualiser |
| **Vehicle** | Gauges and climate |
| **Settings** | Receiver engine and audio target selection |

Navigation is via the left dock bar, which also carries the voice assistant button.

### 8.3 Selecting the projection engine

Open **Settings ▸ Receiver Engine** and choose:

- **Auto‑detect** (default) — uses the dongle when plugged in, otherwise native wireless.
- **Carlinkit dongle** — force the hardware bridge.
- **Native wireless** — force the software engine.
- **Simulator** — test the UI with no dongle or phone connected (useful on a desktop).

### 8.4 Selecting the audio target

Open **Settings ▸ Audio Target** and choose AUX / 3.5 mm DAC, car Bluetooth stereo (A2DP), FM transmitter, or HDMI speakers.

### 8.5 Operating limits

> [!CAUTION]
> **CAUTION — Use while driving.**
> Interacting with menus while the vehicle is moving causes driver distraction and can lead to a collision.
> Set the audio target, projection engine and destination **before** moving off. While driving, use voice control or single‑tap actions only.

---

## 9. Troubleshooting

Work down the table in order; the checks are arranged cheapest‑first.

| Symptom | Likely cause | Action |
| :--- | :--- | :--- |
| Display remains black, backlight off | Driver board unpowered | Confirm 5 V at the driver board; try a different USB supply/cable |
| Display black, backlight on | No HDMI signal or wrong mode | Set `hdmi_force_hotplug=1`; verify exactly one `hdmi_cvt` line is uncommented; reseat HDMI |
| Image displayed but no touch response | Touch USB not connected | Confirm the Micro‑USB from the `TOUCH` port reaches a Pi USB port; check `lsusb` for an HID device |
| Touch offset from the cursor | Resolution mismatch | Make `hdmi_cvt` match the panel's native resolution exactly; reboot |
| Black bars / wrong aspect ratio | Wrong CVT timing | Select the correct resolution option in Clause 7.6 |
| Pi does not boot at key‑on | No switched 12 V, or blown tap fuse | Multimeter‑check the ACC feed at ACC and at key‑out; check the Add‑a‑Fuse fuse |
| Pi never shuts down at key‑off | Wrong GPIO pin, or service not enabled | Confirm `IGNITION_PIN` against the HAT manual; `systemctl status car-shutdown.service` |
| Pi shuts down while cranking | Debounce too short | Increase `hold_time` in `shutdown_listener.py` above 3 s |
| Filesystem corrupt after a few weeks | No shutdown protection | Implement Method 1 (6.3.1) or OverlayFS (7.9); reflash the card |
| Whine that rises with engine RPM | Ground loop / alternator whine | Fit the **3.5 mm ground loop isolator** inline with the AUX cable (6.4) |
| No audio at all | Wrong audio target | Check **Settings ▸ Audio Target**; verify the DAC appears in `aplay -l` |
| App does not start at boot | Service path mismatch | `systemctl --user status headunit.service`; verify `WorkingDirectory`/`ExecStart` match your clone path |
| Screen blanks after idle | Autostart file missing | Recreate `~/.config/autostart/noblank.desktop` (7.5) |
| Dongle not detected | udev permissions | Confirm the rule file, reload udev, verify the user is in `plugdev`, log out and in |
| Wireless AA never connects | Wi‑Fi band or Bluetooth | Confirm `hw_mode=a` and a valid 5 GHz channel; confirm the phone supports wireless AA; `systemctl status hostapd` |
| Settings reset on every reboot | OverlayFS is enabled | Expected behaviour — disable OverlayFS to make changes, then re‑enable (7.9) |
| Vehicle battery flat after a few days | Pi on constant 12 V without halt | Move to ACC‑switched supply, or fix the Method 1 shutdown chain |

---

## 10. Maintenance

HeadUnit OS has no serviceable wear parts. Perform these checks periodically.

| Interval | Task |
| :--- | :--- |
| Monthly | Verify the Pi halts cleanly at key‑off; clean the touchscreen with a dry microfibre cloth. |
| Quarterly | Check that mounting fasteners are tight and no cable has chafed against trim. |
| Quarterly | With OverlayFS temporarily disabled: `sudo apt update && sudo apt full-upgrade`, then re‑enable. |
| Annually | Back up the MicroSD card image. A card in daily automotive use is a consumable. |
| Annually | Inspect the Add‑a‑Fuse tap and chassis ground for corrosion; re‑torque the ground bolt. |
| As needed | Rebuild after pulling code changes: `git pull && flutter pub get && flutter build linux --release`, then `systemctl --user restart headunit.service`. |

> [!NOTICE]
> **NOTICE — Update procedure with OverlayFS.** Attempting `apt upgrade` or `git pull` with OverlayFS enabled appears to succeed but is discarded at the next reboot. Always disable OverlayFS, reboot, update, then re‑enable and reboot.

Cleaning: use a dry or lightly dampened microfibre cloth. Do not use solvents, glass cleaner or alcohol on the touch panel, and never spray liquid directly at the screen.

---

## 11. Decommissioning and disposal

1. Halt the Pi (`sudo shutdown -h now`) and wait for the activity LED to stop.
2. Disconnect the vehicle battery negative terminal.
3. Remove the Add‑a‑Fuse tap and **refit the original fuse** to its original slot.
4. Remove the chassis ground and refit the original bolt to specification.
5. Remove the display, bracket and all cabling; refit factory trim and the original head unit.
6. Reconnect the battery and confirm no fault lamps are present.

**Disposal.** The Raspberry Pi, display, HAT and DC converter are **waste electrical and electronic equipment (WEEE)**. Do not place them in household waste. Take them to a designated WEEE collection point. Erase the MicroSD card before disposal — it may hold Wi‑Fi passphrases and paired‑device data.

---

## 12. Technical data

### 12.1 Electrical

| Parameter | Value |
| :--- | :--- |
| Vehicle supply voltage | 12 V DC nominal (negative earth) |
| Logic supply | 5 V DC |
| Required converter rating | 5 V, 5 A (25 W) minimum |
| Recommended tap fuse | 5 A (must not exceed converter rating) |
| Typical current draw | 1.5 – 3 A at 5 V, load dependent |
| Standby draw (Method 1, after halt) | Effectively zero — HAT removes 5 V |
| Ignition signal | BCM GPIO 26 (default), active low, `pull_up=True` |
| Shutdown debounce | 3 s continuous hold |

### 12.2 Display

| Parameter | Value |
| :--- | :--- |
| Panel size | 10.1″ (235 mm × 143 mm active area); 7″ also supported |
| Supported resolutions | 1280×800 (recommended), 1024×600, 1280×720 |
| Refresh rate | 60 Hz |
| Video interface | HDMI (`hdmi_group=2`, `hdmi_mode=87`, CVT timing) |
| Touch interface | USB HID capacitive multi‑touch (no driver required) |
| Mounting | Universal Double‑DIN (2‑DIN) aperture |

### 12.3 Computing platform

| Parameter | Value |
| :--- | :--- |
| SBC | Raspberry Pi 4 (4 GB/8 GB) or Raspberry Pi 5 |
| OS | Raspberry Pi OS 64‑bit, Bookworm or Bullseye, with Desktop |
| Application framework | Flutter, Linux ARM64 release build |
| Storage | 32 – 64 GB MicroSD, Class 10 / A2 |
| Boot to UI | ≈10 – 12 s |

### 12.4 Connectivity

| Parameter | Value |
| :--- | :--- |
| Native wireless AA — Bluetooth UUID | `0000fdf0-0000-1000-8000-00805f9b34fb` |
| Native wireless AA — AP | 5 GHz, `hw_mode=a`, channel 36, WPA2 |
| Native wireless AA — endpoint | `192.168.43.1:50001` (TCP) |
| Protobuf channels | 0 control, 1 video (H.264/AV1), 2 media audio (PCM 48 kHz), 3 speech audio, 4 input, 5 sensor |
| Dongle | Carlinkit CPC200‑CCPA / CPC200‑AutoKit over USB (`libusb`) |
| Dongle vendor IDs | `13fd`, `0b05`, `2e8a` |

### 12.5 Audio

| Parameter | Value |
| :--- | :--- |
| Targets | 3.5 mm DAC → AUX, Bluetooth A2DP, FM transmitter, HDMI |
| Audio stack | PulseAudio / ALSA |
| PCM format | 48 kHz |
| Required accessory | 3.5 mm ground loop isolator (AUX path) |

### 12.6 Environmental

| Parameter | Value |
| :--- | :--- |
| Operating temperature | 0 °C to +50 °C ambient (thermal throttling above this) |
| Storage temperature | −20 °C to +60 °C |
| Humidity | Non‑condensing |
| Ingress protection | None — indoor cabin use only |

### 12.7 UI design tokens (summary)

| Token | Hex | Role |
| :--- | :--- | :--- |
| Dash Black | `#0B0E14` | Base background |
| Panel Base | `#151B26` | Container background |
| Glass Panel | `#1B2230` | Elevated tiles |
| Stroke (hairline) | `#262E3D` | 1 px borders |
| Electric Cyan | `#00E5D4` | Primary accent, active states |
| Dongle Violet | `#B18CFF` | Hardware bridge indicator |
| Native Green | `#3DDC84` | Native wireless / status OK |
| Text Primary | `#E9EDF5` | Headings and body |

Typography: **Space Grotesk** (display, 700, 18 – 40 px), **Inter** (body, 400/600, 13 – 16 px), **JetBrains Mono** (data, 400/500, 10 – 13 px). Tiles use a 14 px radius. Minimum tap targets: 64 px primary, 48 px secondary. Full specification in [brand_identity_guide.md](brand_identity_guide.md).

---

## 13. Terms and abbreviations

| Term | Definition |
| :--- | :--- |
| **A2DP** | Advanced Audio Distribution Profile — Bluetooth stereo audio streaming. |
| **ACC** | Accessory — a vehicle circuit live only when the ignition key is at ACC or ON. |
| **Add‑a‑Fuse** | A piggy‑back tap that adds a separately fused circuit to an existing fuse slot. |
| **Alternator whine** | Engine‑speed‑dependent noise induced in audio by a ground loop. |
| **AOA** | Android Open Accessory protocol. |
| **Constant 12 V** | A vehicle circuit live at all times, independent of key position. |
| **Double‑DIN (2‑DIN)** | Standard 180 × 100 mm dashboard radio aperture. |
| **FPC** | Flexible printed circuit — the flat ribbon connecting the LCD to its driver board. |
| **GPIO** | General‑purpose input/output pin on the Raspberry Pi. |
| **Ground loop** | An unintended current path between two ground references, producing audible noise. |
| **HAT** | Hardware Attached on Top — a Raspberry Pi expansion board. |
| **Kiosk mode** | Full‑screen single‑application operation with no desktop chrome. |
| **NAL unit** | Network Abstraction Layer unit — an H.264 video packet. |
| **OverlayFS** | A union filesystem that redirects writes to RAM, protecting the SD card. |
| **Protobuf** | Protocol Buffers — Google's binary serialisation format. |
| **RFCOMM** | Bluetooth serial port emulation profile. |
| **SBC** | Single‑board computer. |
| **SRS** | Supplemental Restraint System — the airbag system. |
| **WEEE** | Waste Electrical and Electronic Equipment. |
| **ZIF** | Zero insertion force — the latching connector type used for FPC ribbons. |

---

## 14. Related documents and feedback

### 14.1 Companion documents

| Document | Content |
| :--- | :--- |
| [README.md](../README.md) | Project overview, feature summary, desktop development setup. |
| [brand_identity_guide.md](brand_identity_guide.md) | Full visual identity, colour tokens, typography, UI motifs, voice. |
| [hardware_shopping_list.md](hardware_shopping_list.md) | Source detail for Clause 4. |
| [hardware_assembly_guide.md](hardware_assembly_guide.md) | Source detail for Clause 6. |
| [rpi_setup_guide.md](rpi_setup_guide.md) | Source detail for Clause 7. |
| [carlinkit_dongle_guide.md](carlinkit_dongle_guide.md) | Source detail for Clause 7.7. |
| [native_android_auto_protocol.md](native_android_auto_protocol.md) | Source detail for Clause 7.8. |

### 14.2 Reference scripts

| File | Purpose |
| :--- | :--- |
| [scripts/shutdown_listener.py](../scripts/shutdown_listener.py) | GPIO ignition monitor daemon (Clause 7.10). |
| [scripts/car-shutdown.service](../scripts/car-shutdown.service) | `systemd` unit for the shutdown listener. |

### 14.3 Feedback on this document

Report errors, omissions or unclear instructions as an issue on the project repository. Include the document identifier (**HUOS‑IFU‑001**), revision (**A**) and the clause number.

### 14.4 Revision history

| Rev. | Date | Change | Author |
| :--- | :--- | :--- | :--- |
| A | 2026‑08‑08 | Initial issue. Consolidates the five hardware/software guides into a single 82079‑1 structured document; adds safety, troubleshooting, maintenance, disposal, technical data and glossary clauses. | HeadUnit OS project |

---

*This document is provided as‑is under the project's licence. The installer is responsible for compliance with local vehicle, electrical and radio regulations, and for the safety of the completed installation.*
