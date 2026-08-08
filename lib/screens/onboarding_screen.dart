import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/vehicle_provider.dart';
import '../providers/wifi_provider.dart';
import '../providers/keyboard_provider.dart';
import '../services/settings_storage_service.dart';
import '../models/wifi_network.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  String _selectedAudioOutput = "AUX Cable / 3.5mm DAC";

  @override
  void initState() {
    super.initState();
    final vehicle = context.read<VehicleProvider>();
    _nameController.text = vehicle.isDefaultDriverName ? "" : vehicle.driverName;
  }

  Future<void> _completeOnboarding() async {
    context.read<KeyboardProvider>().hide();
    final vehicle = context.read<VehicleProvider>();
    if (_nameController.text.trim().isNotEmpty) {
      await vehicle.updateDriverName(_nameController.text);
    }
    await SettingsStorageService().saveOnboardingCompleted(true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => const MainNavigationScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showWifiPasswordDialog(BuildContext context, WifiProvider wifi, WifiNetwork network) {
    final passwordController = TextEditingController();
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.only(top: 40, left: 24, right: 24),
              backgroundColor: AutomotiveColors.glassPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
              ),
              title: Row(
                children: [
                  const Icon(Icons.wifi_lock_rounded, color: AutomotiveColors.electricCyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Connect to ${network.ssid}",
                      style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter Wi-Fi Password to connect for system updates:",
                    style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscureText,
                    autofocus: true,
                    style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14),
                    onTap: () {
                      context.read<KeyboardProvider>().show(passwordController);
                    },
                    decoration: InputDecoration(
                      hintText: "Wi-Fi Password",
                      hintStyle: GoogleFonts.inter(color: AutomotiveColors.textMuted),
                      filled: true,
                      fillColor: AutomotiveColors.stroke,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AutomotiveColors.electricCyan),
                      ),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.keyboard_rounded, color: AutomotiveColors.electricCyan),
                        onPressed: () {
                          context.read<KeyboardProvider>().show(passwordController);
                        },
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AutomotiveColors.textSecondary,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    context.read<KeyboardProvider>().hide();
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AutomotiveColors.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    context.read<KeyboardProvider>().hide();
                    Navigator.pop(context);
                    await wifi.connectToNetwork(network.ssid, passwordController.text);
                  },
                  child: Text("Connect", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04070C),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Header & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_filled_rounded, color: AutomotiveColors.electricCyan, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    "HEADUNIT OS",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AutomotiveColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AutomotiveColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      "Skip Setup",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AutomotiveColors.electricCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildProfilePage(),
                  _buildWifiUpdatesPage(),
                  _buildAudioPage(),
                ],
              ),
            ),

            // Bottom Navigation Controls & Page Indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Back Button
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AutomotiveColors.textPrimary,
                        side: const BorderSide(color: AutomotiveColors.stroke),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Back", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox(width: 80),

                  const Spacer(),

                  // Page Indicator Dots
                  Row(
                    children: List.generate(3, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.stroke,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AutomotiveColors.electricCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _currentPage == 2 ? "Get Started" : "Next",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 1: Driver Profile Setup
  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AutomotiveColors.electricCyan.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AutomotiveColors.electricCyan.withAlpha(120), width: 1.5),
                ),
                child: const Icon(Icons.person_pin_rounded, color: AutomotiveColors.electricCyan, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                "Welcome to HeadUnit OS",
                style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                "Personalize your vehicle dashboard greeting & driver profile telemetry.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textSecondary),
              ),
              const SizedBox(height: 28),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Driver Profile Name",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 15),
                      onTap: () {
                        context.read<KeyboardProvider>().show(_nameController);
                      },
                      decoration: InputDecoration(
                        hintText: "Enter your name (e.g. Carl)...",
                        hintStyle: GoogleFonts.inter(color: AutomotiveColors.textMuted),
                        filled: true,
                        fillColor: AutomotiveColors.stroke,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AutomotiveColors.electricCyan),
                        ),
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.keyboard_rounded, color: AutomotiveColors.electricCyan),
                          onPressed: () {
                            context.read<KeyboardProvider>().show(_nameController);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slide 2: Wi-Fi Setup for System Updates
  Widget _buildWifiUpdatesPage() {
    return Consumer<WifiProvider>(
      builder: (context, wifi, child) {
        final bool isConnected = wifi.isConnected;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AutomotiveColors.electricCyan.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AutomotiveColors.electricCyan.withAlpha(120), width: 1.5),
                    ),
                    child: const Icon(Icons.wifi_rounded, color: AutomotiveColors.electricCyan, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Connect Wi-Fi for Updates",
                    style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Connect your vehicle to Wi-Fi to receive OTA system updates, weather telemetry, and online navigation.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isConnected ? "Connected: ${wifi.connectedSsid}" : "Available Wi-Fi Networks",
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textPrimary),
                            ),
                            IconButton(
                              icon: wifi.isScanning
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AutomotiveColors.electricCyan))
                                  : const Icon(Icons.refresh_rounded, color: AutomotiveColors.electricCyan),
                              onPressed: wifi.isScanning ? null : () => wifi.scanNetworks(),
                              tooltip: "Rescan Wi-Fi",
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (wifi.availableNetworks.isEmpty && !wifi.isScanning)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("No Wi-Fi networks found. Tap refresh to scan.", style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 12)),
                          ),
                        ...wifi.availableNetworks.take(4).map((net) {
                          final isCurrent = net.ssid == wifi.connectedSsid;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.wifi_rounded, color: isCurrent ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary),
                            title: Text(net.ssid, style: GoogleFonts.inter(color: isCurrent ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text("${net.security} • ${net.signalStrength}% Signal", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                            trailing: isCurrent
                                ? const Icon(Icons.check_circle_rounded, color: AutomotiveColors.nativeGreen, size: 20)
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AutomotiveColors.stroke, foregroundColor: AutomotiveColors.electricCyan, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                                    onPressed: () {
                                      if (net.isSecured) {
                                        _showWifiPasswordDialog(context, wifi, net);
                                      } else {
                                        wifi.connectToNetwork(net.ssid, "");
                                      }
                                    },
                                    child: Text("Connect", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Slide 3: Audio & Bluetooth Setup
  Widget _buildAudioPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AutomotiveColors.electricCyan.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AutomotiveColors.electricCyan.withAlpha(120), width: 1.5),
                ),
                child: const Icon(Icons.volume_up_rounded, color: AutomotiveColors.electricCyan, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                "Audio & Output Setup",
                style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                "Select how your vehicle receives audio output from HeadUnit OS.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textSecondary),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  children: [
                    _buildAudioOptionTile("AUX Cable / 3.5mm DAC", Icons.headphones_rounded, "Plugged into Car AUX Input Port"),
                    _buildAudioOptionTile("Car Bluetooth Stereo (A2DP)", Icons.bluetooth_audio_rounded, "Wireless stream to Car Factory Bluetooth"),
                    _buildAudioOptionTile("FM Transmitter (88.3 MHz)", Icons.radio_rounded, "Broadcast to Car FM Radio Frequency"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioOptionTile(String target, IconData icon, String subtitle) {
    final isSelected = _selectedAudioOutput == target;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.textSecondary),
      title: Text(target, style: GoogleFonts.inter(color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AutomotiveColors.electricCyan, size: 20) : null,
      onTap: () {
        setState(() {
          _selectedAudioOutput = target;
        });
      },
    );
  }
}
