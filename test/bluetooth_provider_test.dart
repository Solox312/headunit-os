import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/models/bluetooth_device.dart';
import 'package:headunit_os/providers/bluetooth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BluetoothDevice Model Tests', () {
    test('fromBluetoothctlLine parses valid device line', () {
      const line = 'Device 00:11:22:33:44:55 Pixel_8_Pro';
      final dev = BluetoothDevice.fromBluetoothctlLine(line, isPaired: true);

      expect(dev.macAddress, equals('00:11:22:33:44:55'));
      expect(dev.name, equals('Pixel_8_Pro'));
      expect(dev.isPaired, isTrue);
      expect(dev.type, equals(BluetoothDeviceType.phone));
    });

    test('copyWith updates fields correctly', () {
      const dev = BluetoothDevice(macAddress: 'AA:BB:CC:DD:EE:FF', name: 'Test Headset');
      final updated = dev.copyWith(isConnected: true, name: 'Renamed Headset');

      expect(updated.macAddress, equals('AA:BB:CC:DD:EE:FF'));
      expect(updated.name, equals('Renamed Headset'));
      expect(updated.isConnected, isTrue);
    });
  });

  group('BluetoothProvider State Tests', () {
    test('BluetoothProvider initializes with enabled state', () async {
      final provider = BluetoothProvider();
      await provider.init();
      expect(provider.isBluetoothEnabled, isTrue);
    });

    test('togglePower updates power state', () async {
      final provider = BluetoothProvider();
      await provider.init();
      await provider.togglePower(false);
      expect(provider.isBluetoothEnabled, isFalse);

      await provider.togglePower(true);
      expect(provider.isBluetoothEnabled, isTrue);
    });

    test('toggleDiscoverable updates discoverable state', () async {
      final provider = BluetoothProvider();
      await provider.init();
      await provider.toggleDiscoverable(false);
      expect(provider.isDiscoverable, isFalse);
    });

    test('scanDevices queries discovered devices list', () async {
      final provider = BluetoothProvider();
      await provider.init();
      await provider.scanDevices();
      expect(provider.discoveredDevices, isList);
    });
  });
}
