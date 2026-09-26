import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/services/audio_storage/audio_storage_providers.dart';
import '../../../../core/services/network/network_info_helper.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../download_manager/application/controllers/download_hub_controller.dart';
import '../../../download_manager/application/controllers/downloaded_items_controller.dart';
import '../../../download_manager/infrastructure/datasources/download_manager_local_datasource.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../../quran_reader/domain/entities/reciter_entity.dart';
import '../../../quran_reader/domain/enums/audio_playback_mode.dart';
import '../../../subscription/application/vip_subscription_controller.dart';
import '../../../subscription/domain/policy/audio_vip_policy.dart';
import '../../../subscription/presentation/widgets/vip_required_dialog.dart';
import '../../../subscription/presentation/utils/audio_vip_helper.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../../surah_list/domain/entities/surah_entity.dart';
import '../../application/controllers/audio_download_controller.dart';
import '../../application/controllers/surah_downloaded_ayahs_provider.dart';
import '../../application/states/download_manager_state.dart';
import '../../domain/entities/audio_download_task.dart';

class DownloadManagerSurahList extends ConsumerStatefulWidget {
  final int? initialSurahId;

  const DownloadManagerSurahList({
    super.key,
    this.initialSurahId,
  });

  @override
  ConsumerState<DownloadManagerSurahList> createState() =>
      _DownloadManagerSurahListState();
}

class _DownloadManagerSurahListState
    extends ConsumerState<DownloadManagerSurahList> {
  late ScrollController _scrollController;
  final GlobalKey _targetKey = GlobalKey();
  bool _hasCentered = false;
  bool _highlightTarget = false;

  @override
  void initState() {
    super.initState();
    final initialId = widget.initialSurahId;
    double initialOffset = 0.0;
    if (initialId != null && initialId > 1) {
      // Each surah item is ~61.5px + 1px divider = 62.5px
      const itemExtent = 62.5;
      // Centering places the target item near the middle of the viewport (~240px offset)
      const estimatedCenterOffset = 240.0;
      initialOffset = (10.0 + ((initialId - 1) * itemExtent) - estimatedCenterOffset)
          .clamp(0.0, double.infinity);
    }
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void didUpdateWidget(covariant DownloadManagerSurahList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSurahId != null &&
        widget.initialSurahId != oldWidget.initialSurahId) {
      _hasCentered = false;
      _highlightTarget = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerTargetSurah(List<SurahEntity> surahs) {
    if (_hasCentered || widget.initialSurahId == null || surahs.isEmpty) return;

    final targetIndex = surahs.indexWhere((s) => s.number == widget.initialSurahId);
    if (targetIndex < 0) return;

    _hasCentered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      void triggerHighlight() {
        if (mounted) {
          setState(() {
            _highlightTarget = true;
          });
        }
      }

      // 1. If target item's BuildContext is ready, use Scrollable.ensureVisible for pixel-perfect centering
      if (_targetKey.currentContext != null) {
        Scrollable.ensureVisible(
          _targetKey.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        ).then((_) => triggerHighlight());
      } else if (_scrollController.hasClients) {
        // 2. Fallback: exact math centering based on measured viewport
        const itemExtent = 62.5;
        final viewportHeight = _scrollController.position.viewportDimension;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = (10.0 + (targetIndex * itemExtent) - ((viewportHeight - itemExtent) / 2))
            .clamp(0.0, maxScroll);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        ).then((_) => triggerHighlight());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahState = ref.watch(surahListControllerProvider);
    final selectedReciter = ref.watch(downloadManagerSelectedReciterProvider);

    final fontScript = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final fontFamily = AppTypography.getFontFamilyByScript(fontScript);

    if (surahState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (surahState.errorMessage != null) {
      return Center(child: Text('خطا: ${surahState.errorMessage}'));
    }

    final surahs = surahState.filteredSurahs;
    if (widget.initialSurahId != null) {
      _centerTargetSurah(surahs);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Section Header: "لیست سوره‌ها"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'لیست سوره‌ها',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // Surah ListView or Empty Search State
        if (surahs.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  AppConstants.noSurahFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 260),
              itemCount: surahs.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.7,
                color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.4),
              ),
              itemBuilder: (context, index) {
                final surah = surahs[index];
                final isCurrentTarget = widget.initialSurahId == surah.number;
                return KeyedSubtree(
                  key: isCurrentTarget ? _targetKey : ValueKey('surah_${surah.number}'),
                  child: _SurahListItem(
                    key: ValueKey('surah_item_${surah.number}'),
                    surah: surah,
                    fontFamily: fontFamily,
                    selectedReciter: selectedReciter,
                    isTargeted: _highlightTarget && isCurrentTarget,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SurahListItem extends ConsumerWidget {
  final SurahEntity surah;
  final String fontFamily;
  final ReciterEntity? selectedReciter;
  final bool isTargeted;

  const _SurahListItem({
    super.key,
    required this.surah,
    required this.fontFamily,
    required this.selectedReciter,
    this.isTargeted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final storageService = ref.watch(audioStorageServiceProvider);

    return ListenableBuilder(
      listenable: storageService.downloadStatusListenable,
      builder: (context, child) {
        final isDownloaded = selectedReciter != null
            ? storageService.isSurahDownloaded(
                selectedReciter!.id, surah.number)
            : false;

        final taskKey = selectedReciter != null
            ? 'r${selectedReciter!.id}_s${surah.number}'
            : null;
        final downloadTask = taskKey != null
            ? ref.watch(audioDownloadControllerProvider
                .select((map) => map[taskKey]))
            : null;
        final isDownloading = downloadTask != null &&
            downloadTask.status == DownloadTaskStatus.downloading;
        final isPaused = downloadTask != null &&
            downloadTask.status == DownloadTaskStatus.paused;

        int? downloadedAyahsCount;
        if (selectedReciter != null && !isDownloaded && !isDownloading && !isPaused) {
          final countAsync = ref.watch(
            surahDownloadedAyahsCountProvider((
              reciterId: selectedReciter!.id,
              surahId: surah.number,
              totalAyahs: surah.numberOfAyahs,
            )),
          );
          downloadedAyahsCount = countAsync.when(
            data: (count) => count,
            loading: () => downloadTask?.completedAyahs,
            error: (_, _) => downloadTask?.completedAyahs,
          );
        } else if (isDownloading || isPaused) {
          downloadedAyahsCount = downloadTask.completedAyahs;
        }

        final hasPartialDownload = !isDownloaded &&
            !isDownloading &&
            !isPaused &&
            downloadedAyahsCount != null &&
            downloadedAyahsCount > 0;

        final isVip = ref.watch(hasVipAccessProvider);
        final isTranslation = selectedReciter?.styleId == 4;
        final isLocked = selectedReciter != null &&
            !isDownloaded &&
            (isTranslation
                ? !AudioVipPolicy.canPlayAudioTranslation(isVip: isVip)
                : !AudioVipPolicy.canPlayReciter(
                    reciterIdentifier: selectedReciter!.identifier,
                    surahId: surah.number,
                    isVip: isVip,
                  ));

        return InkWell(
          onTap: () {
            if (isDownloaded) {
              if (selectedReciter != null) {
                _playSurah(
                  context: context,
                  ref: ref,
                  surah: surah,
                  reciter: selectedReciter!,
                );
              }
            } else if (hasPartialDownload) {
              if (selectedReciter != null) {
                _showSurahOptionsBottomSheet(
                  context: context,
                  ref: ref,
                  surah: surah,
                  reciter: selectedReciter!,
                  isDownloaded: isDownloaded,
                  hasPartialDownload: hasPartialDownload,
                  downloadedAyahsCount: downloadedAyahsCount,
                  fontFamily: fontFamily,
                );
              }
            } else if (isDownloading) {
              if (selectedReciter != null) {
                ref
                    .read(audioDownloadControllerProvider.notifier)
                    .pauseDownload(selectedReciter!.id, surah.number);
              }
            } else if (isPaused) {
              if (selectedReciter != null) {
                ref
                    .read(audioDownloadControllerProvider.notifier)
                    .resumeDownload(
                      reciter: selectedReciter!,
                      surahId: surah.number,
                    );
              }
            } else {
              _startSurahDownload(context, ref, isLocked, isTranslation);
            }
          },
          onLongPress: (isDownloaded || hasPartialDownload || isDownloading || isPaused)
              ? () {
                  if (selectedReciter != null) {
                    _showSurahOptionsBottomSheet(
                      context: context,
                      ref: ref,
                      surah: surah,
                      reciter: selectedReciter!,
                      isDownloaded: isDownloaded,
                      hasPartialDownload: hasPartialDownload || isPaused,
                      downloadedAyahsCount: downloadedAyahsCount ?? downloadTask?.completedAyahs,
                      fontFamily: fontFamily,
                    );
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 4.0),
            child: Row(
              children: [
                // Right Badge: Surah Number
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF0EBE1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    surah.number.toPersianDigit(),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF4A453A),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Info: Surah Name & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سوره ${surah.nameFa}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/ic_kaaba.svg',
                            width: 12,
                            height: 12,
                            colorFilter: ColorFilter.mode(
                              context.colorScheme.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            surah.revelationTypeFa,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Text(
                            'جزء ${surah.startJuz.toPersianDigit()}',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          Text(
                            '${surah.numberOfAyahs.toPersianDigit()} ${AppConstants.ayahLabel}',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Left Action Widget
                _PulsingActionButton(
                  isTargeted: isTargeted && !isDownloaded,
                  child: _buildActionWidget(
                    context: context,
                    ref: ref,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    isDownloaded: isDownloaded,
                    isDownloading: isDownloading,
                    isPaused: isPaused,
                    hasPartialDownload: hasPartialDownload,
                    downloadTask: downloadTask,
                    downloadedAyahsCount: downloadedAyahsCount,
                    isLocked: isLocked,
                    isTranslation: isTranslation,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionWidget({
    required BuildContext context,
    required WidgetRef ref,
    required bool isDark,
    required ColorScheme colorScheme,
    required bool isDownloaded,
    required bool isDownloading,
    required bool isPaused,
    required bool hasPartialDownload,
    required AudioDownloadTask? downloadTask,
    required int? downloadedAyahsCount,
    required bool isLocked,
    required bool isTranslation,
  }) {
    // 1. Downloaded State: Transforms into "حذف" button with outlined trash can (No border, neutral)
    if (isDownloaded) {
      final neutralBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);
      final neutralFg = isDark
          ? Colors.white70
          : Colors.black.withValues(alpha: 0.65);

      return InkWell(
        onTap: () {
          if (selectedReciter != null) {
            _showDeleteConfirmDialog(
              context: context,
              sheetContext: null,
              ref: ref,
              surah: surah,
              reciter: selectedReciter!,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: neutralBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.trash,
                size: 15,
                color: neutralFg,
              ),
              const SizedBox(width: 5),
              Text(
                'حذف',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: neutralFg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Downloading State: Progress % and X (cancel/stop) button inside same button (No border)
    if (isDownloading && downloadTask != null) {
      final percent = (downloadTask.progress * 100).clamp(0, 100).toInt();
      final accentColor = context.colorScheme.primary;

      return InkWell(
        onTap: () {
          if (selectedReciter != null) {
            ref
                .read(audioDownloadControllerProvider.notifier)
                .pauseDownload(selectedReciter!.id, surah.number);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  value: downloadTask.progress > 0 ? downloadTask.progress : null,
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${percent.toPersianDigit()}٪',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.close_rounded,
                size: 15,
                color: accentColor.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Paused or Partial Download State: Shows downloaded ayahs count and resumes on tap (No border, neutral)
    if (isPaused || hasPartialDownload) {
      final completed = downloadTask?.completedAyahs ?? downloadedAyahsCount ?? 0;
      final percent = surah.numberOfAyahs > 0
          ? ((completed / surah.numberOfAyahs) * 100).clamp(0, 100).toInt()
          : 0;
      final neutralBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);
      final neutralFg = isDark
          ? Colors.white70
          : Colors.black.withValues(alpha: 0.65);

      return InkWell(
        onTap: () {
          if (selectedReciter != null) {
            if (isPaused) {
              ref
                  .read(audioDownloadControllerProvider.notifier)
                  .resumeDownload(
                    reciter: selectedReciter!,
                    surahId: surah.number,
                  );
            } else {
              _startSurahDownload(context, ref, isLocked, isTranslation);
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: neutralBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.arrow_down,
                size: 13,
                color: neutralFg,
              ),
              const SizedBox(width: 5),
              Text(
                'ادامه (${percent.toPersianDigit()}٪ • ${completed.toPersianDigit()}/${surah.numberOfAyahs.toPersianDigit()})',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: neutralFg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Idle / Not Downloaded State: Action pill with No Border
    final pillBgColor = isDark
        ? context.colorScheme.primary.withValues(alpha: 0.14)
        : context.colors.cardBackground;
    final pillTextColor = context.colorScheme.primary;

    return InkWell(
      onTap: () => _startSurahDownload(context, ref, isLocked, isTranslation),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: pillBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock_rounded : CupertinoIcons.arrow_down,
              size: 13.5,
              color: pillTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              'دانلود',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: pillTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playSurah({
    required BuildContext context,
    required WidgetRef ref,
    required SurahEntity surah,
    required ReciterEntity reciter,
  }) async {
    final isAudioTranslation = reciter.styleId == 4;
    await ref.read(quranAudioControllerProvider.notifier).stop();
    if (isAudioTranslation) {
      await ref
          .read(quranAudioControllerProvider.notifier)
          .selectTranslationReciter(reciter, autoRestart: false);
      ref
          .read(quranAudioControllerProvider.notifier)
          .setPlaybackMode(AudioPlaybackMode.onlyTranslation);
    } else {
      await ref
          .read(quranAudioControllerProvider.notifier)
          .selectReciter(reciter, autoRestart: false);
      ref
          .read(quranAudioControllerProvider.notifier)
          .setPlaybackMode(AudioPlaybackMode.onlyQuran);
    }

    if (context.mounted) {
      context.pushNamed(
        quranReaderRoute,
        pathParameters: {'id': surah.number.toString()},
        queryParameters: {
          'ayah': '1',
          'name': surah.name,
        },
      );
    }
  }

  Future<void> _startSurahDownload(
    BuildContext context,
    WidgetRef ref,
    bool isLocked,
    bool isTranslation,
  ) async {
    if (selectedReciter == null) return;

    if (isLocked) {
      if (isTranslation) {
        VipRequiredDialog.show(
          context: context,
          reciterName: selectedReciter?.name,
          isTranslation: true,
        );
      } else {
        AudioVipHelper.checkAndPromptVip(
          context: context,
          ref: ref,
          surahId: surah.number,
          targetReciter: selectedReciter!,
        );
      }
      return;
    }

    final isWifiOnly = ref
        .read(downloadManagerLocalDataSourceProvider)
        .getWifiOnlyPreference();
    if (isWifiOnly) {
      final isWifi = await NetworkInfoHelper.isWifiConnected();
      if (!isWifi) {
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            'دانلود انجام نشد: تنظیم «فقط با وای‌فای» فعال است. لطفاً وای‌فای را روشن کرده یا این گزینه را در مدیریت دانلود غیرفعال کنید.',
          );
        }
        return;
      }
    }

    ref.read(audioDownloadControllerProvider.notifier).startDownload(
          reciter: selectedReciter!,
          surahId: surah.number,
        );

    if (context.mounted) {
      AppSnackBar.showSuccess(
        context,
        'دانلود سوره ${surah.nameFa} شروع شد.',
      );
    }
  }

  void _showSurahOptionsBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required SurahEntity surah,
    required ReciterEntity reciter,
    required bool isDownloaded,
    required bool hasPartialDownload,
    required int? downloadedAyahsCount,
    required String? fontFamily,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAudioTranslation = reciter.styleId == 4;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final colorScheme = sheetCtx.colorScheme;
        return Material(
          color: isDark ? const Color(0xFF1E2624) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppModalHeader(
                    showDragHandle: true,
                    showDivider: true,
                    bottomSpacing: 12.0,
                    title: 'سوره ${surah.nameFa}',
                    leadingAction: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        surah.number.toPersianDigit(),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAudioTranslation
                            ? 'ترجمه گویا: ${reciter.name}'
                            : 'با صدای: ${reciter.name}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDownloaded
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDownloaded
                              ? 'دانلود کامل'
                              : '${(downloadedAyahsCount ?? 0).toPersianDigit()} از ${surah.numberOfAyahs.toPersianDigit()} آیه',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDownloaded
                                ? colorScheme.primary
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Action 1: Play Surah (if downloaded)
                  if (isDownloaded)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.play_circle_fill,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        'پخش صوت سوره',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isAudioTranslation
                            ? 'پخش ترجمه گویا از آیه ۱'
                            : 'پخش تلاوت از آیه ۱',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        Navigator.pop(sheetCtx);

                        await ref.read(quranAudioControllerProvider.notifier).stop();
                        if (isAudioTranslation) {
                          await ref
                              .read(quranAudioControllerProvider.notifier)
                              .selectTranslationReciter(reciter);
                          ref
                              .read(quranAudioControllerProvider.notifier)
                              .setPlaybackMode(AudioPlaybackMode.onlyTranslation);
                        } else {
                          await ref
                              .read(quranAudioControllerProvider.notifier)
                              .selectReciter(reciter);
                          ref
                              .read(quranAudioControllerProvider.notifier)
                              .setPlaybackMode(AudioPlaybackMode.onlyQuran);
                        }

                        if (context.mounted) {
                          context.pushNamed(
                            quranReaderRoute,
                            pathParameters: {'id': surah.number.toString()},
                            queryParameters: {
                              'ayah': '1',
                              'name': surah.name,
                            },
                          );
                        }
                      },
                    ),

                  // Action 2: Resume / Complete Download (if partial)
                  if (hasPartialDownload)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.cloud_download_fill,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        'ادامه و تکمیل دانلود',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'دانلود آیه‌های باقیمانده (${(surah.numberOfAyahs - (downloadedAyahsCount ?? 0)).toPersianDigit()} آیه)',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        final isVip = ref.read(hasVipAccessProvider);
                        final isTranslation = reciter.styleId == 4;
                        final isLocked = isTranslation
                            ? !AudioVipPolicy.canPlayAudioTranslation(isVip: isVip)
                            : !AudioVipPolicy.canPlayReciter(
                                reciterIdentifier: reciter.identifier,
                                surahId: surah.number,
                                isVip: isVip,
                              );
                        if (isLocked) {
                          if (isTranslation) {
                            VipRequiredDialog.show(
                              context: context,
                              reciterName: reciter.name,
                              isTranslation: true,
                            );
                          } else {
                            AudioVipHelper.checkAndPromptVip(
                              context: context,
                              ref: ref,
                              surahId: surah.number,
                              targetReciter: reciter,
                            );
                          }
                          return;
                        }
                        ref
                            .read(audioDownloadControllerProvider.notifier)
                            .startDownload(
                              reciter: reciter,
                              surahId: surah.number,
                            );
                        AppSnackBar.showSuccess(
                          context,
                          'دانلود سوره ${surah.nameFa} شروع شد.',
                        );
                      },
                    ),

                  // Action 3: Delete from storage
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.trash_fill,
                        color: colorScheme.error,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'حذف از حافظه دستگاه',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                    subtitle: Text(
                      'پاک‌سازی فایل‌های صوتی ذخیره شده این سوره',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.error,
                      ),
                    ),
                    trailing: Icon(CupertinoIcons.chevron_back, size: 14, color: colorScheme.error),
                    onTap: () {
                      _showDeleteConfirmDialog(
                        context: context,
                        sheetContext: sheetCtx,
                        ref: ref,
                        surah: surah,
                        reciter: reciter,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog({
    required BuildContext context,
    BuildContext? sheetContext,
    required WidgetRef ref,
    required SurahEntity surah,
    required ReciterEntity reciter,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final colorScheme = dialogCtx.colorScheme;
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppModalHeader(
                  title: 'حذف صوت سوره ${surah.nameFa}',
                  onClose: () => Navigator.pop(dialogCtx),
                  bottomSpacing: 12,
                ),
                Text(
                  'آیا از حذف کامل فایل‌های صوتی سوره ${surah.nameFa} با صدای «${reciter.name}» از حافظه دستگاه اطمینان دارید؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          if (sheetContext != null && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }

                          final storage = ref.read(audioStorageServiceProvider);
                          await storage.deleteSurahAudio(
                            reciterId: reciter.id,
                            surahId: surah.number,
                          );

                          ref.invalidate(surahDownloadedAyahsCountProvider);
                          ref.read(downloadedItemsControllerProvider.notifier).loadItems();
                          ref.read(downloadHubControllerProvider.notifier).loadSummary();

                          if (context.mounted) {
                            AppSnackBar.showSuccess(
                              context,
                              'صوت سوره ${surah.nameFa} با موفقیت از حافظه پاک شد.',
                            );
                          }
                        },
                        child: const Text(
                          'حذف',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
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
        );
    },
    );
  }
}

class _PulsingActionButton extends StatefulWidget {
  final bool isTargeted;
  final Widget child;

  const _PulsingActionButton({
    required this.isTargeted,
    required this.child,
  });

  @override
  State<_PulsingActionButton> createState() => _PulsingActionButtonState();
}

class _PulsingActionButtonState extends State<_PulsingActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _colorAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = TweenSequence<double>([
      // First click: press down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.84)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      // First click: release pop up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.84, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      // Settle
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
      // Short pause between clicks
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 14,
      ),
      // Second click: press down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.87)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 14,
      ),
      // Second click: release pop up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.87, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 12,
      ),
      // Settle
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 12,
      ),
    ]).animate(_controller);

    _colorAnimation = TweenSequence<double>([
      // Fade in subtle tint during first click
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      // Hold subtle tint throughout clicks
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 55,
      ),
      // Fade out smoothly as animation ends
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    if (widget.isTargeted && !_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTargeted && !_hasAnimated) {
      _hasAnimated = true;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnimated && !widget.isTargeted) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final colorVal = _colorAnimation.value;
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: colorVal > 0.01
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: (isDark ? 0.28 : 0.18) * colorVal,
                        ),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                widget.child,
                if (colorVal > 0.01)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: primaryColor.withValues(
                            alpha: (isDark ? 0.18 : 0.12) * colorVal,
                          ),
                          border: Border.all(
                            color: primaryColor.withValues(
                              alpha: (isDark ? 0.40 : 0.30) * colorVal,
                            ),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

