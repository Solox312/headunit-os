import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/providers/display_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DisplayProvider State Tests', () {
    test('DisplayProvider initializes with default 85% brightness', () {
      final provider = DisplayProvider();
      expect(provider.brightness, equals(0.85));
      expect(provider.brightnessPercent, equals(85));
    });

    test('setBrightness updates brightness within bounds (10% to 100%)', () {
      final provider = DisplayProvider();
      provider.setBrightness(0.50);

      expect(provider.brightness, equals(0.50));
      expect(provider.brightnessPercent, equals(50));

      // Clamping lower bound
      provider.setBrightness(0.01);
      expect(provider.brightness, equals(0.10));

      // Clamping upper bound
      provider.setBrightness(1.50);
      expect(provider.brightness, equals(1.00));
    });
  });
}
