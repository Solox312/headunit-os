# Complete Master Hardware Shopping List (DIY 10.1" Head Unit)

This is the complete parts list and hardware breakdown for building your **Raspberry Pi 10.1" Touchscreen Head Unit**.

---

## 🛍️ Master Parts List Breakdown

| Item | Component | Est. Price | Notes & Recommendations |
| :--- | :--- | :--- | :--- |
| **1. Computer** | **Raspberry Pi 4 (4GB/8GB)** or **Raspberry Pi 5** | $55 – $80 | RPi 4 4GB or RPi 5 4GB provides silky smooth 60fps performance. |
| **2. Display** | **10.1" LCD Capacitive Touch Monitor + HDMI Board** | $32 – $45 | 235mm × 143mm, HDMI driver board + USB Touch cable (e.g. AliExpress / Waveshare). |
| **3. Power** | **Intelligent Automotive Power HAT** (CarPiHAT / StromPi 3 / Mausberry) | $20 – $40 | **Primary Standard (Method 1):** 3-wire ignition setup for safe shutdown & zero SD corruption. |
| **4. Storage** | **32GB or 64GB MicroSD Card (A2 Class 10)** | $8 – $12 | SanDisk Extreme or Samsung EVO Select (A2 rated for fast boot speeds). |
| **5. Audio** | **USB 3.5mm Hi-Fi DAC + 3.5mm Ground Loop Isolator** | $15 – $22 | **Crucial:** Plugs inline with 3.5mm Aux cable. Prevents ground loops & alternator noise when powering Pi from car 12V. |
| **6. Wireless** | **Carlinkit CPC200-CCPA Wireless USB Dongle** | $38 – $48 | *(Optional)* For dual Wireless CarPlay + Wireless AA dual-chip hardware bridge. |
| **7. Mic** | **USB Mini Microphone** | $6 – $10 | For Google Assistant & Siri hands-free voice commands while driving. |
| **8. Mount** | **Universal 10.1" Double-DIN Dash Mount Kit** | $12 – $20 | Universal 2-DIN frame to mount the 10.1" screen neatly into your car dash. |

---

## 🔌 Wiring & Cable Accessories List

1. **Short HDMI Cable / Ribbon Cable** (0.3m / 1ft): Connects RPi Micro-HDMI/HDMI port to Display Driver Board.
2. **Micro-USB to USB-A Cable**: Connects Display Driver Board touch controller to RPi USB port.
3. **3.5mm AUX Stereo Audio Cable** (3ft): Connects USB DAC to Car's AUX input port.
4. **3.5mm Ground Loop Noise Isolator ($8 – $10)**: **Crucial Component!** Plugs inline between the DAC / Pi audio output and the vehicle's AUX jack.
5. **Inline Fuse Tap Adapter (12V)**: Plugs into your car's fuse box (ACC ignition fuse) for safe power delivery.

---

## 🔌 How to Power the Head Unit from Your Car

You have **3 options** to power the Raspberry Pi and 10.1" Display from your car:

### Option A: Intelligent Power Supply HAT (Recommended — Safe Shutdown)
1. Use an automotive Pi power HAT (**CarPiHAT**, **StromPi 3**, or **Mausberry Switch**).
2. Wire 3 cables using Add-a-Fuse taps:
   - **Constant 12V (Battery)**: Always powered for sleeping & clean shutdown buffer.
   - **Switched 12V (ACC / Ignition)**: Triggers auto-boot on key turn & GPIO shutdown on key off.
   - **Ground (GND)**: Chassis metal bolt.
* **Result**: Zero risk of SD card corruption! Gracefully shuts down Linux before cutting power.

---

### Option B: Hardwiring 12V-to-5V Step-Down Converter (Hidden Install — $12)
1. Buy a **12V-to-5V 5A (25W) DC-DC Step-Down Converter**.
2. Connect RED (+) to ACC ignition fuse and BLACK (-) to ground chassis.
3. **Important**: Enable **OverlayFS (Read-Only)** in Raspberry Pi OS to protect the SD card from abrupt power loss.

---

### Option C: Car 12V Cigarette Lighter Outlet (Plug-and-Play — $10)
1. Plug a high-power **Dual USB-C Car Charger** (30W+) into your car's 12V outlet.
2. Cable 1 (USB-C): Raspberry Pi power port.
3. Cable 2 (USB): 10.1" Display Driver Board power port.
4. **Important**: Enable **OverlayFS (Read-Only)** in Raspberry Pi OS to protect the SD card from abrupt power loss.

---

## 📐 Overall Budget Summary

* **Minimum Budget Build** (Native Wireless, AUX Audio): **~$125 – $150 Total**
* **Deluxe Premium Build** (RPi 5, Carlinkit Dongle, USB DAC, Mount): **~$185 – $220 Total**

*(Compare to $600 – $1,200 commercial pioneer / alpine stereos!)*
