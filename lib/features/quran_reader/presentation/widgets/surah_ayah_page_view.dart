import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../../core/services/quran_navigation/domain/entities/ayah_target.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../application/controllers/quran_display_settings_controller.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../domain/entities/ayah_entity.dart';
import '../../domain/entities/ayah_theme_entity.dart';
import '../../../quran_home/application/controllers/continue_reading_controller.dart';
import 'ayah_list_item.dart';

class SurahAyahPageView extends ConsumerStatefulWidget {
  final int surahId;
  final String surahName;
  final bool isCurrentPage;
  final int? initialAyahNumber;
  final String? translationId;

  const SurahAyahPageView({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.isCurrentPage,
    this.initialAyahNumber,
    this.translationId,
  });

  @override
  ConsumerState<SurahAyahPageView> createState() => _SurahAyahPageViewState();
}

class _SurahAyahPageViewState extends ConsumerState<SurahAyahPageView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  bool _hasScrolledToInitialAyah = false;
  bool _hasCompletedInitialScroll = false;

  @override
  void didUpdateWidget(SurahAyahPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAyahNumber != null &&
        widget.initialAyahNumber != oldWidget.initialAyahNumber) {
      _hasScrolledToInitialAyah = false;
      _hasCompletedInitialScroll = false;
      _scrollToAyah(widget.initialAyahNumber!);
    }
  }

  void _scrollToAyah(int ayahNumber, {bool highlight = true}) {
    void attemptScroll([int attempt = 0]) {
      if (!mounted) return;
      final state = ref.read(quranReaderControllerProvider);
      final ayahs = state.ayahs;

      // If ayahs are loading or not yet available for this surah, retry
      if (state.isLoading || ayahs.isEmpty || state.currentSurahId != widget.surahId) {
        if (attempt < 25) {
          Future.delayed(Duration(milliseconds: 50 + (attempt * 20)), () {
            attemptScroll(attempt + 1);
          });
        }
        return;
      }

      final targetIndex = ayahs.indexWhere((a) => a.ayahNumber == ayahNumber);
      if (targetIndex == -1) return;

      if (highlight) {
        ref.read(activeAyahProvider.notifier).setActiveAyah(ayahNumber);
      }

      final hasPositions = _itemPositionsListener.itemPositions.value.isNotEmpty;
      if (_itemScrollController.isAttached && hasPositions) {
        try {
          _itemScrollController.scrollTo(
            index: targetIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            alignment: 0.04,
          );
          return;
        } catch (_) {}
      }

      if (attempt < 25) {
        Future.delayed(Duration(milliseconds: 50 + (attempt * 20)), () {
          attemptScroll(attempt + 1);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      attemptScroll();
    });
  }

  void _scrollToInitialAyahIfNeeded(List<AyahEntity> ayahs) {
    if (_hasScrolledToInitialAyah) return;
    final targetAyah = widget.initialAyahNumber;
    if (targetAyah == null || ayahs.isEmpty) return;

    final targetIndex = ayahs.indexWhere((a) => a.ayahNumber == targetAyah);
    if (targetIndex == -1) return;

    _hasScrolledToInitialAyah = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audioState = ref.read(quranAudioControllerProvider);
      final isPlayingOther = audioState.status != AudioStatus.stopped &&
          audioState.status != AudioStatus.initial &&
          audioState.currentSurahId != null &&
          audioState.currentSurahId != widget.surahId;
      if (!isPlayingOther) {
        ref.read(activeAyahProvider.notifier).setActiveAyah(targetAyah);
      }

      void attemptScroll([int attempt = 0]) {
        if (!mounted) return;
        final hasPositions = _itemPositionsListener.itemPositions.value.isNotEmpty;
        if (_itemScrollController.isAttached && hasPositions) {
          try {
            _hasCompletedInitialScroll = true;
            if (targetIndex > 0) {
              _itemScrollController.scrollTo(
                index: targetIndex,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                alignment: 0.05,
              );
            }
          } catch (_) {}
        } else if (attempt < 15) {
          Future.delayed(Duration(milliseconds: 60 + (attempt * 25)), () {
            attemptScroll(attempt + 1);
          });
        }
      }

      // Small delay to allow the layout to settle before programmatic scroll
      Future.delayed(const Duration(milliseconds: 100), () {
        attemptScroll();
      });
    });
  }

  int _getInitialScrollIndex(List<dynamic> ayahs) {
    int? targetAyah = widget.initialAyahNumber;
    final navTarget = ref.read(navigationTargetProvider);
    if (navTarget != null && navTarget.surahId == widget.surahId) {
      targetAyah = navTarget.ayahNumber;
    }
    if (targetAyah == null) {
      final audioState = ref.read(quranAudioControllerProvider);
      if (audioState.currentSurahId == widget.surahId) {
        targetAyah = audioState.currentAyahNumber;
      }
    }
    if (targetAyah != null) {
      final index = ayahs.indexWhere((a) => a.ayahNumber == targetAyah);
      if (index != -1) {
        return index;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCurrentPage) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // Register active ItemPositionsListener for QuranInfoBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(activeItemPositionsListenerProvider) != _itemPositionsListener) {
        ref.read(activeItemPositionsListenerProvider.notifier).setListener(_itemPositionsListener);
      }
    });

    final state = ref.watch(quranReaderControllerProvider);
    final ayahThemeId = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.ayahThemeId),
    );
    final activeTheme = AyahThemePresets.getById(ayahThemeId);

    if (state.isLoading) {
      return ColoredBox(
        color: activeTheme.evenColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null && state.ayahs.isEmpty) {
      return ColoredBox(
        color: activeTheme.evenColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConstants.ayahLoadError,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(quranReaderControllerProvider.notifier).retry(),
                child: const Text(AppConstants.retryButtonLabel),
              ),
            ],
          ),
        ),
      );
    }

    if (state.ayahs.isEmpty) {
      return ColoredBox(
        color: activeTheme.evenColor,
        child: const Center(child: Text(AppConstants.noAyahFound)),
      );
    }

    // Check if there is a pending navigation target for this surah
    final pendingTarget = ref.read(navigationTargetProvider);
    if (pendingTarget != null && pendingTarget.surahId == widget.surahId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToAyah(pendingTarget.ayahNumber);
          ref.read(navigationTargetProvider.notifier).setTarget(null);
        }
      });
    } else if (widget.initialAyahNumber != null && !_hasScrolledToInitialAyah) {
      _scrollToInitialAyahIfNeeded(state.ayahs);
    }

    // Target navigation listener (e.g. QuickJump triggered while already viewing this surah)
    ref.listen<AyahTarget?>(navigationTargetProvider, (previous, target) {
      if (target != null && target.surahId == widget.surahId) {
        _scrollToAyah(target.ayahNumber);
      }
    });

    // Auto-scroll listener for ayah audio playback
    ref.listen<int?>(activeAyahProvider, (previous, next) {
      if (next != null) {
        // Skip duplicate scroll while initial scroll is handling this ayah
        if (next == widget.initialAyahNumber && !_hasCompletedInitialScroll) {
          return;
        }

        // CRITICAL GUARD: Audio auto-scroll MUST only scroll the Surah currently being played!
        final audioState = ref.read(quranAudioControllerProvider);
        if (audioState.currentSurahId != widget.surahId) {
          return;
        }

        final targetIndex = state.ayahs.indexWhere((a) => a.ayahNumber == next);
        if (targetIndex != -1 && _itemScrollController.isAttached) {
          final isAudioPlaying = audioState.status == AudioStatus.playing;
          final isSuspended = audioState.isAutoScrollSuspended;

          if (isAudioPlaying && isSuspended) return;

          try {
            if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
              _itemScrollController.scrollTo(
                index: targetIndex,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: 0.0,
              );
            }
          } catch (_) {}
        }
      }
    });

    // Immediate Re-Sync listener when auto-scroll is resumed via Re-Sync button
    ref.listen<bool>(
      quranAudioControllerProvider.select((s) => s.isAutoScrollSuspended),
      (previous, isSuspended) {
        if (previous == true && !isSuspended) {
          final audioState = ref.read(quranAudioControllerProvider);
          if (audioState.currentSurahId != widget.surahId) return;

          final currentAyah = audioState.currentAyahNumber;
          if (currentAyah != null) {
            final targetIndex = state.ayahs.indexWhere((a) => a.ayahNumber == currentAyah);
            if (targetIndex != -1 && _itemScrollController.isAttached) {
              try {
                if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
                  _itemScrollController.scrollTo(
                    index: targetIndex,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    alignment: 0.0,
                  );
                }
              } catch (_) {}
            }
          }
        }
      },
    );

    // Maintain scroll offset when display settings change (e.g. font size, brackets)
    // because height changes cause ListView to jump
    ref.listen(
      quranDisplaySettingsControllerProvider,
      (previous, next) {
        if (previous != next && _itemScrollController.isAttached) {
          final positions = _itemPositionsListener.itemPositions.value;
          if (positions.isNotEmpty) {
            // Find the item that is currently near the top
            final firstVisible = positions.reduce((min, position) =>
                position.itemLeadingEdge.abs() < min.itemLeadingEdge.abs() ? position : min);
            
            final index = firstVisible.index;
            final alignment = firstVisible.itemLeadingEdge > 0 ? 0.0 : firstVisible.itemLeadingEdge;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (_itemScrollController.isAttached) {
                try {
                  if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
                    _itemScrollController.jumpTo(
                      index: index,
                      alignment: alignment,
                    );
                  }
                } catch (_) {}
              }
            });
          }
        }
      },
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      color: activeTheme.evenColor,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final isUserDrag = (notification is ScrollStartNotification && notification.dragDetails != null) ||
              (notification is ScrollUpdateNotification && notification.dragDetails != null);
          if (isUserDrag) {
            final audioState = ref.read(quranAudioControllerProvider);
            final hasActiveSession = audioState.status == AudioStatus.playing || audioState.status == AudioStatus.paused;
            final isThisSurah = audioState.currentSurahId == widget.surahId;
            if (hasActiveSession && isThisSurah) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(quranAudioControllerProvider.notifier).suspendAutoScroll();
              });
            }
          }
          
          // Track reading progress on scroll end
          if (notification is ScrollEndNotification) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final positions = _itemPositionsListener.itemPositions.value;
              if (positions.isNotEmpty && state.ayahs.isNotEmpty) {
                // Find the item that is currently near the top (index 0)
                final firstVisible = positions.reduce((min, position) =>
                    position.itemLeadingEdge < min.itemLeadingEdge ? position : min);
                
                final index = firstVisible.index;
                if (index >= 0 && index < state.ayahs.length) {
                  final ayah = state.ayahs[index];
                  ref.read(continueReadingControllerProvider.notifier).updateStateInMemory(
                    surahId: widget.surahId,
                    surahName: widget.surahName,
                    ayahNumber: ayah.ayahNumber,
                    totalAyahs: state.ayahs.length,
                  );
                }
              }
            });
          }
          return false;
        },
        child: ScrollablePositionedList.builder(
          key: ValueKey('surah_list_${widget.surahId}'),
          initialScrollIndex: _getInitialScrollIndex(state.ayahs),
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          padding: EdgeInsets.only(
            left: 0.0,
            right: 0.0,
            top: 0.0,
            bottom: MediaQuery.paddingOf(context).bottom + 140,
          ),
          itemCount: state.ayahs.length,
          itemBuilder: (context, index) {
            final ayah = state.ayahs[index];
            final previousAyah = index > 0 ? state.ayahs[index - 1] : null;
            
            final isPageStart = previousAyah == null || previousAyah.page != ayah.page;
            final isJuzStart = (previousAyah != null)
                ? (ayah.juz != null && previousAyah.juz != ayah.juz)
                : (ayah.juz != null);
            final isHizbStart = (previousAyah != null)
                ? (ayah.hizb != null && previousAyah.hizb != ayah.hizb)
                : (ayah.hizb != null);
            
            return AyahListItem(
              ayah: ayah,
              surahName: widget.surahName,
              totalAyahsInSurah: state.ayahs.length,
              isPageStart: isPageStart,
              isJuzStart: isJuzStart,
              isHizbStart: isHizbStart,
              translationId: widget.translationId,
            );
          },
        ),
      ),
    );
  }
}
