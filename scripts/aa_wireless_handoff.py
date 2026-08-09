#!/usr/bin/env python3
# ==============================================================================
#  HeadUnit OS — Wireless Android Auto Bluetooth Handoff Daemon
#
#  Registers the Android Auto Wireless RFCOMM profile with BlueZ via D-Bus
#  (org.bluez.ProfileManager1 — no deprecated sdptool, no bluetoothd -C
#  needed). When the phone pairs and connects to the profile, performs the
#  Wi-Fi credential handshake that tells it to join our hotspot and open a
#  TCP connection to the head unit's Android Auto socket:
#
#    HU  -> phone : WifiStartRequest  { ip_address, port }
#    phone -> HU  : WifiInfoRequest
#    HU  -> phone : WifiInfoResponse  { ssid, key, bssid, security, ap_type }
#    phone joins the hotspot and dials <ip_address>:<port>
#
#  Wire format on the RFCOMM link: big-endian u16 payload length, big-endian
#  u16 message id, then a protobuf payload (hand-encoded below — the messages
#  are tiny and this keeps the daemon dependency-free beyond python3-dbus).
#
#  Lifecycle events are printed to stdout as single "EVENT:..." lines for the
#  Flutter app (WirelessAABridge) to parse. Runs until SIGTERM.
#
#  Dependencies (preinstalled on Mint/RPi OS desktop images):
#    sudo apt install python3-dbus python3-gi
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


def handle_connection(fd, config):
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
        try:
            os.close(fd)
        except OSError:
            pass


# ── BlueZ Profile1 implementation ─────────────────────────────────────────────

class AAWirelessProfile(dbus.service.Object):
    def __init__(self, bus, path, config):
        super().__init__(bus, path)
        self._config = config

    @dbus.service.method("org.bluez.Profile1", in_signature="oha{sv}", out_signature="")
    def NewConnection(self, device, fd, fd_properties):
        raw_fd = fd.take()  # take ownership so BlueZ doesn't close it under us
        emit(f"PHONE_CONNECTED {device}")
        threading.Thread(target=handle_connection,
                         args=(raw_fd, self._config), daemon=True).start()

    @dbus.service.method("org.bluez.Profile1", in_signature="o", out_signature="")
    def RequestDisconnection(self, device):
        emit(f"PHONE_DISCONNECT_REQUESTED {device}")

    @dbus.service.method("org.bluez.Profile1", in_signature="", out_signature="")
    def Release(self):
        emit("PROFILE_RELEASED")


def main():
    parser = argparse.ArgumentParser(description="Wireless Android Auto BT handoff daemon")
    parser.add_argument("--ssid", required=True)
    parser.add_argument("--psk", required=True)
    parser.add_argument("--ip", default="10.42.0.1",
                        help="Head unit IP on the hotspot (nmcli shared-mode default)")
    parser.add_argument("--port", type=int, default=50001)
    parser.add_argument("--channel", type=int, default=8, help="RFCOMM channel")
    parser.add_argument("--bssid", default=None, help="Hotspot BSSID (auto-detected if omitted)")
    config = parser.parse_args()

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    AAWirelessProfile(bus, PROFILE_PATH, config)

    manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"),
                             "org.bluez.ProfileManager1")
    try:
        manager.RegisterProfile(PROFILE_PATH, AA_WIRELESS_UUID, {
            "Name": "Android Auto Wireless",
            "Role": "server",
            "Channel": dbus.UInt16(config.channel),
            "RequireAuthentication": dbus.Boolean(False),
            "RequireAuthorization": dbus.Boolean(False),
        })
    except dbus.exceptions.DBusException as exc:
        emit(f"ERROR profile registration failed: {exc}")
        sys.exit(1)

    emit(f"PROFILE_REGISTERED uuid={AA_WIRELESS_UUID} channel={config.channel}")

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
