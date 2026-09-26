import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../extensions/int_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// Clean Theme-Aware Islamic Katibah AppBar with Vazirmatn typography,
/// integrated selection mode with fixed/stationary circular buttons where ONLY icons rotate 180 degrees.
class IslamicKatibahAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String surahName;
  final int? surahNumber;
  final String? fontFamily;
  final VoidCallback? onBackPressed;
  final VoidCallback? onBookmarkPressed;
  final ValueChanged<String>? onMenuSelected;
  final PopupMenuItemBuilder<String>? menuItemBuilder;
  final List<Widget>? actions;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearchField;
  final Widget? searchPrefixWidget;
  final FocusNode? searchFocusNode;
  final TextEditingController? searchController;

  // Selection Mode Properties
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback? onClearSelection;
  final VoidCallback? onCopySelected;
  final VoidCallback? onShareSelected;
  final VoidCallback? onDictionarySelected;

  final bool isBookmarked;

  const IslamicKatibahAppBar({
    super.key,
    required this.surahName,
    this.surahNumber,
    this.fontFamily,
    this.onBackPressed,
    this.onBookmarkPressed,
    this.isBookmarked = false,
    this.onMenuSelected,
    this.menuItemBuilder,
    this.actions,
    this.onSearchChanged,
    this.showSearchField = false,
    this.searchPrefixWidget,
    this.searchFocusNode,
    this.searchController,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    this.onClearSelection,
    this.onCopySelected,
    this.onShareSelected,
    this.onDictionarySelected,
  });

  @override
  Size get preferredSize => Size.fromHeight(showSearchField ? 146.0 : 76.0);

  @override
  State<IslamicKatibahAppBar> createState() => _IslamicKatibahAppBarState();
}

class _IslamicKatibahAppBarState extends State<IslamicKatibahAppBar> {
  TextEditingController? _internalSearchController;

  TextEditingController get _searchController =>
      widget.searchController ??
      (_internalSearchController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant IslamicKatibahAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchFocusNode != oldWidget.searchFocusNode) {
      oldWidget.searchFocusNode?.removeListener(_onFocusChange);
      widget.searchFocusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.searchFocusNode?.removeListener(_onFocusChange);
    _internalSearchController?.dispose();
    super.dispose();
  }

  /// Helper widget to build a fixed/stationary subtle translucent circular container
  Widget _buildStationaryCircleContainer({
    required Widget child,
    VoidCallback? onTap,
    String? tooltip,
    Color goldColor = const Color(0xFFF4E0A5),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: goldColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Tooltip(
              message: tooltip ?? '',
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a fixed/stationary subtle translucent capsule container with text
  Widget _buildStationaryTextContainer({
    required String label,
    VoidCallback? onTap,
    String? tooltip,
    Color goldColor = const Color(0xFFF4E0A5),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: goldColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Tooltip(
              message: tooltip ?? '',
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: goldColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Telegram-style Snappy Pop for Action Icons (Copy, Share, Bookmark, Menu)
  /// Pops out quickly from a smaller scale with a bouncy/spring feel.
  Widget _buildTelegramPopSwitcher({required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final scale = Tween<double>(begin: 0.4, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: child,
    );
  }

  /// Morph-like Theme-Toggle Style for Back ↔ Close (X) icon.
  /// Mimics the famous Dark/Light mode toggle (spins 180 degrees while scaling down/up with a bounce).
  Widget _buildBackCloseSwitcher({required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeOutQuart, // Extremely soft, buttery deceleration
      switchOutCurve: Curves.easeInQuart, // Smooth acceleration out
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween<double>(begin: 0.5, end: 1.0).animate(animation);
        // Start scale at 0.3 so it doesn't shrink to an invisible dot too abruptly
        final scale = Tween<double>(begin: 0.3, end: 1.0).animate(animation);
        
        return ScaleTransition(
          scale: scale,
          child: RotationTransition(
            turns: rotate,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// Telegram-style sliding text for Counter Bumps and Title swaps.
  /// The text slides vertically while fading in/out.
  Widget _buildTextSlideSwitcher({required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerRight,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 0.4),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    // Dynamic App Theme Colors (Deep Emerald & Gold)
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF062320), Color(0xFF0B3834)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [AppColors.primary, Color(0xFF09726A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    const softGoldText = Color(0xFFF4E0A5);

    return Container(
      height: widget.preferredSize.height + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        gradient: bgGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Islamic Arabesque Background Pattern (پترن اسلیمی)
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.12 : 0.16,
                child: Image.asset(
                  AppConstants.ayahCardBgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Column for Main Title Row + Prominent UI Search Bar
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Back/Close button, Surah Title/Selection Count, Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        // 1. Left Action Slot (Stationary Circle Box, Rotating Icon Inside: Back ↔ Close X)
                        _buildStationaryCircleContainer(
                          tooltip: widget.isSelectionMode
                              ? 'لغو انتخاب'
                              : 'بازگشت',
                          onTap: widget.isSelectionMode
                              ? widget.onClearSelection
                              : (widget.onBackPressed ??
                                    () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                    }),
                          child: _buildBackCloseSwitcher(
                            child: widget.isSelectionMode
                                ? const Icon(
                                    CupertinoIcons.xmark,
                                    key: ValueKey('icon_close'),
                                    size: 19,
                                    color: softGoldText,
                                  )
                                : const Icon(
                                    CupertinoIcons.chevron_forward,
                                    key: ValueKey('icon_back'),
                                    size: 19,
                                    color: softGoldText,
                                  ),
                          ),
                        ),

                        // 2. Surah Title or Selection Count (Attached directly next to Close X button in selection mode)
                        if (widget.isSelectionMode) ...[
                          const SizedBox(width: 8),
                          _buildTextSlideSwitcher(
                            child: Text(
                              '${widget.selectedCount.toPersianDigit()} آیه انتخاب شده',
                              key: ValueKey(
                                'selection_count_${widget.selectedCount}',
                              ),
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: softGoldText,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ] else ...[
                          const SizedBox(width: 8),
                          _buildTextSlideSwitcher(
                            child: Text(
                              widget.surahName,
                              key: ValueKey('normal_title_${widget.surahName}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.katibahTitle.copyWith(
                                fontFamily:
                                    widget.fontFamily ??
                                    AppTypography.fontFamily,
                                color: softGoldText,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],

                        // 3. Right Action Slots (2 Fixed Stationary Circle Containers + Independent Animated Vocabulary Button)
                        if (widget.actions != null &&
                            widget.actions!.isNotEmpty)
                          ...widget.actions!
                        else if (widget.isSelectionMode ||
                            widget.onBookmarkPressed != null ||
                            widget.onMenuSelected != null) ...[
                          // A) Independent Animated "واژه‌نامه" Capsule Button (Appears only when 1 Ayah is selected)
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            offset:
                                (widget.isSelectionMode &&
                                    widget.selectedCount == 1)
                                ? Offset.zero
                                : const Offset(0.25, 0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              opacity:
                                  (widget.isSelectionMode &&
                                      widget.selectedCount == 1)
                                  ? 1.0
                                  : 0.0,
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                                child:
                                    (widget.isSelectionMode &&
                                        widget.selectedCount == 1)
                                    ? _buildStationaryTextContainer(
                                        label: 'واژه‌نامه',
                                        tooltip: 'واژه‌نامه و لغات آیه',
                                        onTap: widget.onDictionarySelected,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),

                          // B) Circle Container 1 (Permanently Fixed Position): Bookmark (Normal) ↔ Copy (Selection)
                          _buildStationaryCircleContainer(
                            tooltip: widget.isSelectionMode
                                ? (widget.selectedCount == 1
                                      ? 'کپی آیه'
                                      : 'کپی آیات انتخاب‌شده')
                                : (widget.isBookmarked ? 'حذف نشانک' : 'ذخیره نشانک'),
                            onTap: widget.isSelectionMode
                                ? widget.onCopySelected
                                : widget.onBookmarkPressed,
                            child: _buildTelegramPopSwitcher(
                              child: widget.isSelectionMode
                                  ? const Icon(
                                      CupertinoIcons.doc_on_doc,
                                      key: ValueKey('icon_copy'),
                                      size: 18,
                                      color: softGoldText,
                                    )
                                  : Icon(
                                      widget.isBookmarked
                                          ? CupertinoIcons.bookmark_fill
                                          : CupertinoIcons.bookmark,
                                      key: ValueKey('icon_bookmark_${widget.isBookmarked}'),
                                      size: 18,
                                      color: widget.isBookmarked
                                          ? const Color(0xFF52C498)
                                          : softGoldText,
                                    ),
                            ),
                          ),

                          // C) Circle Container 2 (Permanently Fixed Position): Menu (Normal) ↔ Share (Selection)
                          _buildStationaryCircleContainer(
                            tooltip: widget.isSelectionMode
                                ? (widget.selectedCount == 1
                                      ? 'اشتراک‌گذاری آیه'
                                      : 'اشتراک‌گذاری آیات')
                                : 'منو',
                            child: _buildTelegramPopSwitcher(
                              child: widget.isSelectionMode
                                  ? GestureDetector(
                                      key: const ValueKey('icon_share_wrapper'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: widget.onShareSelected,
                                      child: const Icon(
                                        Icons.share_rounded,
                                        size: 18,
                                        color: softGoldText,
                                      ),
                                    )
                                  : PopupMenuButton<String>(
                                      key: const ValueKey('icon_menu'),
                                      tooltip: 'منو',
                                      offset: const Offset(0, 42),
                                      padding: EdgeInsets.zero,
                                      onSelected: widget.onMenuSelected,
                                      itemBuilder:
                                          widget.menuItemBuilder ??
                                          (context) => const [],
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.ellipsis_vertical,
                                          size: 18,
                                          color: softGoldText,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Prominent Always-Visible Search Bar ("همیشه تو چشم")
                if (widget.showSearchField) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.marginPage,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchTextField(softGoldText)),
                        if (widget.searchPrefixWidget != null) ...[
                          const SizedBox(width: 12),
                          widget.searchPrefixWidget!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a prominent, perfectly aligned UI Search TextField
  Widget _buildSearchTextField(Color textGold) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
        border: Border.all(color: textGold.withValues(alpha: 0.45), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          focusNode: widget.searchFocusNode,
          onChanged: (text) {
            widget.onSearchChanged?.call(text);
            setState(() {});
          },
          textAlignVertical: TextAlignVertical.center,
          style: AppTypography.searchInput,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            isDense: true,
            hintText: AppConstants.searchHintText,
            hintStyle: AppTypography.searchHint,
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                CupertinoIcons.search,
                color: textGold.withValues(alpha: 0.85),
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 18,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged?.call('');
                      widget.searchFocusNode?.unfocus();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 8,
            ),
          ),
        ),
      ),
    );
  }
}
