import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// A USB device attach/detach event, as reported by the udev-triggered
/// notifier script installed by scripts/install_usb_hotplug.sh.
class UsbHotplugEvent {
  final bool attached;
  final String vendorId;
  final String productId;

  const UsbHotplugEvent({
    required this.attached,
    required this.vendorId,
    required this.productId,
  });

  @override
  String toString() => 'UsbHotplugEvent(attached: $attached, vendor: $vendorId, product: $productId)';
}

/// Bridges OS-level USB hotplug events into the Flutter app.
///
/// A udev rule (scripts/udev/99-headunit-usb-hotplug.rules) fires a root
/// notifier script (scripts/headunit-usb-notify.sh) on every USB add/remove.
/// That script forwards a one-line JSON event to this service's Unix domain
/// socket. This service is the socket *server* — starting it here means the
/// root-run udev script only ever needs to connect out, never write into a
/// path owned by the app's (non-root) user.
///
/// Note: this only signals that *something* was plugged in — it does not
/// itself negotiate the Android Auto Open Accessory Protocol handshake.
/// That's handled by the aasdk/openauto native process (see
/// scripts/install_openauto.sh); this service just gets the UI out of its
/// idle state immediately instead of waiting for the user to tap a button.
class UsbHotplugService {
  static final UsbHotplugService _instance = UsbHotplugService._internal();
  factory UsbHotplugService() => _instance;
  UsbHotplugService._internal();

  ServerSocket? _server;
  Timer? _debounce;

  final StreamController<UsbHotplugEvent> _controller = StreamController<UsbHotplugEvent>.broadcast();
  Stream<UsbHotplugEvent> get events => _controller.stream;

  bool get isListening => _server != null;

  /// Per-user runtime socket path. Matches what the notifier script scans
  /// for under /run/user/UID/headunit-os/, with /tmp as a fallback for
  /// environments without a systemd user session (e.g. plain `flutter run`).
  String get socketPath {
    final runtimeDir = Platform.environment['XDG_RUNTIME_DIR'];
    final base = (runtimeDir != null && runtimeDir.isNotEmpty) ? runtimeDir : '/tmp';
    return '$base/headunit-os/usb-hotplug.sock';
  }

  /// Binds the notification socket. No-op on non-Linux platforms and if
  /// already listening. Safe to call multiple times.
  Future<void> start() async {
    if (!Platform.isLinux || _server != null) return;

    try {
      final sockFile = File(socketPath);
      await sockFile.parent.create(recursive: true);
      if (await sockFile.exists()) {
        await sockFile.delete();
      }

      _server = await ServerSocket.bind(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );

      if (kDebugMode) print('[UsbHotplugService] Listening on $socketPath');

      _server!.listen(
        _handleClient,
        onError: (e) {
          if (kDebugMode) print('[UsbHotplugService] Server error: $e');
        },
      );
    } catch (e) {
      if (kDebugMode) print('[UsbHotplugService] Failed to bind $socketPath: $e');
      _server = null;
    }
  }

  void _handleClient(Socket client) {
    client.cast<List<int>>().transform(utf8.decoder).listen(
      (data) {
        for (final line in data.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) _handleLine(trimmed);
        }
      },
      onError: (e) {
        if (kDebugMode) print('[UsbHotplugService] Client read error: $e');
      },
      cancelOnError: false,
    );
  }

  void _handleLine(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final action = json['action'] as String?;
      final vendor = (json['vendor'] as String?)?.trim() ?? '';
      final product = (json['product'] as String?)?.trim() ?? '';

      // Hubs and root ports report add/remove too but carry no readable
      // device descriptor attrs from sysfs — ignore that noise.
      if (vendor.isEmpty || (action != 'add' && action != 'remove')) return;

      // A phone re-enumerates (plain USB -> AOAP accessory mode) within a
      // couple of seconds of being physically plugged in. Coalesce that
      // burst into a single debounced event instead of flapping the UI.
      final attached = action == 'add';
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        _controller.add(UsbHotplugEvent(attached: attached, vendorId: vendor, productId: product));
      });
    } catch (e) {
      if (kDebugMode) print('[UsbHotplugService] Malformed event "$line": $e');
    }
  }

  Future<void> stop() async {
    _debounce?.cancel();
    await _server?.close();
    _server = null;
  }
}
