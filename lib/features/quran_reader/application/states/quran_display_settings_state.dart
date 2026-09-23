import 'package:freezed_annotation/freezed_annotation.dart';

part 'quran_display_settings_state.freezed.dart';

/// Data model representing Quran reader display preferences.
@freezed
abstract class QuranDisplaySettingsState with _$QuranDisplaySettingsState {
  const factory QuranDisplaySettingsState({
    @Default(28.0) double arabicFontSize,
    @Default(2.2) double arabicLineHeight,
    @Default(16.0) double translationFontSize,
    @Default('BNazanin') String translationFontFamily,
    @Default(true) bool showTranslation,
    @Default(true) bool showArabicText,
    @Default(true) bool showAyahNumbers,
    @Default(true) bool autoHighlight,
    @Default('عثمان طه') String fontScript,
    @Default('شیخ حسین انصاریان') String translatorName,
    @Default('light') String themeMode, // 'light', 'sepia', 'dark'
    @Default('#FF4444') String harakatColor,
    @Default(true) bool removeTranslationBrackets,
    @Default('classic_ivory') String ayahThemeId,
    @Default(false) bool isAyahThemeSolid,
  }) = _QuranDisplaySettingsState;
}
