import 'package:flutter/foundation.dart';
import '../models/wifi_network.dart';
import '../services/wifi_service.dart';

class WifiProvider extends ChangeNotifier {
  final WifiService _service = WifiService();

  bool _isWifiEnabled = true;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectedSsid;
  String? _ipAddress;
  String? _errorMessage;
  List<WifiNetwork> _availableNetworks = [];

  bool get isWifiEnabled => _isWifiEnabled;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connectedSsid != null && _connectedSsid!.isNotEmpty;
  String? get connectedSsid => _connectedSsid;
  String? get ipAddress => _ipAddress;
  String? get errorMessage => _errorMessage;
  List<WifiNetwork> get availableNetworks => List.unmodifiable(_availableNetworks);

  WifiProvider() {
    init();
  }

  Future<void> init() async {
    _isWifiEnabled = await _service.isWifiRadioOn();
    await refreshStatus();
    if (_isWifiEnabled) {
      await scanNetworks();
    }
  }

  Future<void> refreshStatus() async {
    final status = await _service.getCurrentStatus();
    if (status['connected'] == 'true' && status['ssid'] != null && status['ssid']!.isNotEmpty) {
      _connectedSsid = status['ssid'];
      _ipAddress = status['ip'];
    } else {
      _connectedSsid = null;
      _ipAddress = null;
    }
    notifyListeners();
  }

  Future<void> toggleWifi(bool enabled) async {
    _isWifiEnabled = enabled;
    notifyListeners();

    final success = await _service.setWifiRadio(enabled);
    if (success) {
      if (enabled) {
        await scanNetworks();
      } else {
        _availableNetworks = [];
        _connectedSsid = null;
        _ipAddress = null;
      }
    } else {
      _isWifiEnabled = !enabled;
    }
    notifyListeners();
  }

  Future<void> scanNetworks() async {
    if (!_isWifiEnabled || _isScanning) return;

    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableNetworks = await _service.scanNetworks();
      await refreshStatus();
    } catch (e) {
      _errorMessage = "Failed to scan Wi-Fi networks: $e";
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectToNetwork(String ssid, String password) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.connectToNetwork(ssid, password);
      if (success) {
        _connectedSsid = ssid;
        await refreshStatus();
        await scanNetworks();
        return true;
      } else {
        _errorMessage = "Failed to connect to '$ssid'. Check password and try again.";
        return false;
      }
    } catch (e) {
      _errorMessage = "Error connecting to network: $e";
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    _isConnecting = true;
    notifyListeners();

    try {
      await _service.disconnectNetwork();
      _connectedSsid = null;
      _ipAddress = null;
      await scanNetworks();
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }
}
