import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/settings_storage_service.dart';

class DateFormatOption {
  final String pattern;
  final String label;

  const DateFormatOption({
    required this.pattern,
    required this.label,
  });

  String formatExample(DateTime dt) {
    return DateFormat(pattern).format(dt);
  }
}

class TimeDateProvider extends ChangeNotifier {
  final SettingsStorageService _storage = SettingsStorageService();

  bool _use24HourFormat = false;
  bool _showSeconds = true;
  String _dateFormatPattern = 'EEEE, MMMM d, yyyy';

  static const List<DateFormatOption> availableDateFormats = [
    DateFormatOption(
      pattern: 'EEEE, MMMM d, yyyy',
      label: 'Full (Weekday, Month Day, Year)',
    ),
    DateFormatOption(
      pattern: 'MMMM d, yyyy',
      label: 'Long (Month Day, Year)',
    ),
    DateFormatOption(
      pattern: 'MMM d, yyyy',
      label: 'Abbreviated (Mon Day, Year)',
    ),
    DateFormatOption(
      pattern: 'MM/dd/yyyy',
      label: 'US Numeric (MM/DD/YYYY)',
    ),
    DateFormatOption(
      pattern: 'dd/MM/yyyy',
      label: 'EU Numeric (DD/MM/YYYY)',
    ),
    DateFormatOption(
      pattern: 'yyyy-MM-dd',
      label: 'ISO 8601 (YYYY-MM-DD)',
    ),
  ];

  bool get use24HourFormat => _use24HourFormat;
  bool get showSeconds => _showSeconds;
  String get dateFormatPattern => _dateFormatPattern;

  TimeDateProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _use24HourFormat = await _storage.loadUse24HourFormat();
    _showSeconds = await _storage.loadShowSeconds();
    _dateFormatPattern = await _storage.loadDateFormatPattern();
    notifyListeners();
  }

  /// Formats the given time according to 12-hour or 24-hour preference.
  String formatTime(DateTime dt, {bool withSeconds = false}) {
    if (_use24HourFormat) {
      return DateFormat(withSeconds ? 'HH:mm:ss' : 'HH:mm').format(dt);
    } else {
      return DateFormat(withSeconds ? 'h:mm:ss a' : 'h:mm a').format(dt);
    }
  }

  /// Formats the given date according to the chosen pattern.
  String formatDate(DateTime dt) {
    try {
      return DateFormat(_dateFormatPattern).format(dt);
    } catch (_) {
      return DateFormat('EEEE, MMMM d, yyyy').format(dt);
    }
  }

  void setUse24HourFormat(bool value) {
    if (_use24HourFormat == value) return;
    _use24HourFormat = value;
    notifyListeners();
    _storage.saveUse24HourFormat(value);
  }

  void setShowSeconds(bool value) {
    if (_showSeconds == value) return;
    _showSeconds = value;
    notifyListeners();
    _storage.saveShowSeconds(value);
  }

  void setDateFormatPattern(String pattern) {
    if (_dateFormatPattern == pattern) return;
    _dateFormatPattern = pattern;
    notifyListeners();
    _storage.saveDateFormatPattern(pattern);
  }
}
