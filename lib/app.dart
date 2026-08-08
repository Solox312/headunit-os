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
          return HardwareCursorOverlay(
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
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
            ),
          );
        },
      ),
    );
  }
}

/// Software Mouse Pointer Overlay for Linux DRM/KMS displays without hardware DRM cursor planes.
class HardwareCursorOverlay extends StatefulWidget {
  final Widget child;
  const HardwareCursorOverlay({super.key, required this.child});

  @override
  State<HardwareCursorOverlay> createState() => _HardwareCursorOverlayState();
}

class _HardwareCursorOverlayState extends State<HardwareCursorOverlay> {
  Offset _cursorPos = Offset.zero;
  bool _isPointerActive = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) {
        setState(() {
          _cursorPos = event.position;
          _isPointerActive = true;
        });
      },
      onPointerMove: (event) {
        setState(() {
          _cursorPos = event.position;
          _isPointerActive = true;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_isPointerActive)
            Positioned(
              left: _cursorPos.dx,
              top: _cursorPos.dy,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(20, 20),
                  painter: _CursorPainter(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 18)
      ..lineTo(4.5, 13.5)
      ..lineTo(8, 20)
      ..lineTo(11, 18.5)
      ..lineTo(7.5, 12)
      ..lineTo(14, 12)
      ..close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill,
    );

    // Black border
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // White fill
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
