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
import '../../application/controllers/bookmarks_controller.dart';

/// Luxury bottom sheet for writing, viewing, editing, and removing personal notes on bookmarked Ayahs.
class BookmarkNoteBottomSheet extends ConsumerStatefulWidget {
  final int surahId;
  final int ayahNumber;
  final String surahName;
  final String? initialNote;

  const BookmarkNoteBottomSheet({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.surahName,
    this.initialNote,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahId,
    required int ayahNumber,
    required String surahName,
    String? initialNote,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarkNoteBottomSheet(
        surahId: surahId,
        ayahNumber: ayahNumber,
        surahName: surahName,
        initialNote: initialNote,
      ),
    );
  }

  @override
  ConsumerState<BookmarkNoteBottomSheet> createState() =>
      _BookmarkNoteBottomSheetState();
}

class _BookmarkNoteBottomSheetState
    extends ConsumerState<BookmarkNoteBottomSheet> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    HapticFeedback.lightImpact();
    final text = _noteController.text.trim();

    await ref.read(bookmarksControllerProvider.notifier).updateBookmarkNote(
          surahId: widget.surahId,
          ayahNumber: widget.ayahNumber,
          note: text.isNotEmpty ? text : null,
        );

    if (mounted) {
      Navigator.of(context).pop();
      if (text.isNotEmpty) {
        AppSnackBar.showSuccess(context, 'یادداشت شخصی ذخیره شد.');
      } else {
        AppSnackBar.showInfo(context, 'یادداشت این نشانه برداشته شد.');
      }
    }
  }

  Future<void> _deleteNote() async {
    HapticFeedback.lightImpact();
    await ref.read(bookmarksControllerProvider.notifier).updateBookmarkNote(
          surahId: widget.surahId,
          ayahNumber: widget.ayahNumber,
          note: null,
        );

    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showInfo(context, 'یادداشت این نشانه حذف شد.');
    }
  }

  Future<void> _copyNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppSnackBar.showSuccess(context, 'متن یادداشت کپی شد.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final viewInsets = MediaQuery.viewInsetsOf(context);
    final hasExistingNote =
        widget.initialNote != null && widget.initialNote!.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutQuad,
        child: Container(
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  AppModalHeader(
                    showDragHandle: true,
                    title: 'یادداشت شخصی آیه',
                    bottomSpacing: 6,
                  ),

                  // Ayah Info Badge
                  Center(
                    child: Text(
                      'سوره ${widget.surahName} • آیه ${widget.ayahNumber.toPersianDigit()}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  14.vSpace,

                  // Note Text Area
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF7F5F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 12,
                              left: 36,
                              top: 12,
                              bottom: 12,
                            ),
                            child: TextField(
                              controller: _noteController,
                              autofocus: true,
                              maxLines: 6,
                              minLines: 4,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14,
                                height: 1.6,
                                color: colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'برداشت، دل‌نوشته، نکته تفسیری یا یادآوری شخصی خود را در این قسمت بنویسید...',
                                hintStyle: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  height: 1.6,
                                  color: textSecondary.withValues(alpha: 0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _noteController,
                              builder: (context, value, _) {
                                if (value.text.trim().isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  icon: const Icon(
                                    CupertinoIcons.doc_on_doc,
                                    size: 16,
                                  ),
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  tooltip: 'کپی متن',
                                  onPressed: _copyNote,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  16.vSpace,

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                    ),
                    child: Row(
                      children: [
                        // Save Button
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _saveNote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'ذخیره یادداشت',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasExistingNote) ...[
                          10.hSpace,
                          // Delete Note Button
                          SizedBox(
                            height: 44,
                            child: TextButton.icon(
                              onPressed: _deleteNote,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(CupertinoIcons.trash, size: 16),
                              label: const Text(
                                'حذف',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  14.vSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
