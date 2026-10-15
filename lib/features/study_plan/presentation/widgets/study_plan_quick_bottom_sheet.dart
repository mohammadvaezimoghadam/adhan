import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/services/quran_navigation/domain/entities/ayah_target.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../page_navigation/application/page_navigation_service.dart';
import '../../../surah_list/infrastructure/datasources/static_surahs_data.dart';
import '../../application/controllers/study_plan_controller.dart';
import '../../domain/entities/study_plan.dart';
import 'create_study_plan_bottom_sheet.dart';

/// Quick Bottom Sheet to inspect and switch active study plan from Quran Reader or screens.
class StudyPlanQuickBottomSheet extends ConsumerWidget {
  const StudyPlanQuickBottomSheet({super.key});

  static Future<AyahTarget?> show(BuildContext context) {
    return showModalBottomSheet<AyahTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StudyPlanQuickBottomSheet(),
    );
  }

  Future<void> _jumpToPlanPage(
    BuildContext context,
    WidgetRef ref,
    StudyPlan plan,
  ) async {
    if (plan.isTodayCompleted) return;
    HapticFeedback.lightImpact();

    // 1. Resolve reading target
    AyahTarget? target;

    final hasUnfinishedAyahOnCurrentPage = plan.lastReadSurahId != null &&
        plan.lastReadAyahNumber != null &&
        !plan.isTodayCompleted &&
        plan.currentPage >= plan.nextPageToRead;

    if (plan.unit == StudyPlanUnit.ayah) {
      final targetGlobal = min(6236, (plan.todayStartAyahGlobal ?? 1) + (plan.todayAyahsRead ?? 0));
      final pos = getSurahAndAyahFromGlobalIndex(targetGlobal);
      target = AyahTarget(surahId: pos.surahId, ayahNumber: pos.ayahNumber);
    } else if (hasUnfinishedAyahOnCurrentPage) {
      target = AyahTarget(
        surahId: plan.lastReadSurahId!,
        ayahNumber: plan.lastReadAyahNumber!,
      );
    } else {
      final targetPage = plan.isTodayCompleted ? plan.todayStartPage : plan.nextPageToRead;
      final pageNav = ref.read(pageNavigationServiceProvider);
      final targetResult = await pageNav.getTargetByPageNumber(targetPage);

      targetResult.when(
        (navTarget) {
          target = AyahTarget(
            surahId: navTarget.surahId,
            ayahNumber: navTarget.ayahNumber,
          );
        },
        (failure) {
          // Fallback: locate surah by startPage in static data
          for (int i = kStaticQuranSurahs.length - 1; i >= 0; i--) {
            if (kStaticQuranSurahs[i].startPage <= targetPage) {
              target = AyahTarget(
                surahId: kStaticQuranSurahs[i].number,
                ayahNumber: 1,
              );
              break;
            }
          }
        },
      );
    }

    // 2. Set plan active and session active BEFORE popping to ensure ref remains valid
    await ref.read(studyPlanControllerProvider.notifier).setActivePlan(plan.id);
    ref.read(isStudyPlanSessionActiveProvider.notifier).set(true);

    if (target != null) {
      ref.read(studyPlanJumpTargetProvider.notifier).setTarget(target);
    }

    // 3. Close the bottom sheet safely
    if (context.mounted) {
      Navigator.of(context).pop(target);
    }
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
            child: const Text(
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

    // Ensure all plan dates are refreshed for today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlanControllerProvider.notifier).checkAndRefreshAllPlans();
    });

    final planState = ref.watch(studyPlanControllerProvider);
    final activePlan = planState.activePlan;
    final plans = planState.plans;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: colors.dialogSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.cardBorder, width: 0.8),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          12,
          18,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppModalHeader(
              title: 'برنامه مطالعه قرآن',
              showDragHandle: true,
              leadingAction: IconButton(
                tooltip: 'ایجاد برنامه جدید',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  CupertinoIcons.plus,
                  size: 22,
                  color: colorScheme.primary,
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final newPlan = await CreateStudyPlanBottomSheet.show(context);
                  if (newPlan != null && context.mounted) {
                    ref.read(studyPlanControllerProvider.notifier).loadPlans();
                  }
                },
              ),
              onClose: () => Navigator.of(context).pop(),
              bottomSpacing: 10.0,
            ),

            if (plans.isEmpty)
              _buildEmptyState(context, colorScheme, isDark)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isActive = plan.id == activePlan?.id;
                    return _buildSimplePlanCard(
                      context,
                      ref,
                      plan,
                      isActive,
                      colorScheme,
                      colors,
                      isDark,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Compact & Sleek Plan Card - Styled exactly as StudyPlansScreen
  Widget _buildSimplePlanCard(
    BuildContext context,
    WidgetRef ref,
    StudyPlan plan,
    bool isActive,
    ColorScheme colorScheme,
    dynamic colors,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.cardBorder,
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
          borderRadius: BorderRadius.circular(14),
          onTap: plan.isTodayCompleted ? null : () => _jumpToPlanPage(context, ref, plan),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          // Header: Title & Menu (clean title without parentheses, no active badge)
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.displayTitle,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (plan.status == StudyPlanStatus.completed) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'به اتمام رسیده',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                4.hSpace,
              ],
              PopupMenuButton<String>(
                icon: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  size: 17,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) async {
                  if (val == 'start') {
                    _jumpToPlanPage(context, ref, plan);
                  } else if (val == 'edit') {
                    await CreateStudyPlanBottomSheet.show(
                      context,
                      initialPlan: plan,
                    );
                  } else if (val == 'delete') {
                    _confirmDeletePlan(context, ref, plan);
                  }
                },
                itemBuilder: (ctx) => [
                  if (!plan.isTodayCompleted)
                    PopupMenuItem(
                      value: 'start',
                      child: Text(
                        'شروع مطالعه',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
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

          8.vSpace,

          // Row with Circular Progress Indicator and Details
          Row(
            children: [
              // Circular progress
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  end: plan.isOngoing ? plan.todayProgress : plan.overallProgress,
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  final int animatedPercent =
                      (animatedProgress * 100).toInt();
                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: animatedProgress,
                            strokeWidth: 3.5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : colors.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${animatedPercent.toPersianDigit()}٪',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              12.hSpace,
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.summarizedLocation,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    3.vSpace,
                    Text(
                      plan.quotaDescription,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          10.vSpace,

          // Action button (status: تکمیل شده / تکمیل نشده, no extra colors, no icon)
          InkWell(
            onTap: plan.isTodayCompleted ? null : () => _jumpToPlanPage(context, ref, plan),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9.5, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFF3F1EC),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                plan.isTodayCompleted ? 'تکمیل شده' : 'ادامه مطالعه',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
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

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.book, size: 48, color: colorScheme.primary.withValues(alpha: 0.5)),
          12.vSpace,
          Text(
            'هنوز برنامه مطالعه‌ای ایجاد نکرده‌اید',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          6.vSpace,
          Text(
            'با ایجاد یک برنامه، روزانه طبق هدف مشخص قرآن بخوانید.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          16.vSpace,
          ElevatedButton.icon(
            onPressed: () async {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              CreateStudyPlanBottomSheet.show(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(CupertinoIcons.add, size: 16),
            label: const Text(
              'ایجاد اولین برنامه مطالعه',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper state provider to pass jump target back to QuranReader
final studyPlanJumpTargetProvider =
    NotifierProvider<StudyPlanJumpTargetNotifier, AyahTarget?>(
  StudyPlanJumpTargetNotifier.new,
);

class StudyPlanJumpTargetNotifier extends Notifier<AyahTarget?> {
  @override
  AyahTarget? build() => null;

  void setTarget(AyahTarget? target) => state = target;
  void clear() => state = null;
}
