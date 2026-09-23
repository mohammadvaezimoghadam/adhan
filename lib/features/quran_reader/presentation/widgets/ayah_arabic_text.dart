import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/utils/arabic_text_helper.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/quran_display_settings_controller.dart';
import '../../domain/entities/ayah_theme_entity.dart';
import 'ayah_number_marker.dart';

/// Renders the Arabic text of an Ayah with an inline number marker
/// and custom diacritics (Tashkeel) coloring.
///
/// If [ayahNumber] is 1 and Bismillah is prefixed inside the Ayah text
/// (as is standard for Surahs 2 to 114, excluding Surah 9), Bismillah
/// is extracted and rendered centered on its own dedicated top line,
/// followed by the main Ayah text on the next line.
class AyahArabicText extends ConsumerWidget {
  final String text;
  final int ayahNumber;
  final bool isActive;
  final int surahId;

  const AyahArabicText({
    super.key,
    required this.text,
    required this.ayahNumber,
    this.isActive = false,
    this.surahId = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final arabicFontSize = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.arabicFontSize),
    );
    final arabicLineHeight = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.arabicLineHeight),
    );
    final fontScript = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final harakatColorHex = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.harakatColor),
    );

    final fontFamily = AppTypography.getFontFamilyByScript(fontScript);
    final harakatColor = ArabicTextHelper.parseHexColor(harakatColorHex);

    final ayahThemeId = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.ayahThemeId),
    );
    final activeTheme = AyahThemePresets.getById(ayahThemeId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = activeTheme.isDark
        ? Colors.white.withValues(alpha: 0.95)
        : (isDark && !activeTheme.isDark
            ? const Color(0xFF1C1B1B)
            : colorScheme.onSurface);

    final baseStyle = AppTypography.displayQuranReader.copyWith(
      fontFamily: fontFamily,
      fontSize: arabicFontSize,
      height: arabicLineHeight,
      color: textColor,
    );

    final sanitizedText = ArabicTextHelper.removeAnnotationMarks(text);
    final bool useCustomColor = harakatColor != null &&
        harakatColor != textColor;

    String? bismillahText;
    String mainText = sanitizedText;

    // Extract Bismillah for Surahs 2..114 (except Surah 9) on Ayah 1
    if (ayahNumber == 1 && surahId != 1 && surahId != 9) {
      final cleaned = sanitizedText.trim().replaceAll(RegExp(r'[\uFEFF\u200B-\u200F\uFFFD]'), '');
      final tokens = cleaned.split(RegExp(r'\s+'));
      if (tokens.length >= 5) {
        bismillahText = tokens.sublist(0, 4).join(' ');
        mainText = tokens.sublist(4).join(' ');
      }
    }

    List<InlineSpan> buildSpans(String rawText) {
      if (useCustomColor) {
        return ArabicTextHelper.buildColoredSpans(
          text: rawText,
          baseStyle: baseStyle,
          baseColor: textColor,
          harakatColor: harakatColor,
        );
      } else {
        return [TextSpan(text: rawText)];
      }
    }

    final List<InlineSpan> mainTextChildren = List<InlineSpan>.from(buildSpans(mainText));

    // Append the Ayah number marker at the end of the main text.
    mainTextChildren.add(const TextSpan(text: ' \u200F'));
    mainTextChildren.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: SelectionContainer.disabled(
          child: AyahNumberMarker(
            number: ayahNumber,
            isActive: isActive,
          ),
        ),
      ),
    );
    mainTextChildren.add(const TextSpan(text: '\u200F'));

    if (bismillahText != null) {
      final bismillahSpans = buildSpans(bismillahText);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text.rich(
              TextSpan(
                style: baseStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                children: bismillahSpans,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
          Text.rich(
            TextSpan(
              style: baseStyle,
              children: mainTextChildren,
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          ),
        ],
      );
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: mainTextChildren,
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}
