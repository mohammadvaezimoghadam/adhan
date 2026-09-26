import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/go_router_provider.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/domain/entities/ayah_entity.dart';
import '../../application/controllers/tafsir_manager_controller.dart';
import '../../application/states/tafsir_manager_state.dart';
import '../../domain/entities/tafsir_entity.dart';
import '../../infrastructure/datasources/tafsir_catalog.dart';

/// Clean, minimal, non-colored centered dialog for selecting and downloading
/// authentic Persian Quran Exegeses (Tafsirs) for a specific Ayah.
class TafsirSelectionDialog extends ConsumerWidget {
  final AyahEntity ayah;
  final String surahName;

  const TafsirSelectionDialog({
    super.key,
    required this.ayah,
    required this.surahName,
  });

  /// Opens the centered Tafsir selection dialog.
  static Future<void> show(
    BuildContext context, {
    required AyahEntity ayah,
    required String surahName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TafsirSelectionDialog(
        ayah: ayah,
        surahName: surahName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

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

    final tafsirState = ref.watch(tafsirManagerControllerProvider).value;
    final tafsirs = tafsirState?.tafsirs ?? TafsirCatalog.allTafsirs;
    final downloadProgress = tafsirState?.downloadProgress ?? {};

    final cleanSurahName = ayah.surahId.surahNameFa;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2226) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.8,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: AppModalHeader(
                  titleWidget: Text(
                    'تفسیر سوره $cleanSurahName • آیه ${ayah.ayahNumber.toPersianDigit()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  showDivider: true,
                  dividerColor: isDark ? Colors.white12 : Colors.black12,
                  bottomSpacing: 10,
                ),
              ),

              // List of 3 Persian Tafsirs (Unboxed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < tafsirs.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final tafsir = tafsirs[i];
                          final isDownloading = downloadProgress.containsKey(tafsir.id);
                          final progress = downloadProgress[tafsir.id] ?? 0.0;

                          return _buildTafsirTile(
                            context: context,
                            ref: ref,
                            tafsir: tafsir,
                            isDownloaded: tafsir.isDownloaded,
                            isDownloading: isDownloading,
                            progress: progress,
                            isDark: isDark,
                            colorScheme: colorScheme,
                            cleanSurahName: cleanSurahName,
                          );
                        },
                      ),
                      if (i < tafsirs.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTafsirTile({
    required BuildContext context,
    required WidgetRef ref,
    required TafsirEntity tafsir,
    required bool isDownloaded,
    required bool isDownloading,
    required double progress,
    required bool isDark,
    required ColorScheme colorScheme,
    required String cleanSurahName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
      child: Row(
        children: [
          // Tafsir Metadata (Name & Author)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tafsir.name,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                3.vSpace,
                Text(
                  tafsir.authorName,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          10.hSpace,

          // Action / Status Button (Uncolored & Minimal)
          if (isDownloading)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    strokeWidth: 2.0,
                    color: colorScheme.onSurface,
                  ),
                ),
                8.hSpace,
                Text(
                  progress > 0
                      ? '${(progress * 100).toInt().toPersianDigit()}٪'
                      : 'دریافت...',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else if (isDownloaded)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                  width: 0.8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final nav = Navigator.of(context);
                await ref.read(tafsirManagerControllerProvider.notifier).setActiveTafsir(tafsir.id);
                nav.pop();

                ref.read(goRouterProvider).pushNamed(
                  tafsirReaderRoute,
                  pathParameters: {'id': ayah.surahId.toString()},
                  queryParameters: {
                    'name': cleanSurahName,
                    'tafsirId': tafsir.id,
                    'ayah': ayah.ayahNumber.toString(),
                  },
                );
              },
              child: const Text(
                'مطالعه',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                  width: 0.8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                // Download starts in the background and will NOT be cancelled on dialog close
                ref.read(tafsirManagerControllerProvider.notifier).downloadTafsir(tafsir);
              },
              icon: Icon(
                CupertinoIcons.arrow_down_to_line,
                size: 13,
                color: colorScheme.onSurface,
              ),
              label: const Text(
                'دانلود',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
