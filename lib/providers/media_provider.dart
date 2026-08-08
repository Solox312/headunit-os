import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

class MediaProvider extends ChangeNotifier {
  MediaItem _mediaItem = const MediaItem();
  Timer? _playbackTimer;

  MediaItem get mediaItem => _mediaItem;

  final List<MediaItem> _playlist = [
    const MediaItem(
      title: "Blinding Lights",
      artist: "The Weeknd",
      album: "After Hours",
      coverUrl: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80",
      duration: Duration(minutes: 3, seconds: 20),
      source: "Spotify",
    ),
    const MediaItem(
      title: "Midnight City",
      artist: "M83",
      album: "Hurry Up, We're Dreaming",
      coverUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80",
      duration: Duration(minutes: 4, seconds: 03),
      source: "CarPlay",
    ),
    const MediaItem(
      title: "Get Lucky",
      artist: "Daft Punk ft. Pharrell",
      album: "Random Access Memories",
      coverUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&q=80",
      duration: Duration(minutes: 4, seconds: 08),
      source: "Android Auto",
    ),
  ];

  int _currentIndex = 0;

  MediaProvider() {
    _startPlaybackTimer();
  }

  void _startPlaybackTimer() {
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_mediaItem.isPlaying) {
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

  void togglePlayPause() {
    _mediaItem = _mediaItem.copyWith(isPlaying: !_mediaItem.isPlaying);
    notifyListeners();
  }

  void nextTrack() {
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _mediaItem = _playlist[_currentIndex].copyWith(isPlaying: true);
    notifyListeners();
  }

  void previousTrack() {
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _mediaItem = _playlist[_currentIndex].copyWith(isPlaying: true);
    notifyListeners();
  }

  void seek(Duration newPosition) {
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
