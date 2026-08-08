# Raspberry Pi & Linux Wi-Fi Setup Guide 📶

This guide documents how **HeadUnit OS** interfaces with the Raspberry Pi built-in Wi-Fi hardware (`wlan0`) and Linux NetworkManager (`nmcli`) to enable Wi-Fi scanning, connection, and status management.

---

## 1. NetworkManager (`nmcli`) Prerequisites

HeadUnit OS uses Linux NetworkManager CLI (`nmcli`) for all Wi-Fi operations. NetworkManager is preinstalled by default on **Raspberry Pi OS (64-bit)** (Bookworm) and **Linux Mint**.

Verify `nmcli` is installed and running on your system:

```bash
nmcli dev status
```

You should see output similar to:
```
DEVICE  TYPE      STATE        CONNECTION 
wlan0   wifi      connected    Home_5G    
eth0    ethernet  unavailable  --         
lo      loopback  unmanaged    --         
```

---

## 2. Passwordless Polkit Permissions (Optional)

By default, standard Linux users in the `netdev` or `sudo` group can scan and connect to Wi-Fi networks without password prompts.

If your Linux user receives permission errors when running `nmcli dev wifi connect`, ensure your user is added to the `netdev` group:

```bash
sudo usermod -aG netdev $USER
```

Alternatively, add a Polkit policy file at `/etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager.rules`:

```javascript
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 &&
        subject.isInGroup("netdev")) {
        return polkit.Result.YES;
    }
});
```

---

## 3. Simultaneous Wireless Android Auto / CarPlay AP & Wi-Fi Station Mode

The Raspberry Pi 4 and Raspberry Pi 5 built-in Broadcom Wi-Fi chips support virtual interface creation (`wlan0` for Station mode, `uap0` / `wlan0_ap` for Access Point mode).

* **Station Mode (`wlan0`)**: Connects the HeadUnit OS to home Wi-Fi or mobile hotspot for software updates, telemetry, and weather data.
* **Access Point Mode (`wlan0_ap`)**: Broadcasts the 5GHz Wi-Fi Access Point (`RPi_HeadUnit_5G`) for Native Wireless Android Auto / Apple CarPlay.

---

## 4. Troubleshooting Wi-Fi Issues

* **Wi-Fi is Soft-Locked**: Run `sudo rfkill unblock wifi` if the radio is disabled at the kernel level.
* **Wi-Fi Interface Down**: Run `sudo ip link set wlan0 up` or `nmcli radio wifi on`.
* **Country Code Not Set**: On Raspberry Pi, set your Wi-Fi country code using `sudo raspi-config` -> **Localisation Options** -> **WLAN Country**.
