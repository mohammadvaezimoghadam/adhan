import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../common/widgets/app_segmented_tab_bar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookmarks/application/controllers/bookmarks_controller.dart';
import '../../../bookmarks/application/controllers/bookmark_labels_controller.dart';
import '../../../bookmarks/domain/entities/bookmark_item.dart';
import '../../../bookmarks/domain/entities/bookmark_label.dart';
import '../../../bookmarks/presentation/widgets/ayah_bookmark_editor_bottom_sheet.dart';
import '../../../bookmarks/presentation/widgets/label_filter_chips_bar.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';

/// Luxury bottom sheet for managing saved bookmarks with tabs for All Bookmarks and Saved Ayahs.
class BookmarksManagerBottomSheet extends ConsumerStatefulWidget {
  const BookmarksManagerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BookmarksManagerBottomSheet(),
    );
  }

  @override
  ConsumerState<BookmarksManagerBottomSheet> createState() =>
      _BookmarksManagerBottomSheetState();
}

class _BookmarksManagerBottomSheetState
    extends ConsumerState<BookmarksManagerBottomSheet> {
  int _selectedTabIndex = 0; // 0: All, 1: Ayahs
  String? _selectedLabelId; // null: All, 'unlabeled': without labels, or specific labelId

  void _navigateToAyah(BookmarkItem item) {
    Navigator.of(context).pop();
    ref.read(quranDisplaySettingsControllerProvider.notifier).toggleArabicText(true);

    Future.microtask(() {
      if (mounted) {
        context.pushNamed(
          quranReaderRoute,
          pathParameters: {'id': item.surahId.toString()},
          queryParameters: {
            'name': item.surahName,
            'ayah': item.ayahNumber.toString(),
          },
        );
      }
    });
  }

  Future<void> _confirmClearAll() async {
    final colors = context.colors;
    final isDark = context.isDark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: colors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppModalHeader(
                title: 'حذف همه نشانه‌ها',
                onClose: () => Navigator.of(dialogCtx).pop(false),
                bottomSpacing: 12,
              ),
              8.vSpace,
              Text(
                'آیا مطمئن هستید که می‌خواهید تمام نشانه‌های ذخیره‌شده را حذف کنید؟ این عمل غیرقابل بازگشت است.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              20.vSpace,
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: const Text(
                    'حذف تمام نشانه‌ها',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
              6.vSpace,
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(
                    'انصراف',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(bookmarksControllerProvider.notifier).clearAll();
      HapticFeedback.mediumImpact();
      if (mounted) {
        AppSnackBar.showInfo(context, 'تمام نشانه‌ها پاک شدند.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarks = ref.watch(bookmarksControllerProvider);
    final labelMap = ref.watch(bookmarkLabelsMapProvider);
    final fontScript = ref.watch(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final arabicFontFamily = AppTypography.getFontFamilyByScript(fontScript);

    // Separate page/reading bookmarks from individual ayah bookmarks
    final readingBookmarks = bookmarks.where((b) => !b.isAyahBookmark).toList();
    final ayahBookmarks = bookmarks.where((b) => b.isAyahBookmark).toList();

    final baseList = _selectedTabIndex == 0 ? readingBookmarks : ayahBookmarks;
    final currentDisplayList = _selectedLabelId == null
        ? baseList
        : _selectedLabelId == 'unlabeled'
            ? baseList.where((b) => b.labelIds.isEmpty).toList()
            : baseList
                .where((b) => b.labelIds.contains(_selectedLabelId))
                .toList();

    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final sheetBg = colors.dialogSurface;
    final cardBg = colors.cardBackground;
    final borderColor = colors.cardBorder;
    final primaryColor = colorScheme.primary;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenHeight * 0.72).clamp(450.0, 680.0);

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: sheetBg,
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
            // 1. Drag Handle & Header
            AppModalHeader(
              showDragHandle: true,
              bottomSpacing: 12.0,
              title: 'نشانه‌های ذخیره‌شده',
              leadingActionWidth: 72.0,
              leadingAction: bookmarks.isNotEmpty
                  ? TextButton(
                      onPressed: _confirmClearAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        foregroundColor: colorScheme.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'پاک‌سازی',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    )
                  : null,
            ),

            // 3. Segmented Tab Bar for Switching between "Page Bookmarks" and "Saved Ayahs"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AppSegmentedTabBar(
                items: [
                  AppSegmentedTabItem(
                    title: 'نشانک صفحه',
                    badge: '(${readingBookmarks.length.toPersianDigit()})',
                  ),
                  AppSegmentedTabItem(
                    title: 'آیات نشان‌شده',
                    badge: '(${ayahBookmarks.length.toPersianDigit()})',
                  ),
                ],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) => setState(() => _selectedTabIndex = index),
              ),
            ),
            8.vSpace,

            // Label Filter Chips Bar
            LabelFilterChipsBar(
              selectedLabelId: _selectedLabelId,
              onLabelSelected: (id) => setState(() => _selectedLabelId = id),
            ),
            8.vSpace,
            Divider(
              height: 1,
              thickness: 1,
              color: borderColor,
            ),

            // 4. Content: Empty State OR List of Bookmarks
            Expanded(
              child: currentDisplayList.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: _buildEmptyState(
                          context,
                          isDark,
                          primaryColor,
                          isAyahTab: _selectedTabIndex == 1,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8.0,
                      ),
                      itemCount: currentDisplayList.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.6,
                        indent: 16,
                        endIndent: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      itemBuilder: (context, index) {
                        final item = currentDisplayList[index];

                        return _buildBookmarkCard(
                          key: ValueKey(item.key),
                          item: item,
                          index: index,
                          isDark: isDark,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                          arabicFontFamily: arabicFontFamily,
                          labelMap: labelMap,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color primaryColor, {
    bool isAyahTab = false,
  }) {
    final isFiltered = _selectedLabelId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isFiltered
                ? 'هیچ نشانه‌ای با این برچسب یافت نشد'
                : isAyahTab
                    ? 'هنوز هیچ آیه‌ای نشانه‌گذاری نشده است'
                    : 'هنوز هیچ نشانه‌ای ثبت نشده است',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          8.vSpace,
          Text(
            isFiltered
                ? 'می‌توانید با لمس آیکون برچسب روی هر نشانه، این برچسب را اضافه کنید.'
                : isAyahTab
                    ? 'با نگه‌داشتن انگشت روی هر آیه، آن را نشانه‌گذاری کنید.'
                    : 'با لمس آیکون نشانک در صفحه قرائت، صفحه را ذخیره کنید.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          24.vSpace,
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.pushNamed(surahListRoute);
            },
            child: const Text(
              'مشاهده فهرست سوره‌ها',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard({
    Key? key,
    required BookmarkItem item,
    required int index,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color primaryColor,
    required String arabicFontFamily,
    required Map<String, BookmarkLabel> labelMap,
  }) {
    final hasArabicSnippet = item.isAyahBookmark && item.arabicText != null && item.arabicText!.isNotEmpty;
    final hasNote = item.isAyahBookmark && item.note != null && item.note!.isNotEmpty;
    final attachedLabels = item.labelIds
        .map((lId) => labelMap[lId])
        .whereType<BookmarkLabel>()
        .toList();

    Widget buildActionButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'ویرایش نشانک',
            icon: Icon(
              hasNote
                  ? CupertinoIcons.square_pencil_fill
                  : CupertinoIcons.square_pencil,
              size: 16,
              color: hasNote
                  ? primaryColor
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            splashRadius: 16,
            onPressed: () {
              HapticFeedback.lightImpact();
              AyahBookmarkEditorBottomSheet.show(
                context,
                surahId: item.surahId,
                surahName: item.surahName,
                ayahNumber: item.ayahNumber,
                totalAyahs: item.totalAyahs,
                arabicText: item.arabicText,
                initialNote: item.note,
                initialLabelIds: item.labelIds,
                isAlreadyBookmarked: true,
                isAyahBookmark: item.isAyahBookmark,
              );
            },
          ),
          8.hSpace,
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref
                  .read(bookmarksControllerProvider.notifier)
                  .removeBookmark(item.surahId, item.ayahNumber);
              if (mounted) {
                AppSnackBar.showInfo(
                  context,
                  'نشانک سوره ${item.surahId.surahNameFa} حذف شد.',
                );
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              visualDensity: VisualDensity.compact,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: isDark ? Colors.white38 : Colors.black38,
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildSurahTitleInfo({bool expanded = false}) {
      final content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'سوره ${item.surahId.surahNameFa}',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1C1B1B),
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          8.hSpace,
          Text(
            item.totalAyahs > 0
                ? '• آیه ${item.ayahNumber.toPersianDigit()} از ${item.totalAyahs.toPersianDigit()}'
                : '• آیه ${item.ayahNumber.toPersianDigit()}',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      );

      return expanded ? Expanded(child: content) : content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToAyah(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Row:
              // If attachedLabels exists, top row shows [Labels] (start) | [Actions] (end).
              // Below it is the Surah Title row.
              // If no labels, top row shows [Surah Title] (start) | [Actions] (end).
              if (attachedLabels.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: attachedLabels.map((label) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF7F5F0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              label.title,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    8.hSpace,
                    buildActionButtons(),
                  ],
                ),
                6.vSpace,
                buildSurahTitleInfo(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildSurahTitleInfo(expanded: true),
                    8.hSpace,
                    buildActionButtons(),
                  ],
                ),
              ],

              // 3. Arabic Text Preview (for Ayah Bookmarks)
              if (hasArabicSnippet) ...[
                6.vSpace,
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    item.arabicText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: arabicFontFamily,
                      fontSize: 15,
                      height: 1.7,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF2C322E),
                    ),
                  ),
                ),
              ],

              // 4. Personal Note Snippet (if present, unboxed clean text)
              if (hasNote) ...[
                4.vSpace,
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0, top: 2.0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      AyahBookmarkEditorBottomSheet.show(
                        context,
                        surahId: item.surahId,
                        surahName: item.surahName,
                        ayahNumber: item.ayahNumber,
                        totalAyahs: item.totalAyahs,
                        arabicText: item.arabicText,
                        initialNote: item.note,
                        initialLabelIds: item.labelIds,
                        isAlreadyBookmarked: true,
                        isAyahBookmark: item.isAyahBookmark,
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'یادداشت: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: item.note!,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
