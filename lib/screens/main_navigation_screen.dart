import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nav_dock.dart';
import '../providers/display_provider.dart';
import '../providers/projection_provider.dart';
import 'dashboard_screen.dart';
import 'projection_screen.dart';
import 'media_screen.dart';
import 'bluetooth_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  bool _wasStreaming = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final projection = Provider.of<ProjectionProvider>(context);
    final isStreaming = projection.state.isConnected && projection.state.isStreaming;

    if (isStreaming && !_wasStreaming) {
      // Android Auto connected & streaming -> automatically open projection screen (index 1)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex != 1) {
          setState(() {
            _selectedIndex = 1;
          });
        }
      });
    }
    _wasStreaming = isStreaming;

    return Consumer<DisplayProvider>(
      builder: (context, display, child) {
        final double dimOpacity = (1.0 - display.brightness).clamp(0.0, 0.85);

        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFF090A0F),
              body: Row(
                children: [
                  // Left Fixed Navigation Dock
                  NavDock(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),

                  // Main Screen View Area
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        DashboardScreen(
                          onOpenProjection: () {
                            setState(() {
                              _selectedIndex = 1; // Switch to App Connect Screen
                            });
                          },
                          onOpenMedia: () {
                            setState(() {
                              _selectedIndex = 2; // Switch to Media Screen
                            });
                          },
                        ),
                        const ProjectionScreen(),
                        const MediaScreen(),
                        const BluetoothScreen(),
                        const SettingsScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Global Screen Brightness Dimming Overlay
            if (dimOpacity > 0.01)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: dimOpacity),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
