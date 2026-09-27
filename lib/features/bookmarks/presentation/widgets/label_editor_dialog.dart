import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/bookmark_labels_controller.dart';
import '../../domain/entities/bookmark_label.dart';

/// Clean, centered modal dialog for creating a new label or editing an existing label.
/// Does not suffer from keyboard bottom-sheet pushing / overflowing bugs.
class LabelEditorDialog extends ConsumerStatefulWidget {
  final BookmarkLabel? initialLabel;

  const LabelEditorDialog({
    super.key,
    this.initialLabel,
  });

  static Future<BookmarkLabel?> show(
    BuildContext context, {
    BookmarkLabel? initialLabel,
  }) {
    return showDialog<BookmarkLabel>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => LabelEditorDialog(initialLabel: initialLabel),
    );
  }

  @override
  ConsumerState<LabelEditorDialog> createState() => _LabelEditorDialogState();
}

class _LabelEditorDialogState extends ConsumerState<LabelEditorDialog> {
  late final TextEditingController _titleController;
  bool get _isEditing => widget.initialLabel != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialLabel?.title ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.showError(context, 'لطفاً نام برچسب را وارد کنید.');
      return;
    }

    HapticFeedback.lightImpact();

    if (_isEditing) {
      await ref
          .read(bookmarkLabelsControllerProvider.notifier)
          .updateLabel(
            widget.initialLabel!.id,
            title: title,
            colorValue: widget.initialLabel!.colorValue,
          );
      final updated = widget.initialLabel!.copyWith(title: title);
      if (mounted) {
        Navigator.of(context).pop(updated);
        AppSnackBar.showSuccess(
          context,
          'برچسب «$title» ویرایش شد.',
        );
      }
    } else {
      final created = await ref
          .read(bookmarkLabelsControllerProvider.notifier)
          .addLabel(title);
      if (mounted) {
        Navigator.of(context).pop(created);
        AppSnackBar.showSuccess(
          context,
          'برچسب «$title» افزوده شد.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: colors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppModalHeader(
                title: _isEditing ? 'ویرایش برچسب' : 'برچسب جدید',
                onClose: () => Navigator.of(context).pop(),
                bottomSpacing: 14,
              ),

              // Title input field
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.cardBorder,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'عنوان برچسب (مثلاً: آیات امیدبخش)',
                    hintStyle: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12.5,
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              16.vSpace,

              // Action Buttons (انصراف و ثبت)
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        'انصراف',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  10.hSpace,
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        _isEditing ? 'ذخیره تغییرات' : 'ثبت برچسب',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
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
  }
}
