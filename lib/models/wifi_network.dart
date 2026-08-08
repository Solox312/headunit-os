class WifiNetwork {
  final String ssid;
  final int signalStrength; // 0 to 100
  final String security; // e.g. WPA2, WPA3, Open
  final bool isConnected;
  final bool isSaved;
  final String? bssid;

  const WifiNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.security,
    this.isConnected = false,
    this.isSaved = false,
    this.bssid,
  });

  bool get isSecured => security.isNotEmpty && !security.toUpperCase().contains('NONE') && !security.toUpperCase().contains('OPEN');

  factory WifiNetwork.fromNmcliLine(String line) {
    // Format expected: SSID:SIGNAL:SECURITY:IN-USE:BSSID
    // Columns separated by colon or escaped colons
    final parts = line.split(':');
    if (parts.length < 4) {
      return WifiNetwork(ssid: line.trim(), signalStrength: 50, security: 'Unknown');
    }

    final ssid = parts[0].trim();
    final signal = int.tryParse(parts[1].trim()) ?? 50;
    final security = parts[2].trim().isEmpty ? 'Open' : parts[2].trim();
    final inUse = parts[3].trim() == '*' || parts[3].trim().toLowerCase() == 'yes';
    final bssid = parts.length > 4 ? parts[4].trim() : null;

    return WifiNetwork(
      ssid: ssid,
      signalStrength: signal,
      security: security,
      isConnected: inUse,
      bssid: bssid,
    );
  }

  Map<String, dynamic> toJson() => {
        'ssid': ssid,
        'signalStrength': signalStrength,
        'security': security,
        'isConnected': isConnected,
        'isSaved': isSaved,
        'bssid': bssid,
      };
}
