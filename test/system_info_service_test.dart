import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/services/system_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemInfoService Tests', () {
    test('getRealSystemInfo returns non-empty OS and kernel telemetry', () async {
      final info = await SystemInfoService.getRealSystemInfo();

      expect(info.osVersion, contains('HeadUnit OS'));
      expect(info.kernelVersion, isNotEmpty);
      expect(info.hardwareModel, isNotEmpty);
      expect(info.cpuArchitecture, isNotEmpty);
      expect(info.totalRam, isNotEmpty);
      expect(info.dartVersion, isNotEmpty);
    });
  });
}
