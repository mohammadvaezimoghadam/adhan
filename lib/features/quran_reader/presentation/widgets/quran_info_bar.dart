import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../common/extensions/int_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/quran_navigation/domain/entities/ayah_target.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../../surah_list/domain/entities/surah_entity.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../domain/entities/ayah_entity.dart';
import 'quran_quick_jump_bottom_sheet.dart';
import '../../../study_plan/application/controllers/study_plan_controller.dart';
import '../../../study_plan/domain/entities/study_plan.dart';

/// A sticky info bar displayed below the AppBar that shows the current
/// Total Ayahs, Ayah, Juz, Hizb, and Page with interactive chips for Quick Jump.
class QuranInfoBar extends ConsumerWidget {
  final ValueChanged<AyahTarget>? onTargetSelected;

  const QuranInfoBar({
    super.key,
    this.onTargetSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahs = ref.watch(quranReaderControllerProvider.select((s) => s.ayahs));
    if (ayahs.isEmpty) return const SizedBox.shrink();

    final surahs = ref.watch(surahListControllerProvider.select((s) => s.surahs));

    // 1. Audio is the Single Source of Truth if currently playing, paused, or loading for this surah!
    final audioState = ref.watch(quranAudioControllerProvider);
    final isAudioActiveForThisSurah = (audioState.status == AudioStatus.playing ||
            audioState.status == AudioStatus.paused ||
            audioState.status == AudioStatus.loading) &&
        audioState.currentSurahId != null &&
        ayahs.isNotEmpty &&
        audioState.currentSurahId == ayahs.first.surahId &&
        audioState.currentAyahNumber != null;

    if (isAudioActiveForThisSurah) {
      final playingAyah = ayahs.firstWhere(
        (a) => a.ayahNumber == audioState.currentAyahNumber,
        orElse: () => ayahs.first,
      );
      return _buildContent(context, ref, playingAyah, surahs);
    }

    final itemPositionsListener = ref.watch(activeItemPositionsListenerProvider);

    if (itemPositionsListener == null) {
      return _buildContent(context, ref, ayahs.first, surahs);
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeTop = MediaQuery.paddingOf(context).top;
    final isSessionActive = ref.watch(isStudyPlanSessionActiveProvider);
    final activePlan = ref.watch(studyPlanControllerProvider.select((s) => s.activePlan));
    final hasStudyBar = isSessionActive && activePlan != null && activePlan.status == StudyPlanStatus.active;
    
    // Header bottom: safeTop + AppBar (60) + InfoBar (40) + StudyBar (32 if active)
    final headerBottom = safeTop + 60.0 + 40.0 + (hasStudyBar ? 32.0 : 0.0);
    final topCutoff = screenHeight > 0 ? (headerBottom / screenHeight) : 0.18;
    final readingBaseline = topCutoff + (18.0 / (screenHeight > 0 ? screenHeight : 800.0));

    return ValueListenableBuilder<Iterable<ItemPosition>>(
      valueListenable: itemPositionsListener.itemPositions,
      builder: (context, positions, child) {
        int currentIndex = 0;
        if (positions.isNotEmpty) {
          final lastPos = positions.where((p) => p.index == ayahs.length - 1).firstOrNull;

          ItemPosition? targetPosition;
          for (final p in positions) {
            if (p.itemLeadingEdge <= readingBaseline && p.itemTrailingEdge > readingBaseline) {
              targetPosition = p;
              break;
            }
          }

          if (targetPosition != null) {
            currentIndex = targetPosition.index;
          } else if (lastPos != null && lastPos.itemTrailingEdge <= readingBaseline) {
            // User has scrolled past the reading baseline all the way to the end of the surah!
            currentIndex = ayahs.length - 1;
          } else {
            final visible = positions.where((p) => p.itemTrailingEdge > topCutoff).toList();
            if (visible.isNotEmpty) {
              targetPosition = visible.reduce((min, cur) => cur.index < min.index ? cur : min);
            } else {
              targetPosition = positions.reduce((min, cur) => cur.index < min.index ? cur : min);
            }
            currentIndex = targetPosition.index;
          }
        }

        if (currentIndex < 0 || currentIndex >= ayahs.length) {
          currentIndex = 0;
        }

        return _buildContent(context, ref, ayahs[currentIndex], surahs);
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AyahEntity currentAyah, List<SurahEntity> surahs) {
    final surah = surahs.where((s) => s.number == currentAyah.surahId).firstOrNull;
    final totalAyahsStr = surah != null ? surah.numberOfAyahs.toPersianDigit() : '؟';

    final ayahStr = currentAyah.ayahNumber.toPersianDigit();
    final juzStr = currentAyah.juz?.toPersianDigit() ?? '؟';
    final hizbStr = currentAyah.hizb?.toPersianDigit() ?? '؟';
    final pageStr = currentAyah.page?.toPersianDigit() ?? '؟';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF16191C).withValues(alpha: 0.94)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E5EA);

    return Container(
      width: double.infinity,
      height: 38.0,
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStaticChip(context, '$totalAyahsStr آیه'),
          _buildDotDivider(context, isDark),
          _buildChip(context, 'آیه $ayahStr', QuickJumpTab.surah),
          _buildDotDivider(context, isDark),
          _buildChip(context, 'جزء $juzStr', QuickJumpTab.juz),
          _buildDotDivider(context, isDark),
          _buildChip(context, 'حزب $hizbStr', QuickJumpTab.hizb),
          _buildDotDivider(context, isDark),
          _buildChip(context, 'صفحه $pageStr', QuickJumpTab.page),
        ],
      ),
    );
  }

  Widget _buildStaticChip(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text, QuickJumpTab tab) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final target = await QuranQuickJumpBottomSheet.show(
            context,
            initialTab: tab,
          );
          if (target != null && context.mounted) {
            onTargetSelected?.call(target);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                CupertinoIcons.chevron_down,
                size: 10.5,
                color: theme.colorScheme.primary.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotDivider(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '•',
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 11,
        ),
      ),
    );
  }
}

