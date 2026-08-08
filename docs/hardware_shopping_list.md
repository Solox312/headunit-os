# Complete Master Hardware Shopping List (DIY 10.1" Head Unit)

This is the complete parts list and hardware breakdown for building your **Raspberry Pi 10.1" Touchscreen Head Unit**.

---

## 🛍️ Master Parts List Breakdown

| Item | Component | Est. Price | Notes & Recommendations |
| :--- | :--- | :--- | :--- |
| **1. Computer** | **Raspberry Pi 4 (4GB/8GB)** or **Raspberry Pi 5** | $55 – $80 | RPi 4 4GB or RPi 5 4GB provides silky smooth 60fps performance. |
| **2. Display** | **10.1" LCD Capacitive Touch Monitor + HDMI Board** | $32 – $45 | 235mm × 143mm, HDMI driver board + USB Touch cable (e.g. AliExpress / Waveshare). |
| **3. Power** | **12V-to-5V 5A (25W) Car Step-Down Converter** | $10 – $15 | Hardwires to your car's Fuse Box / ACC ignition wire so Pi boots on key turn. |
| **4. Storage** | **32GB or 64GB MicroSD Card (A2 Class 10)** | $8 – $12 | SanDisk Extreme or Samsung EVO Select (A2 rated for fast boot speeds). |
| **5. Audio** | **USB 3.5mm Hi-Fi DAC Audio Adapter** | $8 – $12 | Connects Pi USB to Car AUX input. Eliminates ground loops/alternator hum. |
| **6. Wireless** | **Carlinkit CPC200-CCPA Wireless USB Dongle** | $38 – $48 | *(Optional)* For dual Wireless CarPlay + Wireless AA dual-chip hardware bridge. |
| **7. Mic** | **USB Mini Microphone** | $6 – $10 | For Google Assistant & Siri hands-free voice commands while driving. |
| **8. Mount** | **Universal 10.1" Double-DIN Dash Mount Kit** | $12 – $20 | Universal 2-DIN frame to mount the 10.1" screen neatly into your car dash. |

---

## 🔌 Wiring & Cable Accessories List

1. **Short HDMI Cable / Ribbon Cable** (0.3m / 1ft): Connects RPi Micro-HDMI/HDMI port to Display Driver Board.
2. **Micro-USB to USB-A Cable**: Connects Display Driver Board touch controller to RPi USB port.
3. **3.5mm AUX Stereo Audio Cable** (3ft): Connects USB DAC to Car's AUX input port.
4. **Inline Fuse Tap Adapter (12V)**: Plugs into your car's fuse box (ACC ignition fuse) for safe power delivery.

## 🔌 How to Power the Head Unit from Your Car

You have **2 easy options** to power the Raspberry Pi and 10.1" Display from your car:

### Option A: Car 12V Cigarette Lighter Outlet (Plug-and-Play — $10)
1. Buy a high-power **Dual USB-C Car Charger** (30W+ total, 5V 3A - 5A output, e.g. Anker / UGREEN).
2. Plug it into your car's 12V cigarette lighter outlet.
3. Cable 1 (USB-C): Plug into Raspberry Pi power port.
4. Cable 2 (USB): Plug into 10.1" Display Driver Board power port.
* **Result**: Plugs directly into your car's outlet! Turns on/off automatically with your car key.

```
 🔌 12V Car Cigarette Lighter ──► ⚡ Dual USB Charger ──┬──► (USB-C) ──► 💻 Raspberry Pi (5V 3A)
                                                        └──► (USB)   ──► 🖥️ 10.1" Display (5V 2A)
```

---

### Option B: Hardwiring Behind the Dash (Hidden Install — $12)
1. Buy a **12V-to-5V 5A (25W) DC-DC Step-Down Converter**.
2. Connect the RED (+) wire to an **ACC (Ignition Switched)** fuse in your fuse box using an Add-a-Fuse tap.
3. Connect the BLACK (-) wire to any metal chassis bolt ground.
* **Result**: 100% hidden wires behind your dashboard!

---

## 📐 Overall Budget Summary

* **Minimum Budget Build** (Native Wireless, AUX Audio): **~$125 – $150 Total**
* **Deluxe Premium Build** (RPi 5, Carlinkit Dongle, USB DAC, Mount): **~$185 – $220 Total**

*(Compare to $600 – $1,200 commercial pioneer / alpine stereos!)*
