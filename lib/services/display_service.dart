import 'dart:io';
import 'package:flutter/foundation.dart';

class DisplayService {
  /// Sets display hardware brightness (value from 0.1 to 1.0).
  Future<bool> setHardwareBrightness(double brightness) async {
    final clamped = brightness.clamp(0.1, 1.0);
    if (!Platform.isLinux) return true;

    try {
      // 1. Try sysfs RPi backlight controller (/sys/class/backlight/rpi_backlight/brightness)
      final sysfsDir = Directory('/sys/class/backlight');
      if (await sysfsDir.exists()) {
        final entries = await sysfsDir.list().toList();
        for (var entry in entries) {
          if (entry is Directory) {
            final brightnessFile = File('${entry.path}/brightness');
            final maxFile = File('${entry.path}/max_brightness');
            if (await brightnessFile.exists()) {
              int maxVal = 255;
              if (await maxFile.exists()) {
                final maxStr = await maxFile.readAsString();
                maxVal = int.tryParse(maxStr.trim()) ?? 255;
              }
              final targetVal = (clamped * maxVal).round();
              await Process.run('sh', ['-c', 'echo $targetVal > ${brightnessFile.path}']);
              if (kDebugMode) print('[DisplayService] Set sysfs brightness: $targetVal / $maxVal');
              return true;
            }
          }
        }
      }

      // 2. Try xrandr software display brightness control
      final xrandrResult = await Process.run('xrandr', ['--verbose']);
      if (xrandrResult.exitCode == 0) {
        final output = xrandrResult.stdout.toString();
        final match = RegExp(r'^(\S+)\s+connected', multiLine: true).firstMatch(output);
        if (match != null) {
          final displayName = match.group(1);
          await Process.run('xrandr', ['--output', displayName!, '--brightness', clamped.toStringAsFixed(2)]);
          if (kDebugMode) print('[DisplayService] Set xrandr display $displayName brightness: ${clamped.toStringAsFixed(2)}');
          return true;
        }
      }

      // 3. Try ddcutil DDC/CI monitor control
      final ddcVal = (clamped * 100).round();
      await Process.run('ddcutil', ['setvcp', '10', '$ddcVal']);
      return true;
    } catch (e) {
      if (kDebugMode) print('[DisplayService] Hardware brightness exception: $e');
      return false;
    }
  }
}
