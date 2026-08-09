import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Track metadata read from the BlueZ org.bluez.MediaPlayer1 D-Bus interface via AVRCP.
class AvrcpTrackInfo {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Duration position;
  final bool isPlaying;

  const AvrcpTrackInfo({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.position,
    required this.isPlaying,
  });

  static const AvrcpTrackInfo empty = AvrcpTrackInfo(
    title: '',
    artist: '',
    album: '',
    duration: Duration.zero,
    position: Duration.zero,
    isPlaying: false,
  );

  bool get hasTrack => title.isNotEmpty || artist.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is AvrcpTrackInfo &&
      title == other.title &&
      artist == other.artist &&
      isPlaying == other.isPlaying;

  @override
  int get hashCode => Object.hash(title, artist, isPlaying);
}

/// Service that reads Bluetooth AVRCP (A/V Remote Control Profile) track
/// metadata from the BlueZ org.bluez.MediaPlayer1 D-Bus interface.
///
/// Polls the connected phone's media player state (title, artist, album,
/// duration, play/pause) and emits [AvrcpTrackInfo] updates via [onTrackChanged].
class AvrcpService {
  static final AvrcpService _instance = AvrcpService._internal();
  factory AvrcpService() => _instance;
  AvrcpService._internal();

  Timer? _pollTimer;
  String? _activeDeviceMac;
  AvrcpTrackInfo _lastTrack = AvrcpTrackInfo.empty;

  /// Stream of track metadata changes.
  final StreamController<AvrcpTrackInfo> _trackController =
      StreamController<AvrcpTrackInfo>.broadcast();
  Stream<AvrcpTrackInfo> get onTrackChanged => _trackController.stream;

  /// Start polling AVRCP for the given Bluetooth device MAC address.
  void startPolling(String macAddress) {
    if (!Platform.isLinux) return;

    _activeDeviceMac = macAddress;
    _pollTimer?.cancel();

    // Poll every 2 seconds for track changes.
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_activeDeviceMac != null) {
        await _pollTrackInfo(_activeDeviceMac!);
      }
    });

    if (kDebugMode) print('[AvrcpService] Started AVRCP polling for $macAddress');
  }

  /// Stop AVRCP polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeDeviceMac = null;
    _lastTrack = AvrcpTrackInfo.empty;
    if (kDebugMode) print('[AvrcpService] Stopped AVRCP polling.');
  }

  /// Poll BlueZ MediaPlayer1 D-Bus interface for track metadata.
  Future<void> _pollTrackInfo(String macAddress) async {
    try {
      // Convert MAC address format (AA:BB:CC:DD:EE:FF → AA_BB_CC_DD_EE_FF) for D-Bus path.
      final devPath = macAddress.replaceAll(':', '_');
      final basePath = '/org/bluez/hci0/dev_$devPath';
      final playerPath = '$basePath/player0';

      // Query MediaPlayer1 Status (playing/paused/stopped)
      final statusResult = await Process.run('dbus-send', [
        '--system',
        '--print-reply=literal',
        '--dest=org.bluez',
        playerPath,
        'org.freedesktop.DBus.Properties.Get',
        'string:org.bluez.MediaPlayer1',
        'string:Status',
      ]);

      // Query MediaPlayer1 Track metadata dict
      final trackResult = await Process.run('dbus-send', [
        '--system',
        '--print-reply=literal',
        '--dest=org.bluez',
        playerPath,
        'org.freedesktop.DBus.Properties.Get',
        'string:org.bluez.MediaPlayer1',
        'string:Track',
      ]);

      // Query MediaPlayer1 Position (milliseconds)
      final posResult = await Process.run('dbus-send', [
        '--system',
        '--print-reply=literal',
        '--dest=org.bluez',
        playerPath,
        'org.freedesktop.DBus.Properties.Get',
        'string:org.bluez.MediaPlayer1',
        'string:Position',
      ]);

      if (statusResult.exitCode != 0 || trackResult.exitCode != 0) {
        // Player not available yet — silently skip
        return;
      }

      final statusOutput = statusResult.stdout.toString();
      final trackOutput = trackResult.stdout.toString();
      final posOutput = posResult.stdout.toString();

      final isPlaying = statusOutput.contains('playing');
      final title = _parseStringValue(trackOutput, 'Title');
      final artist = _parseStringValue(trackOutput, 'Artist');
      final album = _parseStringValue(trackOutput, 'Album');
      final durationMs = _parseDurationMs(trackOutput, 'Duration');
      final positionMs = _parseUint32(posOutput);

      final track = AvrcpTrackInfo(
        title: title,
        artist: artist,
        album: album,
        duration: Duration(milliseconds: durationMs),
        position: Duration(milliseconds: positionMs),
        isPlaying: isPlaying,
      );

      // Only emit if something changed
      if (track != _lastTrack) {
        _lastTrack = track;
        _trackController.add(track);
        if (kDebugMode) {
          print('[AvrcpService] Track update: "${track.title}" by "${track.artist}" (${track.isPlaying ? "playing" : "paused"})');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[AvrcpService] Poll error: $e');
    }
  }

  /// Parse a string value from dbus-send --print-reply=literal Track dict output.
  /// Example line: `   "Title" variant             string "Song Name"`
  String _parseStringValue(String output, String key) {
    final lines = output.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('"$key"') && i + 1 < lines.length) {
        final valueLine = lines[i + 1];
        final match = RegExp(r'string\s+"([^"]*)"').firstMatch(valueLine);
        if (match != null) return match.group(1) ?? '';
      }
      // Also try same-line format
      final sameLineMatch = RegExp('"$key".*string\\s+"([^"]*)"').firstMatch(lines[i]);
      if (sameLineMatch != null) return sameLineMatch.group(1) ?? '';
    }
    return '';
  }

  /// Parse duration value (uint32 milliseconds) from Track dict.
  int _parseDurationMs(String output, String key) {
    final lines = output.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('"$key"')) {
        final search = i + 1 < lines.length ? lines[i] + lines[i + 1] : lines[i];
        final match = RegExp(r'uint32\s+(\d+)').firstMatch(search);
        if (match != null) return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }
    return 0;
  }

  /// Parse a raw uint32 from a single-property dbus-send reply (Position).
  int _parseUint32(String output) {
    final match = RegExp(r'uint32\s+(\d+)').firstMatch(output);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  /// Send AVRCP play command to the connected device.
  Future<void> sendPlay(String macAddress) async {
    final devPath = macAddress.replaceAll(':', '_');
    await Process.run('dbus-send', [
      '--system', '--print-reply',
      '--dest=org.bluez',
      '/org/bluez/hci0/dev_$devPath/player0',
      'org.bluez.MediaPlayer1.Play',
    ]);
  }

  /// Send AVRCP pause command to the connected device.
  Future<void> sendPause(String macAddress) async {
    final devPath = macAddress.replaceAll(':', '_');
    await Process.run('dbus-send', [
      '--system', '--print-reply',
      '--dest=org.bluez',
      '/org/bluez/hci0/dev_$devPath/player0',
      'org.bluez.MediaPlayer1.Pause',
    ]);
  }

  /// Send AVRCP next track command to the connected device.
  Future<void> sendNext(String macAddress) async {
    final devPath = macAddress.replaceAll(':', '_');
    await Process.run('dbus-send', [
      '--system', '--print-reply',
      '--dest=org.bluez',
      '/org/bluez/hci0/dev_$devPath/player0',
      'org.bluez.MediaPlayer1.Next',
    ]);
  }

  /// Send AVRCP previous track command to the connected device.
  Future<void> sendPrevious(String macAddress) async {
    final devPath = macAddress.replaceAll(':', '_');
    await Process.run('dbus-send', [
      '--system', '--print-reply',
      '--dest=org.bluez',
      '/org/bluez/hci0/dev_$devPath/player0',
      'org.bluez.MediaPlayer1.Previous',
    ]);
  }

  void dispose() {
    stopPolling();
    _trackController.close();
  }
}
