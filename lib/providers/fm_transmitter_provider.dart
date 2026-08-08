import 'package:flutter/foundation.dart';
import '../services/fm_transmitter_service.dart';

class FmTransmitterProvider extends ChangeNotifier {
  final FmTransmitterService _service = FmTransmitterService();

  double _frequencyMhz = 88.3;
  bool _isTransmitting = true;
  bool _rdsEnabled = true;
  String _rdsText = "HeadUnit OS";
  FmHardwareType _selectedHardware = FmHardwareType.si4713;

  final List<double> _presetFrequencies = const [88.1, 88.3, 88.5, 107.9];

  double get frequencyMhz => _frequencyMhz;
  bool get isTransmitting => _isTransmitting;
  bool get rdsEnabled => _rdsEnabled;
  String get rdsText => _rdsText;
  FmHardwareType get selectedHardware => _selectedHardware;
  List<double> get presetFrequencies => _presetFrequencies;

  FmTransmitterProvider() {
    _applyFrequency();
  }

  void setFrequency(double newFreqMhz) {
    final clamped = (double.parse(newFreqMhz.clamp(87.5, 108.0).toStringAsFixed(1)));
    if (_frequencyMhz == clamped) return;

    _frequencyMhz = clamped;
    notifyListeners();
    _applyFrequency();
  }

  void stepFrequency(double deltaMhz) {
    setFrequency(_frequencyMhz + deltaMhz);
  }

  void toggleTransmitter(bool enabled) {
    _isTransmitting = enabled;
    notifyListeners();
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
