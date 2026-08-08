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
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AutomotiveColors.dongleViolet.withValues(alpha: 0.35),
                                blurRadius: 36,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            item.coverUrl,
                            width: 210,
                            height: 210,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 210,
                                height: 210,
                                color: AutomotiveColors.glassPanel,
                                child: const Icon(
                                  Icons.album_rounded,
                                  size: 80,
                                  color: AutomotiveColors.dongleViolet,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Live Audio Equalizer Bar Animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        14,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 5,
                          height: item.isPlaying ? (14 + (index % 5) * 7.0) : 6.0,
                          decoration: BoxDecoration(
                            color: AutomotiveColors.electricCyan,
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
                            color: AutomotiveColors.panelDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AutomotiveColors.stroke),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_audio_rounded, size: 14, color: AutomotiveColors.electricCyan),
                              const SizedBox(width: 6),
                              Text(
                                item.source,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AutomotiveColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
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
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AutomotiveColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${item.artist} — ${item.album}",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AutomotiveColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Progress Bar
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        activeTrackColor: AutomotiveColors.electricCyan,
                        inactiveTrackColor: AutomotiveColors.stroke,
                        thumbColor: AutomotiveColors.textPrimary,
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
                          Text(
                            _formatDuration(item.position),
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AutomotiveColors.textMuted),
                          ),
                          Text(
                            _formatDuration(item.duration),
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AutomotiveColors.textMuted),
                          ),
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
                          iconSize: 36,
                          color: AutomotiveColors.textPrimary,
                          onPressed: () => media.previousTrack(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(item.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded),
                          iconSize: 56,
                          color: AutomotiveColors.electricCyan,
                          onPressed: () => media.togglePlayPause(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 36,
                          color: AutomotiveColors.textPrimary,
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
