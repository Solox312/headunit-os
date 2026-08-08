import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/models/wifi_network.dart';
import 'package:headunit_os/providers/wifi_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WifiNetwork Model Tests', () {
    test('fromNmcliLine correctly parses valid nmcli line', () {
      const line = 'Home_5G:88:WPA2-PSK:*:00:11:22:33:44:55';
      final net = WifiNetwork.fromNmcliLine(line);

      expect(net.ssid, equals('Home_5G'));
      expect(net.signalStrength, equals(88));
      expect(net.security, equals('WPA2-PSK'));
      expect(net.isConnected, isTrue);
      expect(net.isSecured, isTrue);
    });

    test('isSecured returns false for Open networks', () {
      const net = WifiNetwork(ssid: 'Guest_Free', signalStrength: 50, security: 'Open');
      expect(net.isSecured, isFalse);
    });
  });

  group('WifiProvider State Tests', () {
    test('WifiProvider initializes with enabled state', () async {
      final provider = WifiProvider();
      await provider.init();
      expect(provider.isWifiEnabled, isTrue);
    });

    test('toggleWifi updates state', () async {
      final provider = WifiProvider();
      await provider.init();
      await provider.toggleWifi(false);
      expect(provider.isWifiEnabled, isFalse);

      await provider.toggleWifi(true);
      expect(provider.isWifiEnabled, isTrue);
    });

    test('scanNetworks queries available networks', () async {
      final provider = WifiProvider();
      await provider.init();
      await provider.scanNetworks();
      expect(provider.availableNetworks, isList);
    });
  });
}
