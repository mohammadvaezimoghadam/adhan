import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../application/controllers/daily_ayah_controller.dart';

/// Desktop-tailored Hero Banner for Daily Ayah (آیه منتخب روز)
/// Features rich emerald glassmorphism, responsive calligraphy, and 1-click playback.
class WebDailyAyahBanner extends ConsumerWidget {
  const WebDailyAyahBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final ayahAsync = ref.watch(dailyAyahControllerProvider);

    final fontScript = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final arabicFontFamily = AppTypography.getFontFamilyByScript(fontScript);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle ambient Islamic geometric background glow
            Positioned(
              left: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ayahAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CupertinoActivityIndicator(),
                  ),
                ),
                error: (err, _) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('خطا در بارگذاری آیه روز'),
                  ),
                ),
                data: (item) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row: Title badge + Surah & Ayah reference
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.sparkles,
                                  size: 15,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'آیه منتخب امروز',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'سوره ${item.surahName} • آیه ${item.ayahNumber.toPersianDigit()}',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Main Arabic Calligraphy Text
                      Text(
                        item.arabicText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: arabicFontFamily,
                          fontSize: 22,
                          height: 2.1,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Persian Translation Text
                      Text(
                        item.translation,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14.5,
                          height: 1.7,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. Play Audio Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.play_fill, size: 15),
                            label: const Text(
                              'شنیدن تلاوت آیه',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(quranAudioControllerProvider.notifier)
                                  .playAyah(
                                    surahId: item.surahNumber,
                                    ayahNumber: item.ayahNumber,
                                    totalAyahsInSurah: 286,
                                    isSingleAyahMode: true,
                                  );
                              AppSnackBar.showSuccess(
                                context,
                                'پخش تلاوت آیه ${item.ayahNumber.toPersianDigit()} سوره ${item.surahName} آغاز شد.',
                              );
                            },
                          ),

                          const SizedBox(width: 12),

                          // 2. Open in Quran Reader Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                              side: BorderSide(
                                color: colors.cardBorder,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.book_fill, size: 15),
                            label: const Text(
                              'مشاهده در متن سوره',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(quranDisplaySettingsControllerProvider
                                      .notifier)
                                  .toggleArabicText(true);
                              context.pushNamed(
                                quranReaderRoute,
                                pathParameters: {'id': item.surahNumber.toString()},
                                queryParameters: {
                                  'name': item.surahName,
                                  'ayah': item.ayahNumber.toString(),
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 12),

                          // 3. Copy Text Button
                          IconButton(
                            tooltip: 'کپی آیه و ترجمه',
                            icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                            splashRadius: 20,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text:
                                    '${item.arabicText}\n\n${item.translation}\n(سوره ${item.surahName}، آیه ${item.ayahNumber})',
                              ));
                              AppSnackBar.showSuccess(
                                context,
                                'متن و ترجمه آیه با موفقیت کپی شد.',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
