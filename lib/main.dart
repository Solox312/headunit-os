import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'services/audio_routing_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // When returning from Android Auto (openauto.service ExecStopPost creates
  // this flag), skip the splash screen and open directly on App Connect (index 1).
  const flagPath = '/tmp/heados-return-from-aa';
  final flagFile = File(flagPath);
  final bool returnFromAA = flagFile.existsSync();
  if (returnFromAA) {
    try { flagFile.deleteSync(); } catch (_) {}
  }

  AudioRoutingService().init();

  runApp(RpiHeadunitApp(skipSplash: returnFromAA, initialIndex: returnFromAA ? 1 : 0));
}
