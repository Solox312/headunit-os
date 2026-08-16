import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/providers/fm_transmitter_provider.dart';
import 'package:headunit_os/services/fm_transmitter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FmTransmitterProvider State Tests', () {
    test('FmTransmitterProvider initializes with default frequency 88.3 MHz and KT0803K hardware', () {
      final provider = FmTransmitterProvider();
      expect(provider.frequencyMhz, equals(88.3));
      expect(provider.selectedHardware, equals(FmHardwareType.kt0803k));
      expect(provider.isTransmitting, isTrue);
      expect(provider.rdsEnabled, isTrue);
      expect(provider.presetFrequencies, contains(88.3));
    });

    test('setFrequency updates frequency within bounds (87.5 - 108.0 MHz)', () {
      final provider = FmTransmitterProvider();
      provider.setFrequency(95.5);
      expect(provider.frequencyMhz, equals(95.5));

      // Lower boundary clamping
      provider.setFrequency(80.0);
      expect(provider.frequencyMhz, equals(87.5));

      // Upper boundary clamping
      provider.setFrequency(115.0);
      expect(provider.frequencyMhz, equals(108.0));
    });

    test('stepFrequency increments and decrements correctly', () {
      final provider = FmTransmitterProvider();
      provider.setFrequency(88.3);

      provider.stepFrequency(0.1);
      expect(provider.frequencyMhz, equals(88.4));

      provider.stepFrequency(-0.2);
      expect(provider.frequencyMhz, equals(88.2));
    });

    test('toggleTransmitter and toggleRds update state', () {
      final provider = FmTransmitterProvider();

      provider.toggleTransmitter(false);
      expect(provider.isTransmitting, isFalse);

      provider.toggleRds(false);
      expect(provider.rdsEnabled, isFalse);
    });

    test('setHardwareType updates selected hardware module', () {
      final provider = FmTransmitterProvider();

      provider.setHardwareType(FmHardwareType.kt0803l);
      expect(provider.selectedHardware, equals(FmHardwareType.kt0803l));
    });

    test('detectHardware sets isHardwareDetected', () async {
      final provider = FmTransmitterProvider();
      await provider.detectHardware();
      expect(provider.isHardwareDetected, isTrue);
    });
  });
}
