import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:headunit_os/screens/onboarding_screen.dart';
import 'package:headunit_os/providers/vehicle_provider.dart';
import 'package:headunit_os/providers/wifi_provider.dart';
import 'package:headunit_os/providers/bluetooth_provider.dart';
import 'package:headunit_os/providers/keyboard_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders OnboardingScreen with Driver Profile & Skip button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => VehicleProvider()),
            ChangeNotifierProvider(create: (_) => WifiProvider()),
            ChangeNotifierProvider(create: (_) => BluetoothProvider()),
            ChangeNotifierProvider(create: (_) => KeyboardProvider()),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to HeadUnit OS'), findsOneWidget);
      expect(find.text('Skip Setup'), findsOneWidget);
    });
  });
}
