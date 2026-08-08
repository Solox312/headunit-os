import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/projection_provider.dart';
import '../models/projection_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _brightness = 0.85;
  bool _wirelessHotspot = true;
  bool _autoConnect = true;
  String _audioOutputTarget = "AUX Cable / 3.5mm DAC";

  void _showAudioOutputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AutomotiveColors.glassPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
          ),
          title: Text(
            "Select Audio Output Target",
            style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAudioTargetOption("AUX Cable / 3.5mm DAC", Icons.headphones_rounded, "Plugged into Car AUX Input Port (Ground Loop Isolated)"),
              _buildAudioTargetOption("Car Bluetooth Stereo (A2DP)", Icons.bluetooth_audio_rounded, "Wireless stream to Car's Factory Bluetooth"),
              _buildAudioTargetOption("FM Transmitter (88.3 MHz)", Icons.radio_rounded, "Broadcast to Car's FM Radio Frequency"),
              _buildAudioTargetOption("HDMI Display Speakers", Icons.tv_rounded, "Built-in monitor speakers"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: GoogleFonts.inter(color: AutomotiveColors.electricCyan, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioTargetOption(String target, IconData icon, String subtitle) {
    final bool isSelected = _audioOutputTarget == target;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.textSecondary),
      title: Text(
        target,
        style: GoogleFonts.inter(
          color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AutomotiveColors.electricCyan) : null,
      onTap: () {
        setState(() {
          _audioOutputTarget = target;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HEAD UNIT SYSTEM SETTINGS",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AutomotiveColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Display & Brightness",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.brightness_medium_rounded, color: AutomotiveColors.electricCyan),
                            const SizedBox(width: 12),
                            Text("Screen Brightness", style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textPrimary)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AutomotiveColors.electricCyan,
                                  inactiveTrackColor: AutomotiveColors.stroke,
                                  thumbColor: AutomotiveColors.textPrimary,
                                ),
                                child: Slider(
                                  value: _brightness,
                                  onChanged: (val) {
                                    setState(() => _brightness = val);
                                  },
                                ),
                              ),
                            ),
                            Text(
                              "${(_brightness * 100).toInt()}%",
                              style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Connectivity & Receiver Engine",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Consumer<ProjectionProvider>(
                          builder: (context, projection, child) {
                            return RadioGroup<ProjectionEngineType>(
                              groupValue: projection.state.engineType,
                              onChanged: (val) {
                                if (val != null) projection.setEngineType(val);
                              },
                              child: Column(
                                children: [
                                  RadioListTile<ProjectionEngineType>(
                                    title: Text("Auto-Detect Engine (Recommended)", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    subtitle: Text("Uses USB Hardware Dongle if plugged in, otherwise falls back to Native Software Wireless", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                                    value: ProjectionEngineType.autoDetect,
                                    activeColor: AutomotiveColors.electricCyan,
                                  ),
                                  RadioListTile<ProjectionEngineType>(
                                    title: Text("100% Native Software Engine (No Dongle - \$0)", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    subtitle: Text("Native RPi Bluetooth RFCOMM + 5GHz Wi-Fi Access Point engine", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                                    value: ProjectionEngineType.nativeSoftware,
                                    activeColor: AutomotiveColors.nativeGreen,
                                  ),
                                  RadioListTile<ProjectionEngineType>(
                                    title: Text("Carlinkit USB Hardware Dongle", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    subtitle: Text("Dedicated dual-chip hardware bridge (CarPlay & Android Auto)", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                                    value: ProjectionEngineType.carlinkitHardware,
                                    activeColor: AutomotiveColors.dongleViolet,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(color: AutomotiveColors.strokeSoft),
                        SwitchListTile(
                          title: Text("Wireless CarPlay & Android Auto Hotspot", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14)),
                          subtitle: Text("RPi 5GHz Wi-Fi Access Point enabled", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                          value: _wirelessHotspot,
                          activeThumbColor: AutomotiveColors.electricCyan,
                          onChanged: (val) => setState(() => _wirelessHotspot = val),
                        ),
                        SwitchListTile(
                          title: Text("Auto-Connect Last Paired Device", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14)),
                          subtitle: Text("Automatically connect wirelessly via Bluetooth & Wi-Fi on car start", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                          value: _autoConnect,
                          activeThumbColor: AutomotiveColors.electricCyan,
                          onChanged: (val) => setState(() => _autoConnect = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Audio & System Info",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                        ),
                        ListTile(
                          leading: const Icon(Icons.headphones_rounded, color: AutomotiveColors.dongleViolet),
                          title: Text("Audio Output Target", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14)),
                          subtitle: Text(_audioOutputTarget, style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11)),
                          trailing: const Icon(Icons.tune_rounded, color: AutomotiveColors.electricCyan),
                          onTap: _showAudioOutputDialog,
                        ),
                        ListTile(
                          leading: const Icon(Icons.developer_board_rounded, color: AutomotiveColors.nativeGreen),
                          title: Text("Raspberry Pi Hardware", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14)),
                          subtitle: Text("Raspberry Pi 4 / 5 (64-bit Linux Kernel 6.6)", style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textMuted, fontSize: 11)),
                        ),
                      ],
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
}
