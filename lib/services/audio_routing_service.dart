import 'dart:io';
import 'package:flutter/foundation.dart';
import 'settings_storage_service.dart';

/// System service for managing physical and wireless audio routing on Linux (PulseAudio & PipeWire)
/// Enforces user-selected audio routing targets:
/// - "AUX Cable / 3.5mm DAC"
/// - "HDMI Display Speakers"
/// - "FM Transmitter" (feeds KT0803K analog line-in)
/// - "Car Bluetooth Stereo (A2DP)"
class AudioRoutingService {
  static final AudioRoutingService _instance = AudioRoutingService._internal();
  factory AudioRoutingService() => _instance;
  AudioRoutingService._internal();

  String _currentTarget = "AUX Cable / 3.5mm DAC";
  String get currentTarget => _currentTarget;

  /// Initialize and apply the persisted audio target on startup.
  Future<void> init() async {
    final savedTarget = await SettingsStorageService().loadAudioOutputTarget();
    _currentTarget = savedTarget;
    await applyAudioRouting(_currentTarget);
  }

  /// Applies the selected audio routing target across Linux PulseAudio and PipeWire/WirePlumber.
  Future<bool> applyAudioRouting(String target) async {
    _currentTarget = target;
    if (!Platform.isLinux) {
      if (kDebugMode) {
        print('[AudioRoutingService] Simulator: Applied audio target "$target"');
      }
      return true;
    }

    try {
      final sinks = await _getAvailableSinks();
      if (kDebugMode) {
        print('[AudioRoutingService] Available sinks on system: $sinks');
      }

      String? targetSink;

      if (target.contains('AUX') || target.contains('3.5mm') || target.contains('FM Transmitter')) {
        // Find Analog / Headphones / USB Audio / DAC sink
        targetSink = sinks.firstWhere(
          (s) => s.contains('analog') || s.contains('headphones') || s.contains('usb') || s.contains('codec') || s.contains('es8316') || s.contains('rk817'),
          orElse: () => sinks.firstWhere(
            (s) => !s.contains('bluez') && !s.contains('hdmi'),
            orElse: () => sinks.isNotEmpty ? sinks.first : '',
          ),
        );
      } else if (target.contains('HDMI')) {
        // Find HDMI audio sink
        targetSink = sinks.firstWhere(
          (s) => s.contains('hdmi'),
          orElse: () => sinks.isNotEmpty ? sinks.first : '',
        );
      } else if (target.contains('Bluetooth')) {
        // Find BlueZ A2DP output sink
        targetSink = sinks.firstWhere(
          (s) => s.contains('bluez'),
          orElse: () => '',
        );
      }

      if (targetSink != null && targetSink.isNotEmpty) {
        // 1. Set default sink in PulseAudio
        await Process.run('pactl', ['set-default-sink', targetSink]);
        if (kDebugMode) {
          print('[AudioRoutingService] Set pactl default-sink: $targetSink for target "$target"');
        }

        // 2. Move all currently playing audio streams (sink-inputs) to the selected sink
        await _moveActiveStreamsToSink(targetSink);

        // 3. Apply to PipeWire / WirePlumber if active
        await _applyWirePlumberDefaultSink(targetSink);
        return true;
      } else {
        if (kDebugMode) {
          print('[AudioRoutingService] No matching sink found for target "$target"');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('[AudioRoutingService] Error applying audio routing: $e');
      return false;
    }
  }

  /// Lists all available audio sink names on Linux.
  Future<List<String>> _getAvailableSinks() async {
    final sinks = <String>[];
    try {
      final result = await Process.run('pactl', ['list', 'sinks', 'short']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final name = parts[1];
            if (name.isNotEmpty) sinks.add(name);
          }
        }
      }
    } catch (_) {}
    return sinks;
  }

  /// Moves all currently active audio playback streams to the selected sink.
  Future<void> _moveActiveStreamsToSink(String sinkName) async {
    try {
      final result = await Process.run('pactl', ['list', 'sink-inputs', 'short']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            final inputId = parts[0];
            if (int.tryParse(inputId) != null) {
              await Process.run('pactl', ['move-sink-input', inputId, sinkName]);
              if (kDebugMode) {
                print('[AudioRoutingService] Moved audio stream #$inputId -> $sinkName');
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Sets default sink in WirePlumber.
  Future<void> _applyWirePlumberDefaultSink(String sinkName) async {
    try {
      final wpResult = await Process.run('wpctl', ['status']);
      if (wpResult.exitCode == 0) {
        final lines = wpResult.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains(sinkName) && line.contains('.')) {
            final match = RegExp(r'(\d+)\.').firstMatch(line);
            if (match != null) {
              final id = match.group(1)!;
              await Process.run('wpctl', ['set-default', id]);
              if (kDebugMode) print('[AudioRoutingService] Set WirePlumber default sink ID: $id');
              break;
            }
          }
        }
      }
    } catch (_) {}
  }
}
