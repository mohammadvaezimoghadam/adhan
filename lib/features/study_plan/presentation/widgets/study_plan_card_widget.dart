import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../page_navigation/application/page_navigation_service.dart';
import '../../application/controllers/study_plan_controller.dart';
import '../../domain/entities/study_plan.dart';
import 'create_study_plan_bottom_sheet.dart';

/// Reusable and unified study plan card item used across Home and Study Plans screen.
class StudyPlanCardWidget extends ConsumerWidget {
  final StudyPlan plan;
  final double? cardWidth;
  final EdgeInsetsGeometry? margin;

  const StudyPlanCardWidget({
    super.key,
    required this.plan,
    this.cardWidth,
    this.margin,
  });

  Future<void> _continueReading(
    BuildContext context,
    WidgetRef ref,
    StudyPlan plan, {
    bool autoPlayAudio = false,
  }) async {
    if (plan.isTodayCompleted) return;
    HapticFeedback.lightImpact();

    // Ensure this plan is marked as active in the controller
    await ref.read(studyPlanControllerProvider.notifier).setActivePlan(plan.id);
    if (!context.mounted) return;
    ref.read(isStudyPlanSessionActiveProvider.notifier).set(true);

    if (plan.unit == StudyPlanUnit.ayah) {
      final targetGlobal = min(
        6236,
        (plan.todayStartAyahGlobal ?? 1) + (plan.todayAyahsRead ?? 0),
      );
      final pos = getSurahAndAyahFromGlobalIndex(targetGlobal);
      if (!context.mounted) return;
      context.pushNamed(
        quranReaderRoute,
        pathParameters: {'id': pos.surahId.toString()},
        queryParameters: {
          'ayah': pos.ayahNumber.toString(),
          if (autoPlayAudio) 'autoPlay': 'true',
          'isStudyPlan': 'true',
        },
      );
      return;
    }

    // Only resume at saved ayah if the user was in the middle of reading nextPageToRead.
    final hasUnfinishedAyahOnCurrentPage = plan.lastReadSurahId != null &&
        plan.lastReadAyahNumber != null &&
        !plan.isTodayCompleted &&
        plan.currentPage >= plan.nextPageToRead;

    if (hasUnfinishedAyahOnCurrentPage) {
      if (!context.mounted) return;
      context.pushNamed(
        quranReaderRoute,
        pathParameters: {'id': plan.lastReadSurahId.toString()},
        queryParameters: {
          if (plan.lastReadSurahName != null) 'name': plan.lastReadSurahName!,
          'ayah': plan.lastReadAyahNumber.toString(),
          if (autoPlayAudio) 'autoPlay': 'true',
          'isStudyPlan': 'true',
        },
      );
      return;
    }

    final targetPage =
        plan.isTodayCompleted ? plan.todayStartPage : plan.nextPageToRead;
    final pageNav = ref.read(pageNavigationServiceProvider);
    final targetResult = await pageNav.getTargetByPageNumber(targetPage);

    if (!context.mounted) return;

    targetResult.when(
      (target) {
        context.pushNamed(
          quranReaderRoute,
          pathParameters: {'id': target.surahId.toString()},
          queryParameters: {
            'name': target.surahName,
            'ayah': target.ayahNumber.toString(),
            if (autoPlayAudio) 'autoPlay': 'true',
            'isStudyPlan': 'true',
          },
        );
      },
      (failure) {
        context.pushNamed(
          quranReaderRoute,
          pathParameters: {'id': '1'},
          queryParameters: {
            'name': 'الفاتحة',
            if (autoPlayAudio) 'autoPlay': 'true',
            'isStudyPlan': 'true',
          },
        );
      },
    );
  }

  void _confirmDeletePlan(BuildContext context, WidgetRef ref, StudyPlan plan) {
    final isDark = context.isDark;
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          'حذف برنامه',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(dialogCtx).colorScheme.onSurface,
          ),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'آیا از حذف این برنامه مطالعه اطمینان دارید؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref
                  .read(studyPlanControllerProvider.notifier)
                  .deletePlan(plan.id);
              if (context.mounted) {
                AppSnackBar.showSuccess(context, 'برنامه حذف شد.');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? Colors.white12 : Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      width: cardWidth,
      margin: margin,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: plan.isTodayCompleted
              ? null
              : () => _continueReading(context, ref, plan),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: cardWidth != null
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
              children: [
                // ── ۱. ردیف بالا: نشانگر پیشرفت دایره‌ای + عنوان اصلی (مثلاً روزی ۱ صفحه یا روزی ۳ صفحه (۱۰ روز)) + وضعیت در استایل کپشن زیر آن + منوی سه نقطه ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular progress
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        end: plan.isOngoing
                            ? plan.todayProgress
                            : plan.overallProgress,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, child) {
                        final int animatedPercent =
                            (animatedProgress * 100).toInt();
                        return SizedBox(
                          width: 38,
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 38,
                                height: 38,
                                child: CircularProgressIndicator(
                                  value: animatedProgress.clamp(0.0, 1.0),
                                  strokeWidth: 3.2,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : colors.cardBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                              Text(
                                '${animatedPercent.toPersianDigit()}٪',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    12.hSpace,
                    // Column: عنوان بالا و وضعیت در استایل کپشن
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            plan.displayTitle,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          3.vSpace,
                          Text(
                            plan.summarizedLocation,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Three dots menu (no icons, black text)
                    PopupMenuButton<String>(
                      icon: Icon(
                        CupertinoIcons.ellipsis_vertical,
                        size: 17,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          await CreateStudyPlanBottomSheet.show(
                            context,
                            initialPlan: plan,
                          );
                        } else if (val == 'delete') {
                          _confirmDeletePlan(context, ref, plan);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'ویرایش برنامه',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'حذف برنامه',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (cardWidth == null) 10.vSpace,
                // ── ۲. دکمه پایین: ادامه مطالعه یا وضعیت تکمیل ──
                InkWell(
                  onTap: plan.isTodayCompleted
                      ? null
                      : () => _continueReading(context, ref, plan),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7.5,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFF3F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      plan.isTodayCompleted ? 'تکمیل شده' : 'ادامه مطالعه',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: plan.isTodayCompleted
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
