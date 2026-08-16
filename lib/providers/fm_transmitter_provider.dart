import 'package:flutter/foundation.dart';
import '../services/fm_transmitter_service.dart';
import '../services/settings_storage_service.dart';

class FmTransmitterProvider extends ChangeNotifier {
  final FmTransmitterService _service = FmTransmitterService();
  final SettingsStorageService _storage = SettingsStorageService();

  double _frequencyMhz = 88.3;
  bool _isTransmitting = true;
  bool _rdsEnabled = true;
  String _rdsText = "HeadUnit OS";
  FmHardwareType _selectedHardware = FmHardwareType.kt0803k;
  bool _isHardwareDetected = false;
  bool _isDetecting = false;

  final List<double> _presetFrequencies = const [88.1, 88.3, 88.5, 107.9];

  double get frequencyMhz => _frequencyMhz;
  bool get isTransmitting => _isTransmitting;
  bool get rdsEnabled => _rdsEnabled;
  String get rdsText => _rdsText;
  FmHardwareType get selectedHardware => _selectedHardware;
  bool get isHardwareDetected => _isHardwareDetected;
  bool get isDetecting => _isDetecting;
  List<double> get presetFrequencies => _presetFrequencies;

  FmTransmitterProvider() {
    _loadPersistedSettings();
  }

  Future<void> _loadPersistedSettings() async {
    final savedFreq = await _storage.loadFmFrequency();
    final savedHardwareStr = await _storage.loadFmHardwareType();
    final savedTransmitting = await _storage.loadFmTransmitting();

    _frequencyMhz = savedFreq.clamp(87.5, 108.0);
    _isTransmitting = savedTransmitting;

    try {
      _selectedHardware = FmHardwareType.values.firstWhere(
        (h) => h.name.toLowerCase() == savedHardwareStr.toLowerCase(),
        orElse: () => FmHardwareType.kt0803k,
      );
    } catch (_) {
      _selectedHardware = FmHardwareType.kt0803k;
    }

    notifyListeners();
    await detectHardware();
    _applyFrequency();
  }

  Future<void> detectHardware() async {
    _isDetecting = true;
    notifyListeners();

    try {
      final detected = await _service.detectHardware();
      if (detected != null) {
        _selectedHardware = detected;
        _isHardwareDetected = true;
      } else {
        _isHardwareDetected = await _service.probeDevice(_selectedHardware);
      }
    } catch (_) {
      _isHardwareDetected = false;
    } finally {
      _isDetecting = false;
      notifyListeners();
    }
  }

  void setFrequency(double newFreqMhz) {
    final clamped = (double.parse(newFreqMhz.clamp(87.5, 108.0).toStringAsFixed(1)));
    if (_frequencyMhz == clamped) return;

    _frequencyMhz = clamped;
    notifyListeners();
    _storage.saveFmFrequency(_frequencyMhz);
    _applyFrequency();
  }

  void stepFrequency(double deltaMhz) {
    setFrequency(_frequencyMhz + deltaMhz);
  }

  void toggleTransmitter(bool enabled) {
    _isTransmitting = enabled;
    notifyListeners();
    _storage.saveFmTransmitting(enabled);
    _service.setPowerState(enabled: enabled, hardwareType: _selectedHardware);
    if (_isTransmitting) {
      _applyFrequency();
    }
  }

  void toggleRds(bool enabled) {
    _rdsEnabled = enabled;
    notifyListeners();
    _applyFrequency();
  }

  void setRdsText(String text) {
    _rdsText = text;
    notifyListeners();
    _applyFrequency();
  }

  void setHardwareType(FmHardwareType type) {
    _selectedHardware = type;
    notifyListeners();
    _storage.saveFmHardwareType(type.name);
    _applyFrequency();
  }

  Future<void> _applyFrequency() async {
    if (!_isTransmitting) return;
    await _service.setFrequency(
      frequencyMhz: _frequencyMhz,
      hardwareType: _selectedHardware,
      rdsText: _rdsEnabled ? _rdsText : "",
    );
  }
}
