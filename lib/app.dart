import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/automotive_theme.dart';
import 'providers/vehicle_provider.dart';
import 'providers/media_provider.dart';
import 'providers/projection_provider.dart';
import 'providers/wifi_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/fm_transmitter_provider.dart';
import 'providers/display_provider.dart';
import 'screens/main_navigation_screen.dart';

class RpiHeadunitApp extends StatelessWidget {
  const RpiHeadunitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => ProjectionProvider()),
        ChangeNotifierProvider(create: (_) => WifiProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => FmTransmitterProvider()),
        ChangeNotifierProvider(create: (_) => DisplayProvider()),
      ],
      child: MaterialApp(
        title: 'HeadUnit OS',
        debugShowCheckedModeBanner: false,
        theme: AutomotiveTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
