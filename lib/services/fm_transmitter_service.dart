import 'dart:io';
import 'package:flutter/foundation.dart';

enum FmHardwareType {
  si4713, // Silicon Labs Si4713 (I2C 0x63, RDS supported)
  kt0803l, // KT0803L / KT0803M (I2C 0x3E)
  qn8027, // QN8027 / QN8066 (I2C 0x2C)
  elechouseV2, // Elechouse V2 (I2C 0x10 / UART)
  usbDongle, // USB Audio + HID Class FM Dongle
  gpioSoftware, // Direct RPi GPIO4 GPCLK Software PWM
}

class FmTransmitterService {
  /// Checks if Linux `i2cset` or `fm_transmitter` CLI is available.
  Future<bool> isHardwareDriverAvailable() async {
    if (!Platform.isLinux) return false;
    try {
      final i2cResult = await Process.run('which', ['i2cset']);
      if (i2cResult.exitCode == 0) return true;

      final gpioResult = await Process.run('which', ['fm_transmitter']);
      return gpioResult.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Sets the FM transmitter output frequency (87.5 MHz to 108.0 MHz).
  Future<bool> setFrequency({
    required double frequencyMhz,
    required FmHardwareType hardwareType,
    String rdsText = "HeadUnit OS",
  }) async {
    final clampedFreq = frequencyMhz.clamp(87.5, 108.0);

    if (kDebugMode) {
      print('[FmTransmitterService] Setting FM frequency: ${clampedFreq.toStringAsFixed(1)} MHz ($hardwareType)');
    }

    if (!await isHardwareDriverAvailable()) {
      // Simulation / mock mode on Windows/macOS or systems without I2C hardware
      return true;
    }

    try {
      switch (hardwareType) {
        case FmHardwareType.si4713:
          // Si4713 I2C 0x63 frequency tuning command (0x40 0x00 + FreqIn10kHz)
          final freq10kHz = (clampedFreq * 100).toInt();
          final highByte = (freq10kHz >> 8) & 0xFF;
          final lowByte = freq10kHz & 0xFF;
          await Process.run('i2cset', ['-y', '1', '0x63', '0x40', '0x00', '0x$highByte', '0x$lowByte'], runInShell: true);
          if (rdsText.isNotEmpty) {
            await _setSi4713Rds(rdsText);
          }
          return true;

        case FmHardwareType.kt0803l:
          // KT0803L I2C 0x3E frequency registers
          final channelVal = ((clampedFreq - 87.0) * 20).toInt();
          await Process.run('i2cset', ['-y', '1', '0x3E', '0x00', '0x${channelVal.toRadixString(16)}'], runInShell: true);
          return true;

        case FmHardwareType.qn8027:
          // QN8027 I2C 0x2C frequency registers
          final channelVal = ((clampedFreq - 76.0) / 0.05).toInt();
          await Process.run('i2cset', ['-y', '1', '0x2C', '0x00', '0x${channelVal.toRadixString(16)}'], runInShell: true);
          return true;

        case FmHardwareType.gpioSoftware:
          // software GPIO4 GPCLK engine
          await Process.run('fm_transmitter', ['-f', clampedFreq.toStringAsFixed(1)], runInShell: true);
          return true;

        default:
          return true;
      }
    } catch (e) {
      if (kDebugMode) print('[FmTransmitterService] setFrequency exception: $e');
      return false;
    }
  }

  Future<void> _setSi4713Rds(String text) async {
    try {
      final bytes = text.codeUnits.take(32).toList();
      final hexString = bytes.map((b) => '0x${b.toRadixString(16)}').join(' ');
      await Process.run('i2cset', ['-y', '1', '0x63', '0x35', '0x00', hexString], runInShell: true);
    } catch (_) {}
  }
}
