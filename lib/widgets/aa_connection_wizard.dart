import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/projection_state.dart';
import '../services/wireless_aa_bridge.dart';
import '../theme/automotive_colors.dart';

/// Multi-step animated wizard that guides the user through the
/// Wireless Android Auto Bluetooth pairing → streaming flow.
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

  AAConnectionStep _step = AAConnectionStep.idle;
  String _statusMessage = '';
  bool _started = false;
  bool _hasError = false;

  static const _stepOrder = [
    AAConnectionStep.hotspotCreating,
    AAConnectionStep.bluetoothDiscoverable,
    AAConnectionStep.waitingForPhone,
    AAConnectionStep.tlsHandshake,
    AAConnectionStep.channelDiscovery,
    AAConnectionStep.streaming,
  ];

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

  Future<void> _start() async {
    setState(() {
      _started = true;
      _hasError = false;
    });
    await WirelessAABridge().startWirelessAndroidAuto();
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AutomotiveColors.glassPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AutomotiveColors.stroke),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _started ? _buildWizard() : _buildStartScreen(),
      ),
    );
  }

  // ── Start screen ─────────────────────────────────────────────────────────

  Widget _buildStartScreen() {
    return Center(
      key: const ValueKey('start'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) {
              final scale = 1.0 + _pulseCtrl.value * 0.06;
              final glow = _pulseCtrl.value * 0.25;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.08 + glow),
                  border: Border.all(
                    color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.3 + glow),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AutomotiveColors.androidAutoColor.withValues(alpha: glow),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: scale,
                  child: const Icon(Icons.android_rounded, size: 52, color: AutomotiveColors.androidAutoColor),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Wireless Android Auto',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AutomotiveColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect via Bluetooth — no cable or dongle required.\nYour phone will join the HeadUnit Wi-Fi automatically.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AutomotiveColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth_rounded, size: 18),
            label: Text(
              'Start Bluetooth Pairing',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AutomotiveColors.androidAutoColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _start,
          ),
          const SizedBox(height: 12),
          Text(
            'Supported: Android 11+ · Android Auto 9.0+',
            style: GoogleFonts.inter(fontSize: 11, color: AutomotiveColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Wizard screen ─────────────────────────────────────────────────────────

  Widget _buildWizard() {
    return Padding(
      key: const ValueKey('wizard'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(Icons.bluetooth_rounded, size: 18, color: AutomotiveColors.androidAutoColor),
              const SizedBox(width: 8),
              Text(
                'Connecting…',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AutomotiveColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: AutomotiveColors.textMuted,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: Text('Cancel', style: GoogleFonts.inter(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step list
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep(
                  step: AAConnectionStep.hotspotCreating,
                  icon: Icons.wifi_tethering_rounded,
                  title: 'Creating Wi-Fi Hotspot',
                  detail: 'SSID: HeadUnit-OS',
                ),
                _buildConnector(AAConnectionStep.hotspotCreating),
                _buildStep(
                  step: AAConnectionStep.bluetoothDiscoverable,
                  icon: Icons.bluetooth_rounded,
                  title: 'Pair via Bluetooth',
                  detail: 'Select "HeadUnit-OS" on your phone',
                  isUserAction: true,
                ),
                _buildConnector(AAConnectionStep.bluetoothDiscoverable),
                _buildStep(
                  step: AAConnectionStep.waitingForPhone,
                  icon: Icons.phone_android_rounded,
                  title: 'Waiting for Phone',
                  detail: 'Re-pair Bluetooth if previously paired — connection starts automatically',
                  isUserAction: true,
                ),
                _buildConnector(AAConnectionStep.waitingForPhone),
                _buildStep(
                  step: AAConnectionStep.tlsHandshake,
                  icon: Icons.lock_rounded,
                  title: 'Securing Connection',
                  detail: 'TLS handshake in progress',
                ),
                _buildConnector(AAConnectionStep.tlsHandshake),
                _buildStep(
                  step: AAConnectionStep.channelDiscovery,
                  icon: Icons.settings_input_component_rounded,
                  title: 'Negotiating Channels',
                  detail: 'Video · Audio · Input · Sensors',
                ),
                _buildConnector(AAConnectionStep.channelDiscovery),
                _buildStep(
                  step: AAConnectionStep.streaming,
                  icon: Icons.play_circle_rounded,
                  title: 'Streaming',
                  detail: 'Android Auto is live',
                ),
              ],
            ),
          ),

          // Status pill at bottom
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStatusPill(),
          ],
        ],
      ),
    );
  }

  Widget _buildStep({
    required AAConnectionStep step,
    required IconData icon,
    required String title,
    required String detail,
    bool isUserAction = false,
  }) {
    final isActive = _step == step;
    final isPast = _isStepPast(step);
    final Color color;

    if (_hasError && isActive) {
      color = AutomotiveColors.redAccent;
    } else if (isPast) {
      color = AutomotiveColors.greenAccent;
    } else if (isActive) {
      color = AutomotiveColors.androidAutoColor;
    } else {
      color = AutomotiveColors.textMuted;
    }

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glow = isActive ? _pulseCtrl.value * 0.12 : 0.0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10 + glow),
                border: Border.all(
                  color: color.withValues(alpha: isActive ? 0.85 : 0.25),
                  width: isActive ? 2.0 : 1.0,
                ),
              ),
              child: _buildStepIcon(step, icon, color, isPast, isActive),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: (isActive || isPast)
                          ? AutomotiveColors.textPrimary
                          : AutomotiveColors.textMuted,
                    ),
                  ),
                  if (isActive || isPast)
                    Text(
                      detail,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isUserAction && isActive
                            ? AutomotiveColors.androidAutoColor
                            : AutomotiveColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepIcon(
    AAConnectionStep step,
    IconData icon,
    Color color,
    bool isPast,
    bool isActive,
  ) {
    if (isPast) {
      return const Icon(Icons.check_rounded, size: 18, color: AutomotiveColors.greenAccent);
    }
    if (isActive && !_hasError) {
      return Padding(
        padding: const EdgeInsets.all(11),
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Icon(icon, size: 18, color: color);
  }

  Widget _buildConnector(AAConnectionStep afterStep) {
    final isPast = _isStepPast(afterStep) ||
        (_stepOrder.contains(_step) &&
            _stepOrder.indexOf(_step) > _stepOrder.indexOf(afterStep));

    return Padding(
      padding: const EdgeInsets.only(left: 19, top: 3, bottom: 3),
      child: Container(
        width: 2,
        height: 18,
        decoration: BoxDecoration(
          color: isPast
              ? AutomotiveColors.greenAccent.withValues(alpha: 0.4)
              : AutomotiveColors.stroke,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    final accentColor = _hasError ? AutomotiveColors.redAccent : AutomotiveColors.androidAutoColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (!_hasError)
            AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, _) => Opacity(
                opacity: 0.4 + _dotCtrl.value * 0.6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AutomotiveColors.androidAutoColor,
                  ),
                ),
              ),
            )
          else
            const Icon(Icons.error_outline_rounded, size: 14, color: AutomotiveColors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _hasError ? AutomotiveColors.redAccent : AutomotiveColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isStepPast(AAConnectionStep step) {
    if (!_stepOrder.contains(_step) || !_stepOrder.contains(step)) return false;
    return _stepOrder.indexOf(step) < _stepOrder.indexOf(_step);
  }
}
