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
  final String source; // "CarPlay / AA", "Bluetooth", "Aux / FM", "None"
  final AudioSourceMode audioMode;

  const MediaItem({
    this.hasMedia = false,
    this.title = "No Track Playing",
    this.artist = "No Active Audio Source",
    this.album = "",
    this.coverUrl = "",
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.volume = 0.75,
    this.source = "None",
    this.audioMode = AudioSourceMode.bluetooth,
  });

  const MediaItem.none({this.audioMode = AudioSourceMode.bluetooth})
      : hasMedia = false,
        title = "No Track Playing",
        artist = "Select an audio source to begin playback",
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
