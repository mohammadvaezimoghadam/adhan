import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/quran_theme_colors.dart';
import '../../../quran_reader/application/ayah_service.dart';
import '../../../quran_reader/domain/entities/ayah_entity.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../../surah_list/domain/entities/surah_entity.dart';
import '../../application/controllers/surah_tafsir_provider.dart';
import '../../application/controllers/tafsir_manager_controller.dart';
import '../../application/states/tafsir_manager_state.dart';
import '../../infrastructure/datasources/tafsir_catalog.dart';
import '../../../quran_reader/presentation/widgets/quran_ornamental_divider.dart';
import '../../../topic_studio/presentation/widgets/add_to_topic_bottom_sheet.dart';
import '../../../topic_studio/application/controllers/in_drawer_editor_controller.dart';
import '../../../topic_studio/domain/entities/topic_block.dart';
import '../../../topic_studio/presentation/ui/tafakor_editor_screen.dart';
import '../widgets/tafsir_manager_bottom_sheet.dart';

final tafsirAyahsProvider =
    FutureProvider.family<List<AyahEntity>, int>((ref, surahId) async {
  final service = ref.watch(ayahServiceProvider);
  final result = await service.getAyahsBySurah(surahId);
  return result.tryGetSuccess() ?? [];
});

/// Dedicated Screen for Reading Ayah-by-Ayah Quran Exegesis (Tafsir).
/// Strictly adheres to the app's Mint Green theme, typography, and card ergonomics.
class TafsirReaderScreen extends ConsumerStatefulWidget {
  final int surahId;
  final String surahName;
  final String? tafsirId;
  final int? initialAyahNumber;

  const TafsirReaderScreen({
    super.key,
    required this.surahId,
    required this.surahName,
    this.tafsirId,
    this.initialAyahNumber,
  });

  @override
  ConsumerState<TafsirReaderScreen> createState() => _TafsirReaderScreenState();
}

class _TafsirReaderScreenState extends ConsumerState<TafsirReaderScreen> {
  late int _currentSurahId;
  late String _currentSurahName;
  late String _currentTafsirId;
  double _fontSize = 15.0;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final Map<int, TextSelection> _tafsirSelections = {};
  int _currentFocusedAyahNumber = 1;

  @override
  void initState() {
    super.initState();
    _currentSurahId = widget.surahId;
    _currentSurahName = widget.surahId.surahNameFa;
    _currentTafsirId = widget.tafsirId ?? 'tafsir.nemouneh';
    _currentFocusedAyahNumber = widget.initialAyahNumber ?? 1;
  }

  void _changeSurah(int newSurahId, [String? newSurahName]) {
    if (newSurahId < 1 || newSurahId > 114) return;
    setState(() {
      _currentSurahId = newSurahId;
      _currentSurahName = newSurahName ?? newSurahId.surahNameFa;
      _currentFocusedAyahNumber = 1;
    });
    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: 0);
    }
  }

  void _scrollToNextAyah(int totalAyahs) {
    HapticFeedback.lightImpact();
    if (!_itemScrollController.isAttached) return;

    final currentAyah = _getCurrentTopAyah(totalAyahs);
    if (currentAyah < totalAyahs) {
      final targetAyah = currentAyah + 1;
      _currentFocusedAyahNumber = targetAyah;
      _itemScrollController.scrollTo(
        index: targetAyah,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollToPrevAyah(int totalAyahs) {
    HapticFeedback.lightImpact();
    if (!_itemScrollController.isAttached) return;

    final currentAyah = _getCurrentTopAyah(totalAyahs);
    if (currentAyah > 1) {
      final targetAyah = currentAyah - 1;
      _currentFocusedAyahNumber = targetAyah;
      _itemScrollController.scrollTo(
        index: targetAyah,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _currentFocusedAyahNumber = 1;
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  int _getCurrentTopAyah(int totalAyahs) {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return _currentFocusedAyahNumber;

    final visibleAyahs = positions
        .where((p) => p.index >= 1 && p.index <= totalAyahs)
        .toList();

    if (visibleAyahs.isEmpty) {
      return _currentFocusedAyahNumber;
    }

    visibleAyahs.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));

    final topItem = visibleAyahs.firstWhere(
      (p) => p.itemTrailingEdge > 0.08,
      orElse: () => visibleAyahs.first,
    );

    return topItem.index;
  }

  bool _isAtFirstAyah(Iterable<ItemPosition> positions, int totalAyahs) {
    if (positions.isEmpty) return _currentFocusedAyahNumber <= 1;
    final visibleAyahs = positions.where((p) => p.index >= 1 && p.index <= totalAyahs).toList();
    if (visibleAyahs.isEmpty) return _currentFocusedAyahNumber <= 1;
    visibleAyahs.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final topAyah = visibleAyahs.firstWhere(
      (p) => p.itemTrailingEdge > 0.08,
      orElse: () => visibleAyahs.first,
    );
    return topAyah.index <= 1;
  }

  bool _isAtLastAyah(Iterable<ItemPosition> positions, int totalAyahs) {
    if (positions.isEmpty) return false;
    final footerPos = positions.where((p) => p.index == totalAyahs + 1).firstOrNull;
    if (footerPos != null && footerPos.itemLeadingEdge <= 1.0) {
      return true;
    }
    final lastAyahPos = positions.where((p) => p.index == totalAyahs).firstOrNull;
    if (lastAyahPos != null && lastAyahPos.itemTrailingEdge <= 1.08) {
      return true;
    }
    final visibleAyahs = positions.where((p) => p.index >= 1 && p.index <= totalAyahs).toList();
    if (visibleAyahs.isNotEmpty) {
      visibleAyahs.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
      return visibleAyahs.last.index == totalAyahs && visibleAyahs.first.index == totalAyahs;
    }
    return false;
  }

  void _showFontSizeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = context.colorScheme;
        final isDark = context.isDark;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  14.vSpace,
                  Text(
                    'اندازه قلم تفسیر: ${_fontSize.toInt().toPersianDigit()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  16.vSpace,
                  Row(
                    children: [
                      const Text(
                        'A-',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorScheme.primary,
                            thumbColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _fontSize,
                            min: 12.0,
                            max: 24.0,
                            divisions: 12,
                            onChanged: (val) {
                              setSheetState(() => _fontSize = val);
                              setState(() => _fontSize = val);
                            },
                          ),
                        ),
                      ),
                      const Text(
                        'A+',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    ref.listen<AsyncValue<TafsirManagerState>>(
      tafsirManagerControllerProvider,
      (previous, next) {
        final error = next.value?.errorMessage;
        final prevError = previous?.value?.errorMessage;
        if (error != null && error.isNotEmpty && error != prevError) {
          AppSnackBar.showError(context, error);
          ref.read(tafsirManagerControllerProvider.notifier).clearErrorMessage();
        }
      },
    );

    final tafsirAsync = ref.watch(tafsirManagerControllerProvider);
    final tafsirState = tafsirAsync.value;
    final effectiveTafsirId = widget.tafsirId ?? tafsirState?.activeTafsirId ?? _currentTafsirId;
    final tafsirs = tafsirState?.tafsirs ?? [];
    final activeTafsir = tafsirs.firstWhere(
      (t) => t.id == effectiveTafsirId,
      orElse: () => TafsirCatalog.allTafsirs.firstWhere(
        (t) => t.id == effectiveTafsirId,
        orElse: () => TafsirCatalog.allTafsirs.first,
      ),
    );

    final ayahsAsync = ref.watch(tafsirAyahsProvider(_currentSurahId));
    final tafsirMapAsync = ref.watch(
      surahTafsirProvider((surahNumber: _currentSurahId, tafsirId: effectiveTafsirId)),
    );

    final isDownloading = tafsirState?.downloadProgress.containsKey(effectiveTafsirId) ?? false;
    final downloadProgress = tafsirState?.downloadProgress[effectiveTafsirId];

    final surahList = ref.watch(surahListControllerProvider).surahs;

    final hasPrev = _currentSurahId > 1;
    final hasNext = _currentSurahId < 114;

    SurahEntity? prevSurah;
    SurahEntity? nextSurah;

    if (hasPrev && surahList.isNotEmpty && _currentSurahId - 2 >= 0 && _currentSurahId - 2 < surahList.length) {
      prevSurah = surahList[_currentSurahId - 2];
    }
    if (hasNext && surahList.isNotEmpty && _currentSurahId < surahList.length) {
      nextSurah = surahList[_currentSurahId];
    }

    final prevSurahNameFa = prevSurah?.nameFa ?? (_currentSurahId - 1).surahNameFa;
    final nextSurahNameFa = nextSurah?.nameFa ?? (_currentSurahId + 1).surahNameFa;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(62.0),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 4,
              left: 10.0,
              right: 10.0,
              bottom: 4.0,
            ),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: colors.cardBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  tooltip: 'بازگشت',
                  icon: Icon(
                    CupertinoIcons.chevron_forward,
                    size: 22,
                    color: colorScheme.onSurface,
                  ),
                  splashRadius: 20,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.goNamed(quranHomeRoute);
                    }
                  },
                ),

                // Surah Name & Tafsir Name
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'سوره ${_currentSurahId.surahNameFa}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      2.vSpace,
                      Text(
                        '${activeTafsir.name} • ${activeTafsir.authorName}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Font Size Settings Button
                IconButton(
                  tooltip: 'اندازه قلم',
                  icon: Icon(CupertinoIcons.textformat_size, size: 20, color: colorScheme.onSurface),
                  splashRadius: 20,
                  onPressed: _showFontSizeDialog,
                ),

                // Switch Tafsir Bottom Sheet Button
                IconButton(
                  tooltip: 'تغییر تفسیر',
                  icon: Icon(CupertinoIcons.layers, size: 20, color: colorScheme.onSurface),
                  splashRadius: 20,
                  onPressed: () {
                    TafsirManagerBottomSheet.show(context);
                  },
                ),
              ],
            ),
          ),
        ),
        body: Builder(
          builder: (context) {
            // 0. If tafsirManagerControllerProvider is still initially loading and we have no state:
            if (tafsirAsync.isLoading && tafsirState == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // 1. Check if the Tafsir is not downloaded
            if (!activeTafsir.isDownloaded && !isDownloading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          CupertinoIcons.cloud_download,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                      ),
                      18.vSpace,
                      Text(
                        'تفسیر «${activeTafsir.name}» هنوز دریافت نشده است.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      8.vSpace,
                      Text(
                        'برای مشاهده تفسیر سوره $_currentSurahName، کافیست یک‌بار این تفسیر را به رایگان دانلود نمایید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      20.vSpace,
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(tafsirManagerControllerProvider.notifier)
                              .downloadTafsir(activeTafsir);
                        },
                        icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
                        label: Text(
                          'دانلود ${activeTafsir.name}',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 2. Check if currently downloading
            if (isDownloading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        value: (downloadProgress != null && downloadProgress > 0)
                            ? downloadProgress
                            : null,
                        strokeWidth: 3.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    18.vSpace,
                    Text(
                      'در حال دانلود ${activeTafsir.name}...',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    8.vSpace,
                    Text(
                      downloadProgress != null
                          ? '${(downloadProgress * 100).toInt().toPersianDigit()}٪ دریافت شده'
                          : 'لطفاً کمی صبر کنید...',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 3. Render Ayahs with Tafsir
            if (ayahsAsync.isLoading || tafsirMapAsync.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (ayahsAsync.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 44,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                      12.vSpace,
                      Text(
                        'خطا در بارگزاری متن آیات',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      6.vSpace,
                      Text(
                        'امکان دسترسی به اطلاعات آیات این سوره میسر نشد. لطفاً دوباره تلاش نمایید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      16.vSpace,
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => ref.invalidate(tafsirAyahsProvider(_currentSurahId)),
                        icon: const Icon(CupertinoIcons.refresh, size: 16),
                        label: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (tafsirMapAsync.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 44,
                        color: colorScheme.error.withValues(alpha: 0.8),
                      ),
                      12.vSpace,
                      Text(
                        'خطا در دریافت متن تفسیر',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      6.vSpace,
                      Text(
                        'امکان بازخوانی تفسیر این سوره میسر نشد. لطفاً اتصال را بررسی و مجدداً تلاش کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      16.vSpace,
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => ref.invalidate(
                          surahTafsirProvider((surahNumber: _currentSurahId, tafsirId: effectiveTafsirId)),
                        ),
                        icon: const Icon(CupertinoIcons.refresh, size: 16),
                        label: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final ayahs = ayahsAsync.value ?? [];
            final tafsirMap = tafsirMapAsync.value ?? {};

            if (ayahs.isEmpty) {
              return const Center(child: Text('آیه‌ای یافت نشد.'));
            }

            final targetIndex = (_currentSurahId == widget.surahId &&
                    widget.initialAyahNumber != null &&
                    widget.initialAyahNumber! >= 1 &&
                    widget.initialAyahNumber! <= ayahs.length)
                ? widget.initialAyahNumber!
                : 0;

            return Stack(
              children: [
                ScrollablePositionedList.builder(
                  key: ValueKey('tafsir_${_currentSurahId}_$effectiveTafsirId'),
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  initialScrollIndex: targetIndex,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
                  itemCount: ayahs.length + 2, // 0: Surah Header, 1..n: Ayahs, n+1: Navigation Footer
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Surah Top Header
                      return _buildSurahTopHeader(
                        context: context,
                        ayahCount: ayahs.length,
                        isDark: isDark,
                        colors: colors,
                        colorScheme: colorScheme,
                      );
                    }

                    if (index == ayahs.length + 1) {
                      // Surah Footer Navigation
                      return _buildSurahNavigationFooter(
                        context: context,
                        surahs: surahList,
                        currentSurahId: _currentSurahId,
                      );
                    }

                    final ayahIndex = index - 1;
                    final ayah = ayahs[ayahIndex];
                    final tafsirText = tafsirMap[ayah.ayahNumber];
                    final isLastAyah = ayahIndex == ayahs.length - 1;

                    return _buildAyahTafsirItem(
                      context: context,
                      ayah: ayah,
                      tafsirText: tafsirText,
                      isDark: isDark,
                      colors: colors,
                      colorScheme: colorScheme,
                      isLast: isLastAyah,
                    );
                  },
                ),

                // Floating Ayah & Surah Navigation Buttons (Bottom Right, Colorless & Simple, Dynamic Width)
                Positioned(
                  right: 18,
                  bottom: 24,
                  child: ValueListenableBuilder<Iterable<ItemPosition>>(
                    valueListenable: _itemPositionsListener.itemPositions,
                    builder: (context, positions, _) {
                      final isFirst = _isAtFirstAyah(positions, ayahs.length);
                      final isLast = _isAtLastAyah(positions, ayahs.length);

                      final showPrevSurah = isFirst && hasPrev;
                      final showNextSurah = isLast && hasNext;

                      final prevLabel = showPrevSurah
                          ? 'سوره قبلی ($prevSurahNameFa)'
                          : 'قبلی';
                      final nextLabel = showNextSurah
                          ? 'سوره بعدی ($nextSurahNameFa)'
                          : 'بعدی';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Previous Button (Ayah or Surah)
                          _buildFloatingAyahNavButton(
                            context: context,
                            label: prevLabel,
                            isExpanded: showPrevSurah,
                            tooltip: showPrevSurah
                                ? 'سوره قبلی ($prevSurahNameFa)'
                                : 'آیه قبلی',
                            isDark: isDark,
                            colorScheme: colorScheme,
                            onTap: () {
                              if (showPrevSurah) {
                                HapticFeedback.lightImpact();
                                _changeSurah(
                                  _currentSurahId - 1,
                                  prevSurah?.name ?? prevSurahNameFa,
                                );
                              } else {
                                _scrollToPrevAyah(ayahs.length);
                              }
                            },
                          ),
                          8.vSpace,
                          // Next Button (Ayah or Surah)
                          _buildFloatingAyahNavButton(
                            context: context,
                            label: nextLabel,
                            isExpanded: showNextSurah,
                            tooltip: showNextSurah
                                ? 'سوره بعدی ($nextSurahNameFa)'
                                : 'آیه بعدی',
                            isDark: isDark,
                            colorScheme: colorScheme,
                            onTap: () {
                              if (showNextSurah) {
                                HapticFeedback.lightImpact();
                                _changeSurah(
                                  _currentSurahId + 1,
                                  nextSurah?.name ?? nextSurahNameFa,
                                );
                              } else {
                                _scrollToNextAyah(ayahs.length);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSurahTopHeader({
    required BuildContext context,
    required int ayahCount,
    required bool isDark,
    required QuranThemeColors colors,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Text(
            'سوره ${_currentSurahId.surahNameFa}',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          4.vSpace,
          Text(
            '${ayahCount.toPersianDigit()} آیه',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          14.vSpace,
          QuranOrnamentalDivider(
            color: colors.goldAccent.withValues(alpha: isDark ? 0.4 : 0.3),
            height: 26,
          ),
        ],
      ),
    );
  }

  String _formatTafsirDisplayText(String raw) {
    var t = raw.trim();
    t = t.replaceAll(RegExp(r'```[a-zA-Z]*'), '');
    t = t.replaceAll(RegExp(r'#{1,6}\s*'), '\n• ');
    t = t.replaceAll('**', '');
    t = t.replaceAll('****', '');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

  Widget _buildAyahTafsirItem({
    required BuildContext context,
    required AyahEntity ayah,
    required String? tafsirText,
    required bool isDark,
    required QuranThemeColors colors,
    required ColorScheme colorScheme,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Ayah Metadata (Minimal vertical accent mark + Ayah number)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Minimal vertical accent mark + Ayah number
                Container(
                  width: 3.5,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                6.hSpace,
                Text(
                  'آیه ${ayah.ayahNumber.toPersianDigit()}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          6.vSpace,

          // 2. Arabic Quranic Verse (Solid distinct background spanning full screen width edge-to-edge)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E252B) : const Color(0xFFEFECE6),
            ),
            child: SelectableText(
              ayah.arabicText,
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 22,
                height: 2.15,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
              ),
              contextMenuBuilder: (context, editableTextState) {
                final List<ContextMenuButtonItem> buttonItems = [];

                // 1. Add Ayah to Topic Studio
                buttonItems.add(
                  ContextMenuButtonItem(
                    label: 'افزودن آیه به دفتر تفکر',
                    onPressed: () {
                      editableTextState.hideToolbar();
                      AddToTopicBottomSheet.show(
                        context,
                        surahId: _currentSurahId,
                        surahName: _currentSurahName,
                        ayahNumber: ayah.ayahNumber,
                        arabicText: ayah.arabicText,
                      );
                    },
                  ),
                );

                // 2. Filter native buttons: only clean Persian 'کپی' and 'انتخاب همه'
                for (final item in editableTextState.contextMenuButtonItems) {
                  if (item.type == ContextMenuButtonType.copy) {
                    buttonItems.add(
                      ContextMenuButtonItem(
                        onPressed: item.onPressed,
                        type: ContextMenuButtonType.copy,
                        label: 'کپی',
                      ),
                    );
                  } else if (item.type == ContextMenuButtonType.selectAll) {
                    buttonItems.add(
                      ContextMenuButtonItem(
                        onPressed: item.onPressed,
                        type: ContextMenuButtonType.selectAll,
                        label: 'انتخاب همه',
                      ),
                    );
                  }
                }

                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: buttonItems,
                );
              },
            ),
          ),

          14.vSpace,

          // 3. Tafsir Text (Pure readable typography with BNazanin font, bold for higher legibility)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SelectableText(
              (tafsirText != null && tafsirText.trim().isNotEmpty)
                  ? _formatTafsirDisplayText(tafsirText)
                  : 'برای این آیه توضیحات تفسیری ثبت نشده است.',
              style: TextStyle(
                fontFamily: 'BNazanin',
                fontSize: _fontSize,
                height: 1.95,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              onSelectionChanged: (selection, cause) {
                _tafsirSelections[ayah.ayahNumber] = selection;
              },
              contextMenuBuilder: (context, editableTextState) {
                final List<ContextMenuButtonItem> buttonItems = [];
                final formattedTafsir = (tafsirText != null && tafsirText.trim().isNotEmpty)
                    ? _formatTafsirDisplayText(tafsirText)
                    : '';

                // 1. Add Selection to Topic Studio
                buttonItems.add(
                  ContextMenuButtonItem(
                    label: 'افزودن گزیده به دفتر تفکر',
                    onPressed: () {
                      String textToSend = '';

                      // 1. Try tracked live selection from onSelectionChanged
                      final savedSel = _tafsirSelections[ayah.ayahNumber];
                      if (savedSel != null && !savedSel.isCollapsed && formattedTafsir.isNotEmpty) {
                        final start = savedSel.start.clamp(0, formattedTafsir.length);
                        final end = savedSel.end.clamp(0, formattedTafsir.length);
                        if (start < end) {
                          textToSend = formattedTafsir.substring(start, end).trim();
                        }
                      }

                      // 2. Try current live selection from editableTextState
                      if (textToSend.isEmpty) {
                        final val = editableTextState.textEditingValue;
                        final sel = val.selection;
                        if (sel.isValid && !sel.isCollapsed) {
                          final start = sel.start.clamp(0, val.text.length);
                          final end = sel.end.clamp(0, val.text.length);
                          if (start < end) {
                            textToSend = val.text.substring(start, end).trim();
                          }
                        }
                      }

                      // 3. Fallback
                      if (textToSend.isEmpty) {
                        textToSend = editableTextState
                            .textEditingValue
                            .selection
                            .textInside(editableTextState.textEditingValue.text)
                            .trim();
                      }

                      editableTextState.hideToolbar();

                      if (textToSend.isEmpty) return;

                      AddToTopicBottomSheet.show(
                        context,
                        surahId: _currentSurahId,
                        surahName: _currentSurahName,
                        ayahNumber: ayah.ayahNumber,
                        tafsirText: textToSend,
                        sourceTitle: 'تفسیر',
                      );
                    },
                  ),
                );

                // 1.2 Send Selection directly to Tafakor Platform
                buttonItems.add(
                  ContextMenuButtonItem(
                    label: 'ارسال گزیده به پلتفرم تفکر',
                    onPressed: () {
                      String textToSend = '';
                      final savedSel = _tafsirSelections[ayah.ayahNumber];
                      if (savedSel != null && !savedSel.isCollapsed && formattedTafsir.isNotEmpty) {
                        final start = savedSel.start.clamp(0, formattedTafsir.length);
                        final end = savedSel.end.clamp(0, formattedTafsir.length);
                        if (start < end) {
                          textToSend = formattedTafsir.substring(start, end).trim();
                        }
                      }
                      if (textToSend.isEmpty) {
                        final val = editableTextState.textEditingValue;
                        final sel = val.selection;
                        if (sel.isValid && !sel.isCollapsed) {
                          final start = sel.start.clamp(0, val.text.length);
                          final end = sel.end.clamp(0, val.text.length);
                          if (start < end) {
                            textToSend = val.text.substring(start, end).trim();
                          }
                        }
                      }
                      if (textToSend.isEmpty) {
                        textToSend = editableTextState
                            .textEditingValue
                            .selection
                            .textInside(editableTextState.textEditingValue.text)
                            .trim();
                      }
                      editableTextState.hideToolbar();
                      if (textToSend.isEmpty) return;

                      HapticFeedback.lightImpact();
                      final blocks = [
                        TopicBlock.create(
                          type: TopicBlockType.ayah,
                          content: ayah.arabicText,
                          surahId: _currentSurahId,
                          surahName: _currentSurahName,
                          ayahNumber: ayah.ayahNumber,
                        ),
                        TopicBlock.create(
                          type: TopicBlockType.tafsir,
                          content: textToSend,
                          surahId: _currentSurahId,
                          surahName: _currentSurahName,
                          ayahNumber: ayah.ayahNumber,
                          sourceTitle: 'تفسیر',
                        ),
                      ];
                      ref
                          .read(inDrawerEditorControllerProvider.notifier)
                          .setBlocks(blocks);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TafakorEditorScreen(),
                        ),
                      );
                    },
                  ),
                );

                // 2. Filter native buttons: only clean Persian 'کپی' and 'انتخاب همه'
                for (final item in editableTextState.contextMenuButtonItems) {
                  if (item.type == ContextMenuButtonType.copy) {
                    buttonItems.add(
                      ContextMenuButtonItem(
                        onPressed: item.onPressed,
                        type: ContextMenuButtonType.copy,
                        label: 'کپی',
                      ),
                    );
                  } else if (item.type == ContextMenuButtonType.selectAll) {
                    buttonItems.add(
                      ContextMenuButtonItem(
                        onPressed: item.onPressed,
                        type: ContextMenuButtonType.selectAll,
                        label: 'انتخاب همه',
                      ),
                    );
                  }
                }

                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: buttonItems,
                );
              },
            ),
          ),

          if (tafsirText != null && tafsirText.trim().isNotEmpty) ...[
            6.vSpace,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white60 : Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(CupertinoIcons.square_pencil, size: 14),
                    label: const Text(
                      'افزودن به موضوعات',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      AddToTopicBottomSheet.show(
                        context,
                        surahId: _currentSurahId,
                        surahName: _currentSurahName,
                        ayahNumber: ayah.ayahNumber,
                        tafsirText: _formatTafsirDisplayText(tafsirText),
                        sourceTitle: 'تفسیر',
                      );
                    },
                  ),
                  8.hSpace,
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(CupertinoIcons.paperplane, size: 14),
                    label: const Text(
                      'ارسال به پلتفرم تفکر',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final blocks = [
                        TopicBlock.create(
                          type: TopicBlockType.ayah,
                          content: ayah.arabicText,
                          surahId: _currentSurahId,
                          surahName: _currentSurahName,
                          ayahNumber: ayah.ayahNumber,
                        ),
                        TopicBlock.create(
                          type: TopicBlockType.tafsir,
                          content: _formatTafsirDisplayText(tafsirText),
                          surahId: _currentSurahId,
                          surahName: _currentSurahName,
                          ayahNumber: ayah.ayahNumber,
                          sourceTitle: 'تفسیر',
                        ),
                      ];
                      ref
                          .read(inDrawerEditorControllerProvider.notifier)
                          .setBlocks(blocks);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TafakorEditorScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          14.vSpace,

          // 4. Divider between Ayahs (Islamic Ornamental Divider)
          if (!isLast)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: QuranOrnamentalDivider(
                color: colors.goldAccent.withValues(alpha: isDark ? 0.35 : 0.25),
                height: 24,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSurahNavigationFooter({
    required BuildContext context,
    required List<SurahEntity> surahs,
    required int currentSurahId,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPrev = currentSurahId > 1;
    final hasNext = currentSurahId < 114;

    SurahEntity? prevSurah;
    SurahEntity? nextSurah;

    if (hasPrev && surahs.isNotEmpty && currentSurahId - 2 >= 0 && currentSurahId - 2 < surahs.length) {
      prevSurah = surahs[currentSurahId - 2];
    }
    if (hasNext && surahs.isNotEmpty && currentSurahId < surahs.length) {
      nextSurah = surahs[currentSurahId];
    }

    final prevSurahNameFa = prevSurah?.nameFa ?? (currentSurahId - 1).surahNameFa;
    final nextSurahNameFa = nextSurah?.nameFa ?? (currentSurahId + 1).surahNameFa;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Row(
        children: [
          // Previous Surah Button
          if (hasPrev)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _changeSurah(
                    currentSurahId - 1,
                    prevSurah?.name ?? prevSurahNameFa,
                  );
                },
                icon: const Icon(CupertinoIcons.chevron_forward, size: 16),
                label: Text(
                  'سوره قبلی ($prevSurahNameFa)',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          12.hSpace,

          // Next Surah Button (Colorless / Uncolored style)
          if (hasNext)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _changeSurah(
                    currentSurahId + 1,
                    nextSurah?.name ?? nextSurahNameFa,
                  );
                },
                label: Text(
                  'سوره بعدی ($nextSurahNameFa)',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(CupertinoIcons.chevron_back, size: 16),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFloatingAyahNavButton({
    required BuildContext context,
    required String label,
    required bool isExpanded,
    required String tooltip,
    required bool isDark,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 46,
            constraints: const BoxConstraints(minWidth: 46),
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 14.0 : 8.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: isDark
                  ? const Color(0xFF23272B).withValues(alpha: 0.94)
                  : Colors.white.withValues(alpha: 0.96),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
                width: 0.8,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.88),
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
