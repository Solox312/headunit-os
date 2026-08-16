import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/bluetooth_provider.dart';
import '../models/bluetooth_device.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  IconData _getDeviceIcon(BluetoothDeviceType type) {
    switch (type) {
      case BluetoothDeviceType.phone:
        return Icons.smartphone_rounded;
      case BluetoothDeviceType.audio:
        return Icons.headphones_rounded;
      case BluetoothDeviceType.car:
        return Icons.directions_car_rounded;
      case BluetoothDeviceType.unknown:
        return Icons.bluetooth_rounded;
    }
  }

  void _showForgetDialog(BuildContext context, BluetoothProvider bt, BluetoothDevice dev) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AutomotiveColors.glassPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AutomotiveColors.stroke, width: 1.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.bluetooth_disabled_rounded, color: AutomotiveColors.redAccent),
            const SizedBox(width: 10),
            Text(
              "Forget '${dev.name}'?",
              style: GoogleFonts.spaceGrotesk(color: AutomotiveColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Unpairing this device will remove its saved Bluetooth connection profile.",
          style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: AutomotiveColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AutomotiveColors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              bt.forgetDevice(dev.macAddress);
            },
            child: Text("Forget", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
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
              "BLUETOOTH DEVICE MANAGER",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AutomotiveColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<BluetoothProvider>(
                builder: (context, bt, child) {
                  return ListView(
                    children: [
                      // Master Settings Card
                      GlassCard(
                        child: Column(
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
                                Row(
                                  children: [
                                    if (bt.isBluetoothEnabled)
                                      IconButton(
                                        icon: bt.isScanning
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AutomotiveColors.electricCyan),
                                              )
                                            : const Icon(Icons.refresh_rounded, color: AutomotiveColors.electricCyan),
                                        onPressed: bt.isScanning ? null : () => bt.scanDevices(),
                                        tooltip: "Scan Nearby Devices",
                                      ),
                                    Switch(
                                      value: bt.isBluetoothEnabled,
                                      activeTrackColor: AutomotiveColors.electricCyan,
                                      onChanged: (val) => bt.togglePower(val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (bt.isBluetoothEnabled) ...[
                              const Divider(color: AutomotiveColors.strokeSoft),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text("Make Discoverable", style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontSize: 14)),
                                subtitle: Text(
                                  bt.isDiscoverable ? "Visible as 'HeadUnit OS' for Wireless CarPlay & AA" : "Hidden from nearby devices",
                                  style: GoogleFonts.inter(color: AutomotiveColors.textSecondary, fontSize: 11),
                                ),
                                value: bt.isDiscoverable,
                                activeTrackColor: AutomotiveColors.electricCyan,
                                onChanged: (val) => bt.toggleDiscoverable(val),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (bt.isBluetoothEnabled) ...[
                        // Active Connected Device Card
                        if (bt.connectedDevice != null) ...[
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Connected Audio / Phone Device",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AutomotiveColors.nativeGreen),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AutomotiveColors.nativeGreen.withAlpha(30),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AutomotiveColors.nativeGreen.withAlpha(120)),
                                      ),
                                      child: Icon(_getDeviceIcon(bt.connectedDevice!.type), color: AutomotiveColors.nativeGreen),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bt.connectedDevice!.name,
                                            style: GoogleFonts.inter(color: AutomotiveColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            "${bt.connectedDevice!.macAddress} • ${bt.connectedDevice!.profiles.join(', ')}",
                                            style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AutomotiveColors.redAccent,
                                        side: BorderSide(color: AutomotiveColors.redAccent.withAlpha(150)),
                                      ),
                                      onPressed: () => bt.disconnectDevice(bt.connectedDevice!.macAddress),
                                      child: Text("Disconnect", style: GoogleFonts.inter(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Error Banner
                        if (bt.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AutomotiveColors.redAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AutomotiveColors.redAccent.withAlpha(120)),
                            ),
                            child: Text(
                              bt.errorMessage!,
                              style: GoogleFonts.inter(color: AutomotiveColors.redAccent, fontSize: 12),
                            ),
                          ),
                        ],

                        // Paired Devices Card
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Paired Devices",
                                style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              if (bt.pairedDevices.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    "No paired Bluetooth devices.",
                                    style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 12),
                                  ),
                                ),
                              ...bt.pairedDevices.map((dev) {
                                final isConnected = dev.isConnected;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(_getDeviceIcon(dev.type), color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textPrimary),
                                  title: Text(
                                    dev.name,
                                    style: GoogleFonts.inter(
                                      color: isConnected ? AutomotiveColors.nativeGreen : AutomotiveColors.textPrimary,
                                      fontWeight: isConnected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${dev.macAddress}${isConnected ? ' • Connected' : ''}",
                                    style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isConnected)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AutomotiveColors.electricCyan,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                          onPressed: bt.isConnecting ? null : () => bt.pairAndConnect(dev.macAddress),
                                          child: bt.isConnecting && bt.connectingMacAddress == dev.macAddress
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                                )
                                              : Text("Connect", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AutomotiveColors.textMuted, size: 20),
                                        onPressed: () => _showForgetDialog(context, bt, dev),
                                        tooltip: "Forget Device",
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Discovered / Scan Results
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Discovered Nearby Devices",
                                    style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                                  ),
                                  Row(
                                    children: [
                                      if (!bt.isScanning && bt.discoveredDevices.isNotEmpty)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            foregroundColor: AutomotiveColors.textSecondary,
                                          ),
                                          icon: const Icon(Icons.cleaning_services_rounded, size: 14),
                                          label: Text("Clean Stale", style: GoogleFonts.inter(fontSize: 11)),
                                          onPressed: () => bt.purgeStaleDiscoveredDevices(),
                                        ),
                                      if (bt.isScanning)
                                        Text("Scanning...", style: GoogleFonts.inter(color: AutomotiveColors.electricCyan, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (bt.discoveredDevices.isEmpty && !bt.isScanning)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "No new nearby devices found. Put your speaker/phone in pairing mode and tap scan.",
                                        style: GoogleFonts.inter(color: AutomotiveColors.textMuted, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AutomotiveColors.electricCyan,
                                          side: const BorderSide(color: AutomotiveColors.electricCyan),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: Text("Scan for Nearby Devices", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () => bt.purgeStaleDiscoveredDevices(),
                                      ),
                                    ],
                                  ),
                                ),
                              ...bt.discoveredDevices.map((dev) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(_getDeviceIcon(dev.type), color: dev.type == BluetoothDeviceType.audio ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary),
                                  title: Text(
                                    dev.name,
                                    style: GoogleFonts.inter(
                                      color: dev.type == BluetoothDeviceType.audio ? AutomotiveColors.electricCyan : AutomotiveColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    dev.type == BluetoothDeviceType.audio
                                        ? "${dev.macAddress} • Bluetooth Audio"
                                        : dev.macAddress,
                                    style: GoogleFonts.jetBrainsMono(color: AutomotiveColors.textSecondary, fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AutomotiveColors.electricCyan,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        onPressed: bt.isConnecting ? null : () => bt.pairAndConnect(dev.macAddress),
                                        child: bt.isConnecting && bt.connectingMacAddress == dev.macAddress
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                              )
                                            : Text("Pair & Connect", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, color: AutomotiveColors.textMuted, size: 18),
                                        onPressed: () => bt.removeDiscoveredDevice(dev.macAddress),
                                        tooltip: "Remove from list",
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
