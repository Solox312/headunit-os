enum BluetoothDeviceType {
  phone,
  audio,
  car,
  unknown,
}

class BluetoothDevice {
  final String macAddress;
  final String name;
  final BluetoothDeviceType type;
  final bool isConnected;
  final bool isPaired;
  final int rssi;
  final List<String> profiles;

  const BluetoothDevice({
    required this.macAddress,
    required this.name,
    this.type = BluetoothDeviceType.unknown,
    this.isConnected = false,
    this.isPaired = false,
    this.rssi = -60,
    this.profiles = const [],
  });

  BluetoothDevice copyWith({
    String? macAddress,
    String? name,
    BluetoothDeviceType? type,
    bool? isConnected,
    bool? isPaired,
    int? rssi,
    List<String>? profiles,
  }) {
    return BluetoothDevice(
      macAddress: macAddress ?? this.macAddress,
      name: name ?? this.name,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      isPaired: isPaired ?? this.isPaired,
      rssi: rssi ?? this.rssi,
      profiles: profiles ?? this.profiles,
    );
  }

  factory BluetoothDevice.fromBluetoothctlLine(String line, {bool isPaired = false, bool isConnected = false}) {
    // Expected line format: Device AA:BB:CC:DD:EE:FF Pixel_8_Pro
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 3) {
      return BluetoothDevice(
        macAddress: line.trim(),
        name: line.trim(),
        isPaired: isPaired,
        isConnected: isConnected,
      );
    }

    final mac = parts[1].trim();
    final name = parts.sublist(2).join(' ').trim();
    final lowerName = name.toLowerCase();

    BluetoothDeviceType devType = BluetoothDeviceType.unknown;
    if (lowerName.contains('phone') || lowerName.contains('pixel') || lowerName.contains('iphone') || lowerName.contains('galaxy') || lowerName.contains('samsung') || lowerName.contains('xiaomi') || lowerName.contains('redmi') || lowerName.contains('oneplus') || lowerName.contains('motorola') || lowerName.contains('huawei')) {
      devType = BluetoothDeviceType.phone;
    } else if (lowerName.contains('headset') || lowerName.contains('headphone') || lowerName.contains('audio') || lowerName.contains('buds') || lowerName.contains('ear') || lowerName.contains('airpod') || lowerName.contains('speaker') || lowerName.contains('sound') || lowerName.contains('jbl') || lowerName.contains('bose') || lowerName.contains('sony') || lowerName.contains('anker') || lowerName.contains('soundcore') || lowerName.contains('beats') || lowerName.contains('echo') || lowerName.contains('marshall') || lowerName.contains('boom') || lowerName.contains('flip') || lowerName.contains('charge') || lowerName.contains('tribit') || lowerName.contains('oontz')) {
      devType = BluetoothDeviceType.audio;
    } else if (lowerName.contains('car') || lowerName.contains('headunit') || lowerName.contains('auto') || lowerName.contains('sync') || lowerName.contains('stereo') || lowerName.contains('receiver') || lowerName.contains('mmi') || lowerName.contains('uconnect') || lowerName.contains('entune') || lowerName.contains('mbux') || lowerName.contains('bt-')) {
      devType = BluetoothDeviceType.car;
    }

    // If the name is just a MAC with dashes (e.g. 11-22-33-44-55-66), clean it or fallback to mac
    final isMacLikeName = RegExp(r'^([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$').hasMatch(name) ||
        RegExp(r'^([0-9a-fA-F]{2}[-]){5}[0-9a-fA-F]{2}$').hasMatch(name);

    return BluetoothDevice(
      macAddress: mac,
      name: isMacLikeName || name.isEmpty ? mac : name,
      type: devType,
      isPaired: isPaired,
      isConnected: isConnected,
      profiles: isConnected ? const ['A2DP Audio', 'Hands-Free (HFP)', 'Android Auto'] : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'macAddress': macAddress,
        'name': name,
        'type': type.name,
        'isConnected': isConnected,
        'isPaired': isPaired,
        'rssi': rssi,
        'profiles': profiles,
      };
}
