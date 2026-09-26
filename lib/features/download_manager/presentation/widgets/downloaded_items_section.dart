import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/widgets/app_cached_network_image.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/data/local/preferences/preferences_keys.dart';
import '../../../../core/data/local/preferences/preferences_service_provider.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../../quran_reader/application/controllers/reciter_providers.dart';
import '../../../quran_reader/domain/enums/audio_playback_mode.dart';
import '../../../subscription/presentation/utils/audio_vip_helper.dart';
import '../../../translation_manager/application/controllers/translation_manager_controller.dart';
import '../../application/controllers/downloaded_items_controller.dart';
import '../../domain/entities/downloaded_item_entity.dart';

class DownloadedItemsSection extends ConsumerStatefulWidget {
  const DownloadedItemsSection({super.key});

  @override
  ConsumerState<DownloadedItemsSection> createState() =>
      _DownloadedItemsSectionState();
}

class _DownloadedItemsSectionState extends ConsumerState<DownloadedItemsSection> {
  String _selectedFilter = 'all'; // 'all', 'quran', 'trans_audio', 'trans_text'
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final colors = context.colors;
    final cardBgColor = colors.cardBackground;
    final cardBorderColor = colors.cardBorder;
    final asyncItems = ref.watch(downloadedItemsControllerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: cardBorderColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: asyncItems.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'خطا در بارگیری دانلودها: $err',
                style: TextStyle(color: context.colorScheme.error, fontSize: 13),
              ),
            ),
          ),
          data: (items) {
            final quranAudioItems = items
                .where((i) => i.type == DownloadedItemType.quranAudio)
                .toList();
            final audioTransItems = items
                .where((i) => i.type == DownloadedItemType.audioTranslation)
                .toList();
            final textTransItems = items
                .where((i) => i.type == DownloadedItemType.textTranslation)
                .toList();

            final filteredItems = items.where((item) {
              if (_selectedFilter == 'quran') {
                return item.type == DownloadedItemType.quranAudio;
              }
              if (_selectedFilter == 'trans_audio') {
                return item.type == DownloadedItemType.audioTranslation;
              }
              if (_selectedFilter == 'trans_text') {
                return item.type == DownloadedItemType.textTranslation;
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Clean title & total count badge
                Row(
                  children: [
                    Text(
                      'فایل‌های دانلود شده',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length.toPersianDigit()} فایل ذخیره',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),

                // 2. Filter Tabs (always visible when items exist)
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'همه', items.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('quran', 'صوت قرآن', quranAudioItems.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('trans_audio', 'ترجمه گویا', audioTransItems.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('trans_text', 'متن ترجمه', textTransItems.length),
                      ],
                    ),
                  ),
                ],

                // 3. Content: Empty or List
                if (items.isEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Center(
                      child: Text(
                        'هنوز فایلی در حافظه دستگاه دانلود نشده است.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ] else if (filteredItems.isEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Center(
                      child: Text(
                        'موردی در این دسته‌بندی وجود ندارد.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _isExpanded
                        ? filteredItems.length
                        : (filteredItems.length > 3 ? 3 : filteredItems.length),
                    separatorBuilder: (context, index) => Divider(
                      height: 18,
                      thickness: 0.6,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _DownloadedItemRow(
                        item: item,
                        isDark: isDark,
                        onOpen: () => _openItem(item),
                        onDelete: () => _confirmDelete(item),
                      );
                    },
                  ),
                  // Show more / Collapse button at the bottom of the list (Unboxed, clean)
                  if (filteredItems.length > 3) ...[
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    final colorScheme = context.colorScheme;
    final colors = context.colors;
    final isDark = context.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = key;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(
                    alpha: isDark ? 0.20 : 0.12,
                  )
                : colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(
                      alpha: isDark ? 0.50 : 0.35,
                    )
                  : colors.cardBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.primary
                      : (isDark ? Colors.white70 : const Color(0xFF5A5852)),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${count.toPersianDigit()})',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.primary
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openItem(DownloadedItemEntity item) async {
    switch (item.type) {
      case DownloadedItemType.quranAudio:
        if (item.reciterId != null) {
          final allReciters = await ref.read(allRecitersListProvider.future);
          final reciter = allReciters
              .tryGetSuccess()
              ?.where((r) => r.id == item.reciterId)
              .firstOrNull;
          if (reciter != null && item.surahId != null) {
            if (!mounted) return;
            final isAllowed = await AudioVipHelper.checkAndPromptVip(
              context: context,
              ref: ref,
              surahId: item.surahId!,
              targetReciter: reciter,
            );
            if (!isAllowed || !mounted) return;

            await ref.read(quranAudioControllerProvider.notifier).stop();
            await ref
                .read(quranAudioControllerProvider.notifier)
                .selectReciter(reciter, autoRestart: false);
          }
        }
        // Set playback mode to only Quran recitation and persist
        ref
            .read(quranAudioControllerProvider.notifier)
            .setPlaybackMode(AudioPlaybackMode.onlyQuran);

        if (mounted && item.surahId != null) {
          context.pushNamed(
            quranReaderRoute,
            pathParameters: {'id': item.surahId.toString()},
            queryParameters: {
              'ayah': '1',
              'name': item.title,
            },
          );
        }
        break;

      case DownloadedItemType.audioTranslation:
        final isAllowed = AudioVipHelper.checkAudioTranslation(
          context: context,
          ref: ref,
        );
        if (!isAllowed) return;

        if (item.reciterId != null) {
          final allReciters = await ref.read(allRecitersListProvider.future);
          final reciter = allReciters
              .tryGetSuccess()
              ?.where((r) => r.id == item.reciterId)
              .firstOrNull;
          if (reciter != null) {
            await ref.read(quranAudioControllerProvider.notifier).stop();
            await ref
                .read(quranAudioControllerProvider.notifier)
                .selectTranslationReciter(reciter, autoRestart: false);
          }
        }
        // Set playback mode to only Translation and persist
        ref
            .read(quranAudioControllerProvider.notifier)
            .setPlaybackMode(AudioPlaybackMode.onlyTranslation);

        if (mounted && item.surahId != null) {
          context.pushNamed(
            quranReaderRoute,
            pathParameters: {'id': item.surahId.toString()},
            queryParameters: {
              'ayah': '1',
              'name': item.title,
            },
          );
        }
        break;

      case DownloadedItemType.textTranslation:
        if (item.translationId != null) {
          // Set as active translation and persist in preferences
          await ref
              .read(translationManagerControllerProvider.notifier)
              .setActiveTranslation(item.translationId!);
        }
        // Ensure translation display is turned on and persisted
        ref
            .read(quranDisplaySettingsControllerProvider.notifier)
            .toggleTranslation(true);
        ref
            .read(preferencesServiceProvider)
            .setBool(PreferencesKeys.showTranslation, true);

        if (mounted) {
          context.pushNamed(
            quranReaderRoute,
            pathParameters: {'id': '1'},
            queryParameters: {'translationId': item.translationId},
          );
        }
        break;
    }
  }

  Future<void> _confirmDelete(DownloadedItemEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppModalHeader(
                  title: 'حذف فایل دانلود شده',
                  onClose: () => Navigator.pop(ctx, false),
                  bottomSpacing: 12,
                ),
                Text(
                  'آیا از حذف «${item.title}» (${item.subtitle}) از حافظه دستگاه اطمینان دارید؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
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
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'حذف فایل',
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

    if (confirmed == true) {
      if (item.reciterId != null && item.surahId != null) {
        await ref.read(downloadedItemsControllerProvider.notifier).deleteAudioItem(
              reciterId: item.reciterId!,
              surahId: item.surahId!,
            );
      } else if (item.translationId != null) {
        await ref
            .read(downloadedItemsControllerProvider.notifier)
            .deleteTextTranslation(item.translationId!);
      }
      if (mounted) {
        AppSnackBar.showSuccess(context, '«${item.title}» از حافظه حذف شد');
      }
    }
  }
}

class _DownloadedItemRow extends StatelessWidget {
  final DownloadedItemEntity item;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _DownloadedItemRow({
    required this.item,
    required this.isDark,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // All badges are uniform and neutral/colorless
    final badgeColor = isDark ? Colors.white60 : Colors.black54;
    final String badgeLabel;
    final IconData iconData;

    switch (item.type) {
      case DownloadedItemType.quranAudio:
        badgeLabel = 'صوت قرآن';
        iconData = CupertinoIcons.waveform;
        break;
      case DownloadedItemType.audioTranslation:
        badgeLabel = 'ترجمه گویا';
        iconData = CupertinoIcons.speaker_2;
        break;
      case DownloadedItemType.textTranslation:
        badgeLabel = 'متن ترجمه';
        iconData = CupertinoIcons.doc_text;
        break;
    }

    final cleanSubtitle = item.subtitle
        .replaceAll('قاری:', '')
        .replaceAll('گوینده:', '')
        .replaceAll('مترجم:', '')
        .replaceAll('استاد', '')
        .trim();

    final fallbackBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final fallbackIconColor = isDark ? Colors.white60 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onOpen();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? AppCachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          fallbackIcon: iconData,
                          backgroundColor: fallbackBg,
                        )
                      : Container(
                          color: fallbackBg,
                          alignment: Alignment.center,
                          child: Icon(
                            iconData,
                            size: 18,
                            color: fallbackIconColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                    if (cleanSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cleanSubtitle,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Removed Action buttons (Play + Delete) as requested by the user.
              // Tapping the row itself already triggers onOpen().
            ],
          ),
        ),
      ),
    );
  }
}
