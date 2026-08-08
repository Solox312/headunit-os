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
          backgroundColor: AutomotiveColors.cardBackground,
          title: Text(
            "Select Audio Output Target",
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAudioTargetOption("AUX Cable / 3.5mm DAC", Icons.cable_rounded, "Plugged into Car AUX Input Port"),
              _buildAudioTargetOption("Car Bluetooth Stereo (A2DP)", Icons.bluetooth_audio_rounded, "Wireless stream to Car's Factory Bluetooth"),
              _buildAudioTargetOption("FM Transmitter (88.3 MHz)", Icons.radio_rounded, "Broadcast to Car's FM Radio Frequency"),
              _buildAudioTargetOption("HDMI Display Speakers", Icons.tv_rounded, "Built-in monitor speakers"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: AutomotiveColors.cyanAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioTargetOption(String target, IconData icon, String subtitle) {
    final bool isSelected = _audioOutputTarget == target;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AutomotiveColors.cyanAccent : Colors.white70),
      title: Text(target, style: TextStyle(color: isSelected ? AutomotiveColors.cyanAccent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, style: const TextStyle(color: AutomotiveColors.textSecondary, fontSize: 11)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AutomotiveColors.cyanAccent) : null,
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
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AutomotiveColors.textPrimary,
                letterSpacing: 1.2,
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
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.brightness_medium_rounded, color: AutomotiveColors.cyanAccent),
                            const SizedBox(width: 12),
                            Text("Screen Brightness", style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
                            Expanded(
                              child: Slider(
                                value: _brightness,
                                activeColor: AutomotiveColors.cyanAccent,
                                onChanged: (val) {
                                  setState(() => _brightness = val);
                                },
                              ),
                            ),
                            Text("${(_brightness * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                                    title: const Text("Auto-Detect Engine (Recommended)", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: const Text("Uses USB Hardware Dongle if plugged in, otherwise falls back to Native Software Wireless", style: TextStyle(color: AutomotiveColors.textSecondary, fontSize: 11)),
                                    value: ProjectionEngineType.autoDetect,
                                    activeColor: AutomotiveColors.cyanAccent,
                                  ),
                                  RadioListTile<ProjectionEngineType>(
                                    title: const Text("100% Native Software Engine (No Dongle)", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: const Text("Native RPi Bluetooth RFCOMM + 5GHz Wi-Fi Access Point engine", style: TextStyle(color: AutomotiveColors.textSecondary, fontSize: 11)),
                                    value: ProjectionEngineType.nativeSoftware,
                                    activeColor: AutomotiveColors.cyanAccent,
                                  ),
                                  RadioListTile<ProjectionEngineType>(
                                    title: const Text("Carlinkit USB Hardware Dongle", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    subtitle: const Text("Dedicated dual-chip hardware bridge (CarPlay & Android Auto)", style: TextStyle(color: AutomotiveColors.textSecondary, fontSize: 11)),
                                    value: ProjectionEngineType.carlinkitHardware,
                                    activeColor: AutomotiveColors.cyanAccent,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(color: AutomotiveColors.cardBorder),
                        SwitchListTile(
                          title: const Text("Wireless CarPlay & Android Auto Hotspot", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("RPi 5GHz Wi-Fi Access Point enabled", style: TextStyle(color: AutomotiveColors.textSecondary, fontSize: 12)),
                          value: _wirelessHotspot,
                          activeThumbColor: AutomotiveColors.cyanAccent,
                          onChanged: (val) => setState(() => _wirelessHotspot = val),
                        ),
                        SwitchListTile(
                          title: const Text("Auto-Connect Last Paired Device", style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Automatically connect wirelessly via Bluetooth & Wi-Fi on car start", style: TextStyle(color: AutomotiveColors.textSecondary, fontSize: 12)),
                          value: _autoConnect,
                          activeThumbColor: AutomotiveColors.cyanAccent,
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
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        ListTile(
                          leading: const Icon(Icons.speaker_group_rounded, color: AutomotiveColors.blueAccent),
                          title: const Text("Audio Output Target", style: TextStyle(color: Colors.white)),
                          subtitle: Text(_audioOutputTarget, style: const TextStyle(color: AutomotiveColors.textSecondary, fontSize: 12)),
                          trailing: const Icon(Icons.tune_rounded, color: AutomotiveColors.cyanAccent),
                          onTap: _showAudioOutputDialog,
                        ),
                        const ListTile(
                          leading: Icon(Icons.developer_board_rounded, color: AutomotiveColors.greenAccent),
                          title: Text("Raspberry Pi Hardware", style: TextStyle(color: Colors.white)),
                          subtitle: Text("Raspberry Pi 4 / 5 (64-bit Linux Kernel 6.6)", style: TextStyle(color: AutomotiveColors.textSecondary, fontSize: 12)),
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
