import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../common/extensions/context_extension.dart';
import '../../../../../common/extensions/size_extension.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../main_navigation/application/tab_navigation_controller.dart';
import '../../../../tafsir_manager/presentation/widgets/tafsir_manager_bottom_sheet.dart';
import '../../../../translation_manager/presentation/widgets/translation_manager_bottom_sheet.dart';

/// Modern Asymmetric Action Hub:
/// Highlights "فهرست سوره‌ها" as the primary hero gateway,
/// paired with elegant compact companions for "ترجمه‌ها" and "تنظیمات".
class HomeQuickAccessGrid extends ConsumerWidget {
  const HomeQuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final colors = context.colors;
    final colorScheme = context.colorScheme;

    final primaryMint = colorScheme.primary;
    final cardBorderColor = colors.cardBorder;
    final cardBg = colors.cardBackground;

    return Row(
      children: [
        // 1. Primary Hero Gateway: "فهرست سوره‌ها"
        Expanded(
          flex: 5,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Color.alphaBlend(primaryMint.withValues(alpha: 0.08), cardBg)
                  : Color.alphaBlend(primaryMint.withValues(alpha: 0.05), cardBg),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: primaryMint.withValues(alpha: isDark ? 0.30 : 0.22),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryMint.withValues(alpha: isDark ? 0.12 : 0.05),
                  blurRadius: 10.0,
                  offset: const Offset(0, 2.0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(tabNavigationControllerProvider.notifier).switchTab(1);
                },
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Quran Surahs Icon
                      SvgPicture.asset(
                        'assets/icons/ic_surah_list.svg',
                        width: 38,
                        height: 38,
                        colorFilter: ColorFilter.mode(
                          primaryMint,
                          BlendMode.srcIn,
                        ),
                      ),
                      10.hSpace,

                      // Surah List Typography (Clean, Minimal, No Sub-label)
                      Expanded(
                        child: Text(
                          'فهرست سوره‌ها',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      4.hSpace,
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        8.hSpace,

        // 2. Secondary Companion Card: "ترجمه‌ها"
        Expanded(
          flex: 2,
          child: _buildSecondaryCard(
            context: context,
            title: 'ترجمه‌ها',
            iconWidget: Icon(
              CupertinoIcons.text_bubble,
              size: 27,
              color: primaryMint,
            ),
            isDark: isDark,
            bgColor: cardBg,
            borderColor: cardBorderColor,
            onTap: () {
              HapticFeedback.lightImpact();
              TranslationManagerBottomSheet.show(context);
            },
          ),
        ),
        8.hSpace,

        // 3. Secondary Companion Card: "تفسیر"
        Expanded(
          flex: 2,
          child: _buildSecondaryCard(
            context: context,
            title: 'تفسیر',
            iconWidget: SvgPicture.asset(
              'assets/icons/ic_tafsir.svg',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                primaryMint,
                BlendMode.srcIn,
              ),
            ),
            isDark: isDark,
            bgColor: cardBg,
            borderColor: cardBorderColor,
            onTap: () {
              HapticFeedback.lightImpact();
              TafsirManagerBottomSheet.show(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryCard({
    required BuildContext context,
    required String title,
    required Widget iconWidget,
    required bool isDark,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2.0),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: iconWidget,
                  ),
                ),
                2.vSpace,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C),
                      height: 1.1,
                    ),
                    maxLines: 1,
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
