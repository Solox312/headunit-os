#!/usr/bin/env python3
# ==============================================================================
#  HeadUnit OS — Wireless Android Auto Bluetooth Handoff Daemon
#
#  Wireless Android Auto is HEAD-UNIT-INITIATED: the phone hosts an RFCOMM
#  service with the AA Wireless UUID, and the car connects to it after the
#  Bluetooth link comes up (this is why real cars start AA the moment you
#  get in). This daemon:
#
#    1. Registers an org.bluez Profile for the AA Wireless UUID — required
#       so BlueZ hands the resulting connection fd to our NewConnection
#       handler when ConnectProfile succeeds.
#    2. Watches for phone connections (already-connected devices at startup
#       + D-Bus PropertiesChanged Connected=true events).
#    3. Calls org.bluez.Device1.ConnectProfile(AA_UUID) on the phone with
#       retries — BlueZ performs SDP on the phone, finds ITS record, and
#       opens the RFCOMM channel to it.
#    4. Performs the Wi-Fi credential handshake over that link:
#         HU  -> phone : WifiStartRequest  { ip_address, port }
#         phone -> HU  : WifiInfoRequest
#         HU  -> phone : WifiInfoResponse  { ssid, key, bssid, security, ap }
#       after which the phone joins the hotspot and dials <ip>:<port>.
#
#  Wire format: big-endian u16 payload length, big-endian u16 message id,
#  then a protobuf payload (hand-encoded — keeps the daemon dependency-free
#  beyond python3-dbus/python3-gi, preinstalled on Mint/RPi OS desktop).
#
#  Lifecycle events are printed to stdout as single "EVENT:..." lines for
#  the Flutter app (WirelessAABridge) to parse. Runs until SIGTERM.
#
#  Usage:
#    python3 aa_wireless_handoff.py --ssid HeadUnit-OS --psk headunit2024 \
#        --ip 10.42.0.1 --port 50001
# ==============================================================================
import argparse
import os
import select
import struct
import sys
import threading
import time

def emit(event):
    print(f"EVENT:{event}", flush=True)

try:
    import dbus
    import dbus.service
    import dbus.mainloop.glib
    from gi.repository import GLib
except ImportError as exc:
    emit(f"ERROR missing python dependency ({exc}) — run: sudo apt install python3-dbus python3-gi")
    sys.exit(1)

AA_WIRELESS_UUID = "4de17a00-52cb-11e6-bdf4-0800200c9a66"
PROFILE_PATH = "/org/headunitos/aa_wireless"

# Message ids on the RFCOMM handoff link
MSG_WIFI_START_REQUEST = 1
MSG_WIFI_INFO_REQUEST = 2
MSG_WIFI_INFO_RESPONSE = 3
MSG_WIFI_CONNECT_STATUS = 6
MSG_WIFI_START_RESPONSE = 7

# WifiInfoResponse enums
SECURITY_WPA2_PERSONAL = 8
ACCESS_POINT_STATIC = 0

CONNECT_ATTEMPTS = 10
CONNECT_RETRY_DELAY_S = 3

_bus = None
_lock = threading.Lock()
_active_devices = set()      # device paths with a live handoff link
_attempting_devices = set()  # device paths with a connect loop in flight


# ── Minimal protobuf encoding ─────────────────────────────────────────────────

def _pb_varint(value):
    out = bytearray()
    while True:
        bits = value & 0x7F
        value >>= 7
        if value:
            out.append(bits | 0x80)
        else:
            out.append(bits)
            return bytes(out)


def _pb_string(field_number, text):
    data = text.encode("utf-8")
    return bytes([(field_number << 3) | 2]) + _pb_varint(len(data)) + data


def _pb_uint(field_number, value):
    return bytes([(field_number << 3) | 0]) + _pb_varint(value)


def encode_wifi_start_request(ip_address, port):
    return _pb_string(1, ip_address) + _pb_uint(2, port)


def encode_wifi_info_response(ssid, psk, bssid):
    return (
        _pb_string(1, ssid)
        + _pb_string(2, psk)
        + _pb_string(3, bssid)
        + _pb_uint(4, SECURITY_WPA2_PERSONAL)
        + _pb_uint(5, ACCESS_POINT_STATIC)
    )


# ── Framed RFCOMM I/O over a raw fd ───────────────────────────────────────────

def write_frame(fd, msg_id, payload):
    frame = struct.pack(">HH", len(payload), msg_id) + payload
    while frame:
        written = os.write(fd, frame)
        frame = frame[written:]


def read_exact(fd, count):
    buf = bytearray()
    while len(buf) < count:
        select.select([fd], [], [])
        chunk = os.read(fd, count - len(buf))
        if not chunk:
            return None  # EOF — phone closed the link
        buf.extend(chunk)
    return bytes(buf)


def read_frame(fd):
    header = read_exact(fd, 4)
    if header is None:
        return None, None
    length, msg_id = struct.unpack(">HH", header)
    payload = read_exact(fd, length) if length else b""
    if length and payload is None:
        return None, None
    return msg_id, payload


# ── Handoff conversation ──────────────────────────────────────────────────────

def detect_bssid(explicit):
    if explicit:
        return explicit
    # The hotspot AP's MAC — for nmcli AP-mode hotspots this is the wireless
    # interface's own hardware address.
    for iface in sorted(os.listdir("/sys/class/net")):
        if iface.startswith("wl"):
            try:
                with open(f"/sys/class/net/{iface}/address") as f:
                    return f.read().strip()
            except OSError:
                continue
    return "00:00:00:00:00:00"


def handle_connection(fd, config, device_path):
    try:
        write_frame(fd, MSG_WIFI_START_REQUEST,
                    encode_wifi_start_request(config.ip, config.port))
        emit(f"WIFI_START_SENT ip={config.ip} port={config.port}")

        while True:
            msg_id, payload = read_frame(fd)
            if msg_id is None:
                emit("PHONE_DISCONNECTED")
                return

            if msg_id == MSG_WIFI_INFO_REQUEST:
                bssid = detect_bssid(config.bssid)
                write_frame(fd, MSG_WIFI_INFO_RESPONSE,
                            encode_wifi_info_response(config.ssid, config.psk, bssid))
                emit(f"CREDENTIALS_SENT ssid={config.ssid} bssid={bssid}")
            elif msg_id == MSG_WIFI_START_RESPONSE:
                emit("WIFI_START_RESPONSE")
            elif msg_id == MSG_WIFI_CONNECT_STATUS:
                emit(f"WIFI_CONNECT_STATUS len={len(payload)}")
            else:
                emit(f"UNKNOWN_MESSAGE id={msg_id} len={len(payload)}")
    except OSError as exc:
        emit(f"ERROR rfcomm i/o failed: {exc}")
    finally:
        with _lock:
            _active_devices.discard(device_path)
        try:
            os.close(fd)
        except OSError:
            pass


# ── Outgoing connection management (head unit dials the phone) ────────────────

def start_connect_loop(device_path):
    with _lock:
        if device_path in _active_devices or device_path in _attempting_devices:
            return
        _attempting_devices.add(device_path)
    threading.Thread(target=_connect_loop, args=(device_path,), daemon=True).start()


def _connect_loop(device_path):
    try:
        emit(f"PHONE_SEEN {device_path}")
        for attempt in range(1, CONNECT_ATTEMPTS + 1):
            with _lock:
                if device_path in _active_devices:
                    return
            try:
                device = dbus.Interface(_bus.get_object("org.bluez", device_path),
                                        "org.bluez.Device1")
                device.ConnectProfile(AA_WIRELESS_UUID, timeout=30)
                emit(f"CONNECT_PROFILE_OK {device_path}")
                return  # BlueZ delivers the fd via Profile1.NewConnection
            except dbus.exceptions.DBusException as exc:
                name = exc.get_dbus_name() or ""
                if "AlreadyConnected" in name or "InProgress" in name:
                    return
                emit(f"CONNECT_ATTEMPT_FAILED attempt={attempt} device={device_path} error={name}: {exc}")
                time.sleep(CONNECT_RETRY_DELAY_S)
        emit(f"CONNECT_GAVE_UP {device_path}")
    finally:
        with _lock:
            _attempting_devices.discard(device_path)


def on_properties_changed(interface, changed, invalidated, path=None):
    if interface != "org.bluez.Device1" or path is None:
        return
    if bool(changed.get("Connected", False)):
        start_connect_loop(str(path))


def connect_already_connected_devices():
    om = dbus.Interface(_bus.get_object("org.bluez", "/"),
                        "org.freedesktop.DBus.ObjectManager")
    for path, interfaces in om.GetManagedObjects().items():
        device = interfaces.get("org.bluez.Device1")
        if device and bool(device.get("Connected", False)):
            start_connect_loop(str(path))


# ── BlueZ Profile1 implementation ─────────────────────────────────────────────

class AAWirelessProfile(dbus.service.Object):
    def __init__(self, bus, path, config):
        super().__init__(bus, path)
        self._config = config

    @dbus.service.method("org.bluez.Profile1", in_signature="oha{sv}", out_signature="")
    def NewConnection(self, device, fd, fd_properties):
        raw_fd = fd.take()  # take ownership so BlueZ doesn't close it under us
        device_path = str(device)
        with _lock:
            _active_devices.add(device_path)
        emit(f"PHONE_CONNECTED {device_path}")
        threading.Thread(target=handle_connection,
                         args=(raw_fd, self._config, device_path), daemon=True).start()

    @dbus.service.method("org.bluez.Profile1", in_signature="o", out_signature="")
    def RequestDisconnection(self, device):
        emit(f"PHONE_DISCONNECT_REQUESTED {device}")

    @dbus.service.method("org.bluez.Profile1", in_signature="", out_signature="")
    def Release(self):
        emit("PROFILE_RELEASED")


def main():
    global _bus

    parser = argparse.ArgumentParser(description="Wireless Android Auto BT handoff daemon")
    parser.add_argument("--ssid", required=True)
    parser.add_argument("--psk", required=True)
    parser.add_argument("--ip", default="10.42.0.1",
                        help="Head unit IP on the hotspot (nmcli shared-mode default)")
    parser.add_argument("--port", type=int, default=50001)
    parser.add_argument("--bssid", default=None, help="Hotspot BSSID (auto-detected if omitted)")
    config = parser.parse_args()

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    _bus = dbus.SystemBus()

    AAWirelessProfile(_bus, PROFILE_PATH, config)

    manager = dbus.Interface(_bus.get_object("org.bluez", "/org/bluez"),
                             "org.bluez.ProfileManager1")
    try:
        # No Role restriction: we mainly connect outward (ConnectProfile),
        # but stay open to phone-initiated connections too.
        manager.RegisterProfile(PROFILE_PATH, AA_WIRELESS_UUID, {
            "Name": "Android Auto Wireless",
            "RequireAuthentication": dbus.Boolean(False),
            "RequireAuthorization": dbus.Boolean(False),
        })
    except dbus.exceptions.DBusException as exc:
        emit(f"ERROR profile registration failed: {exc}")
        sys.exit(1)

    emit(f"PROFILE_REGISTERED uuid={AA_WIRELESS_UUID}")

    # Watch for phones connecting, and dial any phone that's already here.
    _bus.add_signal_receiver(
        on_properties_changed,
        dbus_interface="org.freedesktop.DBus.Properties",
        signal_name="PropertiesChanged",
        arg0="org.bluez.Device1",
        path_keyword="path",
    )
    connect_already_connected_devices()

    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    finally:
        try:
            manager.UnregisterProfile(PROFILE_PATH)
        except dbus.exceptions.DBusException:
            pass


if __name__ == "__main__":
    main()
