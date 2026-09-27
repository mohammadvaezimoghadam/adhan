import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/utils/arabic_text_helper.dart';
import '../../../../common/widgets/app_theme_toggle_button.dart';
import '../../../../common/widgets/reciter/horizontal_reciter_selector.dart';
import '../../../../common/widgets/reciter/reciter_selection_bottom_sheet.dart';
import '../../../../common/widgets/settings_switch_tile.dart';
import '../../../../common/widgets/app_segmented_tab_bar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/presentation/theme_controller.dart';
import '../../../translation_manager/presentation/widgets/translation_settings_section.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../application/controllers/quran_display_settings_controller.dart';
import '../../domain/enums/audio_playback_mode.dart';
import '../../domain/entities/ayah_theme_entity.dart';
import '../../../subscription/application/vip_subscription_controller.dart';
import '../../../subscription/presentation/widgets/vip_required_dialog.dart';
import '../utils/reciter_download_helper.dart';
import 'ayah_number_marker.dart';
import 'ayah_theme_carousel.dart';
import 'tashkeel_color_selector_tile.dart';
import '../../../quick_access/presentation/widgets/bookmarks_manager_bottom_sheet.dart';

/// Ultra-modern iOS-style Tabbed Settings Bottom Sheet (Display & Audio).
class QuickSettingsDrawer extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const QuickSettingsDrawer({
    super.key,
    this.initialTabIndex = 0,
  });

  /// Helper method to display settings as a full-screen page on mobile or centered modal on web.
  static Future<void> show(
    BuildContext context, {
    int initialTabIndex = 0,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier =
        container.read(quranDisplaySettingsControllerProvider.notifier);

    // Record baseline state before user makes changes in settings
    notifier.recordInitialState();

    if (context.isWideScreen) {
      await showDialog(
        context: context,
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Material(
                color: Colors.transparent,
                child: QuickSettingsDrawer(
                  initialTabIndex: initialTabIndex,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuickSettingsDrawer(
            initialTabIndex: initialTabIndex,
          ),
        ),
      );
    }

    // Save ONLY if changes were made upon closing
    notifier.saveSettingsIfChanged();
  }

  @override
  ConsumerState<QuickSettingsDrawer> createState() =>
      _QuickSettingsDrawerState();
}

class _QuickSettingsDrawerState extends ConsumerState<QuickSettingsDrawer> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 2);
  }

  static const List<String> _fontNames = [
    'عثمان طه',
    'امیری',
    'شهرزاد',
    'نیریزی',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    // Notifiers for dispatching actions (does not trigger rebuilds)
    final displayNotifier =
        ref.read(quranDisplaySettingsControllerProvider.notifier);
    final audioController =
        ref.read(quranAudioControllerProvider.notifier);

    final currentThemeMode = ref.watch(themeControllerProvider);
    final activeThemeMode = currentThemeMode == ThemeMode.system
        ? (isDark ? ThemeMode.dark : ThemeMode.light)
        : currentThemeMode;

    final screenBgColor = isDark ? colorScheme.surface : const Color(0xFFF7F5F0);
    final cardBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;
    final accentColor = colorScheme.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            displayNotifier.saveSettingsIfChanged();
          }
        },
        child: Scaffold(
          backgroundColor: screenBgColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                border: Border(
                  bottom: BorderSide(
                    color: colors.cardBorder,
                    width: 0.8,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'بازگشت',
                        icon: Icon(
                          CupertinoIcons.chevron_forward,
                          size: 24,
                          color: textPrimary,
                        ),
                        splashRadius: 22,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).maybePop();
                        },
                      ),
                      Expanded(
                        child: Text(
                          'تنظیمات مطالعه و پخش',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'نشانه‌های ذخیره‌شده',
                        icon: Icon(
                          CupertinoIcons.bookmark,
                          size: 22,
                          color: textPrimary,
                        ),
                        splashRadius: 22,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          BookmarksManagerBottomSheet.show(context);
                        },
                      ),
                      const SizedBox(width: 4),
                      const AppThemeToggleButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                12.0.vSpace,

                // Tab Switcher (Hayat/Tafakor Style: متن قرآن / ترجمه / صوت و تلاوت)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppSegmentedTabBar(
                    items: const [
                      AppSegmentedTabItem(title: 'متن قرآن'),
                      AppSegmentedTabItem(title: 'ترجمه'),
                      AppSegmentedTabItem(title: 'صوت و تلاوت'),
                    ],
                    selectedIndex: _selectedTabIndex,
                    onTabSelected: (index) => setState(() => _selectedTabIndex = index),
                  ),
                ),

                12.0.vSpace,

                // Tab Content (Optimized: Isolated Subtree Watches to avoid unneeded rebuilds)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _selectedTabIndex == 0
                        ? _buildQuranTab(
                            context: context,
                            ref: ref,
                            displayNotifier: displayNotifier,
                            activeThemeMode: activeThemeMode,
                            cardBgColor: cardBgColor,
                            accentColor: accentColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            colorScheme: colorScheme,
                          )
                        : _selectedTabIndex == 1
                            ? _buildTranslationTab(
                                context: context,
                                ref: ref,
                                displayNotifier: displayNotifier,
                                cardBgColor: cardBgColor,
                                accentColor: accentColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                colorScheme: colorScheme,
                              )
                            : _buildAudioTab(
                                context: context,
                                ref: ref,
                                displayNotifier: displayNotifier,
                                audioController: audioController,
                                cardBgColor: cardBgColor,
                                accentColor: accentColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                colorScheme: colorScheme,
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 0: QURAN TEXT & SCRIPT ---
  Widget _buildQuranTab({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic displayNotifier,
    required ThemeMode activeThemeMode,
    required Color cardBgColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    final settings = ref.watch(quranDisplaySettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Pinned Quran Live Preview
        _buildQuranLivePreviewCard(
          context: context,
          settings: settings,
          cardBgColor: cardBgColor,
          accentColor: accentColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          colorScheme: colorScheme,
        ),

        12.0.vSpace,

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── GROUP 0: AYAH COLOR THEMES (Telegram Style) ──
                _buildSectionTitle('پوسته و رنگ آیات', textSecondary),
                8.0.vSpace,
                AyahThemeCarousel(
                  selectedThemeId: settings.ayahThemeId,
                  onThemeSelected: (themeId) =>
                      displayNotifier.updateAyahTheme(themeId),
                ),
                10.0.vSpace,
                _buildCardGroup(
                  cardBgColor: cardBgColor,
                  children: [
                    SettingsSwitchTile(
                      title: 'تفکیک بصری آیات',
                      subtitle: 'تغییر متناوب رنگ پس‌زمینه جهت تمایز و تفکیک آسان‌تر آیات',
                      value: !settings.isAyahThemeSolid,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (val) =>
                          displayNotifier.toggleAyahThemeSolid(!val),
                    ),
                  ],
                ),
                16.0.vSpace,

                // GROUP 1: QURAN SCRIPT & CALLIGRAPHY
                _buildSectionTitle('قلم و نگارش قرآن', textSecondary),
                6.0.vSpace,
                _buildCardGroup(
                  cardBgColor: cardBgColor,
                  children: [
                    _buildFontScriptTile(
                      context: context,
                      settings: settings,
                      notifier: displayNotifier,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      colorScheme: colorScheme,
                    ),
                    _buildInnerDivider(colorScheme),
                    _buildSliderTile(
                      context: context,
                      title: 'اندازه متن عربی',
                      valueLabel: '${settings.arabicFontSize.toInt()} pt',
                      value: settings.arabicFontSize,
                      min: 18,
                      max: 42,
                      divisions: 24,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (val) =>
                          displayNotifier.updateArabicFontSize(val),
                    ),
                    _buildInnerDivider(colorScheme),
                    _buildSliderTile(
                      context: context,
                      title: 'فاصله خطوط متن عربی',
                      valueLabel: settings.arabicLineHeight.toStringAsFixed(1),
                      value: settings.arabicLineHeight,
                      min: 1.6,
                      max: 3.2,
                      divisions: 16,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (val) =>
                          displayNotifier.updateArabicLineHeight(val),
                    ),
                    _buildInnerDivider(colorScheme),
                    TashkeelColorSelectorTile(
                      selectedColorHex: settings.harakatColor,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      colorScheme: colorScheme,
                      onColorSelected: (colorHex) =>
                          displayNotifier.updateHarakatColor(colorHex),
                    ),
                  ],
                ),

                16.0.vSpace,

                // GROUP 2: DISPLAY OPTIONS & THEME
                _buildSectionTitle('نمایش و صفحه', textSecondary),
                6.0.vSpace,
                _buildCardGroup(
                  cardBgColor: cardBgColor,
                  children: [
                    SettingsSwitchTile(
                      title: 'نمایش متن عربی',
                      subtitle: 'نمایش آیات به زبان عربی',
                      value: settings.showArabicText,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (val) => displayNotifier.toggleArabicText(val),
                    ),
                    _buildInnerDivider(colorScheme),
                    SettingsSwitchTile(
                      title: 'نمایش شماره آیه‌ها',
                      subtitle: 'نمایش نشانگر شماره در پایان هر آیه',
                      value: settings.showAyahNumbers,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onChanged: (val) =>
                          displayNotifier.toggleAyahNumbers(val),
                    ),
                    _buildInnerDivider(colorScheme),
                    _buildThemeTile(
                      context: context,
                      activeThemeMode: activeThemeMode,
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),

                16.0.vSpace,

                // RESET BUTTON
                Center(
                  child: TextButton.icon(
                    onPressed: () => displayNotifier.resetToDefaults(),
                    icon: Icon(
                      CupertinoIcons.refresh,
                      size: 16,
                      color: textSecondary,
                    ),
                    label: Text(
                      'بازنشانی تنظیمات متن و نگارش',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                    ),
                  ),
                ),

                24.0.vSpace,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 1: TRANSLATION SETTINGS ---
  Widget _buildTranslationTab({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic displayNotifier,
    required Color cardBgColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    final settings = ref.watch(quranDisplaySettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Pinned Translation Live Preview
        _buildTranslationLivePreviewCard(
          context: context,
          settings: settings,
          cardBgColor: cardBgColor,
          accentColor: accentColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          colorScheme: colorScheme,
        ),

        12.0.vSpace,

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('تنظیمات ترجمه فارسی', textSecondary),
                6.0.vSpace,
                _buildCardGroup(
                  cardBgColor: cardBgColor,
                  children: [
                    TranslationSettingsSection(
                      showTranslation: settings.showTranslation,
                      translationFontSize: settings.translationFontSize,
                      translationFontFamily: settings.translationFontFamily,
                      removeTranslationBrackets:
                          settings.removeTranslationBrackets,
                      onToggleTranslation: (val) =>
                          displayNotifier.toggleTranslation(val),
                      onFontSizeChanged: (val) =>
                          displayNotifier.updateTranslationFontSize(val),
                      onFontFamilyChanged: (val) =>
                          displayNotifier.updateTranslationFontFamily(val),
                      onToggleRemoveBrackets: (val) =>
                          displayNotifier.toggleRemoveTranslationBrackets(val),
                      accentColor: accentColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),

                16.0.vSpace,

                // RESET TRANSLATION BUTTON
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      displayNotifier.updateTranslationFontSize(16.0);
                      displayNotifier.updateTranslationFontFamily('BNazanin');
                      displayNotifier.toggleRemoveTranslationBrackets(true);
                      displayNotifier.toggleTranslation(true);
                    },
                    icon: Icon(
                      CupertinoIcons.refresh,
                      size: 16,
                      color: textSecondary,
                    ),
                    label: Text(
                      'بازنشانی تنظیمات ترجمه',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                    ),
                  ),
                ),

                24.0.vSpace,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PINNED QURAN LIVE PREVIEW CARD ---
  Widget _buildQuranLivePreviewCard({
    required BuildContext context,
    required dynamic settings,
    required Color cardBgColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    final fontFamily =
        AppTypography.getFontFamilyByScript(settings.fontScript);
    final harakatColor =
        ArabicTextHelper.parseHexColor(settings.harakatColor);
    const sampleArabicText = 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَالَمِينَ';

    final activeTheme = AyahThemePresets.getById(settings.ayahThemeId);
    final isThemeDark = activeTheme.isDark;
    final effectiveTextColor =
        isThemeDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1C1B1B);
    final previewBgColor = settings.isAyahThemeSolid
        ? activeTheme.evenColor
        : activeTheme.oddColor;
    final previewBorderColor = activeTheme.borderColor;

    final baseArabicStyle = AppTypography.displayQuranReader.copyWith(
      fontFamily: fontFamily,
      fontSize: settings.arabicFontSize,
      height: settings.arabicLineHeight,
      color: effectiveTextColor,
    );

    final bool useCustomHarakat =
        harakatColor != null && harakatColor != effectiveTextColor;

    final List<InlineSpan> textChildren = [];

    if (settings.showArabicText) {
      if (useCustomHarakat) {
        textChildren.addAll(
          ArabicTextHelper.buildColoredSpans(
            text: sampleArabicText,
            baseStyle: baseArabicStyle,
            baseColor: effectiveTextColor,
            harakatColor: harakatColor,
          ),
        );
      } else {
        textChildren.add(const TextSpan(text: sampleArabicText));
      }

      if (settings.showAyahNumbers) {
        textChildren.add(const TextSpan(text: '\u200F'));
        textChildren.add(
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: AyahNumberMarker(
              number: 2,
              isActive: false,
            ),
          ),
        );
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: previewBgColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: previewBorderColor,
          width: 1.2,
        ),
      ),
      child: settings.showArabicText
          ? RichText(
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: baseArabicStyle,
                children: textChildren,
              ),
            )
          : Center(
              child: Text(
                'نمایش متن عربی غیرفعال است',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: isThemeDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
    );
  }

  // --- PINNED TRANSLATION LIVE PREVIEW CARD ---
  Widget _buildTranslationLivePreviewCard({
    required BuildContext context,
    required dynamic settings,
    required Color cardBgColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    const rawSampleTranslationText =
        '(خداوندی که) ستایش مخصوص اوست [که] پروردگار جهانیان است.';
    final sampleTranslationText = settings.removeTranslationBrackets
        ? rawSampleTranslationText.removeTranslatorExplanations()
        : rawSampleTranslationText;

    final activeTheme = AyahThemePresets.getById(settings.ayahThemeId);
    final isThemeDark = activeTheme.isDark;

    final previewBgColor = settings.isAyahThemeSolid
        ? activeTheme.evenColor
        : activeTheme.oddColor;
    final previewBorderColor = activeTheme.borderColor;

    final translationTextColor = isThemeDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF334155);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: previewBgColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: previewBorderColor,
          width: 1.2,
        ),
      ),
      child: settings.showTranslation
          ? Text(
              sampleTranslationText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: settings.translationFontFamily,
                fontSize: settings.translationFontSize,
                color: translationTextColor,
                height: 1.45,
              ),
            )
          : Center(
              child: Text(
                'نمایش ترجمه غیرفعال است',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: isThemeDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
    );
  }

  // --- TAB 2: AUDIO & RECITATION (Optimized with targeted select watchers) ---
  Widget _buildAudioTab({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic displayNotifier,
    required dynamic audioController,
    required Color cardBgColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    // Targeted selectors: Audio ticks/duration updates do NOT trigger rebuilds here
    final playbackMode = ref.watch(
      quranAudioControllerProvider.select((s) => s.playbackMode),
    );
    final isAutoPlayNext = ref.watch(
      quranAudioControllerProvider.select((s) => s.isAutoPlayNext),
    );
    final isSingleAyahMode = ref.watch(
      quranAudioControllerProvider.select((s) => s.isSingleAyahMode),
    );
    final autoHighlight = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.autoHighlight),
    );
    final hasVip = ref.watch(hasVipAccessProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softGreenColor = (isDark ? const Color(0xFF1B6B58) : const Color(0xFF267D69))
        .withValues(alpha: 0.70);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GROUP 0: PLAYBACK MODE SELECTION
          _buildSectionTitle('نحوه پخش صوت', textSecondary),
          6.0.vSpace,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
            children: AudioPlaybackMode.values.map((mode) {
              final isSelected = playbackMode == mode;
              final isLocked = !hasVip && mode.includesTranslation;
              
              String shortTitle;
              switch (mode) {
                case AudioPlaybackMode.onlyQuran:
                  shortTitle = 'تلاوت';
                  break;
                case AudioPlaybackMode.onlyTranslation:
                  shortTitle = 'ترجمه';
                  break;
                case AudioPlaybackMode.quranThenTranslation:
                  shortTitle = 'تلاوت+ترجمه';
                  break;
                case AudioPlaybackMode.translationThenQuran:
                  shortTitle = 'ترجمه+تلاوت';
                  break;
              }

              final disabledColor = textSecondary.withValues(alpha: 0.45);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: InkWell(
                    onTap: () async {
                      // VIP check first — don't switch mode if user doesn't have VIP
                      if (isLocked) {
                        await VipRequiredDialog.show(
                          context: context,
                          isTranslation: true,
                        );
                        if (!context.mounted) return;
                        final hasVipNow = ref.read(hasVipAccessProvider);
                        if (!hasVipNow) return; // User didn't purchase, do nothing
                      }

                      // If the new mode includes translation, verify download
                      // readiness BEFORE switching mode
                      if (mode.includesTranslation && context.mounted) {
                        // Temporarily set mode so checkAndPromptForPlayback
                        // evaluates against the TARGET mode
                        ref
                            .read(quranAudioControllerProvider.notifier)
                            .setPlaybackMode(mode);
                        final isReady = await ReciterDownloadHelper.checkAndPromptForPlayback(
                          context: context,
                          ref: ref,
                        );
                        if (!isReady) {
                          // Translation not downloaded → revert to onlyQuran
                          if (context.mounted) {
                            ref
                                .read(quranAudioControllerProvider.notifier)
                                .setPlaybackMode(AudioPlaybackMode.onlyQuran);
                          }
                          return;
                        }
                      } else {
                        // Mode doesn't include translation, just set it
                        ref
                            .read(quranAudioControllerProvider.notifier)
                            .setPlaybackMode(mode);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? softGreenColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isLocked) ...[
                                Icon(
                                  Icons.lock_rounded,
                                  size: 13.0,
                                  color: isSelected ? Colors.white : disabledColor,
                                ),
                                const SizedBox(width: 3.5),
                              ],
                              Text(
                                shortTitle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12.0,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isLocked ? disabledColor : textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        16.0.vSpace,

        // GROUP 1: ARABIC RECITER SELECTION
        if (playbackMode.includesQuran) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('قاری تلاوت قرآن', textSecondary),
              InkWell(
                onTap: () => ReciterSelectionBottomSheet.show(context,
                    checkDownloadStatus: true),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'لیست کامل',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      4.0.hSpace,
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 13,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          6.0.vSpace,
          const HorizontalReciterSelector(
              isTranslationMode: false, checkDownloadStatus: true),
          16.0.vSpace,
        ],

        // GROUP 2: AUDIO TRANSLATION SELECTION
        if (playbackMode.includesTranslation) ...[
          _buildSectionTitle('گوینده ترجمه گویا', textSecondary),
          6.0.vSpace,
          const HorizontalReciterSelector(
              isTranslationMode: true, checkDownloadStatus: true),
          16.0.vSpace,
        ],

        // GROUP 2: AUDIO PLAYBACK OPTIONS
        _buildSectionTitle('گزینه‌های پخش صوت', textSecondary),
        6.0.vSpace,
        _buildCardGroup(
          cardBgColor: cardBgColor,
          children: [
            SettingsSwitchTile(
              title: 'پخش خودکار آیه بعدی',
              subtitle: 'ادامه تلاوت خودکار آیه‌ها پس از پایان هر آیه',
              value: isAutoPlayNext,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onChanged: (val) => audioController.toggleAutoPlayNext(),
            ),
            _buildInnerDivider(colorScheme),
            SettingsSwitchTile(
              title: 'حالت تک آیه‌ای (تکرار)',
              subtitle: 'پخش مجدد همان آیه و توقف پس از پایان آن',
              value: isSingleAyahMode,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onChanged: (val) => audioController.toggleSingleAyahMode(),
            ),
            _buildInnerDivider(colorScheme),
            SettingsSwitchTile(
              title: 'هایلایت خودکار آیه در حال پخش',
              subtitle: 'هایلایت رنگی و اسکرول همگام آیه در حال تلاوت',
              value: autoHighlight,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onChanged: (val) => displayNotifier.toggleAutoHighlight(val),
            ),
          ],
        ),

        24.0.vSpace,
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionTitle(String title, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textSecondary,
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required Color cardBgColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildInnerDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 14,
      endIndent: 14,
      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
    );
  }

  Widget _buildSliderTile({
    required BuildContext context,
    required String title,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          4.0.vSpace,
          Row(
            children: [
              Text(
                'کوچک',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10.5,
                  color: textSecondary,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: accentColor,
                    inactiveTrackColor: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: accentColor.withValues(alpha: 0.15),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                'بزرگ',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontScriptTile({
    required BuildContext context,
    required dynamic settings,
    required dynamic notifier,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softGreenColor = (isDark ? const Color(0xFF1B6B58) : const Color(0xFF267D69))
        .withValues(alpha: 0.70);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع خط عربی',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          8.0.vSpace,
          Row(
            children: List.generate(_fontNames.length, (index) {
              final fontName = _fontNames[index];
              final isSelected = settings.fontScript == fontName;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        notifier.updateFontScript(fontName);
                      },
                      borderRadius: BorderRadius.circular(24.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected ? softGreenColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          fontName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12.5,
                            color: isSelected ? Colors.white : textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required ThemeMode activeThemeMode,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required ColorScheme colorScheme,
  }) {
    final isDark = activeThemeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالت صفحه (تم)',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                isDark ? 'تم تیره (حالت شب)' : 'تم روشن (حالت روز)',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const AppThemeToggleButton(
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}
