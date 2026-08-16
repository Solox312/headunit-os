import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SettingsStorageService {
  static final SettingsStorageService _instance = SettingsStorageService._internal();
  factory SettingsStorageService() => _instance;
  SettingsStorageService._internal();

  File? _settingsFileCache;
  Map<String, dynamic>? _inMemorySettings;
  Timer? _debounceTimer;

  Future<File> _getSettingsFile() async {
    if (_settingsFileCache != null) return _settingsFileCache!;

    Directory dir;
    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '.';
      dir = Directory('$home/.config/headunit-os');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '.';
      dir = Directory('$appData\\headunit-os');
    } else {
      dir = Directory.systemTemp;
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _settingsFileCache = File('${dir.path}${Platform.pathSeparator}settings.json');
    return _settingsFileCache!;
  }

  /// Load persisted user settings from JSON file.
  Future<Map<String, dynamic>> loadSettings() async {
    if (_inMemorySettings != null) return _inMemorySettings!;

    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          _inMemorySettings = data;
          if (kDebugMode) print('[SettingsStorageService] Loaded settings: $data');
          return data;
        }
      }
    } catch (e) {
      if (kDebugMode) print('[SettingsStorageService] Exception loading settings: $e');
    }
    _inMemorySettings = {};
    return _inMemorySettings!;
  }

  /// Save settings map to persistent storage file with debouncing & atomic write.
  Future<void> saveSettings(Map<String, dynamic> newSettings) async {
    _inMemorySettings ??= await loadSettings();
    _inMemorySettings!.addAll(newSettings);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _writeToDisk();
    });
  }

  /// Flush any pending debounced save immediately to disk.
  /// Call this before navigating away from a screen that has unsaved critical
  /// state (e.g. onboarding completion), so the write is guaranteed before the
  /// process context changes.
  Future<void> flush() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _writeToDisk();
  }

  Future<void> _writeToDisk() async {
    if (_inMemorySettings == null) return;
    try {
      final file = await _getSettingsFile();
      final tmpFile = File('${file.path}.tmp');
      await tmpFile.writeAsString(jsonEncode(_inMemorySettings));
      await tmpFile.rename(file.path);
      if (kDebugMode) print('[SettingsStorageService] Saved settings cleanly to disk: $_inMemorySettings');
    } catch (e) {
      if (kDebugMode) print('[SettingsStorageService] Exception saving settings: $e');
    }
  }

  /// Helper to save brightness setting specifically.
  Future<void> saveBrightness(double brightness) async {
    await saveSettings({'brightness': brightness});
  }

  /// Helper to read stored brightness setting (returns 0.85 default if not set).
  Future<double> loadBrightness() async {
    final settings = await loadSettings();
    if (settings.containsKey('brightness') && settings['brightness'] is num) {
      final val = (settings['brightness'] as num).toDouble();
      return val.clamp(0.1, 1.0);
    }
    return 0.85;
  }

  /// Helper to save driver profile name.
  Future<void> saveDriverName(String name) async {
    await saveSettings({'driverName': name});
  }

  /// Helper to read stored driver profile name (defaults to 'Change Me').
  Future<String> loadDriverName() async {
    final settings = await loadSettings();
    if (settings.containsKey('driverName') && settings['driverName'] is String) {
      final name = (settings['driverName'] as String).trim();
      if (name.isNotEmpty) return name;
    }
    return 'Change Me';
  }

  /// Helper to save onboarding completion state.
  /// Flushes immediately — this value must be on disk before the caller
  /// navigates to MainNavigationScreen, or the splash screen will show
  /// onboarding again on the next launch.
  Future<void> saveOnboardingCompleted(bool completed) async {
    await saveSettings({'onboardingCompleted': completed});
    await flush();
  }

  /// Helper to read stored onboarding completion state (defaults to false).
  Future<bool> loadOnboardingCompleted() async {
    final settings = await loadSettings();
    if (settings.containsKey('onboardingCompleted') && settings['onboardingCompleted'] is bool) {
      return settings['onboardingCompleted'] as bool;
    }
    return false;
  }

  /// Helper to save driver name prompt skipped state.
  Future<void> saveDriverNamePromptSkipped(bool skipped) async {
    await saveSettings({'driverNamePromptSkipped': skipped});
  }

  /// Helper to read stored driver name prompt skipped state (defaults to false).
  Future<bool> loadDriverNamePromptSkipped() async {
    final settings = await loadSettings();
    if (settings.containsKey('driverNamePromptSkipped') && settings['driverNamePromptSkipped'] is bool) {
      return settings['driverNamePromptSkipped'] as bool;
    }
    return false;
  }

  /// Helper to save audio output target selection.
  Future<void> saveAudioOutputTarget(String target) async {
    await saveSettings({'audioOutputTarget': target});
  }

  /// Helper to read stored audio output target selection (defaults to 'AUX Cable / 3.5mm DAC').
  Future<String> loadAudioOutputTarget() async {
    final settings = await loadSettings();
    if (settings.containsKey('audioOutputTarget') && settings['audioOutputTarget'] is String) {
      final target = (settings['audioOutputTarget'] as String).trim();
      if (target.isNotEmpty) return target;
    }
    return 'AUX Cable / 3.5mm DAC';
  }

  /// Helper to save 24-hour clock setting.
  Future<void> saveUse24HourFormat(bool is24Hour) async {
    await saveSettings({'use24HourFormat': is24Hour});
  }

  /// Helper to read 24-hour clock setting (defaults to false / 12-Hour).
  Future<bool> loadUse24HourFormat() async {
    final settings = await loadSettings();
    if (settings.containsKey('use24HourFormat') && settings['use24HourFormat'] is bool) {
      return settings['use24HourFormat'] as bool;
    }
    return false;
  }

  /// Helper to save show seconds setting.
  Future<void> saveShowSeconds(bool showSeconds) async {
    await saveSettings({'showSeconds': showSeconds});
  }

  /// Helper to read show seconds setting (defaults to true).
  Future<bool> loadShowSeconds() async {
    final settings = await loadSettings();
    if (settings.containsKey('showSeconds') && settings['showSeconds'] is bool) {
      return settings['showSeconds'] as bool;
    }
    return true;
  }

  /// Helper to save date format pattern.
  Future<void> saveDateFormatPattern(String pattern) async {
    await saveSettings({'dateFormatPattern': pattern});
  }

  /// Helper to read date format pattern (defaults to 'EEEE, MMMM d, yyyy').
  Future<String> loadDateFormatPattern() async {
    final settings = await loadSettings();
    if (settings.containsKey('dateFormatPattern') && settings['dateFormatPattern'] is String) {
      final pattern = (settings['dateFormatPattern'] as String).trim();
      if (pattern.isNotEmpty) return pattern;
    }
    return 'EEEE, MMMM d, yyyy';
  }

  /// Helper to save FM transmitter frequency.
  Future<void> saveFmFrequency(double freqMhz) async {
    await saveSettings({'fmFrequency': freqMhz});
  }

  /// Helper to read stored FM transmitter frequency (defaults to 88.3 MHz).
  Future<double> loadFmFrequency() async {
    final settings = await loadSettings();
    if (settings.containsKey('fmFrequency') && settings['fmFrequency'] is num) {
      return (settings['fmFrequency'] as num).toDouble();
    }
    return 88.3;
  }

  /// Helper to save FM transmitter hardware type.
  Future<void> saveFmHardwareType(String hardwareType) async {
    await saveSettings({'fmHardwareType': hardwareType});
  }

  /// Helper to read stored FM transmitter hardware type (defaults to 'kt0803k').
  Future<String> loadFmHardwareType() async {
    final settings = await loadSettings();
    if (settings.containsKey('fmHardwareType') && settings['fmHardwareType'] is String) {
      final type = (settings['fmHardwareType'] as String).trim();
      if (type.isNotEmpty) return type;
    }
    return 'kt0803k';
  }

  /// Helper to save FM transmitting power/enabled state.
  Future<void> saveFmTransmitting(bool isTransmitting) async {
    await saveSettings({'fmTransmitting': isTransmitting});
  }

  /// Helper to read stored FM transmitting state (defaults to true).
  Future<bool> loadFmTransmitting() async {
    final settings = await loadSettings();
    if (settings.containsKey('fmTransmitting') && settings['fmTransmitting'] is bool) {
      return settings['fmTransmitting'] as bool;
    }
    return true;
  }
}
