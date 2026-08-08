enum AudioSourceMode {
  bluetooth,
  projectionCarPlayAA,
  auxFm,
}

class MediaItem {
  final bool hasMedia;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final double volume; // 0.0 to 1.0
  final String source; // "Spotify", "CarPlay / AA", "Bluetooth", "Aux / FM", "None"
  final AudioSourceMode audioMode;

  const MediaItem({
    this.hasMedia = true,
    this.title = "Blinding Lights",
    this.artist = "The Weeknd",
    this.album = "After Hours",
    this.coverUrl = "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80",
    this.duration = const Duration(minutes: 3, seconds: 20),
    this.position = const Duration(minutes: 1, seconds: 12),
    this.isPlaying = true,
    this.volume = 0.75,
    this.source = "Bluetooth",
    this.audioMode = AudioSourceMode.bluetooth,
  });

  const MediaItem.none({this.audioMode = AudioSourceMode.bluetooth})
      : hasMedia = false,
        title = "No Music Playing",
        artist = "Select a mode to start audio playback",
        album = "Idle",
        coverUrl = "",
        duration = Duration.zero,
        position = Duration.zero,
        isPlaying = false,
        volume = 0.75,
        source = "None";

  MediaItem copyWith({
    bool? hasMedia,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    double? volume,
    String? source,
    AudioSourceMode? audioMode,
  }) {
    return MediaItem(
      hasMedia: hasMedia ?? this.hasMedia,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      source: source ?? this.source,
      audioMode: audioMode ?? this.audioMode,
    );
  }
}
