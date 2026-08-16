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

    test('VehicleProvider updateDriverName capitalizes lowercase names', () async {
      final provider = VehicleProvider();
      await provider.updateDriverName('carl smith');

      expect(provider.driverName, equals('Carl Smith'));
    });
  });
}
