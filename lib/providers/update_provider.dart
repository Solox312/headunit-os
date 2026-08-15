import 'dart:io';
import 'package:flutter/foundation.dart';
import 'wifi_provider.dart';
import '../services/update_service.dart';

/// Provider for managing state, background checks, and execution logs for system updates.
class UpdateProvider extends ChangeNotifier {
  final WifiProvider _wifiProvider;
  final UpdateService _service = UpdateService();

  bool _isChecking = false;
  bool _isUpdateAvailable = false;
  String? _remoteVersion;
  int? _remoteBuildNumber;
  List<String> _changelog = [];
  String? _downloadUrl;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  bool _isApplying = false;
  List<String> _updateLogs = [];

  bool _isOverlayFsActive = false;
  String? _errorMessage;
  bool _updateSuccess = false;

  // Default repository update manifest JSON URL.
  String _manifestUrl = "https://raw.githubusercontent.com/Solox312/headunit-os/master/update_manifest.json";

  // Getters
  bool get isChecking => _isChecking;
  bool get isUpdateAvailable => _isUpdateAvailable;
  String? get remoteVersion => _remoteVersion;
  int? get remoteBuildNumber => _remoteBuildNumber;
  List<String> get changelog => _changelog;
  String? get downloadUrl => _downloadUrl;

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;

  bool get isApplying => _isApplying;
  List<String> get updateLogs => List.unmodifiable(_updateLogs);

  bool get isOverlayFsActive => _isOverlayFsActive;
  String? get errorMessage => _errorMessage;
  bool get updateSuccess => _updateSuccess;
  String get manifestUrl => _manifestUrl;

  UpdateProvider(this._wifiProvider) {
    _wifiProvider.addListener(_onWifiStateChanged);
    _init();
  }

  bool _wasConnected = false;

  void _init() async {
    _isOverlayFsActive = await _service.checkOverlayFsActive();
    _wasConnected = _wifiProvider.isConnected;
    if (_wasConnected) {
      checkForUpdates();
    }
  }

  void _onWifiStateChanged() {
    final isConnected = _wifiProvider.isConnected;
    if (isConnected && !_wasConnected) {
      checkForUpdates();
    }
    _wasConnected = isConnected;
  }

  /// Change remote update manifest URL configuration (e.g. from developer options)
  Future<void> setManifestUrl(String url) async {
    _manifestUrl = url;
    notifyListeners();
    if (_wifiProvider.isConnected) {
      await checkForUpdates();
    }
  }

  /// Check whether OverlayFS read-only mode is active
  Future<void> refreshOverlayFsStatus() async {
    _isOverlayFsActive = await _service.checkOverlayFsActive();
    notifyListeners();
  }

  /// Helper to toggle simulated OverlayFS active state for testing/development
  void toggleSimulateOverlayFs(bool value) {
    UpdateService.simulateOverlayFs = value;
    refreshOverlayFsStatus();
  }

  /// Run update check against the remote JSON manifest.
  Future<void> checkForUpdates() async {
    if (_isChecking || _isDownloading || _isApplying) return;

    _isChecking = true;
    _errorMessage = null;
    _isUpdateAvailable = false;
    notifyListeners();

    try {
      _isOverlayFsActive = await _service.checkOverlayFsActive();
      final result = await _service.checkForUpdates(_manifestUrl);
      if (result.success) {
        _isUpdateAvailable = result.updateAvailable;
        _remoteVersion = result.remoteVersion;
        _remoteBuildNumber = result.remoteBuildNumber;
        _changelog = result.changelog;
        _downloadUrl = result.downloadUrl;
      } else {
        _errorMessage = result.errorMessage;
      }
    } catch (e) {
      _errorMessage = "Failed checking updates: $e";
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Runs the full download, extraction, and service restart OTA workflow.
  Future<bool> startUpdateFlow() async {
    if (!_isUpdateAvailable || _downloadUrl == null || _downloadUrl!.isEmpty) {
      _errorMessage = "No update is available to apply.";
      notifyListeners();
      return false;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _updateLogs = [];
    _errorMessage = null;
    _updateSuccess = false;
    notifyListeners();

    // Check OverlayFS status one last time
    _isOverlayFsActive = await _service.checkOverlayFsActive();

    final savePath = Platform.isLinux
        ? '/tmp/headunit-update.tar.gz'
        : 'headunit-update-simulation.tar.gz';

    try {
      final downloadOk = await _service.downloadUpdate(_downloadUrl!, savePath, (progress) {
        _downloadProgress = progress;
        notifyListeners();
      });

      if (!downloadOk) {
        _errorMessage = "Failed to download update package.";
        _isDownloading = false;
        notifyListeners();
        return false;
      }

      _isDownloading = false;
      _isApplying = true;
      notifyListeners();

      // Listen to apply update logs (stdout/stderr merged)
      final logStream = _service.applyUpdate(savePath);
      await for (var log in logStream) {
        _updateLogs.add(log);
        notifyListeners();
      }

      _isApplying = false;

      // Scan logs to check if extraction was completed successfully
      final lastLogLine = _updateLogs.isNotEmpty ? _updateLogs.last : "";
      if (_updateLogs.isNotEmpty &&
          (lastLogLine.toLowerCase().contains("successfully") ||
              lastLogLine.toLowerCase().contains("applied"))) {
        _updateSuccess = true;
        _isUpdateAvailable = false;
      } else {
        _errorMessage = "Update failed during deployment. Verify the logs.";
      }
      notifyListeners();
      return _updateSuccess;
    } catch (e) {
      _errorMessage = "Update failed: $e";
      _isDownloading = false;
      _isApplying = false;
      notifyListeners();
      return false;
    }
  }

  /// Restart/reboot target system
  Future<bool> triggerReboot() async {
    return await _service.rebootSystem();
  }

  @override
  void dispose() {
    _wifiProvider.removeListener(_onWifiStateChanged);
    super.dispose();
  }
}
