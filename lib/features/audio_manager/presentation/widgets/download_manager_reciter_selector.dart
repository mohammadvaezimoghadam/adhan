import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/widgets/app_cached_network_image.dart';
import '../../../../common/widgets/reciter/reciter_selection_bottom_sheet.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/reciter_providers.dart';
import '../../../quran_reader/domain/entities/reciter_entity.dart';
import '../../application/states/download_manager_state.dart';

class DownloadManagerReciterSelector extends ConsumerWidget {
  final bool isTranslationMode;

  const DownloadManagerReciterSelector({
    super.key,
    this.isTranslationMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedReciter = ref.watch(downloadManagerSelectedReciterProvider);
    final recitersResult = ref.watch(
      isTranslationMode ? translationRecitersListProvider : recitersListProvider,
    );

    List<ReciterEntity> reciters = [];
    if (recitersResult.value != null && recitersResult.value!.isSuccess()) {
      reciters = recitersResult.value!.tryGetSuccess() ?? [];
    }

    if (selectedReciter == null && reciters.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final audioState = ref.read(quranAudioControllerProvider);
        final defaultReciter = isTranslationMode
            ? (audioState.selectedTranslationReciter ?? reciters.first)
            : (audioState.selectedReciter ?? reciters.first);
        ref.read(downloadManagerSelectedReciterProvider.notifier).setReciter(defaultReciter);
      });
    }

    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final cardBgColor = colors.cardBackground;
    final cardBorderColor = colors.cardBorder;

    final imageUrl = selectedReciter?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final styleName = selectedReciter?.styleName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
            onTap: () {
              ReciterSelectionBottomSheet.show(
                context,
                isDownloadMode: true,
                isTranslationMode: isTranslationMode,
                onReciterSelected: (ReciterEntity reciter) {
                  ref.read(downloadManagerSelectedReciterProvider.notifier).setReciter(reciter);
                  if (isTranslationMode || reciter.styleId == 4) {
                    ref.read(quranAudioControllerProvider.notifier).selectTranslationReciter(reciter, autoRestart: false);
                  } else {
                    ref.read(quranAudioControllerProvider.notifier).selectReciter(reciter, autoRestart: false);
                  }
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor, width: 1.2),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // 1. Reciter photo background on the RIGHT (confined to text area, never reaching change button)
                  if (hasImage)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 130,
                      child: ClipRect(
                        child: Opacity(
                          opacity: isDark ? 0.30 : 0.38,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.25, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: Transform.scale(
                              scale: 1.35,
                              alignment: Alignment.centerRight,
                              child: AppCachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 2. Foreground Card Content (No microphone icon)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        // Texts on Start (Right in RTL)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isTranslationMode ? 'گوینده ترجمه' : 'قاری منتخب',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 11.5,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (styleName != null && styleName.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '• $styleName',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedReciter?.name ??
                                    (isTranslationMode
                                        ? 'انتخاب گوینده'
                                        : 'انتخاب قاری'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Change button / chevron (no background, flipped icon direction)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تغییر',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
