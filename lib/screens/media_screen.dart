import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/automotive_colors.dart';
import '../widgets/glass_card.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';

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
        child: Column(
          children: [
            // Top Mode Selector Bar: Bluetooth vs CarPlay / AA vs AUX/FM
            Row(
              children: [
                Text(
                  "AUDIO SOURCE MODE",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AutomotiveColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                _buildSourceModeChip(
                  context,
                  label: "Bluetooth Audio",
                  mode: AudioSourceMode.bluetooth,
                  activeColor: AutomotiveColors.electricCyan,
                  icon: Icons.bluetooth_audio_rounded,
                ),
                const SizedBox(width: 8),
                _buildSourceModeChip(
                  context,
                  label: "CarPlay / AA Stream",
                  mode: AudioSourceMode.projectionCarPlayAA,
                  activeColor: AutomotiveColors.dongleViolet,
                  icon: Icons.layers_rounded,
                ),
                const SizedBox(width: 8),
                _buildSourceModeChip(
                  context,
                  label: "AUX / FM Radio",
                  mode: AudioSourceMode.auxFm,
                  activeColor: AutomotiveColors.orangeAccent,
                  icon: Icons.radio_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Content Area (Active Player vs No Music Playing)
            Expanded(
              child: !media.hasMedia
                  ? _buildNoMusicPlayingState(context, media)
                  : _buildActiveMediaPlayer(context, media, item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceModeChip(
    BuildContext context, {
    required String label,
    required AudioSourceMode mode,
    required Color activeColor,
    required IconData icon,
  }) {
    final media = Provider.of<MediaProvider>(context);
    final isSelected = media.currentMode == mode;

    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AutomotiveColors.textSecondary),
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: AutomotiveColors.glassPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? activeColor : AutomotiveColors.stroke),
      ),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : AutomotiveColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          media.setAudioMode(mode);
        }
      },
    );
  }

  Widget _buildActiveMediaPlayer(BuildContext context, MediaProvider media, MediaItem item) {
    return Row(
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
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: item.audioMode == AudioSourceMode.bluetooth
                                ? AutomotiveColors.electricCyan.withValues(alpha: 0.3)
                                : (item.audioMode == AudioSourceMode.projectionCarPlayAA
                                    ? AutomotiveColors.dongleViolet.withValues(alpha: 0.35)
                                    : AutomotiveColors.orangeAccent.withValues(alpha: 0.3)),
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
                        width: 190,
                        height: 190,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 190,
                            height: 190,
                            color: AutomotiveColors.glassPanel,
                            child: Icon(
                              Icons.album_rounded,
                              size: 80,
                              color: item.audioMode == AudioSourceMode.bluetooth
                                  ? AutomotiveColors.electricCyan
                                  : AutomotiveColors.dongleViolet,
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
                    14,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5,
                      height: item.isPlaying ? (14 + (index % 5) * 7.0) : 6.0,
                      decoration: BoxDecoration(
                        color: item.audioMode == AudioSourceMode.bluetooth
                            ? AutomotiveColors.electricCyan
                            : (item.audioMode == AudioSourceMode.projectionCarPlayAA
                                ? AutomotiveColors.dongleViolet
                                : AutomotiveColors.orangeAccent),
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
                          Icon(
                            item.audioMode == AudioSourceMode.bluetooth
                                ? Icons.bluetooth_audio_rounded
                                : (item.audioMode == AudioSourceMode.projectionCarPlayAA
                                    ? Icons.layers_rounded
                                    : Icons.radio_rounded),
                            size: 14,
                            color: item.audioMode == AudioSourceMode.bluetooth
                                ? AutomotiveColors.electricCyan
                                : AutomotiveColors.dongleViolet,
                          ),
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
                    IconButton(
                      icon: const Icon(Icons.stop_rounded, color: AutomotiveColors.redAccent),
                      tooltip: "Stop & Clear Media",
                      onPressed: () => media.clearMedia(),
                    ),
                    const Icon(Icons.favorite_border_rounded, color: AutomotiveColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  item.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AutomotiveColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item.artist} — ${item.album}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AutomotiveColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress Bar
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: item.audioMode == AudioSourceMode.bluetooth
                        ? AutomotiveColors.electricCyan
                        : AutomotiveColors.dongleViolet,
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
                const SizedBox(height: 12),

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
                      iconSize: 52,
                      color: item.audioMode == AudioSourceMode.bluetooth
                          ? AutomotiveColors.electricCyan
                          : AutomotiveColors.dongleViolet,
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
    );
  }

  Widget _buildNoMusicPlayingState(BuildContext context, MediaProvider media) {
    final String modeName = media.currentMode == AudioSourceMode.bluetooth
        ? "Bluetooth Audio"
        : (media.currentMode == AudioSourceMode.projectionCarPlayAA
            ? "CarPlay / Android Auto Stream"
            : "AUX / FM Radio");

    return GlassCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AutomotiveColors.glassPanel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AutomotiveColors.stroke, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: AutomotiveColors.electricCyan.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(
                media.currentMode == AudioSourceMode.bluetooth
                    ? Icons.bluetooth_audio_rounded
                    : (media.currentMode == AudioSourceMode.projectionCarPlayAA
                        ? Icons.layers_rounded
                        : Icons.radio_rounded),
                size: 38,
                color: AutomotiveColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "No Audio Active ($modeName)",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AutomotiveColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Connect device via $modeName mode or tap play to start audio playback.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AutomotiveColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text("Start $modeName Audio", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: media.currentMode == AudioSourceMode.bluetooth
                    ? AutomotiveColors.electricCyan
                    : (media.currentMode == AudioSourceMode.projectionCarPlayAA
                        ? AutomotiveColors.dongleViolet
                        : AutomotiveColors.orangeAccent),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                media.playDefaultTrack();
              },
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
