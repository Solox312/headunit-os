import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_os/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget Tests', () {
    testWidgets('renders SplashScreen with boot progress status', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('INITIALIZING SYSTEM KERNEL...'), findsOneWidget);
    });
  });
}
