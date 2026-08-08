import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  MediaItem _mediaItem = const MediaItem.none(audioMode: AudioSourceMode.bluetooth);
  Timer? _playbackTimer;

  MediaItem get mediaItem => _mediaItem;
  bool get hasMedia => _mediaItem.hasMedia;
  AudioSourceMode get currentMode => _mediaItem.audioMode;

  final List<MediaItem> _bluetoothPlaylist = [
    const MediaItem(
      hasMedia: true,
      title: "Blinding Lights",
      artist: "The Weeknd",
      album: "After Hours",
      coverUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80",
      duration: Duration(minutes: 3, seconds: 20),
      source: "Bluetooth Audio",
      audioMode: AudioSourceMode.bluetooth,
      isPlaying: true,
    ),
    const MediaItem(
      hasMedia: true,
      title: "Starboy",
      artist: "The Weeknd ft. Daft Punk",
      album: "Starboy",
      coverUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80",
      duration: Duration(minutes: 3, seconds: 50),
      source: "Bluetooth Audio",
      audioMode: AudioSourceMode.bluetooth,
      isPlaying: true,
    ),
  ];

  final List<MediaItem> _projectionPlaylist = [
    const MediaItem(
      hasMedia: true,
      title: "Midnight City",
      artist: "M83",
      album: "Hurry Up, We're Dreaming",
      coverUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80",
      duration: Duration(minutes: 4, seconds: 03),
      source: "CarPlay / Android Auto",
      audioMode: AudioSourceMode.projectionCarPlayAA,
      isPlaying: true,
    ),
    const MediaItem(
      hasMedia: true,
      title: "Get Lucky",
      artist: "Daft Punk ft. Pharrell",
      album: "Random Access Memories",
      coverUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80",
      duration: Duration(minutes: 4, seconds: 08),
      source: "CarPlay / Android Auto",
      audioMode: AudioSourceMode.projectionCarPlayAA,
      isPlaying: true,
    ),
  ];

  final List<MediaItem> _auxFmPlaylist = [
    const MediaItem(
      hasMedia: true,
      title: "88.3 FM Radio Live Stream",
      artist: "FM Radio Broadcaster",
      album: "88.3 MHz HD Audio",
      coverUrl: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500&q=80",
      duration: Duration(hours: 1),
      source: "AUX / FM Radio (88.3 MHz)",
      audioMode: AudioSourceMode.auxFm,
      isPlaying: true,
    ),
  ];

  int _currentIndex = 0;

  MediaProvider() {
    _startPlaybackTimer();
  }

  void _startPlaybackTimer() {
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mediaItem.hasMedia && _mediaItem.isPlaying) {
        if (_mediaItem.position < _mediaItem.duration) {
          _mediaItem = _mediaItem.copyWith(
            position: _mediaItem.position + const Duration(seconds: 1),
          );
          notifyListeners();
        } else {
          nextTrack();
        }
      }
    });
  }

  void setAudioMode(AudioSourceMode mode) {
    _currentIndex = 0;
    if (mode == AudioSourceMode.bluetooth) {
      _mediaItem = _bluetoothPlaylist[0];
    } else if (mode == AudioSourceMode.projectionCarPlayAA) {
      _mediaItem = _projectionPlaylist[0];
    } else if (mode == AudioSourceMode.auxFm) {
      _mediaItem = _auxFmPlaylist[0];
    }
    notifyListeners();
  }

  List<MediaItem> _getActivePlaylist() {
    if (_mediaItem.audioMode == AudioSourceMode.bluetooth) {
      return _bluetoothPlaylist;
    } else if (_mediaItem.audioMode == AudioSourceMode.projectionCarPlayAA) {
      return _projectionPlaylist;
    } else {
      return _auxFmPlaylist;
    }
  }

  void playDefaultTrack() {
    final playlist = _getActivePlaylist();
    _mediaItem = playlist[_currentIndex].copyWith(isPlaying: true);
    notifyListeners();
  }

  void clearMedia() {
    _mediaItem = MediaItem.none(audioMode: _mediaItem.audioMode);
    notifyListeners();
  }

  void togglePlayPause() {
    if (!_mediaItem.hasMedia) {
      playDefaultTrack();
      return;
    }
    _mediaItem = _mediaItem.copyWith(isPlaying: !_mediaItem.isPlaying);
    notifyListeners();
  }

  void nextTrack() {
    final playlist = _getActivePlaylist();
    if (!_mediaItem.hasMedia) {
      playDefaultTrack();
      return;
    }
    _currentIndex = (_currentIndex + 1) % playlist.length;
    _mediaItem = playlist[_currentIndex].copyWith(isPlaying: true);
    notifyListeners();
  }

  void previousTrack() {
    final playlist = _getActivePlaylist();
    if (!_mediaItem.hasMedia) {
      playDefaultTrack();
      return;
    }
    _currentIndex = (_currentIndex - 1 + playlist.length) % playlist.length;
    _mediaItem = playlist[_currentIndex].copyWith(isPlaying: true);
    notifyListeners();
  }

  void seek(Duration newPosition) {
    if (!_mediaItem.hasMedia) return;
    _mediaItem = _mediaItem.copyWith(position: newPosition);
    notifyListeners();
  }

  void setVolume(double newVolume) {
    _mediaItem = _mediaItem.copyWith(volume: newVolume.clamp(0.0, 1.0));
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
