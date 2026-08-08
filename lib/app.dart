import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/automotive_theme.dart';
import 'providers/vehicle_provider.dart';
import 'providers/media_provider.dart';
import 'providers/projection_provider.dart';
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
      ],
      child: MaterialApp(
        title: 'Raspberry Pi DIY Head Unit',
        debugShowCheckedModeBanner: false,
        theme: AutomotiveTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
