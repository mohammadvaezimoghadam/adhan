import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/favorite_surahs_controller.dart';
import '../../application/controllers/surah_list_controller.dart';
import '../../domain/entities/surah_entity.dart';
import '../../domain/enums/surah_sort_options.dart';
import '../widgets/surah_grid_card.dart';
import '../widgets/surah_list_quick_actions.dart';

enum _WebSurahFilter {
  all('همه سوره‌ها'),
  makki('سوره‌های مکی'),
  madani('سوره‌های مدنی'),
  favorites('علاقه‌مندی‌ها');

  final String label;
  const _WebSurahFilter(this.label);
}

/// Dedicated Enterprise-Grade Web Catalog View for Quran Surahs.
/// Tailored for desktop browsers with instant search, filter tabs,
/// popup sort menus, and responsive hover-lift cards.
class WebSurahCatalogView extends ConsumerStatefulWidget {
  final ValueChanged<SurahEntity> onOpenReader;
  final ValueChanged<SurahEntity> onDownloadTap;
  final VoidCallback onBeforeNavigation;

  const WebSurahCatalogView({
    super.key,
    required this.onOpenReader,
    required this.onDownloadTap,
    required this.onBeforeNavigation,
  });

  @override
  ConsumerState<WebSurahCatalogView> createState() =>
      _WebSurahCatalogViewState();
}

class _WebSurahCatalogViewState extends ConsumerState<WebSurahCatalogView> {
  _WebSurahFilter _activeFilter = _WebSurahFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final surahListState = ref.watch(surahListControllerProvider);
    final favoriteIds = ref.watch(favoriteSurahsProvider);
    final rawSurahs = surahListState.filteredSurahs;

    // Apply active web filter
    final List<SurahEntity> displayedSurahs;
    switch (_activeFilter) {
      case _WebSurahFilter.all:
        displayedSurahs = rawSurahs;
        break;
      case _WebSurahFilter.makki:
        displayedSurahs = rawSurahs.where((s) => s.isMeccan).toList();
        break;
      case _WebSurahFilter.madani:
        displayedSurahs = rawSurahs.where((s) => !s.isMeccan).toList();
        break;
      case _WebSurahFilter.favorites:
        displayedSurahs = rawSurahs
            .where((s) => favoriteIds.contains(s.number))
            .toList();
        break;
    }

    final currentSortBy = surahListState.sortBy;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Web Catalog Header Toolbar ──
            Container(
              margin: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.cardBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  // Title & Count Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.book_fill,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'فهرست سوره‌های قرآن کریم',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${displayedSurahs.length.toPersianDigit()} سوره',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Inline Search Input
                  Container(
                    width: 260,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1EFEA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.cardBorder, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 16,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (q) {
                              ref
                                  .read(surahListControllerProvider.notifier)
                                  .searchSurahs(q);
                            },
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'جستجوی نام یا شماره سوره...',
                              hintStyle: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              ref
                                  .read(surahListControllerProvider.notifier)
                                  .searchSurahs('');
                              setState(() {});
                            },
                            child: Icon(
                              CupertinoIcons.clear_circled_solid,
                              size: 15,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Desktop Sort Menu (PopupMenuButton instead of Bottom Sheet!)
                  PopupMenuButton<SurahSortBy>(
                    tooltip: 'مرتب‌سازی سوره‌ها',
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colors.cardBorder, width: 0.8),
                    ),
                    color: colors.dialogSurface,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1EFEA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.cardBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_up_arrow_down,
                            size: 15,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'مرتب‌سازی: ${currentSortBy.label}',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_down,
                            size: 12,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) {
                      return SurahSortBy.values.map((sort) {
                        final isSelected = currentSortBy == sort;
                        return PopupMenuItem<SurahSortBy>(
                          value: sort,
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_alt
                                    : CupertinoIcons.circle,
                                size: 16,
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.transparent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                sort.label,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    onSelected: (selectedSort) {
                      ref
                          .read(surahListControllerProvider.notifier)
                          .setSortBy(selectedSort);
                    },
                  ),
                ],
              ),
            ),

            // ── 2. Filter Pills Tab Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
              child: Row(
                children: [
                  for (final filter in _WebSurahFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: _activeFilter == filter,
                        onSelected: (selected) {
                          if (selected) setState(() => _activeFilter = filter);
                        },
                        labelStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          fontWeight: _activeFilter == filter
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _activeFilter == filter
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                        ),
                        selectedColor: colorScheme.primary,
                        backgroundColor: colors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _activeFilter == filter
                                ? colorScheme.primary
                                : colors.cardBorder,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Quick Actions Bar (سوره‌های پرطرفدار و چهار قل)
                  SurahListQuickActions(
                    onBeforeNavigation: widget.onBeforeNavigation,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── 3. Main Surahs Grid ──
            Expanded(
              child: displayedSurahs.isEmpty
                  ? Center(
                      child: Text(
                        'هیچ سوره‌ای یافت نشد.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: displayedSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = displayedSurahs[index];
                        return SurahGridCard(
                          key: ValueKey(surah.number),
                          surah: surah,
                          onTap: () => widget.onOpenReader(surah),
                          onDownloadTap: () => widget.onDownloadTap(surah),
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
