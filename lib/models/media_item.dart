class MediaItem {
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final double volume; // 0.0 to 1.0
  final String source; // "Spotify", "CarPlay", "Android Auto", "Bluetooth"

  const MediaItem({
    this.title = "Blinding Lights",
    this.artist = "The Weeknd",
    this.album = "After Hours",
    this.coverUrl = "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80",
    this.duration = const Duration(minutes: 3, seconds: 20),
    this.position = const Duration(minutes: 1, seconds: 12),
    this.isPlaying = true,
    this.volume = 0.75,
    this.source = "Spotify",
  });

  MediaItem copyWith({
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    double? volume,
    String? source,
  }) {
    return MediaItem(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      source: source ?? this.source,
    );
  }
}
