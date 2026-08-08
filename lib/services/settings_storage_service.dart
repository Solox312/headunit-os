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
      try {
        final file = await _getSettingsFile();
        final tmpFile = File('${file.path}.tmp');
        await tmpFile.writeAsString(jsonEncode(_inMemorySettings));
        await tmpFile.rename(file.path);
        if (kDebugMode) print('[SettingsStorageService] Saved settings cleanly to disk: $_inMemorySettings');
      } catch (e) {
        if (kDebugMode) print('[SettingsStorageService] Exception saving settings: $e');
      }
    });
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
}
