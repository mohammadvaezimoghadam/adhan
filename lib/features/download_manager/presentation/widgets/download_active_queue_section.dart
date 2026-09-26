import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/surah_constants.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/widgets/app_cached_network_image.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../audio_manager/application/controllers/audio_download_controller.dart';
import '../../../audio_manager/domain/entities/audio_download_task.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/reciter_providers.dart';
import '../../../quran_reader/domain/entities/reciter_entity.dart';
import '../../../quran_reader/domain/enums/audio_playback_mode.dart';
import '../../../subscription/presentation/utils/audio_vip_helper.dart';
import '../../../translation_manager/application/controllers/translation_manager_controller.dart';
import '../../../translation_manager/domain/entities/translation_entity.dart';

class DownloadActiveQueueSection extends ConsumerStatefulWidget {
  const DownloadActiveQueueSection({super.key});

  @override
  ConsumerState<DownloadActiveQueueSection> createState() =>
      _DownloadActiveQueueSectionState();
}

class _DownloadActiveQueueSectionState
    extends ConsumerState<DownloadActiveQueueSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Audio Tasks (Quran audio and audio translations)
    final tasksMap = ref.watch(audioDownloadControllerProvider);
    final audioQueueTasks = tasksMap.values.where((task) {
      return task.status == DownloadTaskStatus.downloading ||
          task.status == DownloadTaskStatus.paused ||
          task.status == DownloadTaskStatus.failed;
    }).toList();

    // 2. Text Translation Tasks
    final translationState = ref.watch(translationManagerControllerProvider).value;
    final activeTranslationProgress = translationState?.downloadProgress ?? {};
    final allTranslations = translationState?.translations ?? [];
    final downloadingTranslationIds = activeTranslationProgress.keys.toList();

    // 3. Reciters catalog to distinguish Quran audio from Audio Translation
    final allReciters = ref.watch(allRecitersListProvider).asData?.value.tryGetSuccess() ?? [];

    final totalCount = audioQueueTasks.length + downloadingTranslationIds.length;

    final colors = context.colors;
    final cardBgColor = colors.cardBackground;
    final cardBorderColor = colors.cardBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: cardBorderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Clean text title & count badge
            Row(
              children: [
                Text(
                  'صف دانلودهای جاری',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (totalCount > 0)
                  Text(
                    '${totalCount.toPersianDigit()} مورد',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),

            // Empty State
            if (totalCount == 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Text(
                    'در حال حاضر هیچ دانلودی در صف نیست.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12.5,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              // List of downloading items (Initial 3 or All)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _isExpanded
                    ? totalCount
                    : (totalCount > 3 ? 3 : totalCount),
                separatorBuilder: (context, index) => Divider(
                  height: 18,
                  thickness: 0.6,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                ),
                itemBuilder: (context, index) {
                  // Display audio tasks first, then text translation tasks
                  if (index < audioQueueTasks.length) {
                    final task = audioQueueTasks[index];
                    final surahName = SurahConstants.getSurahName(task.surahId);
                    final reciter = allReciters
                        .where((r) => r.id == task.reciterId)
                        .firstOrNull;

                    return _AudioQueueTaskItem(
                      task: task,
                      surahName: surahName,
                      reciter: reciter,
                      isDark: isDark,
                    );
                  } else {
                    final translationIndex = index - audioQueueTasks.length;
                    final translationId = downloadingTranslationIds[translationIndex];
                    final progress = activeTranslationProgress[translationId] ?? 0.0;
                    final translation = allTranslations
                        .where((t) => t.id == translationId)
                        .firstOrNull;

                    return _TextTranslationQueueTaskItem(
                      translationId: translationId,
                      translation: translation,
                      progress: progress,
                      isDark: isDark,
                    );
                  }
                },
              ),
              // Show more / Collapse button at the bottom (Unboxed, clean)
              if (totalCount > 3) ...[
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        _isExpanded ? 'بستن لیست' : 'نمایش بیشتر',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Item for Audio downloads (both Arabic Quran recitation and Audio translation)
class _AudioQueueTaskItem extends ConsumerWidget {
  final AudioDownloadTask task;
  final String surahName;
  final ReciterEntity? reciter;
  final bool isDark;

  const _AudioQueueTaskItem({
    required this.task,
    required this.surahName,
    required this.reciter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAudioTranslation = reciter?.styleId == 4;
    final isDownloading = task.status == DownloadTaskStatus.downloading;
    final isPaused = task.status == DownloadTaskStatus.paused;
    final isFailed = task.status == DownloadTaskStatus.failed;
    final percent = (task.progress * 100).toInt();

    // All badge labels are uniform and colorless/neutral
    final badgeColor = isDark ? Colors.white60 : Colors.black54;
    final badgeLabel = isAudioTranslation ? 'ترجمه گویا' : 'صوت قرآن';
    final badgeIcon = isAudioTranslation
        ? CupertinoIcons.speaker_2
        : CupertinoIcons.waveform;

    final cleanReciterName = reciter != null
        ? reciter!.name
            .replaceAll('استاد ', '')
            .replaceAll('قاری:', '')
            .trim()
        : 'قاری کد ${task.reciterId}';

    final baseAvatar = (reciter?.imageUrl != null && reciter!.imageUrl!.isNotEmpty)
        ? AppCachedNetworkImage(
            imageUrl: reciter!.imageUrl,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            fallbackIcon: badgeIcon,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          )
        : Container(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            alignment: Alignment.center,
            child: Icon(
              badgeIcon,
              size: 20,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSurah(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              // Reciter Avatar with circular percentage overlay
              Container(
                width: 42,
                height: 42,
                margin: const EdgeInsetsDirectional.only(end: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isDownloading || isPaused)
                        ? context.colorScheme.primary.withValues(alpha: 0.45)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : context.colors.cardBorder),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      baseAvatar,
                      if (isDownloading || isPaused) ...[
                        // Dark scrim overlay for high contrast
                        Container(
                          color: Colors.black.withValues(alpha: 0.52),
                        ),
                        // Circular progress indicator with centered Persian percentage
                        Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: task.progress.clamp(0.0, 1.0),
                                  strokeWidth: 2.2,
                                  color: context.colorScheme.primary,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.25),
                                ),
                                Text(
                                  '${percent.toPersianDigit()}٪',
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (isFailed) ...[
                        Container(
                          color: Colors.black.withValues(alpha: 0.52),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.arrow_counterclockwise,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'سوره $surahName',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• $badgeLabel',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cleanReciterName,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${task.completedAyahs.toPersianDigit()}/${task.totalAyahs.toPersianDigit()})',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10.5,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons: Play + Delete ('حذف')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isDownloading ? 'توقف' : (isFailed ? 'تلاش مجدد' : 'ادامه'),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      isDownloading
                          ? CupertinoIcons.pause_circle
                          : (isFailed
                              ? CupertinoIcons.arrow_clockwise_circle
                              : CupertinoIcons.play_circle),
                      size: 22,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final controller = ref.read(audioDownloadControllerProvider.notifier);
                      if (isDownloading) {
                        controller.pauseDownload(task.reciterId, task.surahId);
                      } else {
                        controller.resumeDownloadById(
                          reciterId: task.reciterId,
                          surahId: task.surahId,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await ref
                          .read(audioDownloadControllerProvider.notifier)
                          .cancelDownload(task.reciterId, task.surahId);
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'حذف',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: context.colorScheme.error,
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
  }

  Future<void> _openSurah(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    ReciterEntity? targetReciter = reciter;
    if (targetReciter == null) {
      final allReciters = await ref.read(allRecitersListProvider.future);
      targetReciter = allReciters
          .tryGetSuccess()
          ?.where((r) => r.id == task.reciterId)
          .firstOrNull;
    }

    final isAudioTranslation = targetReciter?.styleId == 4;

    if (targetReciter != null) {
      if (!context.mounted) return;
      if (isAudioTranslation) {
        final isAllowed = AudioVipHelper.checkAudioTranslation(
          context: context,
          ref: ref,
        );
        if (!isAllowed) return;

        await ref.read(quranAudioControllerProvider.notifier).stop();
        await ref
            .read(quranAudioControllerProvider.notifier)
            .selectTranslationReciter(targetReciter, autoRestart: false);
        ref
            .read(quranAudioControllerProvider.notifier)
            .setPlaybackMode(AudioPlaybackMode.onlyTranslation);
      } else {
        if (!context.mounted) return;
        final isAllowed = await AudioVipHelper.checkAndPromptVip(
          context: context,
          ref: ref,
          surahId: task.surahId,
          targetReciter: targetReciter,
        );
        if (!isAllowed || !context.mounted) return;

        await ref.read(quranAudioControllerProvider.notifier).stop();
        await ref
            .read(quranAudioControllerProvider.notifier)
            .selectReciter(targetReciter, autoRestart: false);
        ref
            .read(quranAudioControllerProvider.notifier)
            .setPlaybackMode(AudioPlaybackMode.onlyQuran);
      }
    }

    if (context.mounted) {
      context.pushNamed(
        quranReaderRoute,
        pathParameters: {'id': task.surahId.toString()},
        queryParameters: {
          'ayah': '1',
          'name': surahName,
        },
      );
    }
  }
}

/// Item for Text Translation downloads
class _TextTranslationQueueTaskItem extends ConsumerWidget {
  final String translationId;
  final TranslationEntity? translation;
  final double progress;
  final bool isDark;

  const _TextTranslationQueueTaskItem({
    required this.translationId,
    required this.translation,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = (progress * 100).toInt();

    final title = translation != null
        ? 'ترجمه ${translation!.name}'
        : 'ترجمه متنی ($translationId)';
    final subtitle = translation != null
        ? 'مترجم: ${translation!.translatorName}'
        : 'در حال دریافت فایل داده...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Book Icon container with circular percentage overlay inside
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.45),
                  width: 1.0,
                ),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF2EFE9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Muted doc icon in background
                    Icon(
                      CupertinoIcons.doc_text,
                      size: 20,
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.15),
                    ),
                    // Circular progress ring
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 2.2,
                        color: context.colorScheme.primary,
                        backgroundColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    // Centered percentage inside the book icon
                    Text(
                      '${percent.toPersianDigit()}٪',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• متن ترجمه',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Cancel Download button (Plain unboxed text)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                ref
                    .read(translationManagerControllerProvider.notifier)
                    .cancelDownload(translationId);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'حذف',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
