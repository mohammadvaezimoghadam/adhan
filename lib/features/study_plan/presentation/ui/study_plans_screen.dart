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
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../page_navigation/application/page_navigation_service.dart';
import '../../domain/entities/study_plan.dart';
import '../../application/controllers/study_plan_controller.dart';
import '../widgets/create_study_plan_bottom_sheet.dart';

/// Clean & Minimal Quran Study Plans Screen.
class StudyPlansScreen extends ConsumerWidget {
  const StudyPlansScreen({super.key});

  Future<void> _continueReading(
      BuildContext context, WidgetRef ref, StudyPlan plan) async {
    HapticFeedback.lightImpact();
    final targetPage = plan.todayCurrentPage;
    final pageNav = ref.read(pageNavigationServiceProvider);
    final targetResult = await pageNav.getTargetByPageNumber(targetPage);

    targetResult.when(
      (target) {
        context.pushNamed(
          quranReaderRoute,
          pathParameters: {'id': target.surahId.toString()},
          queryParameters: {
            'name': target.surahName,
            'ayah': target.ayahNumber.toString(),
          },
        );
      },
      (failure) {
        context.pushNamed(
          quranReaderRoute,
          pathParameters: {'id': '1'},
          queryParameters: {'name': 'الفاتحة'},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final planState = ref.watch(studyPlanControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colors.cardBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              CupertinoIcons.back,
              color: colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: Text(
            'برنامه‌های مطالعه قرآن',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: planState.isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : planState.plans.isEmpty
                ? _buildEmptyState(context, colorScheme, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                      vertical: 16,
                    ),
                    itemCount: planState.plans.length,
                    itemBuilder: (context, index) {
                      final plan = planState.plans[index];
                      final isActive = planState.activePlan?.id == plan.id;
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
        floatingActionButton: planState.plans.isNotEmpty
            ? FloatingActionButton.extended(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(CupertinoIcons.add, size: 20),
                label: Text(
                  'برنامه جدید',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => CreateStudyPlanBottomSheet.show(context),
              )
            : null,
      ),
    );
  }

  /// Simple & Minimal Plan Card
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

  /// Helper to render text where any content inside parentheses (..) gets caption typography
  Widget _buildTextWithCaptionParentheses({
    required String text,
    required TextStyle baseStyle,
    required TextStyle captionStyle,
    TextAlign textAlign = TextAlign.start,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    final regex = RegExp(r'\(([^)]+)\)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final spans = <InlineSpan>[];
    int current = 0;

    for (final match in matches) {
      if (match.start > current) {
        spans.add(TextSpan(
          text: text.substring(current, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: captionStyle,
      ));
      current = match.end;
    }

    if (current < text.length) {
      spans.add(TextSpan(
        text: text.substring(current),
        style: baseStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  /// Compact & Sleek Plan Card (Monochrome / Neutral)
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
      margin: const EdgeInsets.only(bottom: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title, Neutral Badge & Menu
          Row(
            children: [
              Expanded(
                child: _buildTextWithCaptionParentheses(
                  text: plan.title,
                  baseStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  captionStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.normal,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
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
                  plan.status == StudyPlanStatus.completed
                      ? 'تموم شده'
                      : (plan.status == StudyPlanStatus.active ? 'فعال' : 'غیرفعال'),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: plan.status == StudyPlanStatus.active
                        ? colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              4.hSpace,
              PopupMenuButton<String>(
                icon: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  size: 17,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) async {
                  if (val == 'toggle_status') {
                    await ref
                        .read(studyPlanControllerProvider.notifier)
                        .togglePlanStatus(plan.id);
                  } else if (val == 'activate') {
                    await ref
                        .read(studyPlanControllerProvider.notifier)
                        .setActivePlan(plan.id);
                  } else if (val == 'delete') {
                    _confirmDeletePlan(context, ref, plan);
                  }
                },
                itemBuilder: (ctx) => [
                  if (plan.status != StudyPlanStatus.completed)
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(
                        plan.status == StudyPlanStatus.active
                            ? 'غیرفعال کردن'
                            : 'فعال کردن',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  if (plan.status == StudyPlanStatus.active && !isActive)
                    PopupMenuItem(
                      value: 'activate',
                      child: Text(
                        'نمایش در صفحه اصلی',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'حذف برنامه',
                      style: TextStyle(color: colorScheme.onSurface),
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
                      '${plan.unitDescription} • ${plan.durationDescription}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    2.vSpace,
                    _buildTextWithCaptionParentheses(
                      text: plan.isOngoing
                          ? (plan.isTodayCompleted
                              ? 'مطالعه امروز تکمیل شد (${plan.completedPagesCount.toPersianDigit()} صفحه تا کنون)'
                              : 'امروز: صفحه ${plan.todayStartPage.toPersianDigit()} تا ${plan.todayEndPage.toPersianDigit()}')
                          : (plan.isTodayCompleted
                              ? 'امروز تکمیل شد • ${plan.completedPagesCount.toPersianDigit()} از ${plan.totalPages.toPersianDigit()} صفحه'
                              : 'امروز: صفحه ${plan.todayStartPage.toPersianDigit()} تا ${plan.todayEndPage.toPersianDigit()} • ${plan.completedPagesCount.toPersianDigit()} از ${plan.totalPages.toPersianDigit()} صفحه'),
                      baseStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      captionStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          10.vSpace,

          // Action button (Monochrome & low profile)
          InkWell(
            onTap: () => _continueReading(context, ref, plan),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFF3F1EC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.play_fill,
                    size: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  6.hSpace,
                  _buildTextWithCaptionParentheses(
                    text: plan.isTodayCompleted
                        ? 'مطالعه امروز تکمیل شد (ادامه مطالعه)'
                        : 'مطالعه امروز (صفحه ${plan.todayStartPage.toPersianDigit()} تا ${plan.todayEndPage.toPersianDigit()})',
                    baseStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    captionStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean & Simple Empty State
  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'هنوز برنامه مطالعه‌ای ندارید',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            8.vSpace,
            Text(
              'می‌توانید برای مطالعه روزانه قرآن یک برنامه تنظیم کنید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
            20.vSpace,
            ElevatedButton(
              onPressed: () => CreateStudyPlanBottomSheet.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'ایجاد برنامه مطالعه',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
