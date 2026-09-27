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
import '../../domain/entities/bookmark_label.dart';
import 'label_editor_dialog.dart';

/// Unified luxury bottom sheet for creating, editing, and saving an Ayah bookmark
/// complete with personal reflection note and customizable categorization labels.
class AyahBookmarkEditorBottomSheet extends ConsumerStatefulWidget {
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final int totalAyahs;
  final String? arabicText;
  final String? initialNote;
  final List<String> initialLabelIds;
  final bool isAlreadyBookmarked;
  final bool isAyahBookmark;

  const AyahBookmarkEditorBottomSheet({
    super.key,
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.totalAyahs,
    this.arabicText,
    this.initialNote,
    this.initialLabelIds = const [],
    this.isAlreadyBookmarked = false,
    this.isAyahBookmark = true,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahId,
    required String surahName,
    required int ayahNumber,
    required int totalAyahs,
    String? arabicText,
    String? initialNote,
    List<String> initialLabelIds = const [],
    bool isAlreadyBookmarked = false,
    bool isAyahBookmark = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AyahBookmarkEditorBottomSheet(
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        totalAyahs: totalAyahs,
        arabicText: arabicText,
        initialNote: initialNote,
        initialLabelIds: initialLabelIds,
        isAlreadyBookmarked: isAlreadyBookmarked,
        isAyahBookmark: isAyahBookmark,
      ),
    );
  }

  @override
  ConsumerState<AyahBookmarkEditorBottomSheet> createState() =>
      _AyahBookmarkEditorBottomSheetState();
}

class _AyahBookmarkEditorBottomSheetState
    extends ConsumerState<AyahBookmarkEditorBottomSheet> {
  late final TextEditingController _noteController;
  late Set<String> _selectedLabelIds;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _selectedLabelIds = Set<String>.from(widget.initialLabelIds);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  Future<void> _openCreateLabelDialog() async {
    HapticFeedback.lightImpact();
    final newLabel = await LabelEditorDialog.show(context);

    if (newLabel != null && mounted) {
      setState(() {
        _selectedLabelIds.add(newLabel.id);
      });
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

  Future<void> _saveBookmark() async {
    HapticFeedback.lightImpact();
    final noteText = widget.isAyahBookmark ? _noteController.text.trim() : '';

    await ref.read(bookmarksControllerProvider.notifier).saveOrUpdateAyahBookmark(
          surahId: widget.surahId,
          surahName: widget.surahName,
          ayahNumber: widget.ayahNumber,
          totalAyahs: widget.totalAyahs,
          arabicText: widget.isAyahBookmark ? widget.arabicText : null,
          labelIds: _selectedLabelIds.toList(),
          note: noteText.isNotEmpty ? noteText : null,
          isAyahBookmark: widget.isAyahBookmark,
        );

    if (mounted) {
      Navigator.of(context).pop();
      final cleanSurah = widget.surahName.replaceAll('سوره', '').trim();
      final typeLabel = widget.isAyahBookmark
          ? 'آیه ${widget.ayahNumber.toPersianDigit()}'
          : 'صفحه (آیه ${widget.ayahNumber.toPersianDigit()})';
      AppSnackBar.showSuccess(
        context,
        widget.isAlreadyBookmarked
            ? 'تغییرات نشانه $typeLabel سوره $cleanSurah ذخیره شد.'
            : 'نشانه $typeLabel سوره $cleanSurah ذخیره شد.',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final allLabels = ref.watch(bookmarkLabelsControllerProvider);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final cleanSurah = widget.surahName.replaceAll('سوره', '').trim();

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
                  // 1. Modal Header
                  AppModalHeader(
                    showDragHandle: true,
                    title: widget.isAlreadyBookmarked
                        ? (widget.isAyahBookmark ? 'ویرایش نشانه آیه' : 'ویرایش نشانک صفحه')
                        : (widget.isAyahBookmark ? 'نشانه‌گذاری آیه' : 'نشانه‌گذاری صفحه'),
                    bottomSpacing: 6,
                  ),

                  // 2. Ayah Subtitle & optional Arabic preview
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'سوره $cleanSurah • آیه ${widget.ayahNumber.toPersianDigit()}',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        if (widget.isAyahBookmark &&
                            widget.arabicText != null &&
                            widget.arabicText!.isNotEmpty) ...[
                          6.vSpace,
                          Text(
                            widget.arabicText!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'UthmanicHafs',
                              fontSize: 13.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.isAyahBookmark) ...[
                    14.vSpace,

                    // 3. Section: Personal Note
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.marginPage,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'متن یا دل‌نوشته شخصی',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          8.vSpace,
                          Container(
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
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  child: TextField(
                                    controller: _noteController,
                                    maxLines: 4,
                                    minLines: 3,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'برداشت، دل‌نوشته، نکته تفسیری یا یادآوری شخصی خود را اینجا بنویسید...',
                                      hintStyle: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 12.5,
                                        height: 1.5,
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
                        ],
                      ),
                    ),
                    16.vSpace,
                  ] else ...[
                    14.vSpace,
                  ],

                  // 4. Section: Labels
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'برچسب‌ها',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        8.hSpace,
                        // Quick Add "+" button right next to title
                        InkWell(
                          onTap: _openCreateLabelDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF7F5F0),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.cardBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.plus,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  8.vSpace,

                  // 2-Row Horizontal Scrollable Chips
                  if (allLabels.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.marginPage,
                      ),
                      child: Text(
                        'هنوز برچسبی ایجاد نشده است.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        final row1 = <BookmarkLabel>[];
                        final row2 = <BookmarkLabel>[];
                        for (int i = 0; i < allLabels.length; i++) {
                          if (i % 2 == 0) {
                            row1.add(allLabels[i]);
                          } else {
                            row2.add(allLabels[i]);
                          }
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.marginPage,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: row1
                                    .map((l) => Padding(
                                          padding: const EdgeInsetsDirectional.only(end: 6.0),
                                          child: _buildLabelChip(l, colors, colorScheme, isDark),
                                        ))
                                    .toList(),
                              ),
                              if (row2.isNotEmpty) ...[
                                6.vSpace,
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: row2
                                      .map((l) => Padding(
                                            padding: const EdgeInsetsDirectional.only(end: 6.0),
                                            child: _buildLabelChip(l, colors, colorScheme, isDark),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  20.vSpace,

                  // 5. Action Buttons (انصراف و تأیید/ذخیره)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                    ),
                    child: Row(
                      children: [
                        // انصراف (Cancel)
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: colors.cardBorder,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                        ),
                        12.hSpace,

                        // تأیید و ذخیره (Confirm & Save)
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _saveBookmark,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                widget.isAlreadyBookmarked
                                    ? 'ذخیره تغییرات'
                                    : 'تأیید و نشانه‌گذاری',
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  12.vSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(
    BookmarkLabel label,
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isSelected = _selectedLabelIds.contains(label.id);
    return InkWell(
      key: ValueKey(label.id),
      onTap: () => _toggleLabel(label.id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF7F5F0)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.35)
                : colors.cardBorder,
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                CupertinoIcons.checkmark_alt,
                size: 14,
                color: colorScheme.primary,
              ),
              5.hSpace,
            ],
            Text(
              label.title,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.87)
                        : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


