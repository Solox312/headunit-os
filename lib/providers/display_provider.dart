import 'package:flutter/foundation.dart';
import '../services/display_service.dart';
import '../services/settings_storage_service.dart';

class DisplayProvider extends ChangeNotifier {
  final DisplayService _service = DisplayService();
  final SettingsStorageService _storage = SettingsStorageService();

  double _brightness = 0.85; // 0.1 to 1.0

  double get brightness => _brightness;
  int get brightnessPercent => (_brightness * 100).round();

  DisplayProvider() {
    _init();
  }

  Future<void> _init() async {
    _brightness = await _storage.loadBrightness();
    notifyListeners();
    await _service.setHardwareBrightness(_brightness);
  }

  void setBrightness(double value) {
    final clamped = double.parse(value.clamp(0.1, 1.0).toStringAsFixed(2));
    if ((_brightness - clamped).abs() < 0.01) return;

    _brightness = clamped;
    notifyListeners();
    _service.setHardwareBrightness(_brightness);
    _storage.saveBrightness(_brightness);
  }
}
