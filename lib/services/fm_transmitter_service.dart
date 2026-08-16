import 'dart:io';
import 'package:flutter/foundation.dart';

enum FmHardwareType {
  kt0803k, // On-board KT0803K / KT0803L / KT0803M (I2C 0x3E)
  si4713, // Silicon Labs Si4713 (I2C 0x63, RDS supported)
  kt0803l, // KT0803L / KT0803M (I2C 0x3E)
  qn8027, // QN8027 / QN8066 (I2C 0x2C)
  elechouseV2, // Elechouse V2 (I2C 0x10 / UART)
  usbDongle, // USB Audio + HID Class FM Dongle
  gpioSoftware, // Direct RPi GPIO4 GPCLK Software PWM
}

class FmTransmitterService {
  int _activeI2cBus = 1;
  int get activeI2cBus => _activeI2cBus;

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

  /// Discovers available I2C buses on production boards (/dev/i2c-*).
  Future<List<int>> getAvailableI2cBuses() async {
    if (!Platform.isLinux) return [1];
    final buses = <int>[];
    try {
      final devDir = Directory('/dev');
      if (await devDir.exists()) {
        final entries = await devDir.list().toList();
        for (final entry in entries) {
          final name = entry.path.split(Platform.pathSeparator).last;
          if (name.startsWith('i2c-')) {
            final numStr = name.substring(4);
            final busNum = int.tryParse(numStr);
            if (busNum != null) buses.add(busNum);
          }
        }
      }
    } catch (_) {}

    if (buses.isEmpty) {
      buses.addAll([1, 0, 3, 4, 5, 6]);
    }
    buses.sort();
    return buses;
  }

  /// Probes all available I2C buses on production boards to detect FM transmitter IC.
  Future<FmHardwareType?> detectHardware() async {
    if (!Platform.isLinux) {
      // In simulator / development mode, assume KT0803K on I2C-1
      _activeI2cBus = 1;
      return FmHardwareType.kt0803k;
    }

    try {
      final whichI2c = await Process.run('which', ['i2cget']);
      if (whichI2c.exitCode == 0) {
        final candidateBuses = await getAvailableI2cBuses();

        for (final bus in candidateBuses) {
          // Probe KT0803K at address 0x3E
          final ktResult = await Process.run('i2cget', ['-y', '$bus', '0x3E', '0x00']);
          if (ktResult.exitCode == 0) {
            _activeI2cBus = bus;
            if (kDebugMode) print('[FmTransmitterService] KT0803K detected on production I2C bus $bus (0x3E)');
            return FmHardwareType.kt0803k;
          }

          // Probe Si4713 at address 0x63
          final siResult = await Process.run('i2cget', ['-y', '$bus', '0x63', '0x00']);
          if (siResult.exitCode == 0) {
            _activeI2cBus = bus;
            if (kDebugMode) print('[FmTransmitterService] Si4713 detected on production I2C bus $bus (0x63)');
            return FmHardwareType.si4713;
          }

          // Probe QN8027 at address 0x2C
          final qnResult = await Process.run('i2cget', ['-y', '$bus', '0x2C', '0x00']);
          if (qnResult.exitCode == 0) {
            _activeI2cBus = bus;
            if (kDebugMode) print('[FmTransmitterService] QN8027 detected on production I2C bus $bus (0x2C)');
            return FmHardwareType.qn8027;
          }
        }
      }

      // Check software GPIO transmitter
      final whichGpio = await Process.run('which', ['fm_transmitter']);
      if (whichGpio.exitCode == 0) {
        return FmHardwareType.gpioSoftware;
      }
    } catch (e) {
      if (kDebugMode) print('[FmTransmitterService] detectHardware exception: $e');
    }

    return null;
  }

  /// Probe whether a specific hardware type responds on the active bus.
  Future<bool> probeDevice(FmHardwareType hardwareType) async {
    if (!Platform.isLinux) return true;
    try {
      final bus = '$_activeI2cBus';
      switch (hardwareType) {
        case FmHardwareType.kt0803k:
        case FmHardwareType.kt0803l:
          final result = await Process.run('i2cget', ['-y', bus, '0x3E', '0x00']);
          return result.exitCode == 0;
        case FmHardwareType.si4713:
          final result = await Process.run('i2cget', ['-y', bus, '0x63', '0x00']);
          return result.exitCode == 0;
        case FmHardwareType.qn8027:
          final result = await Process.run('i2cget', ['-y', bus, '0x2C', '0x00']);
          return result.exitCode == 0;
        case FmHardwareType.gpioSoftware:
          final result = await Process.run('which', ['fm_transmitter']);
          return result.exitCode == 0;
        default:
          return false;
      }
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
      print('[FmTransmitterService] Setting FM frequency: ${clampedFreq.toStringAsFixed(1)} MHz ($hardwareType on bus $_activeI2cBus)');
    }

    if (!await isHardwareDriverAvailable()) {
      // Simulation / mock mode on Windows/macOS or systems without I2C hardware
      return true;
    }

    try {
      switch (hardwareType) {
        case FmHardwareType.kt0803k:
        case FmHardwareType.kt0803l:
          return await _setKt0803kFrequency(clampedFreq);

        case FmHardwareType.si4713:
          // Si4713 I2C 0x63 frequency tuning command (0x40 0x00 + FreqIn10kHz)
          final freq10kHz = (clampedFreq * 100).toInt();
          final highByte = (freq10kHz >> 8) & 0xFF;
          final lowByte = freq10kHz & 0xFF;
          await Process.run('i2cset', ['-y', '$_activeI2cBus', '0x63', '0x40', '0x00', '0x$highByte', '0x$lowByte'], runInShell: true);
          if (rdsText.isNotEmpty) {
            await _setSi4713Rds(rdsText);
          }
          return true;

        case FmHardwareType.qn8027:
          // QN8027 I2C 0x2C frequency registers
          final channelVal = ((clampedFreq - 76.0) / 0.05).toInt();
          await Process.run('i2cset', ['-y', '$_activeI2cBus', '0x2C', '0x00', '0x${channelVal.toRadixString(16)}'], runInShell: true);
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

  /// Exact KT0803K / KT0803L I2C register protocol on active bus (0x3E).
  Future<bool> _setKt0803kFrequency(double clampedFreq) async {
    try {
      // Channel calculation: F_RF = 50kHz * CHSEL + 64.0MHz => CHSEL = (F_MHz - 64.0) * 20
      final int chan = ((clampedFreq - 64.0) * 20).round();
      final int chanLow = chan & 0xFF;
      final int chanHigh = (chan >> 8) & 0x03;

      // Reg 0x01: AU_EN (0x10) | PHTCNST_75us (0x08) | CHSEL[9:8] (chanHigh & 0x03)
      final int reg01 = chanHigh | 0x18;
      // Reg 0x02: Max RF power amplifier level (~108 dBuV)
      const int reg02 = 0xB0;
      // Reg 0x04: Unmuted, standard PGA audio gain
      const int reg04 = 0x00;
      // Reg 0x0B: Stereo transmission with 19kHz pilot tone
      const int reg0B = 0x00;
      // Reg 0x13: Active power mode (not standby)
      const int reg13 = 0x00;

      final bus = '$_activeI2cBus';
      await Process.run('i2cset', ['-y', bus, '0x3E', '0x00', '0x${chanLow.toRadixString(16).padLeft(2, '0')}'], runInShell: true);
      await Process.run('i2cset', ['-y', bus, '0x3E', '0x01', '0x${reg01.toRadixString(16).padLeft(2, '0')}'], runInShell: true);
      await Process.run('i2cset', ['-y', bus, '0x3E', '0x02', '0x${reg02.toRadixString(16).padLeft(2, '0')}'], runInShell: true);
      await Process.run('i2cset', ['-y', bus, '0x3E', '0x04', '0x${reg04.toRadixString(16).padLeft(2, '0')}'], runInShell: true);
      await Process.run('i2cset', ['-y', bus, '0x3E', '0x0B', '0x${reg0B.toRadixString(16).padLeft(2, '0')}'], runInShell: true);
      await Process.run('i2cset', ['-y', bus, '0x3E', '0x13', '0x${reg13.toRadixString(16).padLeft(2, '0')}'], runInShell: true);

      if (kDebugMode) {
        print('[FmTransmitterService] KT0803K configured on bus $bus: ${clampedFreq.toStringAsFixed(1)} MHz (Channel 0x${chan.toRadixString(16)})');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[FmTransmitterService] Error communicating with KT0803K: $e');
      return false;
    }
  }

  /// Sets standby or active power state on the hardware.
  Future<bool> setPowerState({
    required bool enabled,
    required FmHardwareType hardwareType,
  }) async {
    if (!await isHardwareDriverAvailable()) return true;
    try {
      if (hardwareType == FmHardwareType.kt0803k || hardwareType == FmHardwareType.kt0803l) {
        final bus = '$_activeI2cBus';
        if (!enabled) {
          // Set standby bit in Reg 0x01 (Bit 6 = 0x40) and Reg 0x13
          await Process.run('i2cset', ['-y', bus, '0x3E', '0x01', '0x40'], runInShell: true);
          await Process.run('i2cset', ['-y', bus, '0x3E', '0x13', '0x01'], runInShell: true);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('[FmTransmitterService] setPowerState error: $e');
      return false;
    }
  }

  Future<void> _setSi4713Rds(String text) async {
    try {
      final bytes = text.codeUnits.take(32).toList();
      final hexString = bytes.map((b) => '0x${b.toRadixString(16)}').join(' ');
      await Process.run('i2cset', ['-y', '$_activeI2cBus', '0x63', '0x35', '0x00', hexString], runInShell: true);
    } catch (_) {}
  }
}
