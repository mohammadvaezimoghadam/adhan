import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../page_navigation/application/page_navigation_service.dart';
import '../../application/controllers/study_plan_controller.dart';
import '../../domain/entities/study_plan.dart';

/// Minimal Home Screen Card for Quran Study Plan.
class StudyPlanHomeCard extends ConsumerWidget {
  const StudyPlanHomeCard({super.key});

  Future<void> _continueReading(
    BuildContext context,
    WidgetRef ref,
    StudyPlan plan,
  ) async {
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
    final activePlan = planState.activePlan;

    final Widget cardWidget = activePlan == null
        ? _buildNoPlanCard(context, colors, colorScheme, isDark)
        : _buildActivePlanCard(
            context,
            ref,
            activePlan,
            colors,
            colorScheme,
            isDark,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SizedBox(
            height: 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'برنامه مطالعه',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF5A554E),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.pushNamed(studyPlansRoute);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'مشاهده همه',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_left,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        4.vSpace,
        cardWidget,
      ],
    );
  }

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

  Widget _buildActivePlanCard(
    BuildContext context,
    WidgetRef ref,
    StudyPlan plan,
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final primaryColor = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(studyPlansRoute);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: plan.isOngoing ? plan.todayProgress : plan.overallProgress),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  final int animatedPercent =
                      (animatedProgress * 100).toInt();
                  return SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: animatedProgress,
                            strokeWidth: 4.5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : colors.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${animatedPercent.toPersianDigit()}٪',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              14.hSpace,

              // Middle details: Plan title & today's range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextWithCaptionParentheses(
                      text: plan.title,
                      baseStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      captionStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.vSpace,
                    Text(
                      plan.isOngoing
                          ? (plan.isTodayCompleted
                              ? 'مطالعه امروز تکمیل شد'
                              : 'امروز: صفحه ${plan.todayStartPage.toPersianDigit()} تا ${plan.todayEndPage.toPersianDigit()}')
                          : (plan.isTodayCompleted
                              ? 'امروز تکمیل شد • ${plan.completedPagesCount.toPersianDigit()} از ${plan.totalPages.toPersianDigit()} صفحه'
                              : 'امروز: صفحه ${plan.todayStartPage.toPersianDigit()} تا ${plan.todayEndPage.toPersianDigit()} • ${plan.completedPagesCount.toPersianDigit()} از ${plan.totalPages.toPersianDigit()} صفحه'),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Exact action button from ContinueReadingCard
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _continueReading(context, ref, plan),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ادامه',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.chevron_back,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPlanCard(
    BuildContext context,
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final primaryColor = colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.pushNamed(studyPlansRoute);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.book,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              14.hSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'برنامه مطالعه قرآن',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.vSpace,
                    Text(
                      'تنظیم هدف روزانه و ختم',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'شروع',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_back,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
