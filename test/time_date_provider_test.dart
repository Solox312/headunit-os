import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/providers/time_date_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimeDateProvider Unit Tests', () {
    test('formatTime correctly formats 12-hour and 24-hour time', () {
      final provider = TimeDateProvider();
      final testTime = DateTime(2026, 8, 16, 14, 30, 45); // 2:30:45 PM

      // Default 12-hour
      provider.setUse24HourFormat(false);
      expect(provider.formatTime(testTime, withSeconds: false), equals('2:30 PM'));
      expect(provider.formatTime(testTime, withSeconds: true), equals('2:30:45 PM'));

      // 24-hour
      provider.setUse24HourFormat(true);
      expect(provider.formatTime(testTime, withSeconds: false), equals('14:30'));
      expect(provider.formatTime(testTime, withSeconds: true), equals('14:30:45'));
    });

    test('formatDate correctly formats date with patterns', () {
      final provider = TimeDateProvider();
      final testDate = DateTime(2026, 8, 16);

      provider.setDateFormatPattern('EEEE, MMMM d, yyyy');
      expect(provider.formatDate(testDate), equals('Sunday, August 16, 2026'));

      provider.setDateFormatPattern('yyyy-MM-dd');
      expect(provider.formatDate(testDate), equals('2026-08-16'));

      provider.setDateFormatPattern('MM/dd/yyyy');
      expect(provider.formatDate(testDate), equals('08/16/2026'));

      provider.setDateFormatPattern('dd/MM/yyyy');
      expect(provider.formatDate(testDate), equals('16/08/2026'));
    });

    test('setShowSeconds toggles showSeconds property', () {
      final provider = TimeDateProvider();
      provider.setShowSeconds(false);
      expect(provider.showSeconds, isFalse);

      provider.setShowSeconds(true);
      expect(provider.showSeconds, isTrue);
    });
  });
}
