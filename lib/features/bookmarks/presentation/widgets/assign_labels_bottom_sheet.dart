import 'package:flutter/cupertino.dart';
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
import 'label_editor_dialog.dart';
import 'manage_labels_bottom_sheet.dart';

/// Luxury bottom sheet for attaching / detaching labels to a specific Ayah bookmark.
class AssignLabelsBottomSheet extends ConsumerStatefulWidget {
  final int surahId;
  final int ayahNumber;
  final String surahName;
  final List<String> initialLabelIds;

  const AssignLabelsBottomSheet({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.surahName,
    this.initialLabelIds = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required int surahId,
    required int ayahNumber,
    required String surahName,
    List<String> initialLabelIds = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignLabelsBottomSheet(
        surahId: surahId,
        ayahNumber: ayahNumber,
        surahName: surahName,
        initialLabelIds: initialLabelIds,
      ),
    );
  }

  @override
  ConsumerState<AssignLabelsBottomSheet> createState() =>
      _AssignLabelsBottomSheetState();
}

class _AssignLabelsBottomSheetState
    extends ConsumerState<AssignLabelsBottomSheet> {
  late Set<String> _selectedLabelIds;

  @override
  void initState() {
    super.initState();
    _selectedLabelIds = Set<String>.from(widget.initialLabelIds);
  }

  void _toggleLabel(String labelId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedLabelIds.contains(labelId)) {
        _selectedLabelIds.remove(labelId);
      } else {
        _selectedLabelIds.add(labelId);
      }
    });
  }

  Future<void> _applyChanges() async {
    HapticFeedback.lightImpact();
    await ref.read(bookmarksControllerProvider.notifier).updateBookmarkLabels(
          surahId: widget.surahId,
          ayahNumber: widget.ayahNumber,
          labelIds: _selectedLabelIds.toList(),
        );

    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(context, 'برچسب‌های نشانه به‌روزرسانی شدند.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final labels = ref.watch(bookmarkLabelsControllerProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight * 0.72).clamp(440.0, 650.0);

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
                  title: 'برچسب‌های نشانه',
                  bottomSpacing: 4,
                  leadingAction: IconButton(
                    tooltip: 'مدیریت برچسب‌ها',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                    icon: Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: 20,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      ManageLabelsBottomSheet.show(context);
                    },
                  ),
                ),

                // Ayah Info Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'سوره ${widget.surahName} • آیه ${widget.ayahNumber.toPersianDigit()}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                10.vSpace,



                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: colors.cardBorder,
                ),

                // Labels List
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                      vertical: 10,
                    ),
                    itemCount: labels.length + 1,
                    separatorBuilder: (_, _) => 6.vSpace,
                    itemBuilder: (context, index) {
                      // Last item is "Create new label" button
                      if (index == labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final newLabel =
                                  await LabelEditorDialog.show(context);
                              if (newLabel != null && mounted) {
                                setState(() {
                                  _selectedLabelIds.add(newLabel.id);
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.cardBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.plus,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  6.hSpace,
                                  Text(
                                    'ایجاد برچسب جدید',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final label = labels[index];
                      final isSelected = _selectedLabelIds.contains(label.id);

                      return InkWell(
                        key: ValueKey(label.id),
                        onTap: () => _toggleLabel(label.id),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04))
                                : colors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colors.cardBorder,
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Selection Checkbox Icon
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : textSecondary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              12.hSpace,

                              // Title
                              Expanded(
                                child: Text(
                                  label.title,
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),

                              if (label.isDefault) ...[
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Save Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.marginPage,
                    8,
                    AppDimens.marginPage,
                    14,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _applyChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusDefault),
                        ),
                      ),
                      child: Text(
                        _selectedLabelIds.isEmpty
                            ? 'ذخیره (بدون برچسب)'
                            : 'تأیید (${_selectedLabelIds.length.toPersianDigit()} برچسب)',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
