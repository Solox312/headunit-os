# Physical Hardware Assembly & Car Installation Guide

This guide provides step-by-step instructions for physically assembling, wiring, and installing your **10.1" Raspberry Pi Head Unit** into your vehicle dashboard.

---

## 🛠️ Assembly & Installation Overview

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

---

## 📋 Step-by-Step Installation Instructions

### Step 1: Workbench Bench Test (Test Before Mounting in Car)
*Always test all components on your desk before installing behind your car dashboard!*

1. **Connect Display Driver Board**:
   - Carefully connect the FPC ribbon cable from the 10.1" LCD panel to the HDMI Driver Control Board and lock the ZIF connector latch.
2. **Connect Video (HDMI)**:
   - Plug a short HDMI cable from the Raspberry Pi HDMI-0 port to the HDMI port on the Display Driver Board.
3. **Connect Touchscreen Input (USB)**:
   - Plug the Micro-USB cable from the `TOUCH` port on the Display Driver Board to any USB port on the Raspberry Pi.
4. **Power Test**:
   - Power the Pi and screen via USB. Verify the display turns on, Raspberry Pi OS boots, and touchscreen taps respond.

---

### Step 2: Power Supply Installation & Safe Shutdown

> [!CAUTION]
> **Preventing Filesystem Corruption:** Simply unplugging or cutting 5V power to the Raspberry Pi when turning off the ignition is the **#1 cause of failed car Pi projects**. Abrupt power loss during background disk writes eventually corrupts the MicroSD card. Choose one of the power methods below.

#### **Method 1: Intelligent Automotive Power HAT (Primary Standard — 100% Corruption Proof)**
Use a dedicated automotive power supply HAT (**CarPiHAT**, **StromPi 3**, or **Mausberry Switch**):
1. **Constant 12V (Battery)**: Connect to an unswitched battery fuse via Add-a-Fuse tap.
2. **Switched 12V (ACC / Ignition)**: Connect to an ignition switched fuse via Add-a-Fuse tap.
3. **Ground (GND)**: Connect to a bare metal chassis bolt.

* **Graceful Shutdown Sequence**:
  - Turning key **OFF** cuts power to the Switched 12V line.
  - The HAT pulls GPIO 26 LOW while keeping Constant 12V power alive.
  - The background `car-shutdown.service` (`scripts/shutdown_listener.py`) detects the LOW signal, holds 3 seconds to debounce engine cranking, and executes `sudo shutdown -h now`.
  - Once the Pi safely halts, the HAT detects the halt state and cuts 5V power completely, avoiding battery drain!

#### **Method B: Hardwiring 12V-to-5V Step-Down Converter (Clean Hidden Install)**
1. Locate your car's interior fuse box (under dashboard / glove box).
2. Insert an **Add-a-Fuse Tap** into an **ACC (Ignition Switched)** fuse slot.
3. Crimp the **RED (+)** wire of a 12V-to-5V 5A DC converter to the Fuse Tap.
4. Connect the **BLACK (-)** wire to a metal chassis bolt ground.
5. **Crucial:** Enable **OverlayFS (Read-Only Mode)** in Raspberry Pi OS via `sudo raspi-config` so RAM handles all temporary writes and abrupt power loss will not corrupt the SD card.

#### **Method C: 12V Cigarette Lighter Outlet (Easiest — Plug & Play)**
1. Plug a **30W+ Dual USB-C Car Charger** into your car's 12V outlet.
2. Run a **USB-C Cable** to the Raspberry Pi power port.
3. Run a **Micro-USB Cable** to the 10.1" Display Driver Board power port.
4. **Crucial:** Enable **OverlayFS (Read-Only Mode)** in Raspberry Pi OS via `sudo raspi-config`.

---

### Step 3: Car Audio Wiring & Ground Loop Isolation

Choose your preferred audio method:
* **Option A (AUX Cable)**: Plug the **USB 3.5mm DAC** into an RPi USB port, plug a **3.5mm Ground Loop Isolator** inline with the audio cable, and connect into your car's AUX input port.

> [!IMPORTANT]
> **Ground Loop Isolator (Crucial for AUX Audio)**: When you power the Raspberry Pi from the car's electrical system (12V cigarette lighter or hardwired DC converter) and plug directly into the car's Aux port, a ground loop is created between the Pi power ground and audio ground. This causes a high-pitched whining noise that gets louder as engine RPM rises (**alternator whine**). Inserting a inexpensive ~$8-$10 3.5mm Ground Loop Isolator inline with your Aux cable uses audio isolation transformers to 100% eliminate this hum/whine.

* **Option B (Bluetooth A2DP)**: Pair the RPi to your car's factory Bluetooth stereo in **Settings -> Audio Target**.
* **Option C (FM Transmitter)**: Plug a USB FM Transmitter into the Pi and set your car radio to `88.3 FM`.

---

### Step 4: Microphone Installation (Voice Commands)

1. Plug a **USB Mini Microphone** into an open USB port on the Raspberry Pi.
2. Extension wire option: Route an external mic wire up the driver A-pillar trim or clip it near the steering column / sun visor for clear voice pick-up when using Google Assistant or Siri.

---

### Step 5: Dashboard Mounting

1. **Mounting Bracket**: Secure the 10.1" screen inside a **Universal 2-DIN (Double-DIN)** floating trim bezel or 3D-printed dashboard bracket.
2. **Securing the Pi**: Use heavy-duty dual-lock Velcro or zip ties to secure the Raspberry Pi and cables neatly behind the double-DIN radio opening.
3. **Re-assemble Trim**: Snap your car's dashboard trim panels back into place.

---

### 🚦 Step 6: Final Verification Checklist

* [ ] Turn key to ACC ignition position — verify Raspberry Pi boots automatically (~10-12s).
* [ ] Verify Flutter Head Unit app launches full screen in Kiosk mode.
* [ ] Test 10.1" touchscreen tap responsiveness across all buttons.
* [ ] Connect phone wirelessly via Bluetooth/Wi-Fi — verify Android Auto / CarPlay launches.
* [ ] Play music track — verify clean audio output through car speakers.
* [ ] Turn car key off — verify clean power down.
