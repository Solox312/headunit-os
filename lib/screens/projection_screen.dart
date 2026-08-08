import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../models/projection_state.dart';
import '../providers/projection_provider.dart';
import '../widgets/aa_connection_wizard.dart';
import '../widgets/aa_video_surface.dart';

class ProjectionScreen extends StatelessWidget {
  const ProjectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projection = Provider.of<ProjectionProvider>(context);
    final state = projection.state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── Top Control Bar ───────────────────────────────────────────
            Row(
              children: [
                Text(
                  "APP CONNECT",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AutomotiveColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (state.mode != ProjectionMode.disconnected &&
                    state.connectionStep != AAConnectionStep.streaming)
                  _ConnectionStepBadge(step: state.connectionStep),
                if (state.mode != ProjectionMode.disconnected)
                  const SizedBox(width: 8),
                if (state.mode != ProjectionMode.disconnected)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                    label: Text(
                      "Disconnect",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AutomotiveColors.redAccent,
                      side: const BorderSide(color: AutomotiveColors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => projection.switchMode(ProjectionMode.disconnected),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Main Content Area ─────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(animation), child: child),
                ),
                child: _buildContent(context, projection, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProjectionProvider projection, ProjectionState state) {
    // Streaming: full-screen video surface
    if (state.isStreaming && state.connectionStep == AAConnectionStep.streaming) {
      return KeyedSubtree(
        key: const ValueKey('streaming'),
        child: _buildStreamingView(context, projection, state),
      );
    }

    // Android Auto wizard connecting
    if (state.mode == ProjectionMode.androidAuto ||
        state.connectionStep != AAConnectionStep.idle) {
      return KeyedSubtree(
        key: const ValueKey('wizard'),
        child: AAConnectionWizard(
          onStreaming: (deviceName, battery) {
            // State is already updated by provider — AnimatedSwitcher handles transition
          },
          onCancel: () => projection.stopWirelessAndroidAuto(),
        ),
      );
    }

    // Disconnected: landing screen with connection options
    return KeyedSubtree(
      key: const ValueKey('disconnected'),
      child: _buildDisconnectedLanding(context, projection),
    );
  }

  // ── Streaming viewport ──────────────────────────────────────────────────

  Widget _buildStreamingView(BuildContext context, ProjectionProvider projection, ProjectionState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AAVideoSurface(
        deviceName: state.deviceName.isEmpty ? 'Android Phone' : state.deviceName,
        phoneBattery: state.phoneBatteryLevel,
        onDisconnect: () => projection.stopWirelessAndroidAuto(),
      ),
    );
  }

  // ── Disconnected landing ────────────────────────────────────────────────

  Widget _buildDisconnectedLanding(BuildContext context, ProjectionProvider projection) {
    return Container(
      decoration: BoxDecoration(
        color: AutomotiveColors.glassPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AutomotiveColors.stroke),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AutomotiveColors.textMuted.withValues(alpha: 0.08),
                border: Border.all(color: AutomotiveColors.stroke),
              ),
              child: const Icon(Icons.phonelink_off_rounded, size: 36, color: AutomotiveColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              "No Phone Connected",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AutomotiveColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose a connection mode below",
              style: GoogleFonts.inter(fontSize: 14, color: AutomotiveColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Connection option cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ConnectionOptionCard(
                  id: 'btn_android_auto_wireless',
                  icon: Icons.bluetooth_rounded,
                  title: "Android Auto",
                  subtitle: "Wireless via Bluetooth",
                  accentColor: AutomotiveColors.androidAutoColor,
                  badge: "NO DONGLE",
                  onTap: () => projection.startWirelessAndroidAuto(),
                ),
                const SizedBox(width: 14),
                _ConnectionOptionCard(
                  id: 'btn_apple_carplay',
                  icon: Icons.phone_iphone_rounded,
                  title: "Apple CarPlay",
                  subtitle: "USB Dongle required",
                  accentColor: AutomotiveColors.carPlayColor,
                  onTap: () => projection.switchMode(ProjectionMode.appleCarPlay),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ConnectionOptionCard extends StatefulWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? badge;
  final VoidCallback onTap;

  const _ConnectionOptionCard({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.badge,
  });

  @override
  State<_ConnectionOptionCard> createState() => _ConnectionOptionCardState();
}

class _ConnectionOptionCardState extends State<_ConnectionOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _glowAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(_hoverCtrl);
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _hoverCtrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) {
            return Container(
              width: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.06 + _glowAnim.value * 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.25 + _glowAnim.value * 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  if (_hovered)
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: widget.accentColor, size: 22),
                  if (widget.badge != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.badge!,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AutomotiveColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: AutomotiveColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStepBadge extends StatelessWidget {
  final AAConnectionStep step;

  const _ConnectionStepBadge({required this.step});

  String get _label {
    return switch (step) {
      AAConnectionStep.hotspotCreating => 'Creating Hotspot',
      AAConnectionStep.bluetoothDiscoverable => 'BT Discoverable',
      AAConnectionStep.waitingForPhone => 'Waiting for Phone',
      AAConnectionStep.tlsHandshake => 'Handshaking',
      AAConnectionStep.channelDiscovery => 'Negotiating',
      AAConnectionStep.streaming => 'Streaming',
      AAConnectionStep.error => 'Error',
      AAConnectionStep.idle => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (step == AAConnectionStep.idle) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AutomotiveColors.androidAutoColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AutomotiveColors.androidAutoColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AutomotiveColors.androidAutoColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

