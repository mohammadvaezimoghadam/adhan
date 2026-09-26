import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';

class _PopularSurahData {
  final int number;
  final String nameFa;
  final String nameAr;
  final String englishName;
  final int ayahCount;
  final bool isMakki;
  final String subtitle;

  const _PopularSurahData({
    required this.number,
    required this.nameFa,
    required this.nameAr,
    required this.englishName,
    required this.ayahCount,
    required this.isMakki,
    required this.subtitle,
  });
}

const _popularSurahs = [
  _PopularSurahData(
    number: 36,
    nameFa: 'یاسین',
    nameAr: 'يس',
    englishName: 'Yaseen',
    ayahCount: 83,
    isMakki: true,
    subtitle: 'قلب قرآن کریم',
  ),
  _PopularSurahData(
    number: 55,
    nameFa: 'الرحمن',
    nameAr: 'الرَّحْمَن',
    englishName: 'Ar-Rahman',
    ayahCount: 78,
    isMakki: false,
    subtitle: 'عروس قرآن',
  ),
  _PopularSurahData(
    number: 67,
    nameFa: 'ملک',
    nameAr: 'المُلْك',
    englishName: 'Al-Mulk',
    ayahCount: 30,
    isMakki: true,
    subtitle: 'سوره تبارک و نجات',
  ),
  _PopularSurahData(
    number: 56,
    nameFa: 'واقعه',
    nameAr: 'الوَاقِعَة',
    englishName: 'Al-Waqi\'ah',
    ayahCount: 96,
    isMakki: true,
    subtitle: 'سوره برکت و رزق',
  ),
  _PopularSurahData(
    number: 18,
    nameFa: 'کهف',
    nameAr: 'الكَهْف',
    englishName: 'Al-Kahf',
    ayahCount: 110,
    isMakki: true,
    subtitle: 'نور میان دو جمعه',
  ),
  _PopularSurahData(
    number: 78,
    nameFa: 'نبأ',
    nameAr: 'النَّبَأ',
    englishName: 'An-Naba',
    ayahCount: 40,
    isMakki: true,
    subtitle: 'خبر بزرگ قیامت',
  ),
];

/// Desktop Grid for Most Popular / Recited Surahs
class WebPopularSurahsGrid extends ConsumerWidget {
  const WebPopularSurahsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'سوره‌های پرطرفدار و منتخب',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                context.pushNamed(surahListRoute);
              },
              icon: const Icon(CupertinoIcons.square_grid_2x2, size: 16),
              label: const Text(
                'مشاهده همه ۱۱۴ سوره',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Grid Layout: 3 columns on standard wide screen, 6 columns on large screen
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _popularSurahs.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final surah = _popularSurahs[index];
            return _SurahHoverCard(
              surah: surah,
              colors: colors,
              colorScheme: colorScheme,
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }
}

class _SurahHoverCard extends ConsumerStatefulWidget {
  final _PopularSurahData surah;
  final dynamic colors;
  final ColorScheme colorScheme;
  final bool isDark;

  const _SurahHoverCard({
    required this.surah,
    required this.colors,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  ConsumerState<_SurahHoverCard> createState() => _SurahHoverCardState();
}

class _SurahHoverCardState extends ConsumerState<_SurahHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final colorScheme = widget.colorScheme;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: widget.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary.withValues(alpha: 0.5)
                : widget.colors.cardBorder,
            width: _isHovered ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.10)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: _isHovered ? 14 : 6,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(quranDisplaySettingsControllerProvider.notifier)
                  .toggleArabicText(true);
              context.pushNamed(
                quranReaderRoute,
                pathParameters: {'id': surah.number.toString()},
                queryParameters: {'name': surah.nameFa},
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Surah Number Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? colorScheme.primary
                          : colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        surah.number.toPersianDigit(),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? Colors.white : colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Surah Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
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
                            const Spacer(),
                            Text(
                              surah.nameAr,
                              style: TextStyle(
                                fontFamily: AppTypography.uthmanicFont,
                                fontSize: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          surah.subtitle,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${surah.ayahCount.toPersianDigit()} آیه',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: surah.isMakki
                                    ? Colors.amber.withValues(alpha: 0.12)
                                    : Colors.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                surah.isMakki ? 'مکی' : 'مدنی',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: surah.isMakki
                                      ? Colors.amber.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Quick Play Icon Button
                            IconButton(
                              tooltip: 'پخش سریع تلاوت',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                CupertinoIcons.play_circle_fill,
                                size: 24,
                                color: _isHovered
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                ref
                                    .read(quranAudioControllerProvider.notifier)
                                    .playAyah(
                                      surahId: surah.number,
                                      ayahNumber: 1,
                                      totalAyahsInSurah: surah.ayahCount,
                                    );
                              },
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
        ),
      ),
    );
  }
}
