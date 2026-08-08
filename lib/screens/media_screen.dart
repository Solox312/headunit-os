import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/media_provider.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = Provider.of<MediaProvider>(context);
    final item = media.mediaItem;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Side: Large Glowing Album Art & Visualizer
            Expanded(
              flex: 5,
              child: GlassCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AutomotiveColors.purpleAccent.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            item.coverUrl,
                            width: 210,
                            height: 210,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 210,
                                height: 210,
                                color: AutomotiveColors.cardBackground,
                                child: const Icon(
                                  Icons.album_rounded,
                                  size: 80,
                                  color: AutomotiveColors.purpleAccent,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Live Audio Equalizer Bar Animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        12,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: item.isPlaying ? (15 + (index % 5) * 8.0) : 6.0,
                          decoration: BoxDecoration(
                            color: AutomotiveColors.cyanAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Right Side: Track Info, Seek Bar, Controls & Source Selector
            Expanded(
              flex: 6,
              child: GlassCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AutomotiveColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AutomotiveColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_audio_rounded, size: 14, color: AutomotiveColors.cyanAccent),
                              const SizedBox(width: 6),
                              Text(
                                item.source,
                                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.favorite_border_rounded, color: AutomotiveColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      item.title,
                      style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${item.artist} — ${item.album}",
                      style: GoogleFonts.inter(fontSize: 15, color: AutomotiveColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Progress Bar
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        activeTrackColor: AutomotiveColors.cyanAccent,
                        inactiveTrackColor: AutomotiveColors.cardBorder,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: item.position.inSeconds.toDouble().clamp(0.0, item.duration.inSeconds.toDouble()),
                        max: item.duration.inSeconds.toDouble(),
                        onChanged: (val) {
                          media.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(item.position), style: const TextStyle(fontSize: 12, color: AutomotiveColors.textMuted)),
                          Text(_formatDuration(item.duration), style: const TextStyle(fontSize: 12, color: AutomotiveColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Playback Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shuffle_rounded),
                          color: AutomotiveColors.textSecondary,
                          onPressed: () {},
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 40,
                          onPressed: () => media.previousTrack(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(item.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded),
                          iconSize: 58,
                          color: AutomotiveColors.cyanAccent,
                          onPressed: () => media.togglePlayPause(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 40,
                          onPressed: () => media.nextTrack(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.repeat_rounded),
                          color: AutomotiveColors.textSecondary,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
