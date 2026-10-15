import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/study_plan_controller.dart';
import '../../domain/entities/study_plan.dart';
import 'create_study_plan_bottom_sheet.dart';
import 'study_plan_card_widget.dart';

/// Horizontal study plans carousel on Home Screen with sleek, icon-free empty state.
class StudyPlanHomeCard extends ConsumerWidget {
  const StudyPlanHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final planState = ref.watch(studyPlanControllerProvider);
    final allPlans = List<StudyPlan>.from(planState.plans);

    // Ensure activePlan is placed first if available
    if (planState.activePlan != null) {
      allPlans.removeWhere((p) => p.id == planState.activePlan!.id);
      allPlans.insert(0, planState.activePlan!);
    }

    // Limit to the first 3 plans as requested
    final displayPlans = allPlans.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
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
                if (displayPlans.isNotEmpty)
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
        8.vSpace,

        // Content: Empty State vs Single Card vs Horizontal List (up to 3 plans)
        if (displayPlans.isEmpty)
          _buildNoPlanCard(context, ref, colors, colorScheme, isDark)
        else if (displayPlans.length == 1)
          StudyPlanCardWidget(plan: displayPlans.first)
        else
          _buildHorizontalPlansList(
            context,
            ref,
            displayPlans,
            colors,
            colorScheme,
            isDark,
          ),
      ],
    );
  }

  /// Horizontal scrollable list showing up to 3 plans
  Widget _buildHorizontalPlansList(
    BuildContext context,
    WidgetRef ref,
    List<StudyPlan> plans,
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final cardWidth =
        (MediaQuery.of(context).size.width * 0.76).clamp(260.0, 310.0);

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return StudyPlanCardWidget(
            plan: plans[index],
            cardWidth: cardWidth,
          );
        },
      ),
    );
  }

  /// Minimal empty state with dotted border and single 'افزودن' action
  Widget _buildNoPlanCard(
    BuildContext context,
    WidgetRef ref,
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.16);

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final newPlan = await CreateStudyPlanBottomSheet.show(context);
        if (newPlan != null && context.mounted) {
          ref.read(studyPlanControllerProvider.notifier).loadPlans();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _DottedBorderPainter(
          color: borderColor,
          strokeWidth: 1.2,
          dash: 5.0,
          gap: 4.5,
          radius: 16.0,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.015),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.plus,
                size: 17,
                color: colorScheme.primary,
              ),
              6.hSpace,
              Text(
                'افزودن',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rounded rectangle dashed/dotted border
class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  const _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dash = 5.0,
    this.gap = 4.5,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = min(dash, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}
