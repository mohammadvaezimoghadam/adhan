import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/study_plan_controller.dart';
import '../widgets/create_study_plan_bottom_sheet.dart';
import '../widgets/study_plan_card_widget.dart';

/// Clean & Minimal Quran Study Plans Screen using the unified card design.
class StudyPlansScreen extends ConsumerWidget {
  const StudyPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlanControllerProvider.notifier).checkAndRefreshAllPlans();
    });
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
                      return StudyPlanCardWidget(
                        plan: plan,
                        margin: const EdgeInsets.only(bottom: 12),
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
