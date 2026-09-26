import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/surah_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';

/// Desktop Quick Navigation Card allowing direct jumps to Surahs, Juz, and Pages
class WebQuickNavigatorCard extends ConsumerStatefulWidget {
  const WebQuickNavigatorCard({super.key});

  @override
  ConsumerState<WebQuickNavigatorCard> createState() =>
      _WebQuickNavigatorCardState();
}

class _WebQuickNavigatorCardState extends ConsumerState<WebQuickNavigatorCard> {
  int _selectedSurah = 1;
  int _selectedJuz = 1;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.compass,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'پرش و دسترسی مستقیم',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Surah Selector
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'انتخاب سوره',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1EFEA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.cardBorder, width: 0.8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedSurah,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: colors.dialogSurface,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                          items: List.generate(114, (i) {
                            final id = i + 1;
                            final name = SurahConstants.getSurahName(id);
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                '${id.toPersianDigit()}. سوره $name',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSurah = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Juz Selector
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'انتخاب جزء',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1EFEA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.cardBorder, width: 0.8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedJuz,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: colors.dialogSurface,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                          items: List.generate(30, (i) {
                            final id = i + 1;
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text('جزء ${id.toPersianDigit()}'),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedJuz = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Jump Action Button
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.arrow_left, size: 16),
                  label: const Text(
                    'ورود',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(quranDisplaySettingsControllerProvider.notifier)
                        .toggleArabicText(true);
                    final name = SurahConstants.getSurahName(_selectedSurah);
                    context.pushNamed(
                      quranReaderRoute,
                      pathParameters: {'id': _selectedSurah.toString()},
                      queryParameters: {'name': name},
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
