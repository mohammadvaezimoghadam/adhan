import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/bookmark_labels_controller.dart';
import '../../application/controllers/bookmarks_controller.dart';
import 'manage_labels_bottom_sheet.dart';

/// Horizontal scrollable bar with Apple-inspired filter chips for Bookmark Labels.
/// Highly optimized with single-pass histogram counting and uniform clean styling.
class LabelFilterChipsBar extends ConsumerWidget {
  final String? selectedLabelId;
  final ValueChanged<String?> onLabelSelected;
  final VoidCallback? onManageLabelsTap;

  const LabelFilterChipsBar({
    super.key,
    required this.selectedLabelId,
    required this.onLabelSelected,
    this.onManageLabelsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final labels = ref.watch(bookmarkLabelsControllerProvider);
    final bookmarks = ref.watch(bookmarksControllerProvider);

    // Compute histogram in a single O(N) pass instead of O(M*N) in itemBuilder
    final totalCount = bookmarks.length;
    int unlabeledCount = 0;
    final labelCounts = <String, int>{};

    for (final b in bookmarks) {
      if (b.labelIds.isEmpty) {
        unlabeledCount++;
      } else {
        for (final lId in b.labelIds) {
          labelCounts[lId] = (labelCounts[lId] ?? 0) + 1;
        }
      }
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.marginPage),
        itemCount: labels.length + 3, // All + Unlabeled + Labels + Manage Button
        separatorBuilder: (_, _) => 8.hSpace,
        itemBuilder: (context, index) {
          // 1. "All" (همه)
          if (index == 0) {
            final isSelected = selectedLabelId == null;
            return _buildChip(
              context: context,
              title: 'همه',
              count: totalCount,
              isSelected: isSelected,
              activeColor: colorScheme.primary,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onLabelSelected(null);
              },
            );
          }

          // 2. "Unlabeled" (بدون برچسب)
          if (index == 1) {
            final isSelected = selectedLabelId == 'unlabeled';
            return _buildChip(
              context: context,
              title: 'بدون برچسب',
              count: unlabeledCount,
              isSelected: isSelected,
              activeColor: isDark ? Colors.white70 : Colors.black87,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onLabelSelected('unlabeled');
              },
            );
          }

          // 3. Trailing "Manage Labels" button
          if (index == labels.length + 2) {
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (onManageLabelsTap != null) {
                  onManageLabelsTap!();
                } else {
                  ManageLabelsBottomSheet.show(context);
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: colors.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: 14,
                      color: textSecondary,
                    ),
                    6.hSpace,
                    Text(
                      'مدیریت',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Custom Labels (O(1) count lookup)
          final label = labels[index - 2];
          final isSelected = selectedLabelId == label.id;
          final count = labelCounts[label.id] ?? 0;

          return _buildChip(
            context: context,
            title: label.title,
            count: count,
            activeColor: colorScheme.primary,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              onLabelSelected(label.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String title,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : colors.cardBackground),
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: Colors.transparent, width: 0.8)
              : Border.all(color: colors.cardBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : colorScheme.onSurface,
              ),
            ),
            4.hSpace,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.18)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toPersianDigit(),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
