import 'dart:typed_data';

/// Android Auto Protocol Channels
enum AAChannelId {
  control(0),
  mediaAudio(1),
  speechAudio(2),
  systemAudio(3),
  input(4),
  video(5),
  sensor(6);

  final int id;
  const AAChannelId(this.id);

  static AAChannelId fromId(int id) {
    return AAChannelId.values.firstWhere(
      (c) => c.id == id,
      orElse: () => AAChannelId.control,
    );
  }
}

/// Android Auto Packet Frame Types
enum AAFrameType {
  first(1),
  middle(2),
  last(4),
  single(8);

  final int flag;
  const AAFrameType(this.flag);
}

/// Demuxed Android Auto Packet
class AAPacket {
  final AAChannelId channel;
  final int flags;
  final Uint8List payload;

  const AAPacket({
    required this.channel,
    required this.flags,
    required this.payload,
  });

  /// Parse binary frame header:
  /// Byte 0: Channel ID
  /// Byte 1: Flags / Frame Type
  /// Bytes 2-3: Payload Length (Big Endian)
  static AAPacket? fromRawBytes(Uint8List bytes) {
    if (bytes.length < 4) return null;

    final channelId = bytes[0];
    final flags = bytes[1];
    final payloadLength = (bytes[2] << 8) | bytes[3];

    if (bytes.length < 4 + payloadLength) {
      // Return packet with available payload bytes
      return AAPacket(
        channel: AAChannelId.fromId(channelId),
        flags: flags,
        payload: bytes.sublist(4),
      );
    }

    return AAPacket(
      channel: AAChannelId.fromId(channelId),
      flags: flags,
      payload: bytes.sublist(4, 4 + payloadLength),
    );
  }

  /// Encode binary packet for transmission to phone
  Uint8List toRawBytes() {
    final length = payload.length;
    final header = Uint8List(4);
    header[0] = channel.id;
    header[1] = flags;
    header[2] = (length >> 8) & 0xFF;
    header[3] = length & 0xFF;

    final builder = BytesBuilder();
    builder.add(header);
    builder.add(payload);
    return builder.takeBytes();
  }
}

/// Normalized Touch Action Codes for Channel 4 (Input Channel)
class AATouchAction {
  static const int press = 0;
  static const int move = 1;
  static const int release = 2;
}

/// Connection Status State
enum AAEngineState {
  disconnected,
  discoveringUsb,
  aoapSwitching,
  wifiHotspotActive,
  bluetoothPairing,
  handshakeActive,
  streamingActive,
  error,
}
