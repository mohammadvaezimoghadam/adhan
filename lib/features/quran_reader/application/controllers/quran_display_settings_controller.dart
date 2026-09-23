import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local/preferences/preferences_keys.dart';
import '../../../../core/data/local/preferences/preferences_service_provider.dart';
import '../states/quran_display_settings_state.dart';

class QuranDisplaySettingsController
    extends Notifier<QuranDisplaySettingsState> {
  QuranDisplaySettingsState? _initialStateOnOpen;

  @override
  QuranDisplaySettingsState build() {
    final prefs = ref.watch(preferencesServiceProvider);

    final arabicFontSize =
        prefs.getDouble(PreferencesKeys.arabicFontSize) ?? 28.0;
    final arabicLineHeight =
        prefs.getDouble(PreferencesKeys.arabicLineHeight) ?? 2.2;
    final translationFontSize =
        prefs.getDouble(PreferencesKeys.translationFontSize) ?? 16.0;
    final translationFontFamily =
        prefs.getString(PreferencesKeys.translationFontFamily) ?? 'BNazanin';
    final showTranslation =
        prefs.getBool(PreferencesKeys.showTranslation) ?? true;
    final showAyahNumbers =
        prefs.getBool(PreferencesKeys.showAyahNumbers) ?? true;
    final autoHighlight = prefs.getBool(PreferencesKeys.autoHighlight) ?? true;
    final fontScript =
        prefs.getString(PreferencesKeys.fontScript) ?? 'عثمان طه';
    final translatorName =
        prefs.getString(PreferencesKeys.translatorName) ?? 'شیخ حسین انصاریان';
    final harakatColor =
        prefs.getString(PreferencesKeys.harakatColor) ?? '#FF4444';
    final removeTranslationBrackets =
        prefs.getBool(PreferencesKeys.removeTranslationBrackets) ?? true;
    final ayahThemeId =
        prefs.getString(PreferencesKeys.ayahThemeId) ?? 'classic_ivory';
    final ayahThemeSolid =
        prefs.getBool(PreferencesKeys.ayahThemeSolid) ?? false;

    return QuranDisplaySettingsState(
      arabicFontSize: arabicFontSize,
      arabicLineHeight: arabicLineHeight,
      translationFontSize: translationFontSize,
      translationFontFamily: translationFontFamily,
      showTranslation: showTranslation,
      showAyahNumbers: showAyahNumbers,
      autoHighlight: autoHighlight,
      fontScript: fontScript,
      translatorName: translatorName,
      harakatColor: harakatColor,
      removeTranslationBrackets: removeTranslationBrackets,
      ayahThemeId: ayahThemeId,
      isAyahThemeSolid: ayahThemeSolid,
    );
  }

  /// Call when opening the settings drawer to record the baseline state.
  void recordInitialState() {
    _initialStateOnOpen = state;
  }

  /// Call when the drawer is closed to compare current state with baseline,
  /// and persist to SharedPreferences ONLY if changes were made.
  void saveSettingsIfChanged() {
    final baseline = _initialStateOnOpen;
    if (baseline != null && state == baseline) {
      // No settings changed; skip disk writes.
      return;
    }

    final prefs = ref.read(preferencesServiceProvider);
    prefs.setDouble(PreferencesKeys.arabicFontSize, state.arabicFontSize);
    prefs.setDouble(PreferencesKeys.arabicLineHeight, state.arabicLineHeight);
    prefs.setDouble(
      PreferencesKeys.translationFontSize,
      state.translationFontSize,
    );
    prefs.setString(
      PreferencesKeys.translationFontFamily,
      state.translationFontFamily,
    );
    prefs.setBool(PreferencesKeys.showTranslation, state.showTranslation);
    prefs.setBool(PreferencesKeys.showAyahNumbers, state.showAyahNumbers);
    prefs.setBool(PreferencesKeys.autoHighlight, state.autoHighlight);
    prefs.setString(PreferencesKeys.fontScript, state.fontScript);
    prefs.setString(PreferencesKeys.translatorName, state.translatorName);
    prefs.setString(PreferencesKeys.harakatColor, state.harakatColor);
    prefs.setBool(
      PreferencesKeys.removeTranslationBrackets,
      state.removeTranslationBrackets,
    );
    prefs.setString(PreferencesKeys.ayahThemeId, state.ayahThemeId);
    prefs.setBool(PreferencesKeys.ayahThemeSolid, state.isAyahThemeSolid);

    _initialStateOnOpen = state;
  }

  void updateAyahTheme(String themeId) {
    state = state.copyWith(ayahThemeId: themeId);
  }

  void toggleAyahThemeSolid(bool isSolid) {
    state = state.copyWith(isAyahThemeSolid: isSolid);
  }

  void updateArabicFontSize(double size) {
    state = state.copyWith(arabicFontSize: size);
  }

  void updateArabicLineHeight(double height) {
    final clamped = double.parse(height.clamp(1.6, 3.2).toStringAsFixed(1));
    state = state.copyWith(arabicLineHeight: clamped);
  }

  void updateTranslationFontSize(double size) {
    state = state.copyWith(translationFontSize: size);
  }

  void updateTranslationFontFamily(String family) {
    state = state.copyWith(translationFontFamily: family);
  }

  void toggleTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
  }

  void toggleArabicText(bool show) {
    state = state.copyWith(showArabicText: show);
  }

  void toggleRemoveTranslationBrackets(bool remove) {
    state = state.copyWith(removeTranslationBrackets: remove);
  }

  void toggleAyahNumbers(bool show) {
    state = state.copyWith(showAyahNumbers: show);
  }

  void toggleAutoHighlight(bool auto) {
    state = state.copyWith(autoHighlight: auto);
  }

  void updateFontScript(String script) {
    state = state.copyWith(fontScript: script);
  }

  void updateTranslator(String translator) {
    state = state.copyWith(translatorName: translator);
  }

  void updateHarakatColor(String colorHex) {
    state = state.copyWith(harakatColor: colorHex);
  }

  void updateThemeMode(String mode) {
    state = state.copyWith(themeMode: mode);
  }

  void resetToDefaults() {
    state = const QuranDisplaySettingsState();
    final prefs = ref.read(preferencesServiceProvider);
    prefs.remove(PreferencesKeys.arabicFontSize);
    prefs.remove(PreferencesKeys.arabicLineHeight);
    prefs.remove(PreferencesKeys.translationFontSize);
    prefs.remove(PreferencesKeys.translationFontFamily);
    prefs.remove(PreferencesKeys.showTranslation);
    prefs.remove(PreferencesKeys.showAyahNumbers);
    prefs.remove(PreferencesKeys.autoHighlight);
    prefs.remove(PreferencesKeys.fontScript);
    prefs.remove(PreferencesKeys.translatorName);
    prefs.remove(PreferencesKeys.harakatColor);
    prefs.remove(PreferencesKeys.removeTranslationBrackets);
    prefs.remove(PreferencesKeys.ayahThemeId);
    prefs.remove(PreferencesKeys.ayahThemeSolid);
    _initialStateOnOpen = state;
  }
}

final quranDisplaySettingsControllerProvider =
    NotifierProvider<QuranDisplaySettingsController, QuranDisplaySettingsState>(
      QuranDisplaySettingsController.new,
    );
