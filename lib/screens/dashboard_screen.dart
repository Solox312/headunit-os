import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/media_provider.dart';
import '../providers/projection_provider.dart';
import '../providers/wifi_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/keyboard_provider.dart';
import '../providers/time_date_provider.dart';
import '../models/projection_state.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenProjection;
  final VoidCallback? onOpenMedia;

  const DashboardScreen({
    super.key,
    required this.onOpenProjection,
    this.onOpenMedia,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final vehicle = context.read<VehicleProvider>();
      await vehicle.driverNameLoaded;
      if (!mounted) return;
      if (vehicle.isDefaultDriverName && !vehicle.driverNamePromptSkipped) {
        _showEditDriverNameDialog(context, vehicle);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = Provider.of<MediaProvider>(context);
    final projection = Provider.of<ProjectionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Column: Clock, Date, Weather & Quick App Launcher Card
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Consumer<WifiProvider>(
                                builder: (context, wifi, child) {
                                  final bool isConnected = wifi.isConnected;
                                  final String ssid = wifi.connectedSsid ?? "No Wi-Fi";

                                  return Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AutomotiveColors.glassPanel,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car_filled_rounded,
                                          color: AutomotiveColors.electricCyan,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Consumer<VehicleProvider>(
                                              builder: (context, vehicle, child) {
                                                return InkWell(
                                                  onTap: () => _showEditDriverNameDialog(context, vehicle),
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        vehicle.getTimedGreeting(),
                                                        style: GoogleFonts.spaceGrotesk(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: vehicle.isDefaultDriverName
                                                              ? AutomotiveColors.orangeAccent
                                                              : AutomotiveColors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 14,
                                                        color: vehicle.isDefaultDriverName
                                                            ? AutomotiveColors.orangeAccent
                                                            : AutomotiveColors.textSecondary,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            Text(
                                              isConnected ? "System Online • $ssid" : "System Online • Vehicle Standby",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontSize: 11,
                                                color: AutomotiveColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isConnected
                                              ? AutomotiveColors.nativeGreen.withAlpha(30)
                                              : AutomotiveColors.stroke,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isConnected
                                                ? AutomotiveColors.nativeGreen.withAlpha(120)
                                                : AutomotiveColors.strokeSoft,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                              color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textMuted,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isConnected ? ssid : "Disconnected",
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: isConnected ? FontWeight.bold : FontWeight.w500,
                                                color: isConnected ? AutomotiveColors.textPrimary : AutomotiveColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Consumer<TimeDateProvider>(
                                builder: (context, timeDate, _) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timeDate.formatTime(_now, withSeconds: timeDate.showSeconds),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: AutomotiveColors.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeDate.formatDate(_now),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AutomotiveColors.electricCyan,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: AutomotiveColors.strokeSoft),
                              const SizedBox(height: 12),
                              // Quick App Launchers
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickLauncher(
                                    context,
                                    label: "Navigation",
                                    icon: Icons.navigation_rounded,
                                    color: AutomotiveColors.electricCyan,
                                    onTap: widget.onOpenProjection,
                                  ),
                                  _buildQuickLauncher(
                                    context,
                                    label: "Music",
                                    icon: Icons.headphones_rounded,
                                    color: AutomotiveColors.dongleViolet,
                                    onTap: () {
                                      if (widget.onOpenMedia != null) {
                                        widget.onOpenMedia!();
                                      }
                                    },
                                  ),
                                  _buildQuickLauncher(
                                    context,
                                    label: "Phone",
                                    icon: Icons.phone_rounded,
                                    color: AutomotiveColors.nativeGreen,
                                    onTap: widget.onOpenProjection,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Column: CarPlay/Android Auto Card + Media Player Card
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // Projection Status & Quick Viewport Card
                  Expanded(
                    flex: 5,
                    child: GlassCard(
                      onTap: widget.onOpenProjection,
                      showCornerReticles: true,
                      borderColor: projection.state.mode == ProjectionMode.appleCarPlay
                          ? AutomotiveColors.carPlayColor
                          : (projection.state.mode == ProjectionMode.androidAuto
                              ? AutomotiveColors.androidAutoColor
                              : AutomotiveColors.electricCyan),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AutomotiveColors.glassPanel,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: projection.state.mode == ProjectionMode.appleCarPlay
                                          ? AutomotiveColors.carPlayColor
                                          : (projection.state.mode == ProjectionMode.androidAuto
                                              ? AutomotiveColors.androidAutoColor
                                              : AutomotiveColors.electricCyan),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    projection.state.mode == ProjectionMode.appleCarPlay
                                        ? Icons.phone_iphone_rounded
                                        : Icons.phone_android_rounded,
                                    size: 28,
                                    color: projection.state.mode == ProjectionMode.appleCarPlay
                                        ? AutomotiveColors.carPlayColor
                                        : (projection.state.mode == ProjectionMode.androidAuto
                                            ? AutomotiveColors.androidAutoColor
                                            : AutomotiveColors.electricCyan),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  projection.state.mode == ProjectionMode.appleCarPlay
                                      ? "Apple CarPlay Active"
                                      : (projection.state.mode == ProjectionMode.androidAuto
                                          ? "Android Auto Active"
                                          : "Projection Disconnected"),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AutomotiveColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Connected to ${projection.state.deviceName} • Tap for stream",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AutomotiveColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AutomotiveColors.panelDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AutomotiveColors.stroke, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AutomotiveColors.nativeGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "LIVE STREAM",
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AutomotiveColors.textPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Media Control Card
                  Expanded(
                    flex: 4,
                    child: GlassCard(
                      onTap: widget.onOpenMedia,
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AutomotiveColors.glassPanel,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
                            ),
                            child: media.hasMedia
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      media.mediaItem.coverUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.album_rounded,
                                            size: 32,
                                            color: AutomotiveColors.dongleViolet,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.music_off_rounded,
                                      size: 30,
                                      color: AutomotiveColors.textMuted,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  media.hasMedia ? media.mediaItem.title : "No Music Playing",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AutomotiveColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  media.hasMedia ? media.mediaItem.artist : "Connect audio source or tap play",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AutomotiveColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                iconSize: 28,
                                color: AutomotiveColors.textPrimary,
                                onPressed: () => media.previousTrack(),
                              ),
                              IconButton(
                                icon: Icon(media.hasMedia && media.mediaItem.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded),
                                iconSize: 42,
                                color: AutomotiveColors.electricCyan,
                                onPressed: () => media.togglePlayPause(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                iconSize: 28,
                                color: AutomotiveColors.textPrimary,
                                onPressed: () => media.nextTrack(),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildQuickLauncher(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AutomotiveColors.glassPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AutomotiveColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDriverNameDialog(BuildContext context, VehicleProvider vehicle) {
    final nameController = TextEditingController(
      text: vehicle.isDefaultDriverName ? "" : vehicle.driverName,
    );

    showDialog(
      context: context,
      builder: (context) {
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
              const Icon(Icons.person_rounded, color: AutomotiveColors.electricCyan),
              const SizedBox(width: 10),
              Text(
                "Driver Profile Name",
                style: GoogleFonts.spaceGrotesk(
                  color: AutomotiveColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter your name to personalize your vehicle dashboard greeting:",
                style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 15),
                onTap: () {
                  context.read<KeyboardProvider>().show(nameController);
                },
                decoration: InputDecoration(
                  hintText: "Enter your name...",
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
                      context.read<KeyboardProvider>().show(nameController);
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
                vehicle.skipDriverNamePrompt();
                Navigator.pop(context);
              },
              child: Text(
                "Skip & Don't Ask Again",
                style: GoogleFonts.inter(color: AutomotiveColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveColors.electricCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                context.read<KeyboardProvider>().hide();
                vehicle.updateDriverName(nameController.text);
                Navigator.pop(context);
              },
              child: Text(
                "Save Name",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
