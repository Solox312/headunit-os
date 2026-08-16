import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/bluetooth_device.dart';
import 'audio_routing_service.dart';

/// System service for scanning, pairing, connecting, and managing Bluetooth devices
/// on both Linux Mint (testing host) and Raspberry Pi OS via Linux BlueZ `bluetoothctl` & `rfkill`.
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  bool? _isBluetoothctlAvailableCache;

  Future<bool> isBluetoothctlAvailable() async {
    if (_isBluetoothctlAvailableCache != null) return _isBluetoothctlAvailableCache!;
    if (!Platform.isLinux) {
      _isBluetoothctlAvailableCache = false;
      return false;
    }
    try {
      final result = await Process.run('which', ['bluetoothctl']);
      _isBluetoothctlAvailableCache = result.exitCode == 0;
      return _isBluetoothctlAvailableCache!;
    } catch (e) {
      _isBluetoothctlAvailableCache = false;
      return false;
    }
  }

  Process? _persistentAgentProcess;
  StreamSubscription<String>? _agentOutputSub;

  /// Initialize Linux Mint & Raspberry Pi Bluetooth Stack (rfkill unblock + BlueZ agent setup).
  /// Uses DisplayYesNo agent with auto-confirm to handle Numeric Comparison pairing
  /// (required by Android phones like Samsung, Xiaomi, etc. that reject NoInputNoOutput).
  Future<bool> initLinuxBluetooth() async {
    if (!await isBluetoothctlAvailable()) return true;

    try {
      await Process.run('rfkill', ['unblock', 'bluetooth']);
      await Process.run('bluetoothctl', ['power', 'on']);
      await Process.run('bluetoothctl', ['system-alias', 'HeadUnit OS']);
      await Process.run('bluetoothctl', ['discoverable', 'on']);
      await Process.run('bluetoothctl', ['pairable', 'on']);

      // Launch persistent interactive bluetoothctl with DisplayYesNo agent.
      // We listen to stdout and auto-respond 'yes' to any passkey confirmation
      // so the user never has to manually confirm pairing on the headunit.
      _persistentAgentProcess?.kill();
      _agentOutputSub?.cancel();
      _persistentAgentProcess = await Process.start('bluetoothctl', []);

      // Wait for bluetoothctl to connect to bluetoothd and show [bluetooth]# prompt
      // before registering agent — otherwise "Failed to register agent object" occurs.
      final completer = Completer<void>();
      final agentStream = _persistentAgentProcess!.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter());

      _agentOutputSub = agentStream.listen((line) {
        if (kDebugMode) print('[BT-Agent] $line');

        // Wait for ready prompt before sending registration commands
        if (!completer.isCompleted && line.contains('[bluetooth]#')) {
          completer.complete();
        }

        final l = line.toLowerCase();
        if (l.contains('confirm passkey') || l.contains('(yes/no)') || l.contains('request confirmation')) {
          _persistentAgentProcess!.stdin.writeln('yes');
          if (kDebugMode) print('[BT-Agent] Auto-confirmed passkey/pairing.');
        } else if (l.contains('authorize service') || l.contains('request authorization') || l.contains('authorize path')) {
          _persistentAgentProcess!.stdin.writeln('yes');
          if (kDebugMode) print('[BT-Agent] Auto-authorized service/path.');
        } else if (l.contains('enter pin code') || l.contains('request pin code')) {
          _persistentAgentProcess!.stdin.writeln('0000');
          if (kDebugMode) print('[BT-Agent] Provided default PIN 0000.');
        } else if (l.contains('enter passkey') || l.contains('request passkey')) {
          _persistentAgentProcess!.stdin.writeln('000000');
          if (kDebugMode) print('[BT-Agent] Provided default passkey 000000.');
        }
      });

      // Wait up to 5 seconds for the [bluetooth]# prompt, then send agent commands
      await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {});
      _persistentAgentProcess!.stdin.writeln('agent DisplayYesNo');
      await Future.delayed(const Duration(milliseconds: 500));
      _persistentAgentProcess!.stdin.writeln('default-agent');
      _persistentAgentProcess!.stdin.writeln('discoverable on');
      _persistentAgentProcess!.stdin.writeln('pairable on');

      if (kDebugMode) print('[BluetoothService] Persistent DisplayYesNo auto-confirm agent running.');
      return true;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Exception initializing Linux Bluetooth: $e');
      return false;
    }
  }

  /// Check if Bluetooth adapter power is turned on.
  Future<bool> isPowerOn() async {
    if (!await isBluetoothctlAvailable()) return true;
    try {
      final result = await Process.run('bluetoothctl', ['show']);
      if (result.exitCode == 0) {
        return result.stdout.toString().contains('Powered: yes');
      }
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Error checking power state: $e');
    }
    return true;
  }

  /// Turn Bluetooth adapter power on or off.
  Future<bool> setPower(bool enabled) async {
    if (!await isBluetoothctlAvailable()) return true;
    try {
      if (enabled) {
        await Process.run('rfkill', ['unblock', 'bluetooth']);
      }
      final result = await Process.run('bluetoothctl', ['power', enabled ? 'on' : 'off']);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Error setting power: $e');
      return false;
    }
  }

  /// Set HeadUnit OS discoverable & pairable status.
  Future<bool> setDiscoverable(bool discoverable) async {
    if (!await isBluetoothctlAvailable()) return true;
    try {
      final dResult = await Process.run('bluetoothctl', ['discoverable', discoverable ? 'on' : 'off']);
      final pResult = await Process.run('bluetoothctl', ['pairable', 'on']);
      return dResult.exitCode == 0 && pResult.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Error setting discoverable: $e');
      return false;
    }
  }

  /// Get list of paired Bluetooth devices.
  Future<List<BluetoothDevice>> getPairedDevices() async {
    if (!await isBluetoothctlAvailable()) {
      return _getMockPairedDevices();
    }

    try {
      // 'bluetoothctl paired-devices' is invalid as a CLI arg on BlueZ 5.64+ (Ubuntu 24.04).
      // Use 'bluetoothctl devices Paired' instead.
      final result = await Process.run('bluetoothctl', ['devices', 'Paired']);
      if (result.exitCode != 0) return _getMockPairedDevices();

      final List<BluetoothDevice> paired = [];
      final lines = result.stdout.toString().split('\n');

      for (var line in lines) {
        if (line.trim().startsWith('Device')) {
          final dev = BluetoothDevice.fromBluetoothctlLine(line, isPaired: true);
          final connected = await _isDeviceConnected(dev.macAddress);
          paired.add(dev.copyWith(isConnected: connected));
        }
      }

      return paired;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] getPairedDevices exception: $e');
      return _getMockPairedDevices();
    }
  }

  /// Purge all stale unpaired devices from BlueZ discovery cache so powered-off devices disappear.
  Future<void> purgeUnpairedDevices() async {
    if (!await isBluetoothctlAvailable()) return;
    try {
      final paired = await getPairedDevices();
      final pairedMacs = paired.map((p) => p.macAddress.toUpperCase()).toSet();
      final result = await Process.run('bluetoothctl', ['devices']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          if (line.trim().startsWith('Device')) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              final mac = parts[1].trim();
              if (!pairedMacs.contains(mac.toUpperCase())) {
                await Process.run('bluetoothctl', ['remove', mac]);
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] purgeUnpairedDevices error: $e');
    }
  }

  /// Get detailed BlueZ info for a specific device MAC.
  Future<Map<String, String>> getDeviceInfo(String macAddress) async {
    final info = <String, String>{};
    if (!await isBluetoothctlAvailable()) return info;
    try {
      final result = await Process.run('bluetoothctl', ['info', macAddress]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (var line in lines) {
          final trimmed = line.trim();
          final colonIdx = trimmed.indexOf(':');
          if (colonIdx > 0 && colonIdx < trimmed.length - 1) {
            final key = trimmed.substring(0, colonIdx).trim();
            final val = trimmed.substring(colonIdx + 1).trim();
            info[key] = val;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] getDeviceInfo error: $e');
    }
    return info;
  }

  /// Scan for nearby Bluetooth devices on Linux Mint / Raspberry Pi.
  Future<List<BluetoothDevice>> scanDevices({bool purgeStale = false}) async {
    if (!await isBluetoothctlAvailable()) {
      return _getMockDiscoveredDevices();
    }

    try {
      // Ensure bluetooth radio is unblocked, powered on, and not stuck in a previous scan
      await Process.run('rfkill', ['unblock', 'bluetooth']);
      await Process.run('bluetoothctl', ['power', 'on']);
      await Process.run('bluetoothctl', ['scan', 'off']);

      if (purgeStale) {
        await purgeUnpairedDevices();
      }

      final liveNames = <String, String>{};
      final liveSeen = <String>{};

      // Perform a 7-second discovery scan while reading live stream output
      Process? process;
      StreamSubscription<String>? sub;
      try {
        process = await Process.start('bluetoothctl', []);
        sub = process.stdout
            .transform(const SystemEncoding().decoder)
            .transform(const LineSplitter())
            .listen((line) {
          if (kDebugMode) print('[BT-Scan] $line');
          if (line.contains('Device ')) {
            final match = RegExp(r'Device\s+(([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2})(\s+(.*))?').firstMatch(line);
            if (match != null) {
              final mac = match.group(1)!;
              liveSeen.add(mac.toUpperCase());
              final extra = match.group(4)?.trim();
              if (extra != null && extra.isNotEmpty) {
                final clean = extra.startsWith('Name: ') ? extra.substring(6).trim() : extra;
                if (clean.isNotEmpty && !clean.contains('RSSI:') && !clean.contains('TxPower:')) {
                  liveNames[mac.toUpperCase()] = clean;
                }
              }
            }
          }
        });

        // Send scan on commands to interactive bluetoothctl session
        process.stdin.writeln('menu scan');
        process.stdin.writeln('clear');
        process.stdin.writeln('back');
        process.stdin.writeln('scan on');

        await Future.delayed(const Duration(seconds: 7));

        process.stdin.writeln('scan off');
        process.stdin.writeln('quit');
      } catch (e) {
        if (kDebugMode) print('[BluetoothService] Scan stream error: $e');
      } finally {
        await sub?.cancel();
        process?.kill();
        await Process.run('bluetoothctl', ['scan', 'off']);
      }

      final result = await Process.run('bluetoothctl', ['devices']);
      if (result.exitCode != 0) return _getMockDiscoveredDevices();

      final List<BluetoothDevice> discovered = [];
      final lines = result.stdout.toString().split('\n');

      for (var line in lines) {
        if (line.trim().startsWith('Device')) {
          var dev = BluetoothDevice.fromBluetoothctlLine(line);
          final upperMac = dev.macAddress.toUpperCase();

          // Apply live resolved name if available
          if (liveNames.containsKey(upperMac) && liveNames[upperMac]!.isNotEmpty) {
            final resolvedName = liveNames[upperMac]!;
            dev = BluetoothDevice.fromBluetoothctlLine('Device ${dev.macAddress} $resolvedName');
          }

          // If the name is generic, MAC-like, or unknown type, query info
          final isGenericName = dev.name == dev.macAddress ||
              dev.name.replaceAll(':', '-').toUpperCase() == dev.macAddress.replaceAll(':', '-').toUpperCase();
          
          if (isGenericName || dev.type == BluetoothDeviceType.unknown) {
            final info = await getDeviceInfo(dev.macAddress);
            final realName = info['Name'] ?? info['Alias'];
            final icon = info['Icon']?.toLowerCase();
            BluetoothDeviceType type = dev.type;
            
            if (icon != null) {
              if (icon.contains('audio') || icon.contains('headset') || icon.contains('speaker')) {
                type = BluetoothDeviceType.audio;
              } else if (icon.contains('phone')) {
                type = BluetoothDeviceType.phone;
              }
            }

            if (realName != null && realName.isNotEmpty) {
              dev = BluetoothDevice.fromBluetoothctlLine('Device ${dev.macAddress} $realName')
                  .copyWith(type: type != BluetoothDeviceType.unknown ? type : null);
            } else if (type != BluetoothDeviceType.unknown) {
              dev = dev.copyWith(type: type);
            }
          }

          discovered.add(dev);
        }
      }

      return discovered;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] scanDevices exception: $e');
      return _getMockDiscoveredDevices();
    }
  }

  /// Routes Linux PulseAudio / PipeWire audio output according to user selection
  /// and locks the A2DP profile so BlueZ does not drop the link.
  Future<void> _routeAudioToBluetoothSpeaker(String macAddress) async {
    if (!Platform.isLinux) return;
    try {
      final macUnderscore = macAddress.replaceAll(':', '_').toUpperCase();
      final macLower = macAddress.replaceAll(':', '_').toLowerCase();

      // Lock PulseAudio card profile to a2dp_sink / a2dp_source so BlueZ does not drop the link
      await Process.run('pactl', ['set-card-profile', 'bluez_card.$macUnderscore', 'a2dp_sink']);
      await Process.run('pactl', ['set-card-profile', 'bluez_card.$macLower', 'a2dp_sink']);
      await Process.run('pactl', ['set-card-profile', 'bluez_card.$macUnderscore', 'a2dp_source']);
      await Process.run('pactl', ['set-card-profile', 'bluez_card.$macLower', 'a2dp_source']);

      // Check user's configured audio routing target before switching default output
      final activeTarget = AudioRoutingService().currentTarget;

      if (activeTarget.contains('Bluetooth')) {
        // User explicitly wants Bluetooth audio output -> set default sink
        final sinksResult = await Process.run('pactl', ['list', 'sinks', 'short']);
        if (sinksResult.exitCode == 0) {
          final sinkLines = sinksResult.stdout.toString().split('\n');
          for (final line in sinkLines) {
            if (line.contains(macUnderscore) || line.contains(macLower) || line.contains('bluez')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                final sinkName = parts[1];
                await Process.run('pactl', ['set-default-sink', sinkName]);
                if (kDebugMode) print('[BluetoothService] Set PulseAudio default sink: $sinkName');
                break;
              }
            }
          }
        }

        // PipeWire / WirePlumber default sink route
        final wpResult = await Process.run('wpctl', ['status']);
        if (wpResult.exitCode == 0) {
          final wpLines = wpResult.stdout.toString().split('\n');
          for (final line in wpLines) {
            if ((line.contains(macUnderscore) || line.contains(macAddress) || line.contains('bluez')) && line.contains('.')) {
              final match = RegExp(r'(\d+)\.').firstMatch(line);
              if (match != null) {
                final id = match.group(1)!;
                await Process.run('wpctl', ['set-default', id]);
                if (kDebugMode) print('[BluetoothService] Set WirePlumber default sink ID: $id');
                break;
              }
            }
          }
        }
      } else {
        // User selected AUX, HDMI, or FM Transmitter -> Re-assert user's non-Bluetooth target!
        if (kDebugMode) {
          print('[BluetoothService] Bluetooth connected, but keeping user-selected sound route "$activeTarget"');
        }
        await AudioRoutingService().applyAudioRouting(activeTarget);
      }
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Audio routing error: $e');
    }
  }

  /// Pair and connect to a Bluetooth device (audio speaker / phone) by MAC address.
  Future<bool> pairAndConnect(String macAddress) async {
    if (!await isBluetoothctlAvailable()) {
      if (kDebugMode) print('[BluetoothService] Simulator: Mocking pair & connect to $macAddress');
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    try {
      // Ensure bluetooth radio is unblocked and powered on
      await Process.run('rfkill', ['unblock', 'bluetooth']);
      await Process.run('bluetoothctl', ['power', 'on']);

      // Step 1: Trust device first so BlueZ accepts incoming/outgoing audio handshakes
      await Process.run('bluetoothctl', ['trust', macAddress]);
      _persistentAgentProcess?.stdin.writeln('trust $macAddress');

      // Step 2: Attempt pairing (ignore if already paired / bond already exists)
      final pairResult = await Process.run('bluetoothctl', ['pair', macAddress]);
      if (kDebugMode) {
        print('[BluetoothService] pair ($macAddress) exitCode: ${pairResult.exitCode}, out: ${pairResult.stdout.toString().trim()}');
      }

      // Step 3: Brief delay for Service Discovery Protocol (SDP) and A2DP profile registration
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 4: Ensure trusted
      await Process.run('bluetoothctl', ['trust', macAddress]);

      // Step 5: Connect once and immediately lock audio card profile
      final connResult = await Process.run('bluetoothctl', ['connect', macAddress]);
      if (kDebugMode) {
        print('[BluetoothService] connect ($macAddress) exitCode: ${connResult.exitCode}, out: ${connResult.stdout.toString().trim()}');
      }

      // Allow 1.5s for audio sink endpoint to bind in kernel
      await Future.delayed(const Duration(milliseconds: 1500));

      // Lock audio routing and card profile to stop BlueZ from dropping idle link
      await _routeAudioToBluetoothSpeaker(macAddress);

      // Verify connection state
      if (await _isDeviceConnected(macAddress)) {
        if (kDebugMode) print('[BluetoothService] Device $macAddress successfully connected & audio routed!');
        return true;
      }

      // Fallback: If device requires secondary connect attempt after profile registration
      final retryConn = await Process.run('bluetoothctl', ['connect', macAddress]);
      await Future.delayed(const Duration(milliseconds: 1500));
      await _routeAudioToBluetoothSpeaker(macAddress);

      return retryConn.exitCode == 0 || await _isDeviceConnected(macAddress);
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] pairAndConnect exception: $e');
      return false;
    }
  }

  /// Disconnect an active Bluetooth device.
  Future<bool> disconnect(String macAddress) async {
    if (!await isBluetoothctlAvailable()) return true;

    try {
      final result = await Process.run('bluetoothctl', ['disconnect', macAddress]);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] disconnect exception: $e');
      return false;
    }
  }

  /// Unpair / Forget a Bluetooth device.
  Future<bool> removeDevice(String macAddress) async {
    if (!await isBluetoothctlAvailable()) return true;

    try {
      final result = await Process.run('bluetoothctl', ['remove', macAddress]);
      return result.exitCode == 0;
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] removeDevice exception: $e');
      return false;
    }
  }

  Future<bool> _isDeviceConnected(String macAddress) async {
    try {
      // Method 1: Check bluetoothctl info for mac
      final infoResult = await Process.run('bluetoothctl', ['info', macAddress]);
      final infoOutput = infoResult.stdout.toString().toLowerCase();
      if (infoOutput.contains('connected: yes')) {
        return true;
      }

      // Method 2: Check bluetoothctl devices Connected list
      final connResult = await Process.run('bluetoothctl', ['devices', 'Connected']);
      final connOutput = connResult.stdout.toString().toLowerCase();
      if (connOutput.contains(macAddress.toLowerCase())) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('[BluetoothService] Exception checking device connection state: $e');
    }
    return false;
  }

  List<BluetoothDevice> _getMockPairedDevices() {
    return const [];
  }

  List<BluetoothDevice> _getMockDiscoveredDevices() {
    return const [
      BluetoothDevice(
        macAddress: 'FC:A8:9A:12:34:56',
        name: 'JBL Flip 6',
        type: BluetoothDeviceType.audio,
        rssi: -52,
      ),
      BluetoothDevice(
        macAddress: '70:99:1C:88:99:AA',
        name: 'JBL Charge 5',
        type: BluetoothDeviceType.audio,
        rssi: -65,
      ),
      BluetoothDevice(
        macAddress: 'E4:58:B8:33:44:55',
        name: "Carl's iPhone",
        type: BluetoothDeviceType.phone,
        rssi: -58,
      ),
    ];
  }
}
