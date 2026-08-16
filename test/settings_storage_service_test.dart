import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/services/settings_storage_service.dart';
import 'package:headunit_os/providers/vehicle_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsStorageService Tests', () {
    test('saveBrightness and loadBrightness persists brightness value', () async {
      final storage = SettingsStorageService();
      await storage.saveBrightness(0.45);

      final loaded = await storage.loadBrightness();
      expect(loaded, equals(0.45));
    });

    test('saveDriverName and loadDriverName persists driver name', () async {
      final storage = SettingsStorageService();
      await storage.saveDriverName('Carl');

      final loaded = await storage.loadDriverName();
      expect(loaded, equals('Carl'));
    });

    test('saveAudioOutputTarget and loadAudioOutputTarget persists selected target', () async {
      final storage = SettingsStorageService();
      await storage.saveAudioOutputTarget('Car Bluetooth Stereo (A2DP)');

      final loaded = await storage.loadAudioOutputTarget();
      expect(loaded, equals('Car Bluetooth Stereo (A2DP)'));
    });

    test('loadAudioOutputTarget returns default AUX target when unset or empty', () async {
      final storage = SettingsStorageService();
      await storage.saveSettings({'audioOutputTarget': ''});

      final loaded = await storage.loadAudioOutputTarget();
      expect(loaded, equals('AUX Cable / 3.5mm DAC'));
    });

    test('saveUse24HourFormat and loadUse24HourFormat persists 24-hour setting', () async {
      final storage = SettingsStorageService();
      await storage.saveUse24HourFormat(true);

      final loaded = await storage.loadUse24HourFormat();
      expect(loaded, isTrue);
    });

    test('saveShowSeconds and loadShowSeconds persists show seconds setting', () async {
      final storage = SettingsStorageService();
      await storage.saveShowSeconds(false);

      final loaded = await storage.loadShowSeconds();
      expect(loaded, isFalse);
    });

    test('saveDateFormatPattern and loadDateFormatPattern persists pattern', () async {
      final storage = SettingsStorageService();
      await storage.saveDateFormatPattern('yyyy-MM-dd');

      final loaded = await storage.loadDateFormatPattern();
      expect(loaded, equals('yyyy-MM-dd'));
    });

    test('saveFmFrequency and loadFmFrequency persists FM frequency', () async {
      final storage = SettingsStorageService();
      await storage.saveFmFrequency(91.7);

      final loaded = await storage.loadFmFrequency();
      expect(loaded, equals(91.7));
    });

    test('saveFmHardwareType and loadFmHardwareType persists hardware type', () async {
      final storage = SettingsStorageService();
      await storage.saveFmHardwareType('kt0803k');

      final loaded = await storage.loadFmHardwareType();
      expect(loaded, equals('kt0803k'));
    });

    test('VehicleProvider updateDriverName capitalizes lowercase names', () async {
      final provider = VehicleProvider();
      await provider.updateDriverName('carl smith');

      expect(provider.driverName, equals('Carl Smith'));
    });
  });
}
