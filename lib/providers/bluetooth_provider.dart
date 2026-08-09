import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bluetooth_device.dart';
import '../services/bluetooth_service.dart';
import '../services/avrcp_service.dart';

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _service = BluetoothService();
  final AvrcpService _avrcp = AvrcpService();

  bool _isBluetoothEnabled = true;
  bool _isDiscoverable = true;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _errorMessage;
  String? _lastConnectedMac;

  List<BluetoothDevice> _pairedDevices = [];
  List<BluetoothDevice> _discoveredDevices = [];

  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get isDiscoverable => _isDiscoverable;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String? get errorMessage => _errorMessage;

  List<BluetoothDevice> get pairedDevices => List.unmodifiable(_pairedDevices);
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  BluetoothDevice? get connectedDevice {
    try {
      return _pairedDevices.firstWhere((dev) => dev.isConnected);
    } catch (_) {
      return null;
    }
  }

  /// Callback to notify MediaProvider of live AVRCP track updates.
  /// Set this from the app root after both providers are initialized.
  void Function(String title, String artist, String album, Duration duration, bool isPlaying)? onTrackUpdate;
  void Function()? onDeviceDisconnected;

  Timer? _pollingTimer;
  StreamSubscription<AvrcpTrackInfo>? _avrcpSub;

  BluetoothProvider() {
    init();
  }

  Future<void> init() async {
    await _service.initLinuxBluetooth();
    _isBluetoothEnabled = await _service.isPowerOn();
    if (_isBluetoothEnabled) {
      await refreshPairedDevices();
      await scanDevices();
    }
    _startPollingTimer();
    _subscribeAvrcpUpdates();
  }

  /// Subscribe to AVRCP track info updates and forward them to MediaProvider.
  void _subscribeAvrcpUpdates() {
    _avrcpSub?.cancel();
    _avrcpSub = _avrcp.onTrackChanged.listen((track) {
      if (track.hasTrack) {
        onTrackUpdate?.call(
          track.title,
          track.artist,
          track.album,
          track.duration,
          track.isPlaying,
        );
      } else {
        onDeviceDisconnected?.call();
      }
    });
  }

  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isBluetoothEnabled && !_isScanning && !_isConnecting) {
        await refreshPairedDevices();

        // Start or stop AVRCP polling based on connection state
        final connected = connectedDevice;
        if (connected != null && connected.macAddress != _lastConnectedMac) {
          _lastConnectedMac = connected.macAddress;
          _avrcp.startPolling(connected.macAddress);
          if (kDebugMode) print('[BluetoothProvider] AVRCP polling started for ${connected.name}');
        } else if (connected == null && _lastConnectedMac != null) {
          _lastConnectedMac = null;
          _avrcp.stopPolling();
          onDeviceDisconnected?.call();
          if (kDebugMode) print('[BluetoothProvider] Device disconnected — AVRCP polling stopped.');
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _avrcpSub?.cancel();
    _avrcp.stopPolling();
    super.dispose();
  }

  Future<void> refreshPairedDevices() async {
    _pairedDevices = await _service.getPairedDevices();
    notifyListeners();
  }

  Future<void> togglePower(bool enabled) async {
    _isBluetoothEnabled = enabled;
    notifyListeners();

    final success = await _service.setPower(enabled);
    if (success) {
      if (enabled) {
        await refreshPairedDevices();
        await scanDevices();
      } else {
        _pairedDevices = [];
        _discoveredDevices = [];
        _avrcp.stopPolling();
      }
    } else {
      _isBluetoothEnabled = !enabled;
    }
    notifyListeners();
  }

  Future<void> toggleDiscoverable(bool discoverable) async {
    _isDiscoverable = discoverable;
    notifyListeners();

    final success = await _service.setDiscoverable(discoverable);
    if (!success) {
      _isDiscoverable = !discoverable;
      notifyListeners();
    }
  }

  Future<void> scanDevices() async {
    if (!_isBluetoothEnabled || _isScanning) return;

    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _discoveredDevices = await _service.scanDevices();
      await refreshPairedDevices();
    } catch (e) {
      _errorMessage = 'Failed to scan Bluetooth devices: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> pairAndConnect(String macAddress) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.pairAndConnect(macAddress);
      if (success) {
        await refreshPairedDevices();
        _discoveredDevices.removeWhere((dev) => dev.macAddress == macAddress);
        return true;
      } else {
        _errorMessage = 'Failed to pair with device ($macAddress). Ensure device is in pairing mode.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error pairing device: $e';
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnectDevice(String macAddress) async {
    _isConnecting = true;
    notifyListeners();

    try {
      await _service.disconnect(macAddress);
      _avrcp.stopPolling();
      _lastConnectedMac = null;
      await refreshPairedDevices();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> forgetDevice(String macAddress) async {
    _isConnecting = true;
    notifyListeners();

    try {
      await _service.removeDevice(macAddress);
      await refreshPairedDevices();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Send AVRCP play/pause toggle to the connected device.
  Future<void> avrcpTogglePlayPause(bool isCurrentlyPlaying) async {
    final mac = connectedDevice?.macAddress;
    if (mac == null) return;
    if (isCurrentlyPlaying) {
      await _avrcp.sendPause(mac);
    } else {
      await _avrcp.sendPlay(mac);
    }
  }

  /// Send AVRCP next track to the connected device.
  Future<void> avrcpNext() async {
    final mac = connectedDevice?.macAddress;
    if (mac != null) await _avrcp.sendNext(mac);
  }

  /// Send AVRCP previous track to the connected device.
  Future<void> avrcpPrevious() async {
    final mac = connectedDevice?.macAddress;
    if (mac != null) await _avrcp.sendPrevious(mac);
  }
}
