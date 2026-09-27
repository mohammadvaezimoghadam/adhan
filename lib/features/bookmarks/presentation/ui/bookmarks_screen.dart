import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_segmented_tab_bar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/bookmarks_controller.dart';
import '../../application/controllers/bookmark_labels_controller.dart';
import '../../domain/entities/bookmark_item.dart';
import '../../domain/entities/bookmark_label.dart';
import '../widgets/ayah_bookmark_editor_bottom_sheet.dart';
import '../widgets/label_filter_chips_bar.dart';
import '../widgets/manage_labels_bottom_sheet.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';

/// Full-screen Apple-styled Bookmarks screen designed for the Main Navigation Shell.
class BookmarksScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final VoidCallback? onExploreSurahs;

  const BookmarksScreen({
    super.key,
    this.showBackButton = false,
    this.onExploreSurahs,
  });

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Ayahs only
  String? _selectedLabelId; // null: All, 'unlabeled': without labels, or specific labelId
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAyah(BookmarkItem item) {
    ref.read(quranDisplaySettingsControllerProvider.notifier).toggleArabicText(true);

    context.pushNamed(
      quranReaderRoute,
      pathParameters: {'id': item.surahId.toString()},
      queryParameters: {
        'name': item.surahName,
        'ayah': item.ayahNumber.toString(),
      },
    );
  }

  Future<void> _confirmClearAll() async {
    final colors = context.colors;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.trash,
                  size: 24,
                  color: Colors.redAccent,
                ),
              ),
              12.vSpace,
              Text(
                'آیا مطمئن هستید که می‌خواهید تمام نشانه‌های ذخیره‌شده را حذف کنید؟ این عمل غیرقابل بازگشت است.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  height: 1.5,
                  color: textSecondary,
                ),
              ),
              20.vSpace,
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: Text(
                        'انصراف',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
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
                      child: Text(
                        'حذف همه',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
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
      await ref.read(bookmarksControllerProvider.notifier).clearAll();
    }
  }

  String _formatTimeAgo(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'همین الان';
    if (diff.inHours < 1) return '${diff.inMinutes.toPersianDigit()} دقیقه پیش';
    if (diff.inDays < 1) return '${diff.inHours.toPersianDigit()} ساعت پیش';
    if (diff.inDays == 1) return 'دیروز';
    if (diff.inDays < 7) return '${diff.inDays.toPersianDigit()} روز پیش';
    if (diff.inDays < 30) return '${(diff.inDays ~/ 7).toPersianDigit()} هفته پیش';
    return '${date.year.toPersianDigit()}/${date.month.toPersianDigit()}/${date.day.toPersianDigit()}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;
    final allBookmarks = ref.watch(bookmarksControllerProvider);
    final labelMap = ref.watch(bookmarkLabelsMapProvider);

    final tabFiltered = _selectedTabIndex == 0
        ? allBookmarks
        : allBookmarks.where((b) => b.isAyahBookmark).toList();

    final labelFiltered = _selectedLabelId == null
        ? tabFiltered
        : _selectedLabelId == 'unlabeled'
            ? tabFiltered.where((b) => b.labelIds.isEmpty).toList()
            : tabFiltered
                .where((b) => b.labelIds.contains(_selectedLabelId))
                .toList();

    final filtered = _searchQuery.trim().isEmpty
        ? labelFiltered
        : labelFiltered.where((b) {
            final query = _searchQuery.trim();
            final matchesSurah = b.surahName.contains(query);
            final matchesAyah = b.ayahNumber.toString().contains(query);
            final matchesArabic = b.arabicText?.contains(query) ?? false;
            final matchesNote = b.note?.contains(query) ?? false;
            return matchesSurah || matchesAyah || matchesArabic || matchesNote;
          }).toList();

    final topPadding = MediaQuery.paddingOf(context).top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            padding: EdgeInsets.only(
              top: topPadding + 4.0,
              left: 12.0,
              right: 6.0,
              bottom: 8.0,
            ),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: colors.cardBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                if (widget.showBackButton)
                  IconButton(
                    tooltip: 'بازگشت',
                    icon: Icon(
                      CupertinoIcons.chevron_forward,
                      size: 24,
                      color: colorScheme.onSurface,
                    ),
                    splashRadius: 22,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                else
                  const SizedBox(width: 48),

                Expanded(
                  child: Text(
                    'نشانه‌ها و برگزیده‌ها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                // Manage Labels button
                IconButton(
                  tooltip: 'مدیریت برچسب‌ها',
                  icon: Icon(
                    CupertinoIcons.slider_horizontal_3,
                    size: 20,
                    color: textSecondary,
                  ),
                  splashRadius: 22,
                  onPressed: () => ManageLabelsBottomSheet.show(context),
                ),

                if (allBookmarks.isNotEmpty)
                  IconButton(
                    tooltip: 'حذف همه نشانه‌ها',
                    icon: Icon(
                      CupertinoIcons.trash,
                      size: 20,
                      color: textSecondary,
                    ),
                    splashRadius: 22,
                    onPressed: _confirmClearAll,
                  ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            12.vSpace,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.marginPage),
              child: AppSegmentedTabBar(
                items: const [
                  AppSegmentedTabItem(title: 'همه نشانه‌ها'),
                  AppSegmentedTabItem(title: 'نشانه‌های آیه'),
                ],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = index);
                },
              ),
            ),
            10.vSpace,

            // Horizontal Label Filter Chips Bar
            LabelFilterChipsBar(
              selectedLabelId: _selectedLabelId,
              onLabelSelected: (id) => setState(() => _selectedLabelId = id),
            ),

            if (allBookmarks.length > 5) ...[
              10.vSpace,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.marginPage),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.cardBorder,
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'جستجو در نشانه‌ها...',
                      hintStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12.5,
                        color: textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        size: 16,
                        color: textSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],

            12.vSpace,

            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      context,
                      isDark,
                      allBookmarks.isEmpty,
                      _selectedLabelId != null,
                      textSecondary,
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: AppDimens.marginPage,
                        right: AppDimens.marginPage,
                        bottom: 90,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => 8.vSpace,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildBookmarkCard(
                          context,
                          item,
                          isDark,
                          textSecondary,
                          labelMap,
                          key: ValueKey(item.key),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(
    BuildContext context,
    BookmarkItem item,
    bool isDark,
    Color textSecondary,
    Map<String, BookmarkLabel> labelMap, {
    Key? key,
  }) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.cardBorder,
          width: 0.8,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToAyah(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      item.isAyahBookmark
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.book,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                12.hSpace,

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label Badges (Neutral, placed above Surah title)
                      if (item.labelIds.isNotEmpty) ...[
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: item.labelIds.map((lId) {
                            final label = labelMap[lId];
                            if (label == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                        6.vSpace,
                      ],
                      Row(
                        children: [
                          Text(
                            item.surahName,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          8.hSpace,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'آیه ${item.ayahNumber.toPersianDigit()}',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.isAyahBookmark && item.arabicText != null && item.arabicText!.isNotEmpty) ...[
                        4.vSpace,
                        Text(
                          item.arabicText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                      // Personal Note Snippet (clean text, no box)
                      if (item.isAyahBookmark && item.note != null && item.note!.isNotEmpty) ...[
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
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      4.vSpace,
                      Text(
                        _formatTimeAgo(item.createdAt),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Note / Edit Button
                IconButton(
                  tooltip: (item.note != null && item.note!.isNotEmpty)
                      ? 'ویرایش یادداشت'
                      : 'افزودن یادداشت',
                  icon: Icon(
                    (item.note != null && item.note!.isNotEmpty)
                        ? CupertinoIcons.square_pencil_fill
                        : CupertinoIcons.square_pencil,
                    size: 18,
                    color: (item.note != null && item.note!.isNotEmpty)
                        ? colorScheme.primary
                        : textSecondary.withValues(alpha: 0.65),
                  ),
                  splashRadius: 20,
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

                // Delete Button
                IconButton(
                  tooltip: 'حذف نشانک',
                  icon: Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: Colors.redAccent.withValues(alpha: 0.75),
                  ),
                  splashRadius: 20,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(bookmarksControllerProvider.notifier).removeBookmark(
                          item.surahId,
                          item.ayahNumber,
                        );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    bool isCompletelyEmpty,
    bool isFilteredByLabel,
    Color textSecondary,
  ) {
    final colorScheme = context.colorScheme;

    String title;
    String subtitle;
    if (isCompletelyEmpty) {
      title = 'هنوز نشانه‌ای ثبت نشده است';
      subtitle =
          'هنگام تلاوت قرآن، می‌توانید با لمس آیکون نشانه‌گذاری در بالای صفحه، آیه یا سوره مورد نظر خود را ذخیره کنید.';
    } else if (isFilteredByLabel) {
      title = 'هیچ نشانه‌ای با این برچسب یافت نشد';
      subtitle =
          'می‌توانید با لمس آیکون برچسب روی هر نشانه، این برچسب را به آن اختصاص دهید یا فیلتر را تغییر دهید.';
    } else {
      title = 'موردی با این عبارت یافت نشد';
      subtitle = 'لطفاً عبارت دیگری را جستجو کنید.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  isFilteredByLabel
                      ? CupertinoIcons.tag
                      : CupertinoIcons.bookmark,
                  size: 38,
                  color: colorScheme.primary,
                ),
              ),
            ),
            16.vSpace,
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            8.vSpace,
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                height: 1.5,
                color: textSecondary,
              ),
            ),
            if (isCompletelyEmpty && widget.onExploreSurahs != null) ...[
              20.vSpace,
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onExploreSurahs!();
                },
                icon: const Icon(CupertinoIcons.book, size: 18),
                label: const Text('مشاهده فهرست سوره‌ها'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
