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
       │ (Plugs into Car's AUX Input Port)   │                     │ (Car Outlet or Fuse Tap)           │                    │ (Tucked behind dashboard)           │
       └─────────────────────────────────────┘                     └────────────────────────────────────┘                    └─────────────────────────────────────┘
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

### Step 2: Power Supply Installation (Car 12V)

#### **Method A: 12V Cigarette Lighter Outlet (Easiest — Plug & Play)**
1. Plug a **30W+ Dual USB-C Car Charger** into your car's 12V outlet.
2. Run a **USB-C Cable** to the Raspberry Pi power port.
3. Run a **Micro-USB Cable** to the 10.1" Display Driver Board power port.

#### **Method B: Hardwiring Behind Dashboard (Clean Hidden Install)**
1. Locate your car's interior fuse box (usually under the driver dashboard or glove box).
2. Insert an **Add-a-Fuse Tap** into an **ACC (Ignition Switched)** fuse slot (e.g. Cigarette Lighter / Radio fuse).
3. Crimp the **RED (+)** wire of a 12V-to-5V 5A DC converter to the Fuse Tap.
4. Connect the **BLACK (-)** wire to a metal chassis bolt ground.
5. Route the dual USB output cables up behind the radio cavity to power the Pi and screen.

---

### Step 3: Car Audio Wiring

Choose your preferred audio method:
* **Option A (AUX Cable)**: Plug the **USB 3.5mm DAC** into an RPi USB port, and run a 3.5mm Aux cable from the DAC into your car's AUX input port.
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
