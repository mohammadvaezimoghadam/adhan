import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../common/extensions/int_extension.dart';
import '../../../../common/utils/arabic_text_helper.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/quran_display_settings_controller.dart';
import '../../domain/entities/ayah_theme_entity.dart';

/// Renders a circular badge marker for an Ayah number using Eastern Arabic/Persian digits.
class AyahNumberMarker extends ConsumerWidget {
  final int number;
  final bool isActive;

  const AyahNumberMarker({
    super.key,
    required this.number,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isolated check: If showAyahNumbers is false, self-collapse into SizedBox.shrink()
    final showAyahNumber = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.showAyahNumbers),
    );

    if (!showAyahNumber) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    final harakatColorHex = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.harakatColor),
    );
    final customColor = ArabicTextHelper.parseHexColor(harakatColorHex);

    final ayahThemeId = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.ayahThemeId),
    );
    final activeTheme = AyahThemePresets.getById(ayahThemeId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final numberColor = activeTheme.isDark
        ? Colors.white.withValues(alpha: 0.95)
        : (isDark && !activeTheme.isDark
            ? const Color(0xFF1C1B1B)
            : colorScheme.onSurface);

    final defaultBracketColor = activeTheme.isDark
        ? Colors.white.withValues(alpha: 0.70)
        : (isDark && !activeTheme.isDark
            ? const Color(0xFF3E4947)
            : colorScheme.onSurfaceVariant);

    final bool isCustomTooDark = activeTheme.isDark &&
        customColor != null &&
        customColor.computeLuminance() < 0.25;

    final bracketColor = (customColor != null && !isCustomTooDark)
        ? customColor
        : defaultBracketColor;

    final fontScript = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final fontFamily = AppTypography.getFontFamilyByScript(fontScript);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          // Right Bracket (Ra_bracket) + Invisible Text for Selection
          Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                '(',
                style: TextStyle(fontSize: 0.1, color: Colors.transparent),
              ),
              SvgPicture.asset(
                'assets/icons/ic_bracket_right.svg',
                height: 24,
                colorFilter: ColorFilter.mode(bracketColor, BlendMode.srcIn),
              ),
            ],
          ),
          
          const SizedBox(width: 3), // Balanced gap
          
          // Ayah Number - Vertically centered exactly in the middle of brackets
          SizedBox(
            height: 24,
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -5.5),
                child: Text(
                  number.toPersianDigit(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: numberColor,
                    fontSize: 18,
                    fontFamily: fontFamily,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 3), // Balanced gap
          
          // Left Bracket (La_bracket) + Invisible Text for Selection
          Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                ')',
                style: TextStyle(fontSize: 0.1, color: Colors.transparent),
              ),
              SvgPicture.asset(
                'assets/icons/ic_bracket_left.svg',
                height: 24,
                colorFilter: ColorFilter.mode(bracketColor, BlendMode.srcIn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
