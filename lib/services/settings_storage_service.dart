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
}
