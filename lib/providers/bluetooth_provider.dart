import 'package:flutter/foundation.dart';
import '../models/bluetooth_device.dart';
import '../services/bluetooth_service.dart';

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _service = BluetoothService();

  bool _isBluetoothEnabled = true;
  bool _isDiscoverable = true;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _errorMessage;

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
      _errorMessage = "Failed to scan Bluetooth devices: $e";
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
        _errorMessage = "Failed to pair with device ($macAddress). Ensure device is in pairing mode.";
        return false;
      }
    } catch (e) {
      _errorMessage = "Error pairing device: $e";
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
}
