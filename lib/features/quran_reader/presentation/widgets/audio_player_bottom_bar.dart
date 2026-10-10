import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../application/controllers/selected_ayah_action_provider.dart';
import '../../domain/enums/audio_playback_mode.dart';
import '../../domain/enums/current_track_type.dart';
import 'audio_mini_progress_slider.dart';
import 'quick_settings_drawer.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../common/widgets/reciter/reciter_avatar_button.dart';
import '../../../../common/widgets/reciter/reciter_selection_bottom_sheet.dart';
import '../../../../core/routes/go_router_provider.dart';
import '../../../../core/routes/route_name.dart';
import '../../../audio_manager/application/controllers/audio_download_controller.dart';
import '../../../audio_manager/domain/entities/audio_download_task.dart';
import '../utils/reciter_download_helper.dart';
import 'sleep_timer_active_badge.dart';

class AudioPlayerBottomBar extends ConsumerWidget {
  final int surahId;
  final bool isFullScreen;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AudioPlayerBottomBar({
    super.key,
    this.surahId = 1,
    this.isFullScreen = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  String _formatReciterName(String? rawName, {bool isTranslation = false}) {
    if (rawName == null || rawName.isEmpty) {
      return isTranslation ? 'مترجم گویا' : 'استاد پرهیزگار';
    }

    var cleaned = rawName.replaceAll(RegExp(r'\s*[\(\[\{].*?[\)\]\}]'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\d+kbps', caseSensitive: false), '').trim();

    if (!cleaned.startsWith('استاد')) {
      cleaned = 'استاد $cleaned';
    }

    return cleaned;
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
    double width = 34,
    double height = 32,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          radius: 17,
          child: SizedBox(
            width: width,
            height: height,
            child: Center(
              child: Icon(icon, size: size, color: color),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Fine-grained selectors: Prevent rebuilding entire bottom bar on every audio position tick!
    final audioStatus = ref.watch(quranAudioControllerProvider.select((s) => s.status));
    final isAutoScrollSuspended = ref.watch(quranAudioControllerProvider.select((s) => s.isAutoScrollSuspended));
    final selectedReciter = ref.watch(quranAudioControllerProvider.select((s) => s.selectedReciter));
    final selectedTranslationReciter = ref.watch(quranAudioControllerProvider.select((s) => s.selectedTranslationReciter));
    final currentTrackType = ref.watch(quranAudioControllerProvider.select((s) => s.currentTrackType));
    final playbackMode = ref.watch(quranAudioControllerProvider.select((s) => s.playbackMode));
    final currentAyahNumber = ref.watch(quranAudioControllerProvider.select((s) => s.currentAyahNumber));
    final totalAyahsInSurah = ref.watch(quranAudioControllerProvider.select((s) => s.totalAyahsInSurah));
    final playbackSpeed = ref.watch(quranAudioControllerProvider.select((s) => s.speed));
    
    // Download tasks for current surah
    final downloadTasks = ref.watch(audioDownloadControllerProvider);
    final quranTask = selectedReciter != null ? downloadTasks['r${selectedReciter.id}_s$surahId'] : null;
    final transTask = selectedTranslationReciter != null ? downloadTasks['r${selectedTranslationReciter.id}_s$surahId'] : null;
    final isQuranDownloading = playbackMode.includesQuran && quranTask?.status == DownloadTaskStatus.downloading;
    final isTransDownloading = playbackMode.includesTranslation && transTask?.status == DownloadTaskStatus.downloading;
    final isCurrentSurahDownloading = isQuranDownloading || isTransDownloading;
    final activeDownloadTask = isQuranDownloading ? quranTask : (isTransDownloading ? transTask : null);
    final downloadPercent = ((activeDownloadTask?.progress ?? 0) * 100).clamp(0, 100).toInt();

    final audioController = ref.read(quranAudioControllerProvider.notifier);

    final isPlaying = audioStatus == AudioStatus.playing;
    final isSessionActive = audioStatus != AudioStatus.stopped && audioStatus != AudioStatus.initial;
    
    // Determine whether the current active (or configured) track is translation
    final isTranslationTrack = isSessionActive
        ? (currentTrackType == CurrentTrackType.translation)
        : (playbackMode == AudioPlaybackMode.onlyTranslation || playbackMode == AudioPlaybackMode.translationThenQuran);

    final activeReciterName = isTranslationTrack
        ? _formatReciterName(selectedTranslationReciter?.name, isTranslation: true)
        : _formatReciterName(selectedReciter?.name, isTranslation: false);
    
    // Determine if we should show track type badge (only in mixed modes)
    final isMixedMode = playbackMode == AudioPlaybackMode.quranThenTranslation || 
                        playbackMode == AudioPlaybackMode.translationThenQuran;
    final trackTypeLabel = isTranslationTrack ? '🔊 ترجمه' : '🔊 تلاوت';

    void onTogglePlay() async {
      if (isCurrentSurahDownloading) {
        AppSnackBar.showInfo(
          context,
          'صوت این سوره در پس‌زمینه در حال دانلود است (${downloadPercent.toPersianDigit()}٪). لطفاً تا پایان دانلود شکیبا باشید.',
        );
        return;
      }

      final audioState = ref.read(quranAudioControllerProvider);
      final isAtEnd = audioState.duration > Duration.zero &&
          audioState.position >= audioState.duration;
      final isCompleted = audioStatus == AudioStatus.completed || isAtEnd;

      if (isPlaying) {
        audioController.pause();
      } else if (audioStatus == AudioStatus.paused && !isAtEnd) {
        audioController.resume();
      } else {
        // Mode-aware download check: verifies ALL required sources
        final isReady = await ReciterDownloadHelper.checkAndPromptForPlayback(
          context: context,
          ref: ref,
          surahId: surahId,
        );
        if (!isReady) return;

        final ayahs = ref.read(quranReaderControllerProvider).ayahs;
        
        final itemPositionsListener = ref.read(activeItemPositionsListenerProvider);
        int? visibleAyahNumber;
        if (itemPositionsListener != null && ayahs.isNotEmpty) {
          final positions = itemPositionsListener.itemPositions.value;
          if (positions.isNotEmpty) {
            final visiblePositions = positions.where((p) => p.itemTrailingEdge > 0.05);
            if (visiblePositions.isNotEmpty) {
              final topPosition = visiblePositions.reduce((min, p) => p.index < min.index ? p : min);
              final index = topPosition.index.clamp(0, ayahs.length - 1);
              visibleAyahNumber = ayahs[index].ayahNumber;
            }
          }
        }

        final currentAyah = audioState.currentAyahNumber;
        final totalAyahs = ayahs.isNotEmpty ? ayahs.length : (audioState.totalAyahsInSurah ?? 1);

        int startAyah;
        if (isCompleted && currentAyah != null) {
          // Track completed or reached end: advance to next ayah
          startAyah = currentAyah < totalAyahs ? currentAyah + 1 : 1;
        } else {
          // Fresh start or stopped: prioritize visible ayah on screen
          startAyah = visibleAyahNumber ??
              currentAyah ??
              audioState.lastAttemptedAyahNumber ??
              (ayahs.isNotEmpty ? ayahs.first.ayahNumber : 1);
        }
        
        audioController.playAyah(
          surahId: surahId,
          ayahNumber: startAyah,
          totalAyahsInSurah: totalAyahs,
        );
      }
    }

    // Original prominent disc dimensions (Radius: 38dp, Diameter: 76dp + 8dp margin = 84dp total)
    const double discRadius = 38.0;
    const double discSize = discRadius * 2 + 8; // 84.0px
    const double playerHeight = 94.0;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Sleep Timer Active Badge ──
          const SleepTimerActiveBadge(),

          // ── 1. Floating Capsule Pill for Re-Sync ("بازگشت به تلاوت • آیه ۲۴") ──
          if (isAutoScrollSuspended && audioStatus != AudioStatus.stopped && currentAyahNumber != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Center(
                child: Material(
                  color: colorScheme.primary,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedAyahActionProvider.notifier).clearSelection();
                      audioController.resumeAutoScrollAndSync();
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedAudioEqualizer(
                            color: Colors.white,
                            height: 13.0,
                            isAnimating: isPlaying,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isTranslationTrack ? "بازگشت به ترجمه" : "بازگشت به تلاوت"} • ${AppConstants.ayahLabel} ${currentAyahNumber.toPersianDigit()}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── 2. Full-Width Bottom Dock & Hero Reciter Disc ──
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;

              return SizedBox(
                width: screenWidth,
                height: playerHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    // ── A. Full-Width Player Dock (Slides down on collapse) ──
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      offset: isCollapsed ? const Offset(0, 1.25) : Offset.zero,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: isCollapsed ? 0.0 : 1.0,
                        child: IgnorePointer(
                          ignoring: isCollapsed,
                          child: Container(
                            width: screenWidth,
                            height: playerHeight,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: context.colors.cardBorder,
                                  width: 1.0,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 16,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [

                                // Content area with 3 functional zones
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 3.0,
                                    ),
                                    child: Row(
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        // Zone 1: Reserved slot for the Hero Reciter Avatar Disc
                                        const SizedBox(width: discSize),

                                        const SizedBox(width: 8),

                                        // Main Controls Area (Unified 2 Rows for perfect horizontal & vertical alignment)
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // ── Row 1: Reciter Title on Right, Settings on Left ──
                                              Row(
                                                textDirection: TextDirection.rtl,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // Reciter & Ayah Title (Clickable)
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        if (isCurrentSurahDownloading) {
                                                          ref.read(goRouterProvider).pushNamed(
                                                            audioDownloadManagerRoute,
                                                            queryParameters: {
                                                              'surahId': surahId.toString(),
                                                              if (isTransDownloading) 'isTranslation': 'true',
                                                            },
                                                          );
                                                        } else {
                                                          ReciterSelectionBottomSheet.show(
                                                            context,
                                                            isTranslationMode: isTranslationTrack,
                                                          );
                                                        }
                                                      },
                                                      behavior: HitTestBehavior.opaque,
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          if (isCurrentSurahDownloading) ...[
                                                            Icon(
                                                              CupertinoIcons.arrow_down_circle_fill,
                                                              size: 13,
                                                              color: colorScheme.onSurfaceVariant,
                                                            ),
                                                            const SizedBox(width: 5),
                                                          ],
                                                          Flexible(
                                                            child: Text(
                                                              isCurrentSurahDownloading
                                                                  ? 'در حال دانلود صوت (${downloadPercent.toPersianDigit()}٪)...'
                                                                  : '$activeReciterName • ${AppConstants.ayahLabel} ${(currentAyahNumber ?? 1).toPersianDigit()}',
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                                    fontWeight: FontWeight.bold,
                                                                    color: colorScheme.onSurface,
                                                                    fontSize: 12.0,
                                                                    fontFamily: AppTypography.fontFamily,
                                                                  ),
                                                            ),
                                                          ),
                                                          if (isMixedMode && isSessionActive && !isCurrentSurahDownloading) ...[
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '($trackTypeLabel)',
                                                              style: TextStyle(
                                                                fontSize: 9.5,
                                                                fontWeight: FontWeight.w600,
                                                                color: colorScheme.onSurfaceVariant,
                                                                fontFamily: AppTypography.fontFamily,
                                                              ),
                                                            ),
                                                          ],
                                                          const SizedBox(width: 3),
                                                          Icon(
                                                            isCurrentSurahDownloading
                                                                ? CupertinoIcons.chevron_back
                                                                : CupertinoIcons.chevron_down,
                                                            size: 11,
                                                            color: colorScheme.onSurfaceVariant,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 6),

                                                  // Sleep Timer Active Button
                                                  const SleepTimerPlayerButton(),

                                                  // Settings Button (Top Left)
                                                  _buildControlButton(
                                                    icon: CupertinoIcons.gear,
                                                    size: 23,
                                                    width: 40,
                                                    height: 32,
                                                    color: colorScheme.onSurfaceVariant,
                                                    tooltip: 'تنظیمات نمایش',
                                                    onPressed: () => QuickSettingsDrawer.show(context),
                                                  ),
                                                ],
                                              ),

                                              // ── Row 2: Transport Controls + Speed Chip (Vertically Aligned!) ──
                                              Row(
                                                textDirection: TextDirection.rtl,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // 4 Transport Controls evenly spaced
                                                  Expanded(
                                                    child: Row(
                                                      textDirection: TextDirection.rtl,
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        // 1. +5s Forward
                                                        _buildControlButton(
                                                          icon: Icons.forward_5_rounded,
                                                          size: 22,
                                                          color: isSessionActive
                                                              ? colorScheme.onSurface
                                                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                                          tooltip: '۵ ثانیه جلو',
                                                          onPressed: isSessionActive ? () => audioController.seekForward() : null,
                                                        ),

                                                        // 2. Next Ayah
                                                        _buildControlButton(
                                                          icon: CupertinoIcons.forward_fill,
                                                          size: 20,
                                                          color: (currentAyahNumber != null &&
                                                                  totalAyahsInSurah != null &&
                                                                  currentAyahNumber < totalAyahsInSurah)
                                                              ? colorScheme.onSurface
                                                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                                                          tooltip: 'آیه بعدی',
                                                          onPressed: (currentAyahNumber != null &&
                                                                  totalAyahsInSurah != null &&
                                                                  currentAyahNumber < totalAyahsInSurah)
                                                              ? () => audioController.playNextAyah()
                                                              : null,
                                                        ),

                                                        // 3. Previous Ayah
                                                        _buildControlButton(
                                                          icon: CupertinoIcons.backward_fill,
                                                          size: 20,
                                                          color: (currentAyahNumber != null && currentAyahNumber > 1)
                                                              ? colorScheme.onSurface
                                                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                                                          tooltip: 'آیه قبلی',
                                                          onPressed: (currentAyahNumber != null && currentAyahNumber > 1)
                                                              ? () => audioController.playPreviousAyah()
                                                              : null,
                                                        ),

                                                        // 4. -5s Rewind
                                                        _buildControlButton(
                                                          icon: Icons.replay_5_rounded,
                                                          size: 22,
                                                          color: isSessionActive
                                                              ? colorScheme.onSurface
                                                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                                          tooltip: '۵ ثانیه عقب',
                                                          onPressed: isSessionActive ? () => audioController.seekBackward() : null,
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  const SizedBox(width: 6),

                                                  // Speed Dropdown Button (Bottom Left - opens speed selection dropdown menu)
                                                  SizedBox(
                                                    width: 40,
                                                    height: 32,
                                                    child: Center(
                                                      child: Theme(
                                                        data: Theme.of(context).copyWith(
                                                          hoverColor: Colors.transparent,
                                                          splashColor: Colors.transparent,
                                                          highlightColor: Colors.transparent,
                                                        ),
                                                        child: PopupMenuButton<double>(
                                                          initialValue: playbackSpeed,
                                                          tooltip: 'تنظیم سرعت پخش',
                                                          color: colorScheme.surfaceContainerHigh,
                                                          elevation: 8,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(14),
                                                            side: BorderSide(
                                                              color: context.colors.cardBorder,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          onSelected: (double speed) {
                                                            audioController.setPlaybackSpeed(speed);
                                                          },
                                                          itemBuilder: (BuildContext context) {
                                                            const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
                                                            return speeds.map((speed) {
                                                              final isSelected = (speed - playbackSpeed).abs() < 0.05;
                                                              final label = '${speed.toString().replaceAll(RegExp(r'\.0$'), '')}x';
                                                              return PopupMenuItem<double>(
                                                                value: speed,
                                                                height: 38,
                                                                child: Row(
                                                                  textDirection: TextDirection.rtl,
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                      label,
                                                                      style: TextStyle(
                                                                        fontFamily: AppTypography.fontFamily,
                                                                        fontSize: 13,
                                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                                        color: colorScheme.onSurface,
                                                                      ),
                                                                    ),
                                                                    if (isSelected)
                                                                      Icon(
                                                                        Icons.check_rounded,
                                                                        size: 16,
                                                                        color: colorScheme.onSurface,
                                                                      ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList();
                                                          },
                                                          child: Container(
                                                            height: 26,
                                                            alignment: Alignment.center,
                                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.transparent,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(
                                                                color: context.colors.cardBorder,
                                                                width: 0.9,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              '${playbackSpeed.toString().replaceAll(RegExp(r'\.0$'), '')}x',
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                fontFamily: AppTypography.fontFamily,
                                                                fontSize: 11.5,
                                                                fontWeight: FontWeight.bold,
                                                                color: colorScheme.onSurface,
                                                                height: 1.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Full-width Bottom Edge Progress Bar (RTL) - 100% width across flat bottom edge
                                const AudioTopEdgeProgressBar(
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),


                    // ── C. Hero Reciter Disc (Original prominent size, stays on top in both states) ──
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      right: isCollapsed ? 12.0 : 10.0,
                      bottom: isCollapsed ? 6.0 : 2.0,
                      child: ReciterAvatarButton(
                        radius: discRadius,
                        isPlayButton: true,
                        isDownloading: isCurrentSurahDownloading,
                        downloadProgress: activeDownloadTask?.progress,
                        onTap: onTogglePlay,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Compact micro 3-bar animated audio equalizer widget
class _AnimatedAudioEqualizer extends StatefulWidget {
  final Color color;
  final double height;
  final bool isAnimating;

  const _AnimatedAudioEqualizer({
    required this.color,
    this.height = 13.0,
    this.isAnimating = true,
  });

  @override
  State<_AnimatedAudioEqualizer> createState() => _AnimatedAudioEqualizerState();
}

class _AnimatedAudioEqualizerState extends State<_AnimatedAudioEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedAudioEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(0.35 + 0.65 * (val * 1.0 % 1.0)),
              const SizedBox(width: 2),
              _buildBar(0.25 + 0.75 * ((val + 0.33) % 1.0)),
              const SizedBox(width: 2),
              _buildBar(0.45 + 0.55 * ((val + 0.66) % 1.0)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double factor) {
    final clampedFactor = factor.clamp(0.2, 1.0);
    return Container(
      width: 2.5,
      height: widget.height * clampedFactor,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
