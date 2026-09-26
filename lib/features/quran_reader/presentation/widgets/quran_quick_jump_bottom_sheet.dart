import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/surah_picker_dialog.dart';
import '../../../../core/data/local/sqflite/sqflite_service_provider.dart';
import '../../../../core/services/quran_navigation/domain/entities/ayah_target.dart';
import '../../../../core/services/quran_navigation/quran_navigation_service_provider.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../../surah_list/domain/entities/surah_entity.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../domain/entities/ayah_entity.dart';

enum QuickJumpTab { surah, juz, hizb, page }

/// Live Interconnected Single-View Sheet for Quran Quick Jump.
/// Replaces multiple disconnected tabs with a unified, synchronized card
/// where Surah, Ayah, Page, and Juz stay in continuous bidirectional sync.
class QuranQuickJumpBottomSheet extends ConsumerStatefulWidget {
  final QuickJumpTab initialTab;

  const QuranQuickJumpBottomSheet({
    super.key,
    this.initialTab = QuickJumpTab.surah,
  });

  static Future<AyahTarget?> show(
    BuildContext context, {
    QuickJumpTab initialTab = QuickJumpTab.surah,
  }) {
    return showModalBottomSheet<AyahTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: QuranQuickJumpBottomSheet(initialTab: initialTab),
      ),
    );
  }

  @override
  ConsumerState<QuranQuickJumpBottomSheet> createState() =>
      _QuranQuickJumpBottomSheetState();
}

class _QuranQuickJumpBottomSheetState
    extends ConsumerState<QuranQuickJumpBottomSheet> {
  bool _isInitialized = false;

  // Interconnected Live State
  SurahEntity? _selectedSurah;
  int _currentAyahNumber = 1;
  int _currentPageNumber = 1;
  int _currentJuzNumber = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = context.colorScheme;
    final surahs = ref.watch(surahListControllerProvider.select((s) => s.surahs));

    // Initialize from currently visible Ayah in reader or current surah
    if (!_isInitialized) {
      if (surahs.isNotEmpty) {
        _isInitialized = true;
        _initFromReader(surahs);
      } else {
        final currentSurahId = ref.read(quranReaderControllerProvider).currentSurahId;
        if (currentSurahId >= 1 && currentSurahId <= 114) {
          _isInitialized = true;
          _initFallback(currentSurahId);
        }
      }
    } else if (surahs.isNotEmpty && _selectedSurah != null && _selectedSurah!.numberOfAyahs <= 7 && _selectedSurah!.englishName.isEmpty) {
      // Upgrade fallback entity with full SQLite entity when surahs arrive
      final found = surahs.where((s) => s.number == _selectedSurah!.number).firstOrNull;
      if (found != null) {
        _selectedSurah = found;
      }
    }

    final readerSurahId = ref.watch(quranReaderControllerProvider.select((s) => s.currentSurahId));
    final activeSurah = _selectedSurah ??
        (surahs.isNotEmpty
            ? (surahs.where((s) => s.number == readerSurahId).firstOrNull ?? surahs.first)
            : SurahEntity(
                number: readerSurahId,
                name: readerSurahId.surahNameFa,
                englishName: '',
                englishNameTranslation: '',
                numberOfAyahs: 286,
                revelationType: '',
                startPage: 1,
                startJuz: 1,
              ));
    final maxAyahs = activeSurah.numberOfAyahs;

    // Card styling inspired by Hayat/Tafakor modular system
    final cardBg = isDark
        ? const Color(0xFF181717)
        : const Color(0xFFF7F5F0);

    final cardBorder = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE2DDD5);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.colors.dialogSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const AppModalHeader(
                showDragHandle: true,
                bottomSpacing: 14.0,
                title: 'پرش سریع در قرآن',
              ),

              // 3. The Live Interconnected Trio Card
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder, width: 0.8),
                ),
                child: Column(
                  children: [
                    // ROW 1: Surah Selector
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openSurahPickerDialog(
                          context,
                          surahs,
                          activeSurah,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'سوره',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 11.5,
                                        color: isDark
                                            ? const Color(0xFF9E9E9E)
                                            : const Color(0xFF6E6D68),
                                      ),
                                    ),
                                    2.vSpace,
                                    Text(
                                      '${activeSurah.number.toPersianDigit()}. سوره ${activeSurah.nameFa}',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1C1B1B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_left,
                                size: 16,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Hairline Divider
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 16,
                      endIndent: 16,
                      color: cardBorder,
                    ),

                    // ROW 2: Ayah Stepper
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'شماره آیه',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF9E9E9E)
                                        : const Color(0xFF6E6D68),
                                  ),
                                ),
                                2.vSpace,
                                Text(
                                  'آیه ${_currentAyahNumber.toPersianDigit()}',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStepper(
                            currentVal: _currentAyahNumber,
                            minVal: 1,
                            maxVal: maxAyahs,
                            isDark: isDark,
                            primaryColor: colorScheme.primary,
                            onChanged: (newVal) => _updateAyah(newVal),
                            onTapDirectEdit: () => _promptDirectNumber(
                              context: context,
                              title: 'شماره آیه سوره ${activeSurah.nameFa}',
                              currentVal: _currentAyahNumber,
                              minVal: 1,
                              maxVal: maxAyahs,
                              onSubmitted: (val) => _updateAyah(val),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hairline Divider
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 16,
                      endIndent: 16,
                      color: cardBorder,
                    ),

                    // ROW 3: Page Stepper (Dedicated row identical to Ayah)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'شماره صفحه',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF9E9E9E)
                                        : const Color(0xFF6E6D68),
                                  ),
                                ),
                                2.vSpace,
                                Text(
                                  'صفحه ${_currentPageNumber.toPersianDigit()}',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStepper(
                            currentVal: _currentPageNumber,
                            minVal: 1,
                            maxVal: 604,
                            isDark: isDark,
                            primaryColor: colorScheme.primary,
                            onChanged: (newVal) =>
                                _onPageChanged(newVal, surahs),
                            onTapDirectEdit: () => _promptDirectNumber(
                              context: context,
                              title: 'شماره صفحه قرآن',
                              currentVal: _currentPageNumber,
                              minVal: 1,
                              maxVal: 604,
                              onSubmitted: (val) =>
                                  _onPageChanged(val, surahs),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hairline Divider
                    Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 16,
                      endIndent: 16,
                      color: cardBorder,
                    ),

                    // ROW 4: Juz Stepper (Dedicated row identical to Ayah)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'شماره جزء',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF9E9E9E)
                                        : const Color(0xFF6E6D68),
                                  ),
                                ),
                                2.vSpace,
                                Text(
                                  'جزء ${_currentJuzNumber.toPersianDigit()}',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStepper(
                            currentVal: _currentJuzNumber,
                            minVal: 1,
                            maxVal: 30,
                            isDark: isDark,
                            primaryColor: colorScheme.primary,
                            onChanged: (newVal) =>
                                _onJuzChanged(newVal, surahs),
                            onTapDirectEdit: () => _promptDirectNumber(
                              context: context,
                              title: 'شماره جزء قرآن',
                              currentVal: _currentJuzNumber,
                              minVal: 1,
                              maxVal: 30,
                              onSubmitted: (val) =>
                                  _onJuzChanged(val, surahs),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              20.vSpace,

              // 4. Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _handleConfirm(activeSurah),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(CupertinoIcons.paperplane_fill, size: 17),
                  label: Text(
                    'انتقال به سوره ${activeSurah.nameFa}، آیه ${_currentAyahNumber.toPersianDigit()}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
              18.vSpace,
            ],
          ),
        ),
      ),
    ),
  );
}

  // --- Sub-widgets & Steppers ---

  Widget _buildStepper({
    required int currentVal,
    required int minVal,
    required int maxVal,
    required bool isDark,
    required Color primaryColor,
    required ValueChanged<int> onChanged,
    required VoidCallback onTapDirectEdit,
  }) {
    final canMinus = currentVal > minVal;
    final canPlus = currentVal < maxVal;

    final btnBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: CupertinoIcons.minus,
          isEnabled: canMinus,
          btnBg: btnBg,
          isDark: isDark,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(currentVal - 1);
          },
        ),
        8.hSpace,
        Material(
          color: btnBg,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTapDirectEdit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                currentVal.toPersianDigit(),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                ),
              ),
            ),
          ),
        ),
        8.hSpace,
        _stepperButton(
          icon: CupertinoIcons.plus,
          isEnabled: canPlus,
          btnBg: btnBg,
          isDark: isDark,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(currentVal + 1);
          },
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool isEnabled,
    required Color btnBg,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isEnabled ? btnBg : btnBg.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 16,
            color: isEnabled
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white24 : Colors.black26),
          ),
        ),
      ),
    );
  }


  // --- Logic & Synchronization ---

  void _initFallback(int surahId) {
    final ayahs = ref.read(quranReaderControllerProvider).ayahs;
    final firstAyah = ayahs.isNotEmpty ? ayahs.first : null;
    final page = firstAyah?.page ?? 1;
    final juz = firstAyah?.juz ?? 1;

    _selectedSurah = SurahEntity(
      number: surahId,
      name: surahId.surahNameFa,
      englishName: '',
      englishNameTranslation: '',
      numberOfAyahs: ayahs.isNotEmpty ? ayahs.length : 7,
      revelationType: '',
      startPage: page,
      startJuz: juz,
    );
    _currentAyahNumber = firstAyah?.ayahNumber ?? 1;
    _currentPageNumber = page;
    _currentJuzNumber = juz;
  }

  void _initFromReader(List<SurahEntity> surahs) {
    final ayahs = ref.read(quranReaderControllerProvider).ayahs;
    final currentSurahId = ref.read(quranReaderControllerProvider).currentSurahId;
    final itemPositionsListener = ref.read(activeItemPositionsListenerProvider);

    AyahEntity? currentAyah;
    if (ayahs.isNotEmpty) {
      int currentIndex = 0;
      if (itemPositionsListener != null) {
        final positions = itemPositionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          final visiblePositions = positions.where((p) => p.itemTrailingEdge > 0);
          if (visiblePositions.isNotEmpty) {
            currentIndex = visiblePositions
                .reduce((min, current) => current.index < min.index ? current : min)
                .index;
          }
        }
      }
      if (currentIndex >= 0 && currentIndex < ayahs.length) {
        currentAyah = ayahs[currentIndex];
      }
    }

    final targetSurahId = currentAyah?.surahId ?? currentSurahId;
    _selectedSurah = surahs.firstWhere(
      (s) => s.number == targetSurahId,
      orElse: () => surahs.first,
    );
    _currentAyahNumber = currentAyah?.ayahNumber ?? 1;
    _currentPageNumber = currentAyah?.page ?? _selectedSurah!.startPage;
    _currentJuzNumber = currentAyah?.juz ?? _selectedSurah!.startJuz;
  }

  Future<void> _updateAyah(int newAyah) async {
    setState(() {
      _currentAyahNumber = newAyah;
    });

    final surah = _selectedSurah;
    if (surah == null) return;

    // Fast path: check loaded ayahs in reader
    final ayahs = ref.read(quranReaderControllerProvider).ayahs;
    final match = ayahs.where((a) => a.surahId == surah.number && a.ayahNumber == newAyah).firstOrNull;
    if (match != null && match.page != null) {
      final page = match.page!;
      final calculatedJuz = page <= 1 ? 1 : (((page - 2) ~/ 20) + 1).clamp(1, 30);
      if (mounted) {
        setState(() {
          _currentPageNumber = page;
          _currentJuzNumber = match.juz ?? calculatedJuz;
        });
      }
      return;
    }

    // Database lookup (skip on Web where all Quran navigation uses online/cached mapping)
    if (kIsWeb) return;
    try {
      final sqflite = ref.read(sqfliteServiceProvider);
      final res = await sqflite.rawQuery(
        'SELECT page, juz FROM ayahs WHERE surah_number = ? AND number_in_surah = ? LIMIT 1',
        [surah.number, newAyah],
      );
      if (res.isNotEmpty && mounted) {
        final page = res.first['page'] as int?;
        final juz = res.first['juz'] as int?;
        if (page != null) {
          final calculatedJuz = page <= 1 ? 1 : (((page - 2) ~/ 20) + 1).clamp(1, 30);
          setState(() {
            _currentPageNumber = page;
            _currentJuzNumber = juz ?? calculatedJuz;
          });
        }
      }
    } catch (_) {}
  }

  void _onSurahSelected(SurahEntity newSurah) {
    final calculatedJuz = newSurah.startPage <= 1
        ? 1
        : (((newSurah.startPage - 2) ~/ 20) + 1).clamp(1, 30);
    setState(() {
      _selectedSurah = newSurah;
      _currentAyahNumber = 1;
      _currentPageNumber = newSurah.startPage;
      _currentJuzNumber = newSurah.startJuz > 0 ? newSurah.startJuz : calculatedJuz;
    });
  }

  Future<void> _onPageChanged(int page, List<SurahEntity> surahs) async {
    final navService = ref.read(quranNavigationServiceProvider);
    final target = await navService.getTargetByPage(page);
    final calculatedJuz = page <= 1 ? 1 : (((page - 2) ~/ 20) + 1).clamp(1, 30);

    if (target != null && mounted) {
      final matchedSurah = surahs.firstWhere(
        (s) => s.number == target.surahId,
        orElse: () => _selectedSurah ?? surahs.first,
      );
      setState(() {
        _currentPageNumber = page;
        _selectedSurah = matchedSurah;
        _currentAyahNumber = target.ayahNumber;
        _currentJuzNumber = calculatedJuz;
      });
    } else if (mounted) {
      setState(() {
        _currentPageNumber = page;
        _currentJuzNumber = calculatedJuz;
      });
    }
  }

  Future<void> _onJuzChanged(int juz, List<SurahEntity> surahs) async {
    final navService = ref.read(quranNavigationServiceProvider);
    final target = await navService.getTargetByJuz(juz);
    final juzStartPage = juz <= 1 ? 1 : (juz - 1) * 20 + 2;

    if (target != null && mounted) {
      final matchedSurah = surahs.firstWhere(
        (s) => s.number == target.surahId,
        orElse: () => _selectedSurah ?? surahs.first,
      );
      setState(() {
        _currentJuzNumber = juz;
        _selectedSurah = matchedSurah;
        _currentAyahNumber = target.ayahNumber;
        _currentPageNumber = juzStartPage;
      });
    } else if (mounted) {
      setState(() {
        _currentJuzNumber = juz;
        _currentPageNumber = juzStartPage;
      });
    }
  }

  void _handleConfirm(SurahEntity surah) {
    final target = AyahTarget(
      surahId: surah.number,
      ayahNumber: _currentAyahNumber,
    );
    if (mounted) {
      Navigator.of(context).pop(target);
    }
  }

  // --- Modals & Pickers ---

  Future<void> _openSurahPickerDialog(
    BuildContext context,
    List<SurahEntity> surahs,
    SurahEntity? activeSurah,
  ) async {
    final selected = await SurahPickerDialog.show(
      context,
      surahs: surahs,
      activeSurah: activeSurah,
    );

    if (selected != null && mounted) {
      _onSurahSelected(selected);
    }
  }

  void _promptDirectNumber({
    required BuildContext context,
    required String title,
    required int currentVal,
    required int minVal,
    required int maxVal,
    required ValueChanged<int> onSubmitted,
  }) {
    final textController = TextEditingController(text: currentVal.toPersianDigit());
    textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textController.text.length,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final primaryColor = theme.colorScheme.primary;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final raw = textController.text.trim().toEnglishDigit();
              if (raw.isEmpty) {
                setDialogState(() {
                  errorMessage = 'لطفاً یک عدد وارد کنید';
                });
                HapticFeedback.heavyImpact();
                return;
              }
              final val = int.tryParse(raw);
              if (val == null) {
                setDialogState(() {
                  errorMessage = 'لطفاً یک عدد معتبر وارد کنید';
                });
                HapticFeedback.heavyImpact();
                return;
              }
              if (val < minVal || val > maxVal) {
                setDialogState(() {
                  errorMessage =
                      'عدد باید بین ${minVal.toPersianDigit()} تا ${maxVal.toPersianDigit()} باشد.';
                });
                HapticFeedback.heavyImpact();
                return;
              }

              Navigator.pop(ctx);
              onSubmitted(val);
            }

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppModalHeader(
                        title: title,
                        onClose: () => Navigator.pop(ctx),
                        bottomSpacing: 12,
                      ),
                      TextField(
                        controller: textController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final converted = newValue.text.toPersianDigit();
                            return newValue.copyWith(
                              text: converted,
                              selection: newValue.selection,
                            );
                          }),
                        ],
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                        ),
                        onChanged: (text) {
                          final clean = text.trim().toEnglishDigit();
                          if (clean.isEmpty) {
                            if (errorMessage != null) {
                              setDialogState(() {
                                errorMessage = null;
                              });
                            }
                            return;
                          }
                          final val = int.tryParse(clean);
                          String? newError;
                          if (val == null) {
                            newError = 'لطفاً یک عدد معتبر وارد کنید';
                          } else if (val < minVal || val > maxVal) {
                            newError =
                                'عدد باید بین ${minVal.toPersianDigit()} تا ${maxVal.toPersianDigit()} باشد.';
                          }

                          if (newError != errorMessage) {
                            setDialogState(() {
                              errorMessage = newError;
                            });
                          }
                        },
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          hintText: '${minVal.toPersianDigit()} تا ${maxVal.toPersianDigit()}',
                          helperText: errorMessage == null
                              ? 'عدد بین ${minVal.toPersianDigit()} تا ${maxVal.toPersianDigit()} را وارد کنید'
                              : null,
                          helperStyle: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          errorText: errorMessage,
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : const Color(0xFFF5F3EE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: errorMessage != null
                                  ? Colors.redAccent
                                  : (isDark ? Colors.white12 : Colors.black12),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: errorMessage != null
                                  ? Colors.redAccent
                                  : primaryColor,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      16.vSpace,
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'انصراف',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          12.hSpace,
                          Expanded(
                            child: ElevatedButton(
                              onPressed: submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'تأیید',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

