import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:async';
import 'dart:ui';

import '../../../../common/widgets/app_snackbar.dart';
import '../../../../common/widgets/surah_picker_dialog.dart';
import '../widgets/quran_reader_app_bar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../../core/services/quran_navigation/domain/entities/ayah_target.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../../surah_list/domain/entities/surah_entity.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../application/controllers/quran_display_settings_controller.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../application/controllers/selected_ayah_action_provider.dart';
import '../../../mini_audio_player/presentation/widgets/mini_audio_player_bar.dart';
import '../widgets/audio_player_bottom_bar.dart';
import '../widgets/quran_info_bar.dart';
import '../widgets/quick_settings_drawer.dart';
import '../widgets/surah_ayah_page_view.dart';
import '../widgets/word_by_word_bottom_sheet.dart';
import '../../domain/entities/ayah_theme_entity.dart';
import '../../../bookmarks/application/controllers/bookmarks_controller.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../quran_home/application/controllers/continue_reading_controller.dart';

class QuranReaderScreen extends ConsumerStatefulWidget {
  final int surahId;
  final String surahName;
  final int? initialAyahNumber;
  final String? translationId;

  const QuranReaderScreen({
    super.key,
    required this.surahId,
    required this.surahName,
    this.initialAyahNumber,
    this.translationId,
  });

  @override
  ConsumerState<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends ConsumerState<QuranReaderScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  late final ContinueReadingController _continueReadingNotifier;
  late final ReaderControlsNotifier _readerControlsNotifier;

  // Full-screen mode state
  bool _isFullScreen = false;
  bool _isControlsVisible = true;
  bool _isAudioBarCollapsed = false;
  bool _isExitButtonVisible = false;
  Timer? _exitButtonFadeTimer;

  // Quick jump tracking
  int? _targetSurahId;
  int? _targetAyahNumber;

  static const Duration _exitButtonFadeDelay = Duration(milliseconds: 3500);

  @override
  void initState() {
    super.initState();
    _continueReadingNotifier = ref.read(continueReadingControllerProvider.notifier);
    _readerControlsNotifier = ref.read(readerControlsProvider.notifier);
    _pageController = PageController(initialPage: widget.surahId - 1);

    // Fetch ayahs when screen loads & ensure clean normal controls state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _readerControlsNotifier.reset();
      ref.read(quranReaderControllerProvider.notifier).fetchAyahs(widget.surahId);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _exitButtonFadeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    // Save reading progress when leaving screen
    _continueReadingNotifier.saveStateToStorage();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _continueReadingNotifier.saveStateToStorage();
    }
  }

  void _startExitButtonFadeTimer() {
    _exitButtonFadeTimer?.cancel();
    _exitButtonFadeTimer = Timer(_exitButtonFadeDelay, () {
      if (mounted && _isFullScreen) {
        setState(() {
          _isExitButtonVisible = false;
        });
      }
    });
  }

  void _syncProviderState() {
    ref.read(readerControlsProvider.notifier).updateState(
      isFullScreen: _isFullScreen,
      isControlsVisible: _isControlsVisible,
      isAudioBarCollapsed: _isAudioBarCollapsed,
    );
  }

  void _enterFullScreen() {
    // Immediately hide header & collapse audio player capsule upon entering full screen
    setState(() {
      _isFullScreen = true;
      _isControlsVisible = false;
      _isAudioBarCollapsed = true;
      _isExitButtonVisible = true;
    });
    ref.read(readerControlsProvider.notifier).enterFullScreen();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startExitButtonFadeTimer();
  }

  void _exitFullScreen() {
    _exitButtonFadeTimer?.cancel();
    setState(() {
      _isFullScreen = false;
      _isControlsVisible = true;
      _isAudioBarCollapsed = false;
      _isExitButtonVisible = false;
    });
    ref.read(readerControlsProvider.notifier).exitFullScreen();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void _toggleControls() {
    if (!_isFullScreen) return;
    final nextVisible = !_isControlsVisible;
    setState(() {
      _isControlsVisible = nextVisible;
      _isAudioBarCollapsed = !nextVisible;
      _isExitButtonVisible = true;
    });
    if (!nextVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    _syncProviderState();
    _startExitButtonFadeTimer();
  }

  void _onPageChanged(int pageIndex) {
    final newSurahId = pageIndex + 1;
    final activeSurahId = ref.read(quranReaderControllerProvider).currentSurahId;
    if (activeSurahId == newSurahId) return;

    ref.read(quranReaderControllerProvider.notifier).fetchAyahs(newSurahId);
    ref.read(selectedAyahActionProvider.notifier).clearSelection();
  }

  void _handleTargetSelected(AyahTarget target) {
    setState(() {
      _targetSurahId = target.surahId;
      _targetAyahNumber = target.ayahNumber;
    });

    final currentSurahId = ref.read(quranReaderControllerProvider).currentSurahId;
    if (target.surahId != currentSurahId) {
      ref.read(quranReaderControllerProvider.notifier).fetchAyahs(target.surahId);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(target.surahId - 1);
      }
    }

    ref.read(navigationTargetProvider.notifier).forceTarget(target);
  }

  String _getSurahName(WidgetRef ref, int surahId) {
    if (surahId >= 1 && surahId <= 114) {
      return 'سوره ${surahId.surahNameFa}';
    }
    final surahs = ref.watch(surahListControllerProvider.select((s) => s.surahs));
    if (surahs.isNotEmpty) {
      final found = surahs.firstWhere(
        (s) => s.number == surahId,
        orElse: () => SurahEntity(
          number: surahId,
          name: widget.surahName,
          englishName: '',
          englishNameTranslation: '',
          numberOfAyahs: 0,
          revelationType: '',
          startPage: 1,
          startJuz: 1,
        ),
      );
      return 'سوره ${found.nameFa}';
    }
    return widget.surahName;
  }

  // --- Gesture Zoom State ---
  final Map<int, Offset> _activePointers = {};
  double? _initialDistance;
  double? _initialArabicFontSize;
  double? _initialTranslationFontSize;

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length == 2) {
      final positions = _activePointers.values.toList();
      final distance = (positions[0] - positions[1]).distance;

      if (_initialDistance == null) {
        _initialDistance = distance;
        final settings = ref.read(quranDisplaySettingsControllerProvider);
        _initialArabicFontSize = settings.arabicFontSize;
        _initialTranslationFontSize = settings.translationFontSize;
      } else {
        final scale = distance / _initialDistance!;
        
        final newArabic = (_initialArabicFontSize! * scale).clamp(18.0, 42.0);
        final newTranslation = (_initialTranslationFontSize! * scale).clamp(12.0, 26.0);
        
        ref.read(quranDisplaySettingsControllerProvider.notifier)
            .updateArabicFontSize(newArabic);
        ref.read(quranDisplaySettingsControllerProvider.notifier)
            .updateTranslationFontSize(newTranslation);
      }
    }
  }

  void _onPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      if (_initialDistance != null) {
        // Only save to preferences if a pinch zoom actually happened
        ref.read(quranDisplaySettingsControllerProvider.notifier).saveSettingsIfChanged();
      }
      _initialDistance = null;
      _initialArabicFontSize = null;
      _initialTranslationFontSize = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to readerControlsProvider so taps on AyahItems correctly toggle screen controls
    ref.listen<ReaderControlsState>(readerControlsProvider, (previous, next) {
      if (next.isControlsVisible != _isControlsVisible ||
          next.isAudioBarCollapsed != _isAudioBarCollapsed ||
          next.isFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = next.isFullScreen;
          _isControlsVisible = next.isControlsVisible;
          _isAudioBarCollapsed = next.isAudioBarCollapsed;
          _isExitButtonVisible = next.isFullScreen;
        });
        if (!next.isControlsVisible) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else if (!next.isFullScreen) {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }
        if (next.isFullScreen) {
          _startExitButtonFadeTimer();
        } else {
          _exitButtonFadeTimer?.cancel();
        }
      }
    });

    final currentSurahId = ref.watch(
      quranReaderControllerProvider.select((s) => s.currentSurahId),
    );

    // Listen to reader errors
    ref.listen(quranReaderControllerProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
    });

    // Listen to audio errors – distinguish download-related messages
    ref.listen(quranAudioControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        final errorMessage = next.errorMessage!;
        final isDownloadRelated = errorMessage.contains('دانلود');
        final isTranslation = errorMessage.contains('ترجمه');

        if (isDownloadRelated) {
          AppSnackBar.showInfo(
            context,
            errorMessage,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: isTranslation ? 'دانلود ترجمه' : 'دانلود صوت',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                final targetSurahId = next.currentSurahId ?? widget.surahId;
                context.pushNamed(
                  audioDownloadManagerRoute,
                  queryParameters: {
                    'surahId': targetSurahId.toString(),
                    if (isTranslation) 'isTranslation': 'true',
                  },
                );
              },
            ),
          );
        } else {
          AppSnackBar.showError(context, errorMessage);
        }

        // Immediately reset error in state so subsequent taps will trigger ref.listen again
        ref.read(quranAudioControllerProvider.notifier).clearError();
      }
    });

    // Automatic page transition when audio moves to another surah
    ref.listen<int?>(
      quranAudioControllerProvider.select((s) => s.currentSurahId),
      (previous, nextSurahId) {
        if (nextSurahId != null && nextSurahId != currentSurahId) {
          final targetPageIndex = nextSurahId - 1;
          if (_pageController.hasClients && targetPageIndex >= 0 && targetPageIndex < 114) {
            _pageController.animateToPage(
              targetPageIndex,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      },
    );

    // Determine if audio is playing for a DIFFERENT surah
    final isAudioPlayingOtherSurah = ref.watch(
      quranAudioControllerProvider.select((s) =>
          s.currentSurahId != null &&
          s.currentSurahId != currentSurahId &&
          s.status != AudioStatus.stopped),
    );

    // OPTIMIZATION: Only rebuild the entire screen when entering/exiting selection mode.
    // The specific count changes are handled locally via a Consumer around the AppBar.
    final isSelectionMode = ref.watch(
      selectedAyahActionProvider.select((set) => set.isNotEmpty),
    );

    final currentSurahName = _getSurahName(ref, currentSurahId);

    // Controls state in full-screen mode
    final bool controlsHidden = _isFullScreen && !_isControlsVisible;
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double appBarHeight = topPadding + 60.0;

    final double infoBarHeight = 40.0;
    final double headerHeight = appBarHeight + infoBarHeight;

    final ayahThemeId = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.ayahThemeId),
    );
    final activeTheme = AyahThemePresets.getById(ayahThemeId);
    final scaffoldBgColor = activeTheme.evenColor;

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isSelectionMode) {
          ref.read(selectedAyahActionProvider.notifier).clearSelection();
          return;
        }
        if (didPop) {
          _exitButtonFadeTimer?.cancel();
          _isFullScreen = false;
          _isExitButtonVisible = false;
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          ref.read(readerControlsProvider.notifier).reset();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        extendBody: true,
        body: Stack(
          children: [
          // 1. Column containing Header (AppBar + InfoBar) and Bounded PageView (Expanded)
          Column(
            children: [
              // Top Header & QuranInfoBar (AnimatedContainer collapses height in full-screen)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                height: controlsHidden ? 0 : headerHeight,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    minHeight: 0,
                    maxHeight: headerHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: appBarHeight,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final selectedCount = ref.watch(
                                selectedAyahActionProvider.select((set) => set.length),
                              );
                              final selectedSet = ref.watch(selectedAyahActionProvider);
                              final continueReading = ref.watch(continueReadingControllerProvider);
                              final targetAyah = selectedSet.isNotEmpty
                                  ? selectedSet.first
                                  : (continueReading?.surahId == currentSurahId
                                      ? continueReading?.ayahNumber ?? 1
                                      : 1);
                              final isAyahBookmarked = ref.watch(
                                bookmarksControllerProvider.select(
                                  (list) => list.any(
                                    (b) =>
                                        b.surahId == currentSurahId &&
                                        b.ayahNumber == targetAyah,
                                  ),
                                ),
                              );

                              return QuranReaderAppBar(
                                surahName: currentSurahName,
                                surahNumber: currentSurahId,
                                isSelectionMode: isSelectionMode,
                                selectedCount: selectedCount,
                                isBookmarked: isAyahBookmarked,
                                onBackPressed: () {
                                  _exitButtonFadeTimer?.cancel();
                                  _isFullScreen = false;
                                  _isExitButtonVisible = false;
                                  SystemChrome.setEnabledSystemUIMode(
                                    SystemUiMode.manual,
                                    overlays: SystemUiOverlay.values,
                                  );
                                  ref.read(readerControlsProvider.notifier).reset();
                                  Navigator.of(context).maybePop();
                                },
                                onSurahTap: () async {
                                  final surahs = ref.read(surahListControllerProvider).surahs;
                                  final currentSurah = surahs.where((s) => s.number == currentSurahId).firstOrNull;
                                  final selected = await SurahPickerDialog.show(
                                    context,
                                    activeSurah: currentSurah,
                                    surahs: surahs,
                                  );
                                  if (selected != null && _pageController.hasClients) {
                                    _pageController.jumpToPage(selected.number - 1);
                                  }
                                },
                                onClearSelection: () {
                                  ref.read(selectedAyahActionProvider.notifier).clearSelection();
                                },
                            onCopySelected: () {
                              final allAyahs = ref.read(quranReaderControllerProvider).ayahs;
                              ref.read(selectedAyahActionProvider.notifier).copySelectedAyahs(
                                    context: context,
                                    ayahs: allAyahs,
                                    surahName: currentSurahName,
                                  );
                            },
                            onShareSelected: () {
                              final allAyahs = ref.read(quranReaderControllerProvider).ayahs;
                              ref.read(selectedAyahActionProvider.notifier).shareSelectedAyahs(
                                    context: context,
                                    ayahs: allAyahs,
                                    surahName: currentSurahName,
                                  );
                            },
                            onDictionarySelected: () {
                              final selectedSet = ref.read(selectedAyahActionProvider);
                              if (selectedSet.isNotEmpty) {
                                final firstAyahNum = selectedSet.first;
                                ref.read(selectedAyahActionProvider.notifier).clearSelection();
                                WordByWordBottomSheet.show(
                                  context,
                                  surahId: currentSurahId,
                                  surahName: currentSurahName,
                                  ayahNumber: firstAyahNum,
                                );
                              }
                            },
                             onBookmarkPressed: () async {
                               final currentSelected = ref.read(selectedAyahActionProvider);
                               final currentState = ref.read(continueReadingControllerProvider);
                               final ayahNum = currentSelected.isNotEmpty
                                   ? currentSelected.first
                                   : (currentState?.surahId == currentSurahId
                                       ? currentState?.ayahNumber ?? 1
                                       : 1);
                               final totalAyahs = (currentState?.surahId == currentSurahId)
                                   ? currentState?.totalAyahs ?? 0
                                   : 0;

                               final isAdded = await ref
                                   .read(bookmarksControllerProvider.notifier)
                                   .toggleBookmark(
                                     surahId: currentSurahId,
                                     surahName: currentSurahName,
                                     ayahNumber: ayahNum,
                                     totalAyahs: totalAyahs,
                                   );

                               HapticFeedback.lightImpact();
                               if (context.mounted) {
                                 if (isAdded) {
                                   AppSnackBar.showSuccess(
                                     context,
                                     'آیه ${ayahNum.toPersianDigit()} سوره $currentSurahName به نشانه‌ها افزوده شد.',
                                   );
                                 } else {
                                   AppSnackBar.showInfo(
                                     context,
                                     'نشانک آیه ${ayahNum.toPersianDigit()} سوره $currentSurahName حذف شد.',
                                     duration: const Duration(seconds: 2),
                                   );
                                 }
                               }
                             },
                             onMenuSelected: (value) {
                               if (value == 'fullscreen') {
                                 if (_isFullScreen) {
                                   _exitFullScreen();
                                 } else {
                                   _enterFullScreen();
                                 }
                               } else if (value == 'settings') {
                                 QuickSettingsDrawer.show(context);
                               } else if (value == 'toggle_brackets') {
                                 final current = ref.read(quranDisplaySettingsControllerProvider).removeTranslationBrackets;
                                 final notifier = ref.read(quranDisplaySettingsControllerProvider.notifier);
                                 notifier.recordInitialState();
                                 notifier.toggleRemoveTranslationBrackets(!current);
                                 notifier.saveSettingsIfChanged();
                               }
                             },
                             menuItemBuilder: (context) {
                               final removeBrackets = ref.watch(quranDisplaySettingsControllerProvider.select((s) => s.removeTranslationBrackets));
                               return [
                                 const PopupMenuItem<String>(
                                   value: 'settings',
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(CupertinoIcons.slider_horizontal_3, size: 18),
                                       SizedBox(width: 8),
                                       Text(
                                         'تنظیمات نمایش',
                                         style: TextStyle(
                                           fontFamily: AppTypography.fontFamily,
                                           fontSize: 13,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                                 PopupMenuItem<String>(
                                   value: 'toggle_brackets',
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(
                                         removeBrackets ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                         size: 18,
                                       ),
                                       const SizedBox(width: 8),
                                       Text(
                                         removeBrackets ? 'نمایش متن داخل پرانتز' : 'مخفی کردن متن داخل پرانتز',
                                         style: const TextStyle(
                                           fontFamily: AppTypography.fontFamily,
                                           fontSize: 13,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                                 PopupMenuItem<String>(
                                   value: 'fullscreen',
                                   child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(
                                         _isFullScreen ? CupertinoIcons.fullscreen_exit : CupertinoIcons.fullscreen,
                                         size: 18,
                                       ),
                                       const SizedBox(width: 8),
                                       Text(
                                         _isFullScreen ? 'خروج از تمام‌صفحه' : 'حالت تمام صفحه',
                                         style: const TextStyle(
                                           fontFamily: AppTypography.fontFamily,
                                           fontSize: 13,
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ];
                             },
                           );
                         },
                       ),
                        ),
                        QuranInfoBar(
                          onTargetSelected: _handleTargetSelected,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quran PageView (Bounded directly below QuranInfoBar — zero scroll under header!)
              Expanded(
                child: RepaintBoundary(
                  child: Listener(
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    onPointerCancel: _onPointerUp,
                    child: GestureDetector(
                      onTap: () {
                        if (_isFullScreen) {
                          _toggleControls();
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: 114,
                        onPageChanged: _onPageChanged,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, pageIndex) {
                          final pageSurahId = pageIndex + 1;
                          final isTargetPage = pageSurahId == currentSurahId ||
                              pageSurahId == _targetSurahId ||
                              (currentSurahId != widget.surahId &&
                                  pageSurahId == widget.surahId);
                          final initialAyahForPage = (pageSurahId == _targetSurahId)
                              ? _targetAyahNumber
                              : (pageSurahId == widget.surahId ? widget.initialAyahNumber : null);
                          return SurahAyahPageView(
                            key: ValueKey('surah_page_$pageSurahId'),
                            surahId: pageSurahId,
                            surahName: _getSurahName(ref, pageSurahId),
                            isCurrentPage: isTargetPage,
                            initialAyahNumber: initialAyahForPage,
                            translationId: widget.translationId,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. Bottom Audio Player Bar (Positioned at bottom, capsule slides behind disc)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RepaintBoundary(
              child: isAudioPlayingOtherSurah
                  ? const MiniAudioPlayerBar(includeBottomInset: true)
                  : AudioPlayerBottomBar(
                      surahId: currentSurahId,
                      isFullScreen: _isFullScreen,
                      isCollapsed: _isAudioBarCollapsed,
                      onToggleCollapse: () {
                        if (_isFullScreen) {
                          _toggleControls();
                        } else {
                          setState(() {
                            _isAudioBarCollapsed = !_isAudioBarCollapsed;
                          });
                          ref.read(readerControlsProvider.notifier).updateState(
                            isAudioBarCollapsed: _isAudioBarCollapsed,
                          );
                        }
                      },
                    ),
            ),
          ),

          // 4. Exit Full-Screen Button – Visible in fullscreen mode, auto-fades after delay
          if (_isFullScreen)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              top: controlsHidden
                  ? (topPadding > 0 ? topPadding + 10 : 16)
                  : headerHeight + 8,
              left: 12,
              child: IgnorePointer(
                ignoring: !_isExitButtonVisible,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  opacity: _isExitButtonVisible ? 1.0 : 0.0,
                  child: RepaintBoundary(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _exitFullScreen,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.fullscreen_exit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'خروج از تمام‌صفحه',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}
