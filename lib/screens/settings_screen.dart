import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/wifi_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/fm_transmitter_provider.dart';
import '../providers/display_provider.dart';
import '../providers/keyboard_provider.dart';
import '../services/system_info_service.dart';
import '../models/wifi_network.dart';
import '../providers/update_provider.dart';
import '../services/settings_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _audioOutputTarget = "AUX Cable / 3.5mm DAC";

  @override
  void initState() {
    super.initState();
    _loadAudioOutput();
  }

  Future<void> _loadAudioOutput() async {
    final target = await SettingsStorageService().loadAudioOutputTarget();
    if (mounted) {
      setState(() {
        _audioOutputTarget = target;
      });
    }
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
                      "Connect to '${network.ssid}'",
                      style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
                    "Enter the Wi-Fi password for ${network.ssid} (${network.security}):",
                    style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscureText,
                    autofocus: true,
                    readOnly: false,
                    onTap: () {
                      context.read<KeyboardProvider>().show(
                        passwordController,
                        onSubmitted: () {},
                      );
                    },
                    style: GoogleFonts.inter(color: AutomotiveColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Wi-Fi Password",
                      hintStyle: GoogleFonts.inter(color: AutomotiveColors.textMuted),
                      filled: true,
                      fillColor: Colors.black.withAlpha(100),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AutomotiveColors.electricCyan, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
                      ),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.keyboard_rounded, color: AutomotiveColors.electricCyan),
                        onPressed: () {
                          context.read<KeyboardProvider>().show(
                            passwordController,
                            onSubmitted: () {},
                          );
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
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(color: AutomotiveColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AutomotiveColors.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final pwd = passwordController.text.trim();
                    context.read<KeyboardProvider>().hide();
                    Navigator.pop(context);
                    await wifi.connectToNetwork(network.ssid, pwd);
                  },
                  child: Text(
                    "Connect",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getWifiSignalIcon(int signal) {
    if (signal >= 75) return Icons.wifi_rounded;
    if (signal >= 50) return Icons.wifi_2_bar_rounded;
    if (signal >= 25) return Icons.wifi_1_bar_rounded;
    return Icons.wifi_1_bar_rounded;
  }

  void _showSystemInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AutomotiveColors.glassPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AutomotiveColors.electricCyan),
              const SizedBox(width: 10),
              Text(
                "System & Hardware Diagnostics",
                style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: FutureBuilder<SystemInfoData>(
            future: SystemInfoService.getRealSystemInfo(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator(color: AutomotiveColors.electricCyan)),
                );
              }
              final sys = snapshot.data!;
              final wifi = context.watch<WifiProvider>();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSystemSpecRow("OS Version", sys.osVersion),
                    _buildSystemSpecRow("Hardware Model", sys.hardwareModel),
                    _buildSystemSpecRow("Operating System / Kernel", sys.kernelVersion),
                    _buildSystemSpecRow("CPU & Processors", sys.cpuArchitecture),
                    _buildSystemSpecRow("System Memory", sys.totalRam),
                    _buildSystemSpecRow("Runtime Environment", sys.dartVersion),
                    _buildSystemSpecRow("Network Interface (IP)", wifi.isConnected ? "${wifi.connectedSsid} (${wifi.ipAddress ?? '127.0.0.1'})" : "Disconnected"),
                  ],
                ),
              );
            },
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

  Widget _buildSystemSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textPrimary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Divider(color: AutomotiveColors.strokeSoft, height: 1),
        ],
      ),
    );
  }

  void _showUpdateLogsModal(BuildContext context, UpdateProvider update) {
    final scrollController = ScrollController();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AutomotiveColors.panelDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<UpdateProvider>(
          builder: (context, up, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.jumpTo(scrollController.position.maxScrollExtent);
              }
            });

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, color: AutomotiveColors.electricCyan),
                      const SizedBox(width: 10),
                      Text(
                        up.isDownloading ? "Downloading Update Package..." : "Applying System Update...",
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (up.isDownloading) ...[
                    LinearProgressIndicator(
                      value: up.downloadProgress,
                      backgroundColor: Colors.black.withAlpha(80),
                      color: AutomotiveColors.electricCyan,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Downloading bundle... ${(up.downloadProgress * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 12),
                    ),
                  ],
                  if (up.isApplying || up.updateLogs.isNotEmpty) ...[
                    Text(
                      "INSTALLATION LOGS",
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AutomotiveColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
                      ),
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: up.updateLogs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(
                              up.updateLogs[index],
                              style: GoogleFonts.jetBrainsMono(
                                color: up.updateLogs[index].toLowerCase().contains("error") 
                                    ? AutomotiveColors.redAccent 
                                    : (up.updateLogs[index].toLowerCase().contains("success") || up.updateLogs[index].startsWith("✓"))
                                        ? AutomotiveColors.nativeGreen
                                        : AutomotiveColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (up.errorMessage != null) ...[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Close", style: GoogleFonts.inter(color: AutomotiveColors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ] else if (up.updateSuccess) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AutomotiveColors.nativeGreen,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            _showRebootConfirmDialog(context, up);
                          },
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: Text("Reboot to Apply", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AutomotiveColors.electricCyan),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          up.isDownloading ? "Downloading..." : "Installing assets...",
                          style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRebootConfirmDialog(BuildContext context, UpdateProvider update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AutomotiveColors.glassPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.restart_alt_rounded, color: AutomotiveColors.nativeGreen),
              const SizedBox(width: 10),
              Text(
                "System Reboot Required",
                style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            "The update bundle has been successfully extracted. Restart the system to finalize the changes and launch the new version of HeadUnit OS.",
            style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveColors.electricCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                update.triggerReboot();
              },
              child: Text("Reboot Now", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpdateCard(BuildContext context, UpdateProvider update) {
    final wifi = context.watch<WifiProvider>();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: AutomotiveColors.electricCyan),
                  const SizedBox(width: 10),
                  Text(
                    "System Update",
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                  ),
                ],
              ),
              if (update.isChecking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AutomotiveColors.electricCyan),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AutomotiveColors.electricCyan),
                  onPressed: wifi.isConnected ? () => update.checkForUpdates() : null,
                  tooltip: "Check for Updates",
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (!wifi.isConnected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AutomotiveColors.orangeAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AutomotiveColors.orangeAccent.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AutomotiveColors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Connect to a Wi-Fi network to check for and download system updates.",
                      style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (update.isUpdateAvailable) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AutomotiveColors.electricCyan.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AutomotiveColors.electricCyan.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AutomotiveColors.electricCyan, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "New Update Available: v${update.remoteVersion}",
                            style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "CHANGELOG / RELEASES:",
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AutomotiveColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    ...update.changelog.map((change) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: AutomotiveColors.electricCyan)),
                          Expanded(
                            child: Text(
                              change,
                              style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (update.isOverlayFsActive) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AutomotiveColors.orangeAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AutomotiveColors.orangeAccent.withAlpha(120)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AutomotiveColors.orangeAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "OverlayFS Read-Only Mode Active",
                              style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Updates made while OverlayFS is active will be lost on reboot. Temporarily disable OverlayFS in performance settings (raspi-config), reboot, perform the update, and re-enable it.",
                              style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("Simulate OverlayFS", style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 20,
                        width: 36,
                        child: Switch(
                          value: update.isOverlayFsActive,
                          activeTrackColor: AutomotiveColors.orangeAccent,
                          onChanged: (val) => update.toggleSimulateOverlayFs(val),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AutomotiveColors.electricCyan,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      _showUpdateLogsModal(context, update);
                      await update.startUpdateFlow();
                    },
                    icon: const Icon(Icons.system_update_alt_rounded),
                    label: Text("Update Now", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AutomotiveColors.nativeGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "System is up-to-date",
                          style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          "Last checked: ${wifi.isConnected ? 'Just now' : 'No connection'}",
                          style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (update.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  update.errorMessage!,
                  style: GoogleFonts.inter(color: AutomotiveColors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("Simulate OverlayFS", style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 20,
                        width: 36,
                        child: Switch(
                          value: update.isOverlayFsActive,
                          activeTrackColor: AutomotiveColors.orangeAccent,
                          onChanged: (val) => update.toggleSimulateOverlayFs(val),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AutomotiveColors.electricCyan,
                      side: const BorderSide(color: AutomotiveColors.electricCyan),
                    ),
                    onPressed: () => update.checkForUpdates(),
                    child: Text("Check Now", style: GoogleFonts.inter(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showBluetoothPairingModal() {
    context.read<BluetoothProvider>().scanDevices();
    showModalBottomSheet(
      context: context,
      backgroundColor: AutomotiveColors.glassPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<BluetoothProvider>(
          builder: (context, bt, child) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bluetooth_audio_rounded, color: AutomotiveColors.electricCyan),
                          const SizedBox(width: 10),
                          Text(
                            "Select Car Bluetooth Audio Output",
                            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: bt.isScanning
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AutomotiveColors.electricCyan))
                            : const Icon(Icons.refresh_rounded, color: AutomotiveColors.electricCyan),
                        onPressed: bt.isScanning ? null : () => bt.scanDevices(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("PAIRED BLUETOOTH RECEIVERS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AutomotiveColors.textSecondary)),
                  const SizedBox(height: 6),
                  if (bt.pairedDevices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("No paired Bluetooth devices found.", style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 12)),
                    ),
                  ...bt.pairedDevices.map((dev) {
                    final isConnected = dev.isConnected;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.bluetooth_audio_rounded, color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textPrimary),
                      title: Text(dev.name, style: GoogleFonts.inter(color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(dev.macAddress, style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11)),
                      trailing: isConnected
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AutomotiveColors.nativeGreen.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                              child: Text("Connected", style: GoogleFonts.inter(color: AutomotiveColors.nativeGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AutomotiveColors.electricCyan, foregroundColor: Colors.black),
                              onPressed: () {
                                bt.pairAndConnect(dev.macAddress);
                                Navigator.pop(context);
                              },
                              child: Text("Connect", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCarBluetoothConnectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AutomotiveColors.glassPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.bluetooth_audio_rounded, color: AutomotiveColors.electricCyan),
              const SizedBox(width: 10),
              Text(
                "Connect to Car's Bluetooth",
                style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Audio output target set to Car Bluetooth Stereo (A2DP).",
                style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Please make sure your vehicle's stereo is powered on and set to Bluetooth receiver mode. HeadUnit OS will stream all music, navigation prompts, and phone calls wirelessly to your car speakers.",
                style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 12),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AutomotiveColors.electricCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
                _showBluetoothPairingModal();
              },
              icon: const Icon(Icons.bluetooth_searching_rounded, size: 16),
              label: Text("Pair / Connect Device", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAudioTargetRadioTile(String target, IconData icon, String subtitle) {
    final bool isSelected = _audioOutputTarget == target;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AutomotiveColors.electricCyan.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.strokeSoft,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          dense: true,
          leading: Icon(icon, color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.textSecondary),
          title: Text(
            target,
            style: GoogleFonts.inter(
              color: isSelected ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
          ),
          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AutomotiveColors.electricCyan, size: 18) : null,
          onTap: () {
            setState(() {
              _audioOutputTarget = target;
            });
            SettingsStorageService().saveAudioOutputTarget(target);
            if (target.contains("Bluetooth")) {
              _showCarBluetoothConnectDialog();
            }
          },
        ),
      ),
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
                  // Wi-Fi & Network Settings Card
                  Consumer<WifiProvider>(
                    builder: (context, wifi, child) {
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.wifi_rounded, color: AutomotiveColors.electricCyan),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Wi-Fi & Network Settings",
                                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (wifi.isWifiEnabled)
                                      IconButton(
                                        icon: wifi.isScanning
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AutomotiveColors.electricCyan),
                                              )
                                            : const Icon(Icons.refresh_rounded, color: AutomotiveColors.electricCyan),
                                        onPressed: wifi.isScanning ? null : () => wifi.scanNetworks(),
                                        tooltip: "Rescan Wi-Fi",
                                      ),
                                    Switch(
                                      value: wifi.isWifiEnabled,
                                      activeTrackColor: AutomotiveColors.electricCyan,
                                      onChanged: (val) => wifi.toggleWifi(val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (wifi.isWifiEnabled) ...[
                              const SizedBox(height: 10),
                              if (wifi.isConnected) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AutomotiveColors.nativeGreen.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AutomotiveColors.nativeGreen.withAlpha(100)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AutomotiveColors.nativeGreen, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Connected to ${wifi.connectedSsid}",
                                              style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (wifi.ipAddress != null)
                                              Text(
                                                "IP Address: ${wifi.ipAddress}",
                                                style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11),
                                              ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AutomotiveColors.redAccent,
                                          side: BorderSide(color: AutomotiveColors.redAccent.withAlpha(150)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        onPressed: () => wifi.disconnect(),
                                        child: Text("Disconnect", style: GoogleFonts.inter(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (wifi.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AutomotiveColors.redAccent.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AutomotiveColors.redAccent.withAlpha(120)),
                                  ),
                                  child: Text(
                                    wifi.errorMessage!,
                                    style: GoogleFonts.inter(color: AutomotiveColors.redAccent, fontSize: 12),
                                  ),
                                ),
                              ],
                              Text(
                                "Available Networks",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AutomotiveColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              if (wifi.availableNetworks.isEmpty && !wifi.isScanning)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    "No Wi-Fi networks found. Tap refresh to scan.",
                                    style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 12),
                                  ),
                                ),
                              ...wifi.availableNetworks.map((net) {
                                final isCurrent = net.ssid == wifi.connectedSsid;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                  dense: true,
                                  leading: Icon(_getWifiSignalIcon(net.signalStrength), color: isCurrent ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary),
                                  title: Text(
                                    net.ssid,
                                    style: GoogleFonts.inter(
                                      color: isCurrent ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${net.security} • ${net.signalStrength}% Signal",
                                    style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
                                  ),
                                  trailing: net.isSecured
                                      ? const Icon(Icons.lock_rounded, size: 16, color: AutomotiveColors.textMuted)
                                      : const Icon(Icons.lock_open_rounded, size: 16, color: AutomotiveColors.nativeGreen),
                                  onTap: () {
                                    if (isCurrent) return;
                                    if (net.isSecured) {
                                      _showWifiPasswordDialog(context, wifi, net);
                                    } else {
                                      wifi.connectToNetwork(net.ssid, "");
                                    }
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Bluetooth Controller Tile
                  Consumer<BluetoothProvider>(
                    builder: (context, bt, child) {
                      final connected = bt.connectedDevice;
                      return GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bluetooth_rounded, color: AutomotiveColors.electricCyan),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Bluetooth Controller",
                                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: bt.isBluetoothEnabled,
                                  activeTrackColor: AutomotiveColors.electricCyan,
                                  onChanged: (val) => bt.togglePower(val),
                                ),
                              ],
                            ),
                            if (bt.isBluetoothEnabled) ...[
                              const SizedBox(height: 6),
                              Text(
                                connected != null ? "Connected: ${connected.name} (${connected.macAddress})" : "No Bluetooth device connected.",
                                style: GoogleFonts.inter(color: connected != null ? AutomotiveColors.nativeGreen : AutomotiveColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Display & Brightness",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Consumer<DisplayProvider>(
                          builder: (context, display, child) {
                            return Row(
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
                                      value: display.brightness,
                                      min: 0.1,
                                      max: 1.0,
                                      onChanged: (val) {
                                        display.setBrightness(val);
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  "${display.brightnessPercent}%",
                                  style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Dedicated Audio Output & Sound Routing Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.headphones_rounded, color: AutomotiveColors.dongleViolet),
                            const SizedBox(width: 10),
                            Text(
                              "Audio Output & Sound Routing",
                              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildAudioTargetRadioTile(
                          "AUX Cable / 3.5mm DAC",
                          Icons.headphones_rounded,
                          "Plugged into Car AUX Input Port",
                        ),
                        _buildAudioTargetRadioTile(
                          "Car Bluetooth Stereo (A2DP)",
                          Icons.bluetooth_audio_rounded,
                          "Wireless stream to Car's Factory Bluetooth",
                        ),
                        if (_audioOutputTarget.contains("Bluetooth")) ...[
                          const SizedBox(height: 8),
                          Consumer<BluetoothProvider>(
                            builder: (context, bt, child) {
                              final connected = bt.connectedDevice;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AutomotiveColors.electricCyan.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AutomotiveColors.electricCyan.withAlpha(80)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      connected != null ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                                      color: connected != null ? AutomotiveColors.nativeGreen : AutomotiveColors.electricCyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            connected != null ? "Connected to ${connected.name}" : "No Bluetooth Car Stereo Connected",
                                            style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          Text(
                                            connected != null ? connected.macAddress : "Tap to scan and connect your car's Bluetooth audio receiver",
                                            style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AutomotiveColors.electricCyan,
                                        side: const BorderSide(color: AutomotiveColors.electricCyan),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      ),
                                      onPressed: _showBluetoothPairingModal,
                                      child: Text(connected != null ? "Switch Device" : "Pair / Connect", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildAudioTargetRadioTile(
                          "FM Transmitter",
                          Icons.radio_rounded,
                          "Broadcast to Car's FM Radio Frequency (87.5 - 108.0 MHz)",
                        ),
                        _buildAudioTargetRadioTile(
                          "HDMI Display Speakers",
                          Icons.tv_rounded,
                          "Built-in monitor speakers",
                        ),
                        if (_audioOutputTarget.contains("FM Transmitter")) ...[
                          const SizedBox(height: 12),
                          const Divider(color: AutomotiveColors.strokeSoft),
                          const SizedBox(height: 8),
                          Consumer<FmTransmitterProvider>(
                            builder: (context, fm, child) {
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AutomotiveColors.orangeAccent.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AutomotiveColors.orangeAccent.withAlpha(90)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.cell_tower_rounded, color: AutomotiveColors.orangeAccent, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          "FM Frequency Tuner",
                                          style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AutomotiveColors.electricCyan, size: 28),
                                          onPressed: () => fm.stepFrequency(-0.1),
                                          tooltip: "-0.1 MHz",
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AutomotiveColors.glassPanel,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AutomotiveColors.orangeAccent, width: 1.5),
                                          ),
                                          child: Text(
                                            "${fm.frequencyMhz.toStringAsFixed(1)} MHz",
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: AutomotiveColors.orangeAccent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline_rounded, color: AutomotiveColors.electricCyan, size: 28),
                                          onPressed: () => fm.stepFrequency(0.1),
                                          tooltip: "+0.1 MHz",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor: AutomotiveColors.orangeAccent,
                                        inactiveTrackColor: AutomotiveColors.stroke,
                                        thumbColor: AutomotiveColors.textPrimary,
                                      ),
                                      child: Slider(
                                        value: fm.frequencyMhz,
                                        min: 87.5,
                                        max: 108.0,
                                        divisions: 205, // 0.1 MHz steps
                                        onChanged: (val) => fm.setFrequency(val),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("87.5 MHz", style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textMuted, fontSize: 10)),
                                        Text("108.0 MHz", style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textMuted, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Quick Preset Frequencies",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AutomotiveColors.textSecondary),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      children: fm.presetFrequencies.map((preset) {
                                        final isCurrent = (fm.frequencyMhz - preset).abs() < 0.05;
                                        return ChoiceChip(
                                          label: Text("${preset.toStringAsFixed(1)} MHz"),
                                          selected: isCurrent,
                                          selectedColor: AutomotiveColors.orangeAccent.withAlpha(80),
                                          backgroundColor: AutomotiveColors.glassPanel,
                                          labelStyle: GoogleFonts.inter(
                                            color: isCurrent ? AutomotiveColors.textPrimary : AutomotiveColors.textSecondary,
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 11,
                                          ),
                                          onSelected: (_) => fm.setFrequency(preset),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // System Update Card
                  Consumer<UpdateProvider>(
                    builder: (context, update, child) {
                      return _buildUpdateCard(context, update);
                    },
                  ),
                  const SizedBox(height: 12),
                  // System Information & Diagnostics Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "System Information & Diagnostics",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.memory_rounded, color: AutomotiveColors.nativeGreen),
                          title: Text("System Specifications & Diagnostics", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14)),
                          subtitle: FutureBuilder<SystemInfoData>(
                            future: SystemInfoService.getRealSystemInfo(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Text("Reading hardware info...", style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11));
                              }
                              final sys = snapshot.data!;
                              return Text("${sys.hardwareModel} • ${sys.kernelVersion}", maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11));
                            },
                          ),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AutomotiveColors.electricCyan,
                              side: const BorderSide(color: AutomotiveColors.electricCyan),
                            ),
                            onPressed: _showSystemInfoDialog,
                            child: Text("System Specs", style: GoogleFonts.inter(fontSize: 12)),
                          ),
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

