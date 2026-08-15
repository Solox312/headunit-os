import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Details of the update check results.
class UpdateCheckResult {
  final bool success;
  final bool updateAvailable;
  final String? errorMessage;
  final String? remoteVersion;
  final int? remoteBuildNumber;
  final List<String> changelog;
  final String? downloadUrl;

  const UpdateCheckResult({
    required this.success,
    required this.updateAvailable,
    this.errorMessage,
    this.remoteVersion,
    this.remoteBuildNumber,
    this.changelog = const [],
    this.downloadUrl,
  });
}

/// Service for handling OTA/system updates of HeadUnit OS.
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Injectable flag to simulate OverlayFS for testing UI warnings.
  static bool simulateOverlayFs = false;

  /// Check if OverlayFS is active (meaning the root filesystem is mounted as read-only).
  Future<bool> checkOverlayFsActive() async {
    if (simulateOverlayFs) return true;
    if (!Platform.isLinux) return false;

    try {
      final file = File('/proc/mounts');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          final parts = line.split(' ');
          if (parts.length >= 3) {
            final mountPoint = parts[1];
            final fsType = parts[2];
            if (mountPoint == '/' && fsType == 'overlay') {
              return true;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[UpdateService] Error checking OverlayFS: $e');
    }
    return false;
  }

  /// Parse the local application version and build number from pubspec.yaml.
  Future<Map<String, dynamic>> getLocalVersionInfo() async {
    try {
      final pubspecFile = File('pubspec.yaml');
      if (await pubspecFile.exists()) {
        final lines = await pubspecFile.readAsLines();
        for (var line in lines) {
          if (line.trim().startsWith('version:')) {
            final ver = line.split(':').last.trim(); // e.g. "1.0.0+1"
            final parts = ver.split('+');
            final String versionStr = parts[0];
            final int buildNum = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
            return {
              'version': versionStr,
              'buildNumber': buildNum,
            };
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[UpdateService] Error parsing local version: $e');
    }
    return {
      'version': '1.0.0',
      'buildNumber': 1,
    };
  }

  /// Query the remote update JSON manifest to see if a newer version exists.
  Future<UpdateCheckResult> checkForUpdates(String manifestUrl) async {
    // If not running on Linux, or if no internet, run simulator mode.
    if (!Platform.isLinux) {
      await Future.delayed(const Duration(seconds: 1));
      final localInfo = await getLocalVersionInfo();
      final localBuild = localInfo['buildNumber'] as int;

      return UpdateCheckResult(
        success: true,
        updateAvailable: true,
        remoteVersion: '1.1.0',
        remoteBuildNumber: localBuild + 1,
        changelog: const [
          'Added software update system over Wi-Fi',
          'Added OverlayFS read-only status alerts',
          'Improved settings screen diagnostics interface',
          'Resolved memory leak in media AVRCP listener',
        ],
        downloadUrl: 'https://example.com/headunit-os-bundle.tar.gz',
      );
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      
      final request = await client.getUrl(Uri.parse(manifestUrl));
      final response = await request.close();
      
      if (response.statusCode != 200) {
        return UpdateCheckResult(
          success: false,
          updateAvailable: false,
          errorMessage: 'Server returned HTTP ${response.statusCode}',
        );
      }

      final body = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = json.decode(body);

      final String remoteVersion = data['version'] ?? '1.0.0';
      final int remoteBuildNumber = data['build_number'] ?? 1;
      final List<String> changelog = List<String>.from(data['changelog'] ?? []);
      final String downloadUrl = data['download_url'] ?? '';

      final localInfo = await getLocalVersionInfo();
      final int localBuildNumber = localInfo['buildNumber'] as int;

      final bool updateAvailable = remoteBuildNumber > localBuildNumber;

      return UpdateCheckResult(
        success: true,
        updateAvailable: updateAvailable,
        remoteVersion: remoteVersion,
        remoteBuildNumber: remoteBuildNumber,
        changelog: changelog,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      if (kDebugMode) print('[UpdateService] Check update exception: $e');
      return UpdateCheckResult(
        success: false,
        updateAvailable: false,
        errorMessage: 'Connection failed: $e',
      );
    }
  }

  /// Download the update bundle, reporting progress from 0.0 to 1.0.
  Future<bool> downloadUpdate(
    String downloadUrl,
    String savePath,
    Function(double progress) onProgress,
  ) async {
    if (!Platform.isLinux) {
      // Simulate download progress
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress(i / 100.0);
      }
      return true;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      
      final request = await client.getUrl(Uri.parse(downloadUrl));
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw HttpException("Download failed: Status ${response.statusCode}");
      }
      
      final file = File(savePath);
      final sink = file.openWrite();
      
      final totalBytes = response.contentLength;
      int receivedBytes = 0;
      
      await response.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      });
      
      await sink.close();
      return true;
    } catch (e) {
      if (kDebugMode) print('[UpdateService] Download error: $e');
      return false;
    }
  }

  /// Runs the update extraction shell script, returning a real-time log stream.
  Stream<String> applyUpdate(String updateFilePath) async* {
    if (!Platform.isLinux) {
      yield "Starting extraction...";
      await Future.delayed(const Duration(seconds: 1));
      yield "Extracting update package to project directory...";
      await Future.delayed(const Duration(seconds: 1));
      yield "✓ Extraction complete.";
      await Future.delayed(const Duration(seconds: 1));
      yield "Restarting HeadUnit OS Service...";
      await Future.delayed(const Duration(seconds: 1));
      yield "✓ Service restart signal sent.";
      yield "Update applied successfully!";
      return;
    }

    final projectDir = Directory.current.path;
    Process? process;
    try {
      process = await Process.start('sudo', [
        'bash',
        '$projectDir/scripts/apply_update.sh',
        updateFilePath,
        projectDir,
      ]);
    } catch (e) {
      yield "Failed to start update process: $e";
      return;
    }

    final Stream<String> stdoutLines = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    final Stream<String> stderrLines = process.stderr.transform(utf8.decoder).transform(const LineSplitter());

    final StreamController<String> mergedController = StreamController<String>();
    final stdoutSub = stdoutLines.listen((line) => mergedController.add(line));
    final stderrSub = stderrLines.listen((line) => mergedController.add(line));

    final exitCodeFuture = process.exitCode;
    int completed = 0;
    
    void checkDone() {
      completed++;
      if (completed == 2) {
        exitCodeFuture.then((code) {
          if (code != 0) {
            mergedController.add("Process exited with error code $code");
          }
          mergedController.close();
        });
      }
    }

    stdoutSub.onDone(checkDone);
    stderrSub.onDone(checkDone);

    yield* mergedController.stream;
  }

  /// Reboot the system to complete the update process.
  Future<bool> rebootSystem() async {
    if (!Platform.isLinux) {
      if (kDebugMode) print('[UpdateService] Simulator mode: Mocking system reboot');
      return true;
    }
    try {
      final result = await Process.run('sudo', ['reboot']);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[UpdateService] Reboot error: $e');
      return false;
    }
  }
}
