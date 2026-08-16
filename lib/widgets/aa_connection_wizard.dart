import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/projection_state.dart';
import '../services/wireless_aa_bridge.dart';
import '../theme/automotive_colors.dart';

/// Multi-step animated wizard that guides the user to connect via Bluetooth
/// to activate Wireless Android Auto.
class AAConnectionWizard extends StatefulWidget {
  /// Called when the streaming step is reached — triggers switch to AAVideoSurface.
  final void Function(String deviceName, int phoneBattery)? onStreaming;

  /// Called when the user cancels the wizard.
  final VoidCallback? onCancel;

  const AAConnectionWizard({
    super.key,
    this.onStreaming,
    this.onCancel,
  });

  @override
  State<AAConnectionWizard> createState() => _AAConnectionWizardState();
}

class _AAConnectionWizardState extends State<AAConnectionWizard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _dotCtrl;

  StreamSubscription<AAConnectionEvent>? _sub;

  AAConnectionStep _step = AAConnectionStep.waitingForPhone;
  String _statusMessage = 'Waiting for phone Bluetooth connection…';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _sub = WirelessAABridge().events.listen(_onEvent);
  }

  void _onEvent(AAConnectionEvent event) {
    if (!mounted) return;
    setState(() {
      _step = event.step;
      _statusMessage = event.message;
      _hasError = event.step == AAConnectionStep.error;
    });

    if (event.step == AAConnectionStep.streaming) {
      final name = (event.data?['deviceName'] as String?) ?? 'Android Phone';
      final battery = (event.data?['phoneBattery'] as int?) ?? 0;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onStreaming?.call(name, battery);
      });
    }
  }

  Future<void> _cancel() async {
    await WirelessAABridge().stopWirelessAndroidAuto();
    widget.onCancel?.call();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AutomotiveColors.glassPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AutomotiveColors.stroke),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AutomotiveColors.androidAutoColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.android_rounded, size: 20, color: AutomotiveColors.androidAutoColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wireless Android Auto',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AutomotiveColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Connect via Bluetooth to activate projection',
                    style: GoogleFonts.inter(fontSize: 12, color: AutomotiveColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close_rounded, size: 14),
                label: Text('Cancel', style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AutomotiveColors.textSecondary,
                  side: const BorderSide(color: AutomotiveColors.stroke),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AutomotiveColors.strokeSoft, height: 1),
          const SizedBox(height: 16),

          // Main 2-column layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Prominent Phone Instructions
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AutomotiveColors.panelDark.withAlpha(150),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AutomotiveColors.strokeSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, child) {
                                final glow = _pulseCtrl.value * 0.25;
                                return Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AutomotiveColors.electricCyan.withAlpha((40 + glow * 100).toInt()),
                                    border: Border.all(color: AutomotiveColors.electricCyan, width: 1.5),
                                  ),
                                  child: const Icon(Icons.bluetooth_searching_rounded, size: 22, color: AutomotiveColors.electricCyan),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PAIR YOUR PHONE",
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AutomotiveColors.electricCyan),
                                  ),
                                  Text(
                                    "Select device name on phone:",
                                    style: GoogleFonts.inter(fontSize: 12, color: AutomotiveColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Device Name Badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: AutomotiveColors.electricCyan.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AutomotiveColors.electricCyan.withAlpha(120)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bluetooth_rounded, size: 18, color: AutomotiveColors.electricCyan),
                                  const SizedBox(width: 8),
                                  Text(
                                    "HeadUnit-OS",
                                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AutomotiveColors.nativeGreen.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "DISCOVERABLE",
                                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AutomotiveColors.nativeGreen, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Steps
                        _buildInstructionStep(
                          number: "1",
                          title: "Open Phone Bluetooth",
                          subtitle: "Turn on Bluetooth in your phone's settings.",
                        ),
                        const SizedBox(height: 10),
                        _buildInstructionStep(
                          number: "2",
                          title: "Tap \"HeadUnit-OS\"",
                          subtitle: "If already paired, tap HeadUnit-OS in paired list to connect.",
                        ),
                        const SizedBox(height: 10),
                        _buildInstructionStep(
                          number: "3",
                          title: "Auto Wi-Fi Handoff",
                          subtitle: "Your phone will automatically join Wi-Fi and stream Android Auto.",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Right Column: Live Connection Step Tracker
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AutomotiveColors.panelDark.withAlpha(150),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AutomotiveColors.strokeSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CONNECTION STATUS",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AutomotiveColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStep(
                                step: AAConnectionStep.hotspotCreating,
                                icon: Icons.wifi_tethering_rounded,
                                title: 'Wi-Fi Hotspot',
                                detail: 'SSID: HeadUnit-OS (5 GHz)',
                              ),
                              _buildConnector(AAConnectionStep.hotspotCreating),
                              _buildStep(
                                step: AAConnectionStep.bluetoothDiscoverable,
                                icon: Icons.bluetooth_rounded,
                                title: 'Bluetooth Discovery',
                                detail: 'Advertising HeadUnit-OS (0x200408)',
                              ),
                              _buildConnector(AAConnectionStep.bluetoothDiscoverable),
                              _buildStep(
                                step: AAConnectionStep.waitingForPhone,
                                icon: Icons.phone_android_rounded,
                                title: 'Waiting for Phone',
                                detail: 'Waiting for phone Bluetooth connection…',
                              ),
                              _buildConnector(AAConnectionStep.waitingForPhone),
                              _buildStep(
                                step: AAConnectionStep.tlsHandshake,
                                icon: Icons.vpn_key_rounded,
                                title: 'Wi-Fi Handoff & Credentials',
                                detail: 'Exchanging RFCOMM credentials',
                              ),
                              _buildConnector(AAConnectionStep.tlsHandshake),
                              _buildStep(
                                step: AAConnectionStep.channelDiscovery,
                                icon: Icons.settings_input_component_rounded,
                                title: 'Opening Projection Stream',
                                detail: 'TCP port 50001 session',
                              ),
                              _buildConnector(AAConnectionStep.channelDiscovery),
                              _buildStep(
                                step: AAConnectionStep.streaming,
                                icon: Icons.play_circle_rounded,
                                title: 'Streaming',
                                detail: 'Android Auto Live',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom status bar
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _hasError
                  ? AutomotiveColors.redAccent.withAlpha(20)
                  : AutomotiveColors.electricCyan.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hasError
                    ? AutomotiveColors.redAccent.withAlpha(100)
                    : AutomotiveColors.electricCyan.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: _hasError ? AutomotiveColors.redAccent : AutomotiveColors.electricCyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _hasError ? AutomotiveColors.redAccent : AutomotiveColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AutomotiveColors.electricCyan.withAlpha(30),
            border: Border.all(color: AutomotiveColors.electricCyan),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: AutomotiveColors.electricCyan),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AutomotiveColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AutomotiveColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep({
    required AAConnectionStep step,
    required IconData icon,
    required String title,
    required String detail,
  }) {
    final isActive = _step == step;
    final isPast = _isStepPast(step);
    final Color color;

    if (_hasError && isActive) {
      color = AutomotiveColors.redAccent;
    } else if (isPast) {
      color = AutomotiveColors.greenAccent;
    } else if (isActive) {
      color = AutomotiveColors.electricCyan;
    } else {
      color = AutomotiveColors.textMuted;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(isActive ? 40 : 15),
            border: Border.all(color: color, width: isActive ? 1.5 : 1.0),
          ),
          child: Icon(
            isPast ? Icons.check_rounded : icon,
            size: 13,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AutomotiveColors.textPrimary : AutomotiveColors.textSecondary,
                ),
              ),
              Text(
                detail,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isActive ? color : AutomotiveColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(AAConnectionStep step) {
    final isPast = _isStepPast(step);
    return Padding(
      padding: const EdgeInsets.only(left: 12.5),
      child: Container(
        width: 1.5,
        height: 10,
        color: isPast ? AutomotiveColors.greenAccent.withAlpha(150) : AutomotiveColors.stroke,
      ),
    );
  }

  bool _isStepPast(AAConnectionStep step) {
    const order = [
      AAConnectionStep.hotspotCreating,
      AAConnectionStep.bluetoothDiscoverable,
      AAConnectionStep.waitingForPhone,
      AAConnectionStep.tlsHandshake,
      AAConnectionStep.channelDiscovery,
      AAConnectionStep.streaming,
    ];
    final currentIndex = order.indexOf(_step);
    final stepIndex = order.indexOf(step);
    if (currentIndex == -1 || stepIndex == -1) return false;
    return stepIndex < currentIndex;
  }
}
