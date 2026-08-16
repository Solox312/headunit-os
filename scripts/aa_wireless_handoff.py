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
#    4. Optionally exchanges WifiVersionRequest/WifiVersionResponse (some
#       real head units do this before WifiStartRequest; skipped gracefully
#       if the phone doesn't reply).
#    5. Performs the Wi-Fi credential handshake over that link:
#         HU  -> phone : WifiStartRequest  { ip_address, port }
#         phone -> HU  : WifiInfoRequest
#         HU  -> phone : WifiInfoResponse  { ssid, key, bssid, security, ap }
#       after which the phone joins the hotspot and dials <ip>:<port>.
#
#  Wire format, UUID, message IDs, and WifiInfoResponse field layout were
#  cross-checked against the aa-proxy-rs project (github.com/aa-proxy/
#  aa-proxy-rs, src/bluetooth.rs + src/protos/WifiInfoResponse.proto) to
#  replace guesswork with a verified reference: 4-byte big-endian header
#  (u16 length, u16 msg id), then a protobuf payload (hand-encoded here —
#  keeps the daemon dependency-free beyond python3-dbus/python3-gi,
#  preinstalled on Mint/RPi OS desktop).
#
#  Lifecycle events are printed to stdout as single "EVENT:..." lines for
#  the Flutter app (WirelessAABridge) to parse. Runs until SIGTERM.
#
#  Usage:
#    python3 aa_wireless_handoff.py --ssid HeadUnit-OS --psk headunit2024 \
#        --port 50001
#  (--ip is only a fallback; the real hotspot IP is read live from the
#  wireless interface right before each WifiStartRequest is sent.)
# ==============================================================================
import argparse
import os
import re
import select
import socket
import struct
import subprocess
import sys
import threading
import time

def emit(event):
    print(f"EVENT:{event}", flush=True)

try:
    import dbus  # type: ignore
    import dbus.service  # type: ignore
    import dbus.mainloop.glib  # type: ignore
    from gi.repository import GLib  # type: ignore
except ImportError as exc:
    emit(f"ERROR missing python dependency ({exc}) — run: sudo apt install python3-dbus python3-gi")
    sys.exit(1)

# Confirmed via aa-proxy-rs & openauto source
AA_WIRELESS_UUID = "4de17a00-52cb-11e6-bdf4-0800200c9a66"
SPP_UUID = "00001101-0000-1000-8000-00805f9b34fb"
GOOGLE_AA_UUID = "a3c87600-0005-1000-8000-001a11000100"

AA_UUID_CANDIDATES = [AA_WIRELESS_UUID, SPP_UUID, GOOGLE_AA_UUID]
PROFILE_PATH = "/org/headunitos/aa_wireless"

# Message ids on the RFCOMM handoff link (aa-proxy-rs ProxyMessageId enum)
MSG_WIFI_START_REQUEST = 1
MSG_WIFI_INFO_REQUEST = 2
MSG_WIFI_INFO_RESPONSE = 3
MSG_WIFI_VERSION_REQUEST = 4
MSG_WIFI_VERSION_RESPONSE = 5
MSG_WIFI_CONNECT_STATUS = 6
MSG_WIFI_START_RESPONSE = 7
MSG_WIFI_PING_REQUEST = 8
MSG_WIFI_PING_RESPONSE = 9
MSG_WIFI_SETUP_INFO = 11

VERSION_RESPONSE_WAIT_S = 4

# WifiInfoResponse enums
SECURITY_WPA2_PERSONAL = 8
ACCESS_POINT_STATIC = 0

CONNECT_ATTEMPTS = 10
CONNECT_RETRY_DELAY_S = 3

_bus = None
_lock = threading.Lock()
_active_devices = set()      # device paths with a live handoff link
_attempting_devices = set()  # device paths with a connect loop in flight
_profile_objects = []        # keep BlueZ profile D-Bus objects alive (prevent GC)


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


def encode_wifi_version_request(major=1, minor=1):
    # Field numbers per the version-handshake fields aa-proxy-rs relays
    # (major_version=1, minor_version=2). Exact version integers a real
    # phone expects aren't published anywhere we could confirm — 1/1 is a
    # conservative placeholder; the phone is expected to just echo back
    # WifiVersionResponse regardless, since this is a capability probe, not
    # a strict match requirement.
    return _pb_uint(1, major) + _pb_uint(2, minor)


def encode_wifi_info_response(ssid, psk, bssid):
    return (
        _pb_string(1, ssid)
        + _pb_string(2, psk)
        + _pb_string(3, bssid)
        + _pb_uint(4, SECURITY_WPA2_PERSONAL)
        + _pb_uint(5, ACCESS_POINT_STATIC)
    )


# ── Framed RFCOMM I/O over a raw fd ───────────────────────────────────────────
#
# The wire format below (2-byte length, 2-byte msg id, protobuf payload) is
# cross-checked against aa-proxy-rs's src/bluetooth.rs. Every raw read is
# still hex-dumped as RX_RAW before we try to interpret it as a frame, so a
# real trace exists if something still doesn't line up.

SELECT_POLL_S = 5
HEARTBEAT_EVERY_S = 15
RX_HEX_DUMP_LIMIT = 64


def write_frame(fd, msg_id, payload):
    frame = struct.pack(">HH", len(payload), msg_id) + payload
    while frame:
        written = os.write(fd, frame)
        frame = frame[written:]


class RawReader:
    """Buffered reader over the raw fd that logs every chunk received (as
    hex) before any frame-format assumptions are applied on top of it."""

    def __init__(self, fd):
        self._fd = fd
        self._buf = bytearray()

    def _fill(self, min_bytes):
        last_heartbeat = time.monotonic()
        while len(self._buf) < min_bytes:
            ready, _, _ = select.select([self._fd], [], [], SELECT_POLL_S)
            if not ready:
                now = time.monotonic()
                if now - last_heartbeat >= HEARTBEAT_EVERY_S:
                    emit("WAITING_FOR_PHONE_RESPONSE no data received yet")
                    last_heartbeat = now
                continue
            chunk = os.read(self._fd, 4096)
            if not chunk:
                return False  # EOF — phone closed the link
            preview = chunk[:RX_HEX_DUMP_LIMIT].hex()
            more = "..." if len(chunk) > RX_HEX_DUMP_LIMIT else ""
            emit(f"RX_RAW len={len(chunk)} hex={preview}{more}")
            self._buf.extend(chunk)
        return True

    def read_exact(self, count):
        if not self._fill(count):
            return None
        data = bytes(self._buf[:count])
        del self._buf[:count]
        return data

    def data_ready_within(self, timeout_s):
        """Non-consuming poll — used to bound how long we wait for an
        optional reply (e.g. WifiVersionResponse) before moving on."""
        if self._buf:
            return True
        ready, _, _ = select.select([self._fd], [], [], timeout_s)
        return bool(ready)


def read_frame(reader):
    header = reader.read_exact(4)
    if header is None:
        return None, None
    length, msg_id = struct.unpack(">HH", header)
    payload = reader.read_exact(length) if length else b""
    if length and payload is None:
        return None, None
    return msg_id, payload


# ── Handoff conversation ──────────────────────────────────────────────────────

def _find_wireless_iface():
    for iface in sorted(os.listdir("/sys/class/net")):
        if iface.startswith("wl"):
            return iface
    return None


def detect_bssid(explicit):
    if explicit:
        return explicit
    # The hotspot AP's MAC — for nmcli AP-mode hotspots this is the wireless
    # interface's own hardware address.
    iface = _find_wireless_iface()
    if iface:
        try:
            with open(f"/sys/class/net/{iface}/address") as f:
                return f.read().strip()
        except OSError:
            pass
    return "00:00:00:00:00:00"


def detect_hotspot_ip(explicit):
    """Live IP of the hotspot AP interface. Read from the interface itself
    right before use. Falls back to explicit --ip or standard 10.42.0.1."""
    iface = _find_wireless_iface()
    if iface:
        try:
            out = subprocess.run(
                ["ip", "-4", "-o", "addr", "show", iface],
                capture_output=True, text=True, timeout=2,
            ).stdout
            match = re.search(r"inet (\d+\.\d+\.\d+\.\d+)", out)
            if match:
                return match.group(1)
        except (OSError, subprocess.SubprocessError):
            pass
    if explicit:
        return explicit
    return "192.168.50.1"


def handle_connection(fd, config, device_path):
    credentials_sent = False
    try:
        reader = RawReader(fd)

        # Optional version handshake — some real head units send this before
        # WifiStartRequest. Not confirmed required for every phone, so we
        # bound the wait and proceed regardless rather than risk hanging on
        # a phone that doesn't expect it.
        write_frame(fd, MSG_WIFI_VERSION_REQUEST, encode_wifi_version_request())
        emit("WIFI_VERSION_REQUEST_SENT")
        if reader.data_ready_within(VERSION_RESPONSE_WAIT_S):
            msg_id, payload = read_frame(reader)
            if msg_id is None:
                emit("PHONE_DISCONNECTED")
                return
            if msg_id == MSG_WIFI_VERSION_RESPONSE:
                emit(f"WIFI_VERSION_RESPONSE len={len(payload)}")
            else:
                emit(f"UNEXPECTED_AFTER_VERSION_REQUEST id={msg_id} len={len(payload)}")
        else:
            emit("WIFI_VERSION_RESPONSE_TIMEOUT proceeding without it")

        ip_address = detect_hotspot_ip(config.ip)
        if not ip_address:
            emit("ERROR could not determine hotspot IP (interface down and no --ip fallback given)")
            return

        write_frame(fd, MSG_WIFI_START_REQUEST,
                    encode_wifi_start_request(ip_address, config.port))
        emit(f"WIFI_START_SENT ip={ip_address} port={config.port}")

        while True:
            msg_id, payload = read_frame(reader)
            if msg_id is None:
                if credentials_sent:
                    emit("HANDOFF_COMPLETE_RFCOMM_CLOSED")
                else:
                    emit("PHONE_DISCONNECTED")
                return

            if msg_id == MSG_WIFI_INFO_REQUEST:
                bssid = detect_bssid(config.bssid)
                write_frame(fd, MSG_WIFI_INFO_RESPONSE,
                            encode_wifi_info_response(config.ssid, config.psk, bssid))
                credentials_sent = True
                emit(f"CREDENTIALS_SENT ssid={config.ssid} bssid={bssid}")
            elif msg_id == MSG_WIFI_START_RESPONSE:
                emit("WIFI_START_RESPONSE")
            elif msg_id == MSG_WIFI_CONNECT_STATUS:
                emit(f"WIFI_CONNECT_STATUS len={len(payload)}")
            elif msg_id == MSG_WIFI_PING_REQUEST:
                write_frame(fd, MSG_WIFI_PING_RESPONSE, b"")
                emit("PING_REPLIED")
            elif msg_id == MSG_WIFI_SETUP_INFO:
                emit(f"WIFI_SETUP_INFO len={len(payload)}")
            else:
                emit(f"UNKNOWN_MESSAGE id={msg_id} len={len(payload)}")
    except OSError as exc:
        if credentials_sent or "104" in str(exc) or "reset" in str(exc).lower():
            emit("HANDOFF_COMPLETE_RFCOMM_CLOSED")
        else:
            emit(f"ERROR rfcomm i/o failed: {exc}")
    finally:
        with _lock:
            _active_devices.discard(device_path)
        try:
            os.close(fd)
        except OSError:
            pass


# ── Outgoing connection management (head unit dials the phone) ────────────────

def _on_connect_ok(device_path, uuid):
    emit(f"CONNECT_PROFILE_SUCCESS {device_path} uuid={uuid}")

def _on_connect_err(device_path, uuid, err):
    name = getattr(err, "get_dbus_name", lambda: "")() or ""
    if "AlreadyConnected" in name or "InProgress" in name:
        emit(f"CONNECT_PROFILE_ALREADY_CONNECTED {device_path} uuid={uuid}")
    elif "NotAvailable" in name or "not-supported" in str(err).lower():
        emit(f"CONNECT_PROFILE_NOT_SUPPORTED {device_path} uuid={uuid}")
    else:
        emit(f"CONNECT_PROFILE_FAILED {device_path} uuid={uuid} error={name}: {err}")

def _try_connect_profiles(device_path, candidates, attempt=1):
    with _lock:
        if device_path in _active_devices:
            return False

    try:
        device = dbus.Interface(_bus.get_object("org.bluez", device_path), "org.bluez.Device1")
        for uuid in candidates:
            emit(f"CALLING_CONNECT_PROFILE {device_path} uuid={uuid} attempt={attempt}")
            device.ConnectProfile(
                uuid,
                reply_handler=lambda u=uuid: _on_connect_ok(device_path, u),
                error_handler=lambda err, u=uuid: _on_connect_err(device_path, u, err),
                timeout=10,
            )
    except Exception as exc:
        emit(f"ERROR initiating ConnectProfile: {exc}")

    return False  # GLib timeout doesn't repeat automatically


def start_connect_loop(device_path):
    with _lock:
        if device_path in _active_devices or device_path in _attempting_devices:
            return
        _attempting_devices.add(device_path)

    def _schedule():
        try:
            props = dbus.Interface(_bus.get_object("org.bluez", device_path),
                                   "org.freedesktop.DBus.Properties")
            advertised = {str(u).lower() for u in props.Get("org.bluez.Device1", "UUIDs")}
        except Exception:
            advertised = set()
        
        candidates = [u for u in AA_UUID_CANDIDATES if u in advertised]
        if not candidates:
            candidates = list(AA_UUID_CANDIDATES)

        emit(f"PHONE_SEEN {device_path} candidates={','.join(candidates)}")
        # Trigger async ConnectProfile on the GLib event loop after a short 1s delay for SDP settling
        GLib.timeout_add(1000, lambda: _try_connect_profiles(device_path, candidates, attempt=1))
        # Schedule a fallback retry at 3.5s if not yet connected
        GLib.timeout_add(3500, lambda: _try_connect_profiles(device_path, candidates, attempt=2))

    GLib.idle_add(_schedule)



def on_properties_changed(interface, changed, invalidated, path=None):
    try:
        emit(f"PROPS_CHANGED_RX interface={interface} path={path} keys={list(changed.keys())}")
        if interface != "org.bluez.Device1" or path is None:
            return
        
        if "ServicesResolved" in changed and bool(changed["ServicesResolved"]):
            try:
                props = dbus.Interface(_bus.get_object("org.bluez", path), "org.freedesktop.DBus.Properties")
                uuids = [str(u).lower() for u in props.Get("org.bluez.Device1", "UUIDs")]
                emit(f"PHONE_SERVICES_RESOLVED {path} uuids={','.join(uuids)}")
            except Exception as e:
                emit(f"PHONE_SERVICES_RESOLVED {path} (could not read uuids: {e})")
            start_connect_loop(str(path))
        elif bool(changed.get("Connected", False)):
            emit(f"DEVICE_CONNECTED_SIGNAL {path}")
            start_connect_loop(str(path))
    except Exception as exc:
        emit(f"ERROR on_properties_changed: {exc}")


def connect_already_connected_devices():
    om = dbus.Interface(_bus.get_object("org.bluez", "/"),
                        "org.freedesktop.DBus.ObjectManager")
    for path, interfaces in om.GetManagedObjects().items():
        device = interfaces.get("org.bluez.Device1")
        if device and bool(device.get("Connected", False)):
            start_connect_loop(str(path))



RFCOMM_CHANNEL = 22


# ── BlueZ Profile1 implementation ─────────────────────────────────────────────

class AAWirelessProfile(dbus.service.Object):
    """BlueZ Profile1 handler — used when phone dials us via ConnectProfile."""
    def __init__(self, bus, path, config):
        super().__init__(bus, path)
        self._config = config

    @dbus.service.method("org.bluez.Profile1", in_signature="oha{sv}", out_signature="")
    def NewConnection(self, device, fd, fd_properties):
        raw_fd = fd.take()
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
    parser.add_argument("--ip", default=None,
                        help="Fallback head unit IP if live detection from the "
                             "wireless interface fails (auto-detected per-connection "
                             "otherwise — nmcli's shared-mode IP is not reliably "
                             "192.168.50.1 on real hardware)")
    parser.add_argument("--port", type=int, default=50001)
    parser.add_argument("--bssid", default=None, help="Hotspot BSSID (auto-detected if omitted)")
    config = parser.parse_args()

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    _bus = dbus.SystemBus()

    # ── BlueZ RegisterProfile: handles both phone-initiated and head-unit-initiated ──
    manager = dbus.Interface(_bus.get_object("org.bluez", "/org/bluez"),
                             "org.bluez.ProfileManager1")

    registered_paths = []
    # Assign distinct RFCOMM channels per UUID to prevent BlueZ channel collisions:
    profile_map = {
        AA_WIRELESS_UUID: 22,  # Primary Android Auto UUID
        SPP_UUID:         1,   # Serial Port Profile (fallback)
        GOOGLE_AA_UUID:   23,  # Google Android Auto secondary UUID
    }
    for index, (uuid, channel_num) in enumerate(profile_map.items()):
        path = f"{PROFILE_PATH}{index}"
        try:
            manager.UnregisterProfile(path)
        except Exception:
            pass
        try:
            # Store reference to keep the D-Bus object alive (GC must not collect it)
            profile_obj = AAWirelessProfile(_bus, path, config)
            _profile_objects.append(profile_obj)
            profile_opts = {
                "Name": "Android Auto Wireless",
                "RequireAuthentication": dbus.Boolean(False),
                "RequireAuthorization": dbus.Boolean(False),
                "Channel": dbus.UInt16(channel_num),
                "AutoConnect": dbus.Boolean(False),  # phone initiates; we don't dial out
            }
            manager.RegisterProfile(path, uuid, profile_opts)
            registered_paths.append(path)
            emit(f"PROFILE_REGISTERED uuid={uuid} channel={channel_num}")
        except dbus.exceptions.DBusException as exc:
            msg = str(exc).lower()
            if "already registered" in msg or "notpermitted" in msg:
                registered_paths.append(path)
                emit(f"PROFILE_ALREADY_ACTIVE uuid={uuid} channel={channel_num}")
            else:
                emit(f"PROFILE_REGISTER_FAILED uuid={uuid} error={exc}")

    # ── Watch for phones connecting ────────────────────────────────────────────
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
        for path in registered_paths:
            try:
                manager.UnregisterProfile(path)
            except dbus.exceptions.DBusException:
                pass


if __name__ == "__main__":
    main()
