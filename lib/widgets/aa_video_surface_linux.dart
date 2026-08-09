import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/wireless_aa_bridge.dart';

/// Linux-native video surface backed by media_kit + libmpv.
/// Opens the H.264 stream piped from OpenAuto on UDP port 5556.
class _LinuxVideoSurfaceState extends State<_LinuxVideoSurface> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    // OpenAuto outputs H.264 over UDP — libmpv opens it as a live stream.
    _player.open(Media('udp://127.0.0.1:5556'), play: true);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (d) => _touch(d.localPosition, context, 0),
      onPanUpdate: (d) => _touch(d.localPosition, context, 1),
      onPanEnd: (_) => WirelessAABridge().sendTouchEvent(0, 0, 2),
      child: Video(
        controller: _controller,
        fit: BoxFit.cover,
      ),
    );
  }

  void _touch(Offset pos, BuildContext ctx, int action) {
    final size = ctx.size;
    if (size == null || size.isEmpty) return;
    WirelessAABridge().sendTouchEvent(
      pos.dx / size.width,
      pos.dy / size.height,
      action,
    );
  }
}

class _LinuxVideoSurface extends StatefulWidget {
  final String deviceName;
  const _LinuxVideoSurface({required this.deviceName});

  @override
  State<_LinuxVideoSurface> createState() => _LinuxVideoSurfaceState();
}

/// Called from aa_video_surface.dart via conditional import.
Widget buildLinuxVideoSurface({required String deviceName}) {
  return _LinuxVideoSurface(deviceName: deviceName);
}
