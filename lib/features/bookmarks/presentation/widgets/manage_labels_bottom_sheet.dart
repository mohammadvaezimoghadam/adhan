import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/bookmark_labels_controller.dart';
import '../../application/controllers/bookmarks_controller.dart';
import '../../domain/entities/bookmark_label.dart';
import 'label_editor_dialog.dart';

/// Minimalist bottom sheet for managing, creating, editing, and deleting custom bookmark labels.
class ManageLabelsBottomSheet extends ConsumerStatefulWidget {
  const ManageLabelsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManageLabelsBottomSheet(),
    );
  }

  @override
  ConsumerState<ManageLabelsBottomSheet> createState() =>
      _ManageLabelsBottomSheetState();
}

class _ManageLabelsBottomSheetState
    extends ConsumerState<ManageLabelsBottomSheet> {
  Future<void> _startCreating() async {
    HapticFeedback.lightImpact();
    await LabelEditorDialog.show(context);
  }

  Future<void> _startEditing(BookmarkLabel label) async {
    HapticFeedback.lightImpact();
    await LabelEditorDialog.show(context, initialLabel: label);
  }

  Future<void> _confirmDeleteLabel(BookmarkLabel label) async {
    final colors = context.colors;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: colors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppModalHeader(
                title: 'حذف برچسب',
                onClose: () => Navigator.of(dialogCtx).pop(false),
                bottomSpacing: 14,
              ),
              Text(
                'آیا از حذف برچسب «${label.title}» مطمئن هستید؟\nاین برچسب از تمام نشانه‌ها برداشته می‌شود، اما خود نشانه‌ها باقی می‌مانند.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 1.6,
                  color: textSecondary,
                ),
              ),
              20.vSpace,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'انصراف',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  12.hSpace,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'حذف برچسب',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13.5,
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
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await ref
          .read(bookmarkLabelsControllerProvider.notifier)
          .deleteLabel(label.id);
      if (mounted) {
        AppSnackBar.showInfo(context, 'برچسب «${label.title}» حذف شد.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final labels = ref.watch(bookmarkLabelsControllerProvider);
    final bookmarks = ref.watch(bookmarksControllerProvider);

    final bookmarkCounts = <String, int>{};
    for (final b in bookmarks) {
      for (final id in b.labelIds) {
        bookmarkCounts[id] = (bookmarkCounts[id] ?? 0) + 1;
      }
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight * 0.78).clamp(480.0, 720.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: colors.dialogSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              AppModalHeader(
                showDragHandle: true,
                title: 'مدیریت برچسب‌ها',
                bottomSpacing: 8,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.marginPage,
                  vertical: 8,
                ),
                child: InkWell(
                  onTap: _startCreating,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ افزودن برچسب جدید',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                      ),
                    ),
                  ),
                ),
              ),

                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: colors.cardBorder,
                ),

                // Labels List
                Expanded(
                  child: labels.isEmpty
                      ? Center(
                          child: Text(
                            'هیچ برچسبی یافت نشد',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.marginPage,
                            vertical: 12,
                          ),
                          itemCount: labels.length,
                          separatorBuilder: (_, _) => 8.vSpace,
                          itemBuilder: (context, index) {
                            final label = labels[index];
                            final bookmarkCount = bookmarkCounts[label.id] ?? 0;

                            return _buildLabelTile(
                              key: ValueKey(label.id),
                              context: context,
                              label: label,
                              bookmarkCount: bookmarkCount,
                              isDark: isDark,
                              textSecondary: textSecondary,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
  }



  Widget _buildLabelTile({
    Key? key,
    required BuildContext context,
    required BookmarkLabel label,
    required int bookmarkCount,
    required bool isDark,
    required Color textSecondary,
  }) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.cardBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Title & Count
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label.title,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (label.isDefault) ...[
                  8.hSpace,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'پیش‌فرض',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
                8.hSpace,
                Text(
                  bookmarkCount > 0
                      ? '• ${bookmarkCount.toPersianDigit()} نشانه'
                      : '• بدون نشانه',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Actions: Text buttons (Edit and Delete)
          TextButton(
            onPressed: () => _startEditing(label),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: colorScheme.primary,
            ),
            child: const Text(
              'ویرایش',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          4.hSpace,
          TextButton(
            onPressed: () => _confirmDeleteLabel(label),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: isDark ? Colors.white38 : Colors.black38,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
