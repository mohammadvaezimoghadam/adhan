import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/surah_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';

/// Full-width docked web audio player bar matching Quran.com and Spotify standards.
/// Pinned cleanly across the bottom of the desktop web browser layout.
class WebDockedAudioPlayerBar extends ConsumerWidget {
  const WebDockedAudioPlayerBar({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(quranAudioControllerProvider);
    final currentSurahId = audioState.currentSurahId;

    // Show only when there is an active session
    if (currentSurahId == null || audioState.status == AudioStatus.stopped) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final audioController = ref.read(quranAudioControllerProvider.notifier);

    final surahName = SurahConstants.getSurahName(currentSurahId);
    final currentAyah = audioState.currentAyahNumber ?? 1;
    final totalAyahs = audioState.totalAyahsInSurah ?? 1;
    final reciterName = audioState.selectedReciter?.name ?? 'قاری منتخب';

    final isPlaying = audioState.status == AudioStatus.playing;
    final isLoading = audioState.status == AudioStatus.loading;

    final position = audioState.position;
    final duration = audioState.duration;
    final double maxDurationMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final double currentPosMs = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: isDark ? 0.95 : 0.98),
        border: Border(
          top: BorderSide(
            color: colors.cardBorder,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Zone 1: Current Surah & Ayah Info (RTL Right) ──
          SizedBox(
            width: 260,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currentSurahId.toPersianDigit(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سوره $surahName',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'آیه ${currentAyah.toPersianDigit()} از ${totalAyahs.toPersianDigit()} • $reciterName',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ── Zone 2: Player Controls & Timeline (Center) ──
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Ayah Button
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(CupertinoIcons.forward_end_fill, size: 18),
                      tooltip: 'آیه قبلی',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        audioController.playPreviousAyah();
                      },
                    ),

                    const SizedBox(width: 8),

                    // Play / Pause / Loading Main Action
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? CupertinoIcons.pause_fill
                                    : CupertinoIcons.play_fill,
                                size: 18,
                                color: Colors.white,
                              ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (isPlaying) {
                            audioController.pause();
                          } else {
                            audioController.resume();
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Next Ayah Button
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(CupertinoIcons.backward_end_fill, size: 18),
                      tooltip: 'آیه بعدی',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        audioController.playNextAyah();
                      },
                    ),

                    const SizedBox(width: 16),

                    // Playback Speed Toggle
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        audioController.cyclePlaybackSpeed();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${audioState.speed}x',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Scrubber / Timeline Bar
                SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 8),
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.primary
                                .withValues(alpha: 0.15),
                            thumbColor: colorScheme.primary,
                          ),
                          child: Slider(
                            value: currentPosMs,
                            min: 0.0,
                            max: maxDurationMs,
                            onChanged: (val) {
                              audioController.seekForward(
                                  Duration(milliseconds: val.toInt()) - position);
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ── Zone 3: Secondary Actions (RTL Left) ──
          SizedBox(
            width: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Auto Scroll status toggle
                Tooltip(
                  message: audioState.isAutoScrollSuspended
                      ? 'پیمایش خودکار متوقف شده (برای فعال‌سازی کلیک کنید)'
                      : 'پیمایش خودکار فعال است',
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      audioState.isAutoScrollSuspended
                          ? CupertinoIcons.arrow_down_circle
                          : CupertinoIcons.arrow_down_circle_fill,
                      size: 20,
                      color: audioState.isAutoScrollSuspended
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : colorScheme.primary,
                    ),
                    onPressed: () {
                      if (audioState.isAutoScrollSuspended) {
                        audioController.resumeAutoScrollAndSync();
                      } else {
                        audioController.suspendAutoScroll();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 4),

                // Stop & Close Audio Bar Button
                Tooltip(
                  message: 'بستن و توقف صوت',
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      CupertinoIcons.xmark,
                      size: 18,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      audioController.stop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
