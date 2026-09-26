import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../common/extensions/context_extension.dart';
import '../../../../../common/extensions/int_extension.dart';
import '../../../../../common/extensions/size_extension.dart';
import '../../../../../common/extensions/surah_name_extension.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../core/theme/app_dimens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../../application/controllers/daily_ayah_controller.dart';

/// Luxury "Every Day One Ayah" (هر روز یک آیه) Banner Widget
/// Features high-definition spiritual arch background, Makarem translation,
/// responsive typography, and direct navigation to Quran Reader.
class DailyAyahBannerWidget extends ConsumerWidget {
  const DailyAyahBannerWidget({super.key});

  void _onBannerTap(BuildContext context, WidgetRef ref, DailyAyahItem item) {
    HapticFeedback.lightImpact();
    ref.read(quranDisplaySettingsControllerProvider.notifier).toggleArabicText(true);

    Future.microtask(() {
      if (context.mounted) {
        context.pushNamed(
          quranReaderRoute,
          pathParameters: {'id': item.surahNumber.toString()},
          queryParameters: {
            'name': item.surahName,
            'ayah': item.ayahNumber.toString(),
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = context.isDark;

    final ayahAsync = ref.watch(dailyAyahControllerProvider);

    final fontScript = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final arabicFontFamily = AppTypography.getFontFamilyByScript(fontScript);

    final goldColor = colors.goldAccent;

    return Container(
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
            blurRadius: 14.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: ayahAsync.when(
          loading: () => Container(
            color: colors.cardBackground,
            child: const Center(
              child: CupertinoActivityIndicator(color: Colors.white),
            ),
          ),
          error: (err, stack) => Container(
            color: colors.cardBackground,
            padding: const EdgeInsets.all(AppDimens.stackMd),
            child: const Center(
              child: Text(
                'خطا در بارگذاری آیه روز',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          data: (item) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // A) Background Artistic Spiritual Image
                Image.asset(
                  'assets/images/daily_ayah_bg.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0C2B22),
                            Color(0xFF142434),
                            Color(0xFF0F1E28),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // B) Atmospheric Gradient Overlay (Ensures perfect text readability)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),

                // C) Content Body (Clickable)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onBannerTap(context, ref, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Row: Golden Capsule with "هر روز یک آیه" + Surah & Ayah Info
                          Row(
                            children: [
                              // Golden Capsule containing "هر روز یک آیه"
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: goldColor.withValues(alpha: 0.5),
                                    width: 0.9,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.sparkles,
                                      size: 13,
                                      color: goldColor,
                                    ),
                                    5.hSpace,
                                    Text(
                                      'هر روز یک آیه',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: goldColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // Left Indicator with Surah & Ayah Number
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'سوره ${item.surahNumber.surahNameFa} • آیه ${item.ayahNumber.toPersianDigit()}',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    4.hSpace,
                                    Icon(
                                      CupertinoIcons.chevron_left,
                                      size: 11,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Arabic Ayah Preview
                          Text(
                            item.arabicText,
                            style: TextStyle(
                              fontFamily: arabicFontFamily,
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          6.vSpace,

                          // Makarem Translation
                          if (item.translation.isNotEmpty)
                            Text(
                              item.translation,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          2.vSpace,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
