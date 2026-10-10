import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/surah_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../../quran_reader/presentation/widgets/quran_quick_jump_bottom_sheet.dart';
import '../../../quick_access/presentation/widgets/bookmarks_manager_bottom_sheet.dart';

/// Clean Apple-Style Action Pills for "Bookmarks" (نشان شده‌ها)
/// and "Quick Jump" (برو به) with icon-free minimalist typography.
class SurahListQuickActions extends ConsumerWidget {
  final VoidCallback? onBeforeNavigation;

  const SurahListQuickActions({
    super.key,
    this.onBeforeNavigation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    // Apple-style sleek neutral pill surface
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF2EFEB);

    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        children: [
          // 1. Right Button: نشان شده‌ها (Bookmarks)
          Expanded(
            child: _ActionPillItem(
              title: 'نشان شده‌ها',
              bgColor: cardBg,
              borderColor: cardBorder,
              textColor: colorScheme.onSurface,
              onTap: () {
                onBeforeNavigation?.call();
                BookmarksManagerBottomSheet.show(context, isFullScreen: true);
              },
            ),
          ),
          10.hSpace,

          // 2. Left Button: برو به (Jump To)
          Expanded(
            child: _ActionPillItem(
              title: 'برو به',
              bgColor: cardBg,
              borderColor: cardBorder,
              textColor: colorScheme.onSurface,
              onTap: () async {
                final target = await QuranQuickJumpBottomSheet.show(context);
                if (target != null && context.mounted) {
                  onBeforeNavigation?.call();
                  ref
                      .read(quranDisplaySettingsControllerProvider.notifier)
                      .toggleArabicText(true);
                  context.pushNamed(
                    quranReaderRoute,
                    pathParameters: {'id': target.surahId.toString()},
                    queryParameters: {
                      'name': SurahConstants.getSurahName(target.surahId),
                      'ayah': target.ayahNumber.toString(),
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPillItem extends StatelessWidget {
  final String title;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionPillItem({
    required this.title,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
          splashColor: textColor.withValues(alpha: 0.06),
          highlightColor: textColor.withValues(alpha: 0.03),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
