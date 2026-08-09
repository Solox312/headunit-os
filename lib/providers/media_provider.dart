import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  MediaItem _mediaItem = const MediaItem.none(audioMode: AudioSourceMode.bluetooth);
  Timer? _playbackTimer;

  MediaItem get mediaItem => _mediaItem;
  bool get hasMedia => _mediaItem.hasMedia;
  AudioSourceMode get currentMode => _mediaItem.audioMode;

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
        }
      }
    });
  }

  void setAudioMode(AudioSourceMode mode) {
    if (mode == AudioSourceMode.auxFm) {
      _mediaItem = const MediaItem(
        hasMedia: true,
        title: "AUX / FM Radio Stream",
        artist: "Analog Audio Input",
        album: "Live Audio",
        duration: Duration(hours: 1),
        source: "AUX / FM Radio",
        audioMode: AudioSourceMode.auxFm,
        isPlaying: true,
      );
    } else {
      _mediaItem = MediaItem.none(audioMode: mode);
    }
    notifyListeners();
  }

  void updateTrackInfo({
    required String title,
    required String artist,
    String album = '',
    String coverUrl = '',
    Duration duration = Duration.zero,
    String source = 'Connected Device',
    bool isPlaying = true,
    AudioSourceMode? audioMode,
  }) {
    _mediaItem = MediaItem(
      hasMedia: true,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      duration: duration,
      position: Duration.zero,
      isPlaying: isPlaying,
      volume: _mediaItem.volume,
      source: source,
      audioMode: audioMode ?? _mediaItem.audioMode,
    );
    notifyListeners();
  }

  void clearMedia() {
    _mediaItem = MediaItem.none(audioMode: _mediaItem.audioMode);
    notifyListeners();
  }

  void Function()? onTogglePlayPause;
  void Function()? onNextTrack;
  void Function()? onPreviousTrack;

  void togglePlayPause() {
    if (!_mediaItem.hasMedia) return;
    _mediaItem = _mediaItem.copyWith(isPlaying: !_mediaItem.isPlaying);
    notifyListeners();
    onTogglePlayPause?.call();
  }

  void nextTrack() {
    if (!_mediaItem.hasMedia) return;
    onNextTrack?.call();
  }

  void previousTrack() {
    if (!_mediaItem.hasMedia) return;
    onPreviousTrack?.call();
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
