import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/aa_protocol_types.dart';
import 'aa_usb_aoap_service.dart';

/// Native Android Auto Protocol Receiver Engine (AOA 2.0 + Protobuf Channels + Socket Demuxer)
class AndroidAutoEngine {
  static final AndroidAutoEngine _instance = AndroidAutoEngine._internal();
  factory AndroidAutoEngine() => _instance;
  AndroidAutoEngine._internal();

  bool _isSessionActive = false;
  Socket? _aaSocket;
  AAEngineState _state = AAEngineState.disconnected;

  bool get isSessionActive => _isSessionActive;
  bool get isSocketConnected => _aaSocket != null;
  AAEngineState get state => _state;

  // Stream Controllers for H.264 Video, PCM Audio Channels, and Protocol Status
  final StreamController<Uint8List> _h264VideoStreamController = StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _pcmAudioStreamController = StreamController<Uint8List>.broadcast();
  final StreamController<String> _statusStreamController = StreamController<String>.broadcast();
  final StreamController<AAEngineState> _stateStreamController = StreamController<AAEngineState>.broadcast();

  Stream<Uint8List> get h264VideoStream => _h264VideoStreamController.stream;
  Stream<Uint8List> get pcmAudioStream => _pcmAudioStreamController.stream;
  Stream<String> get statusStream => _statusStreamController.stream;
  Stream<AAEngineState> get stateStream => _stateStreamController.stream;

  ServerSocket? _serverSocket;

  /// Start Native Android Auto Server Socket listening for incoming connections on port 50001 (Wi-Fi) or 5277 (ADB)
  Future<bool> connectNativeSocket({String host = '0.0.0.0', int port = 50001}) async {
    try {
      _setState(AAEngineState.handshakeActive);
      if (kDebugMode) {
        print("[AndroidAutoEngine] Binding ServerSocket listening on 0.0.0.0:$port for incoming Android Auto connections...");
      }

      _serverSocket?.close();
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      
      _statusStreamController.add("Listening for Android Auto phone connection on port $port...");
      if (kDebugMode) {
        print("[AndroidAutoEngine] ServerSocket bound to port $port — waiting for phone connection!");
      }

      // Wait for incoming socket connection from phone
      final socketCompleter = Completer<bool>();

      _serverSocket!.listen(
        (Socket clientSocket) {
          _aaSocket = clientSocket;
          _isSessionActive = true;
          _setState(AAEngineState.streamingActive);
          _statusStreamController.add("Phone connected via TCP socket on port $port!");
          if (kDebugMode) {
            print("[AndroidAutoEngine] Incoming phone connection accepted from ${clientSocket.remoteAddress.address}:${clientSocket.remotePort}!");
          }

          if (!socketCompleter.isCompleted) {
            socketCompleter.complete(true);
          }

          // Listen for incoming byte packets and demux using AAPacket header codec
          clientSocket.listen(
            (Uint8List rawBytes) {
              _handleIncomingRawBytes(rawBytes);
            },
            onError: (error) {
              if (kDebugMode) print("[AndroidAutoEngine] Socket Error: $error");
              stopSession();
            },
            onDone: () {
              if (kDebugMode) print("[AndroidAutoEngine] Phone closed socket connection.");
              stopSession();
            },
          );
        },
        onError: (error) {
          if (kDebugMode) print("[AndroidAutoEngine] ServerSocket error: $error");
          if (!socketCompleter.isCompleted) socketCompleter.complete(false);
        },
      );

      // Return true once socket server is bound & listening
      return true;
    } catch (e) {
      if (kDebugMode) print("[AndroidAutoEngine] ServerSocket bind exception: $e");
      return false;
    }
  /// Compatibility alias for ADB DHU server connection
  Future<bool> connectAdbDhuServer({String host = '127.0.0.1', int port = 5277}) {
    return connectNativeSocket(host: host, port: port);
  }

  /// Demux incoming byte stream into discrete AA protocol channels
  void _handleIncomingRawBytes(Uint8List bytes) {
    final packet = AAPacket.fromRawBytes(bytes);
    if (packet == null) return;

    switch (packet.channel) {
      case AAChannelId.video:
        // Channel 5: H.264 Video Stream NAL Units
        _h264VideoStreamController.add(packet.payload);
        break;
      case AAChannelId.mediaAudio:
      case AAChannelId.speechAudio:
      case AAChannelId.systemAudio:
        // Channels 1, 2, 3: PCM Audio Stream
        _pcmAudioStreamController.add(packet.payload);
        break;
      case AAChannelId.control:
        // Channel 0: Control Messages (Service Discovery, Ping)
        _handleControlPacket(packet.payload);
        break;
      case AAChannelId.input:
        break;
      case AAChannelId.sensor:
        break;
    }
  }

  void _handleControlPacket(Uint8List payload) {
    if (kDebugMode) {
      print("[AndroidAutoEngine] Channel 0 Control Message (len: ${payload.length})");
    }
  }

  /// Phase 1: Native USB AOAP Scan and Handshake
  Future<bool> initiateUsbAoapHandshake() async {
    _setState(AAEngineState.discoveringUsb);
    final success = await AaUsbAoapService().checkForAndroidDeviceAndInitiateAoap();
    if (success) {
      _setState(AAEngineState.handshakeActive);
    }
    return success;
  }

  /// Phase 2: Native Touch Event Serialization over Channel 4 (Input Channel)
  void sendTouchEvent({required double x, required double y, required int action}) {
    // Construct Channel 4 Input Packet: Action (0=Press, 1=Move, 2=Release), X (uint16), Y (uint16)
    final xInt = (x.clamp(0.0, 1.0) * 65535).toInt();
    final yInt = (y.clamp(0.0, 1.0) * 65535).toInt();

    final payload = Uint8List(5);
    payload[0] = action;
    payload[1] = (xInt >> 8) & 0xFF;
    payload[2] = xInt & 0xFF;
    payload[3] = (yInt >> 8) & 0xFF;
    payload[4] = yInt & 0xFF;

    final inputPacket = AAPacket(
      channel: AAChannelId.input,
      flags: AAFrameType.single.flag,
      payload: payload,
    );

    if (_aaSocket != null) {
      _aaSocket!.add(inputPacket.toRawBytes());
    }

    if (kDebugMode) {
      print("[AndroidAutoEngine] Channel 4 Touch Packet -> (X: ${(x * 100).toStringAsFixed(1)}%, Y: ${(y * 100).toStringAsFixed(1)}%, Action: $action)");
    }
  }

  void _setState(AAEngineState newState) {
    _state = newState;
    _stateStreamController.add(newState);
  }

  /// Terminate Session
  void stopSession() {
    _aaSocket?.destroy();
    _aaSocket = null;
    _isSessionActive = false;
    _setState(AAEngineState.disconnected);
    _statusStreamController.add("Session disconnected.");
    if (kDebugMode) {
      print("[AndroidAutoEngine] Android Auto session terminated.");
    }
  }
}
