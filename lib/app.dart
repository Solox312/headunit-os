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
import 'providers/keyboard_provider.dart';
import 'widgets/virtual_keyboard.dart';
import 'screens/splash_screen.dart';

class RpiHeadunitApp extends StatelessWidget {
  const RpiHeadunitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        // Not lazy: ProjectionProvider must be constructed at startup so its
        // USB hotplug listener (see UsbHotplugService) is active before the
        // user ever opens the projection screen.
        ChangeNotifierProvider(create: (_) => ProjectionProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => WifiProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => FmTransmitterProvider()),
        ChangeNotifierProvider(create: (_) => DisplayProvider()),
        ChangeNotifierProvider(create: (_) => KeyboardProvider()),
      ],
      child: MaterialApp(
        title: 'HeadUnit OS',
        debugShowCheckedModeBanner: false,
        theme: AutomotiveTheme.darkTheme,
        home: const SplashScreen(),
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              Consumer<KeyboardProvider>(
                builder: (context, kb, _) {
                  if (!kb.isVisible || kb.controller == null) return const SizedBox.shrink();
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: VirtualKeyboard(
                        controller: kb.controller!,
                        onSubmitted: () {
                          if (kb.onSubmitted != null) kb.onSubmitted!();
                          kb.hide();
                        },
                        onClose: () => kb.hide(),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
