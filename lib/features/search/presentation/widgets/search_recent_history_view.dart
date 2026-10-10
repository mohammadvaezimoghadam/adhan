import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/theme/app_typography.dart';

class SearchRecentHistoryView extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onSearchSelected;
  final ValueChanged<String> onRemoveSearch;
  final VoidCallback onClearAll;

  const SearchRecentHistoryView({
    super.key,
    required this.recentSearches,
    required this.onSearchSelected,
    required this.onRemoveSearch,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    if (recentSearches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 56.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(
                    alpha: isDark ? 0.14 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.search,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              18.vSpace,
              Text(
                'جستجو در قرآن کریم',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              8.vSpace,
              Text(
                'می‌توانید نام سوره، شماره سوره، کلمات آیه به عربی یا ترجمه فارسی را جستجو کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 1.6,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 16,
                color: colorScheme.primary,
              ),
              8.hSpace,
              Expanded(
                child: Text(
                  'جستجوهای اخیر',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              8.hSpace,
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onClearAll();
                },
                child: Text(
                  'پاک کردن همه',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          12.vSpace,
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: recentSearches.map((term) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.cardBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSearchSelected(term);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 12.0,
                              top: 5.0,
                              bottom: 5.0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    term,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 12.5,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                6.hSpace,
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onRemoveSearch(term);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Icon(
                                      CupertinoIcons.xmark,
                                      size: 12,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
