import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/services/settings_storage_service.dart';

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
  });
}
