import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/int_extension.dart';
import '../../../../core/services/quran_navigation/domain/entities/ayah_target.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../page_navigation/application/page_navigation_service.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../surah_list/infrastructure/datasources/static_surahs_data.dart';
import '../../domain/entities/study_plan.dart';
import '../../application/controllers/study_plan_controller.dart';
import 'study_plan_quick_bottom_sheet.dart';

/// Minimal sticky capsule banner shown in QuranReader when an active study plan exists.
class StudyPlanReaderBar extends ConsumerWidget {
  final ValueChanged<AyahTarget>? onJumpToTarget;

  const StudyPlanReaderBar({
    super.key,
    this.onJumpToTarget,
  });

  Future<void> _handlePlayAudio(BuildContext context, WidgetRef ref, StudyPlan activePlan) async {
    HapticFeedback.lightImpact();

    int targetSurahId = 1;
    int targetAyahNumber = 1;

    if (activePlan.unit == StudyPlanUnit.ayah) {
      final targetGlobal = min(6236, (activePlan.todayStartAyahGlobal ?? 1) + (activePlan.todayAyahsRead ?? 0));
      final pos = getSurahAndAyahFromGlobalIndex(targetGlobal);
      targetSurahId = pos.surahId;
      targetAyahNumber = pos.ayahNumber;
    } else {
      final hasUnfinishedAyahOnCurrentPage = activePlan.lastReadSurahId != null &&
          activePlan.lastReadAyahNumber != null &&
          !activePlan.isTodayCompleted &&
          activePlan.currentPage >= activePlan.nextPageToRead;

      if (hasUnfinishedAyahOnCurrentPage) {
        targetSurahId = activePlan.lastReadSurahId!;
        targetAyahNumber = activePlan.lastReadAyahNumber!;
      } else {
        final targetPage = activePlan.isTodayCompleted ? activePlan.todayStartPage : activePlan.nextPageToRead;
        final pageNav = ref.read(pageNavigationServiceProvider);
        final targetResult = await pageNav.getTargetByPageNumber(targetPage);

        targetResult.when(
          (target) {
            targetSurahId = target.surahId;
            targetAyahNumber = target.ayahNumber;
          },
          (failure) {},
        );
      }
    }

    onJumpToTarget?.call(AyahTarget(
      surahId: targetSurahId,
      ayahNumber: targetAyahNumber,
    ));

    final audioController = ref.read(quranAudioControllerProvider.notifier);
    final audioState = ref.read(quranAudioControllerProvider);

    if (audioState.status == AudioStatus.playing) {
      await audioController.pause();
      return;
    } else if (audioState.status == AudioStatus.paused &&
        audioState.currentSurahId == targetSurahId) {
      await audioController.resume();
      return;
    }

    final totalAyahs = kStaticQuranSurahs[targetSurahId - 1].numberOfAyahs;
    await audioController.playAyah(
      surahId: targetSurahId,
      ayahNumber: targetAyahNumber,
      totalAyahsInSurah: totalAyahs,
    );
  }

  Future<void> _handleJump(BuildContext context, WidgetRef ref, StudyPlan activePlan) async {
    HapticFeedback.lightImpact();

    if (activePlan.unit == StudyPlanUnit.ayah) {
      final targetGlobal = min(6236, (activePlan.todayStartAyahGlobal ?? 1) + (activePlan.todayAyahsRead ?? 0));
      final pos = getSurahAndAyahFromGlobalIndex(targetGlobal);
      onJumpToTarget?.call(AyahTarget(
        surahId: pos.surahId,
        ayahNumber: pos.ayahNumber,
      ));
      return;
    }

    // Only resume at saved ayah if the user was in the middle of reading nextPageToRead.
    // If currentPage < nextPageToRead, they already completed that page and should start nextPageToRead!
    final hasUnfinishedAyahOnCurrentPage = activePlan.lastReadSurahId != null &&
        activePlan.lastReadAyahNumber != null &&
        !activePlan.isTodayCompleted &&
        activePlan.currentPage >= activePlan.nextPageToRead;

    if (hasUnfinishedAyahOnCurrentPage) {
      onJumpToTarget?.call(AyahTarget(
        surahId: activePlan.lastReadSurahId!,
        ayahNumber: activePlan.lastReadAyahNumber!,
      ));
      return;
    }

    final targetPage = activePlan.isTodayCompleted ? activePlan.todayStartPage : activePlan.nextPageToRead;
    final pageNav = ref.read(pageNavigationServiceProvider);
    final targetResult = await pageNav.getTargetByPageNumber(targetPage);

    targetResult.when(
      (target) => onJumpToTarget?.call(AyahTarget(
        surahId: target.surahId,
        ayahNumber: target.ayahNumber,
      )),
      (failure) {},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSessionActive = ref.watch(isStudyPlanSessionActiveProvider);
    if (!isSessionActive) {
      return const SizedBox.shrink();
    }

    final activePlan = ref.watch(studyPlanControllerProvider.select((s) => s.activePlan));

    if (activePlan == null || activePlan.status != StudyPlanStatus.active) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final isCompleted = activePlan.isTodayCompleted;
    final progressPercent = (activePlan.todayProgress * 100).toInt();

    final audioStatus = ref.watch(quranAudioControllerProvider.select((s) => s.status));
    final currentPlayingSurah = ref.watch(quranAudioControllerProvider.select((s) => s.currentSurahId));
    final isAudioPlaying = audioStatus == AudioStatus.playing && currentPlayingSurah != null;

    final bgColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.92)
        : const Color(0xFFF1F5F9);

    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final textColor = isDark ? Colors.white70 : const Color(0xFF334155);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.selectionClick();
          final target = await StudyPlanQuickBottomSheet.show(context);
          if (target != null) {
            onJumpToTarget?.call(target);
          }
        },
        child: Container(
          width: double.infinity,
          height: 32.0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: borderColor, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.book_fill,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCompleted
                      ? 'هدف امروز برنامه مطالعه تکمیل شد • 🔥 ${activePlan.streakDays.toPersianDigit()} روز پیوسته'
                      : activePlan.unit == StudyPlanUnit.ayah
                          ? 'برنامه مطالعه: ${(activePlan.todayAyahsRead ?? 0).toPersianDigit()} از ${activePlan.unitAmount.toPersianDigit()} آیه امروز'
                          : 'برنامه مطالعه: صفحه ${activePlan.todayStartPage.toPersianDigit()} تا ${activePlan.todayEndPage.toPersianDigit()} (${activePlan.todayCompletedPagesCount.toPersianDigit()} از ${activePlan.todayTargetPagesCount.toPersianDigit()})',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!isCompleted) ...[
                Text(
                  '${progressPercent.toPersianDigit()}٪',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // Audio Play Button (colorless, active/inactive based on isCompleted)
              InkWell(
                onTap: isCompleted
                    ? null
                    : () => _handlePlayAudio(context, ref, activePlan),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted
                          ? (isDark ? Colors.white12 : Colors.black12)
                          : colorScheme.primary.withValues(alpha: 0.45),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAudioPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_arrow_solid,
                        size: 10,
                        color: isCompleted
                            ? (isDark ? Colors.white30 : Colors.black26)
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isAudioPlaying ? 'توقف' : 'پخش صوت',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? (isDark ? Colors.white30 : Colors.black26)
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isCompleted) ...[
                const SizedBox(width: 5),
                InkWell(
                  onTap: () => _handleJump(context, ref, activePlan),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.location_fill, size: 9, color: colorScheme.primary),
                        const SizedBox(width: 2),
                        Text(
                          'پرش',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(studyPlanControllerProvider.notifier).markTodayAsCompleted();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        width: 0.7,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.check_mark, size: 10, color: colorScheme.primary),
                        const SizedBox(width: 2),
                        Text(
                          'تکمیل امروز',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                Text(
                  'تغییر برنامه',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(CupertinoIcons.chevron_left, size: 10, color: colorScheme.primary),
              ],
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(isStudyPlanSessionActiveProvider.notifier).set(false);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
