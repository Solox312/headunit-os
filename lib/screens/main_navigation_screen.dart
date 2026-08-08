import 'package:flutter/material.dart';
import '../widgets/nav_dock.dart';
import 'dashboard_screen.dart';
import 'projection_screen.dart';
import 'media_screen.dart';
import 'vehicle_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Dock Bar
          NavDock(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),

          // Main Screen Content View
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardScreen(
                  onOpenProjection: () {
                    setState(() {
                      _selectedIndex = 1; // Switch to Projection Stream Screen
                    });
                  },
                ),
                const ProjectionScreen(),
                const MediaScreen(),
                const VehicleScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
