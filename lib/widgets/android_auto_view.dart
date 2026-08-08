import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/aa_protocol_types.dart';
import '../services/android_auto_engine.dart';

/// Interactive Native Android Auto Projection View Widget
class AndroidAutoView extends StatefulWidget {
  final VoidCallback? onClose;

  const AndroidAutoView({super.key, this.onClose});

  @override
  State<AndroidAutoView> createState() => _AndroidAutoViewState();
}

class _AndroidAutoViewState extends State<AndroidAutoView> {
  final AndroidAutoEngine _engine = AndroidAutoEngine();
  StreamSubscription<Uint8List>? _videoSubscription;
  StreamSubscription<AAEngineState>? _stateSubscription;

  Uint8List? _currentFrameBytes;
  AAEngineState _state = AAEngineState.disconnected;

  @override
  void initState() {
    super.initState();
    _state = _engine.state;

    _stateSubscription = _engine.stateStream.listen((newState) {
      if (mounted) {
        setState(() {
          _state = newState;
        });
      }
    });

    _videoSubscription = _engine.h264VideoStream.listen((frameBytes) {
      if (mounted) {
        setState(() {
          _currentFrameBytes = frameBytes;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _handlePointerEvent(PointerEvent event, RenderBox box, int action) {
    final localPosition = box.globalToLocal(event.position);
    final normalizedX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final normalizedY = (localPosition.dy / box.size.height).clamp(0.0, 1.0);

    _engine.sendTouchEvent(
      x: normalizedX,
      y: normalizedY,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Video Stream & Touch Surface ──────────────────────────────────
          Positioned.fill(
            child: Builder(
              builder: (context) {
                return Listener(
                  onPointerDown: (event) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      _handlePointerEvent(event, box, AATouchAction.press);
                    }
                  },
                  onPointerMove: (event) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      _handlePointerEvent(event, box, AATouchAction.move);
                    }
                  },
                  onPointerUp: (event) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      _handlePointerEvent(event, box, AATouchAction.release);
                    }
                  },
                  child: Container(
                    color: Colors.black,
                    child: _currentFrameBytes != null
                        ? Image.memory(
                            _currentFrameBytes!,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          )
                        : _buildStandbyProjectionUI(theme),
                  ),
                );
              },
            ),
          ),

          // ── Close Overlay Button ──────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'aa_view_close_fab',
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),

          // ── Status Overlay Pill ───────────────────────────────────────────
          if (_state != AAEngineState.streamingActive)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStatusMessage(_state),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStandbyProjectionUI(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.android_rounded,
              size: 72,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Android Auto Native Receiver',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready for USB or Wireless 5GHz Wi-Fi Connection',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(AAEngineState state) {
    switch (state) {
      case AAEngineState.disconnected:
        return 'Waiting for phone...';
      case AAEngineState.discoveringUsb:
        return 'Scanning USB AOA 2.0 Accessory Mode...';
      case AAEngineState.aoapSwitching:
        return 'Switching USB to AOA Mode (18d1:2d00)...';
      case AAEngineState.wifiHotspotActive:
        return 'Wi-Fi Hotspot Active (HeadUnit-OS)';
      case AAEngineState.bluetoothPairing:
        return 'Bluetooth RFCOMM Handshake...';
      case AAEngineState.handshakeActive:
        return 'Negotiating Protocol Channels...';
      case AAEngineState.streamingActive:
        return 'Active Streaming';
      case AAEngineState.error:
        return 'Connection Error';
    }
  }
}
