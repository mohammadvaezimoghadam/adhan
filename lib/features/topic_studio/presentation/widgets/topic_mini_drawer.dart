import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/selected_ayah_action_provider.dart';
import '../../application/controllers/in_drawer_editor_controller.dart';
import '../../application/controllers/topic_mini_drawer_controller.dart';
import '../../domain/entities/topic_block.dart';
import '../../domain/entities/topic_drag_data.dart';
import '../../../tafakor/application/controllers/tafakor_auth_controller.dart';
import '../../../tafakor/presentation/ui/tafakor_login_screen.dart';
import 'send_to_topic_dialog.dart';

/// Floating Mini-Drawer for Contemplation Notebook (دفتر تفکر).
/// Sits on the right edge of the Quran reader and houses the in-drawer live editor.
class TopicMiniDrawer extends ConsumerStatefulWidget {
  const TopicMiniDrawer({super.key});

  @override
  ConsumerState<TopicMiniDrawer> createState() => _TopicMiniDrawerState();
}

class _TopicMiniDrawerState extends ConsumerState<TopicMiniDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed ||
          status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerState = ref.watch(topicMiniDrawerControllerProvider);
    if (!drawerState.isEnabled) {
      return const SizedBox.shrink();
    }

    ref.listen<TopicMiniDrawerState>(topicMiniDrawerControllerProvider,
        (prev, next) {
      if (next.isOpen && !_animController.isCompleted) {
        _animController.forward();
      } else if (!next.isOpen && !_animController.isDismissed) {
        _animController.reverse();
      }
    });

    if (drawerState.isOpen &&
        !_animController.isCompleted &&
        !_animController.isAnimating) {
      _animController.forward();
    }

    final isDrawerVisible = drawerState.isOpen || !_animController.isDismissed;
    final isDark = context.isDark;
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = math.min(screenWidth * 0.88, 360.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Semi-transparent Barrier when open or animating
          if (isDrawerVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ref.read(topicMiniDrawerControllerProvider.notifier).close();
                },
                behavior: HitTestBehavior.opaque,
                child: FadeTransition(
                  opacity: _animController,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),

          // 2. Sliding Panel (DIRECT Positioned child of Stack)
          if (isDrawerVisible)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: drawerWidth,
              child: RepaintBoundary(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _TopicMiniDrawerContent(
                    isDark: isDark,
                    colors: colors,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),

          // 3. Floating Edge Tab Handle when closed
          if (!drawerState.isOpen)
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 120,
              right: 0,
              child: RepaintBoundary(
                child: _buildEdgeHandle(
                  context: context,
                  isDark: isDark,
                  colors: colors,
                  colorScheme: colorScheme,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The draggable-target edge tab handle on the right side
  Widget _buildEdgeHandle({
    required BuildContext context,
    required bool isDark,
    required dynamic colors,
    required ColorScheme colorScheme,
  }) {
    return DragTarget<TopicDragData>(
      onWillAcceptWithDetails: (details) {
        // Auto-expand drawer when hovered during drag
        HapticFeedback.mediumImpact();
        ref.read(topicMiniDrawerControllerProvider.notifier).open();
        return true;
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(topicMiniDrawerControllerProvider.notifier).open();
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              decoration: BoxDecoration(
                color: isHovered
                    ? colorScheme.primary
                    : (isDark
                        ? const Color(0xF2202026)
                        : const Color(0xF8FFFFFF)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                border: Border.all(
                  color: isHovered
                      ? Colors.white
                      : colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: isHovered ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                    blurRadius: 10,
                    offset: const Offset(-2, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isHovered ? 'رها کنید' : 'دفتر تفکر',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isHovered
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  4.hSpace,
                  Icon(
                    Icons.keyboard_double_arrow_left,
                    size: isHovered ? 18 : 16,
                    color: isHovered ? Colors.white : colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Extracted body of the mini-drawer housing the live in-drawer editor.
class _TopicMiniDrawerContent extends ConsumerWidget {
  final bool isDark;
  final dynamic colors;
  final ColorScheme colorScheme;

  const _TopicMiniDrawerContent({
    required this.isDark,
    required this.colors,
    required this.colorScheme,
  });

  Future<void> _copyFullDraft(
    BuildContext context,
    InDrawerEditorState editorState,
  ) async {
    if (editorState.isEmpty) {
      AppSnackBar.showError(context, 'مطلبی برای کپی کردن وجود ندارد.');
      return;
    }

    final fullText = TopicBlock.formatBlocksForPublication(editorState.blocks);
    if (fullText.isEmpty) {
      AppSnackBar.showError(context, 'مطلبی برای کپی کردن وجود ندارد.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: fullText));
    HapticFeedback.lightImpact();
    if (context.mounted) {
      AppSnackBar.showSuccess(context, 'کل متن پیش‌نویس کپی شد.');
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          title: Text(
            'پاک‌سازی دفتر تفکر',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'آیا می‌خواهید تمام محتوا و آیات موجود در این پیش‌نویس پاک شوند؟',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13.5,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'انصراف',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'پاک کردن',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      ref.read(inDrawerEditorControllerProvider.notifier).clearAll();
      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'دفتر تفکر پاک‌سازی شد.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(inDrawerEditorControllerProvider);
    final blocks = editorState.blocks;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xF21C1C20)
                : const Color(0xF5FAF8F4),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            border: Border(
              left: BorderSide(
                color: colors.cardBorder,
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header with Title, Count, Clear Button, and Close Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 14, 8),
                  child: Row(
                    children: [
                      Text(
                        'دفتر تفکر',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),

                      // Clear all button (visible when there are blocks)
                      if (editorState.isNotEmpty)
                        IconButton(
                          tooltip: 'پاک‌سازی همه',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(CupertinoIcons.trash, size: 17),
                          color: colorScheme.error.withValues(alpha: 0.85),
                          onPressed: () => _confirmClearAll(context, ref),
                        ),

                      // Close drawer button
                      IconButton(
                        tooltip: 'بستن',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(CupertinoIcons.xmark, size: 18),
                        color: isDark ? Colors.white60 : Colors.black54,
                        onPressed: () {
                          ref.read(topicMiniDrawerControllerProvider.notifier).close();
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 0.8),

                // 2. Drag & Drop Canvas (The rest of the drawer is a DropTarget!)
                Expanded(
                  child: DragTarget<TopicDragData>(
                    onWillAcceptWithDetails: (details) {
                      HapticFeedback.selectionClick();
                      return true;
                    },
                    onAcceptWithDetails: (details) {
                      HapticFeedback.heavyImpact();
                      ref
                          .read(inDrawerEditorControllerProvider.notifier)
                          .addAyahData(details.data);
                      ref
                          .read(selectedAyahActionProvider.notifier)
                          .clearSelection();

                      final msg = details.data.isMultiple
                          ? '${details.data.count.toPersianDigit()} آیه به دفتر تفکر افزوده شد.'
                          : 'آیه به دفتر تفکر افزوده شد.';
                      AppSnackBar.showSuccess(context, msg);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isDropHovered = candidateData.isNotEmpty;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: isDropHovered
                            ? colorScheme.primary.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              )
                            : Colors.transparent,
                        child: blocks.isEmpty
                            ? _buildEmptyState(context, ref, isDropHovered)
                            : _buildEditorCanvas(context, ref, blocks),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state matching topic_editor_screen aesthetics
  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    bool isDropHovered,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDropHovered
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDropHovered
                    ? CupertinoIcons.arrow_down_circle
                    : CupertinoIcons.square_pencil,
                size: 38,
                color: isDropHovered
                    ? colorScheme.primary
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
            14.vSpace,
            Text(
              isDropHovered
                  ? 'آیه را اینجا رها کنید...'
                  : 'هنوز مطلبی در این پیش‌نویس وجود ندارد',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            6.vSpace,
            Text(
              'هنگام مطالعه قرآن، آیات را به اینجا بکشید یا یک تأمل جدید بنویسید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            18.vSpace,
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(inDrawerEditorControllerProvider.notifier)
                    .addUserTextBlock();
              },
              icon: const Icon(CupertinoIcons.add, size: 15),
              label: const Text(
                'نوشتن اولین یادداشت',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live scrollable & reorderable editor canvas matching topic_editor_screen EXACTLY
  Widget _buildEditorCanvas(
    BuildContext context,
    WidgetRef ref,
    List<TopicBlock> blocks,
  ) {
    return Column(
      children: [
        // Reorderable list of blocks matching topic_editor_screen
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
            ),
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                physics: const BouncingScrollPhysics(),
                itemCount: blocks.length,
                onReorderStart: (index) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) {
                      final double elevation =
                          Curves.easeInOut.transform(animation.value) * 6;
                      return Material(
                        color: colors.dialogSurface,
                        elevation: elevation,
                        borderRadius: BorderRadius.circular(16),
                        shadowColor: Colors.black26,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: child,
                        ),
                      );
                    },
                  );
                },
                // ignore: deprecated_member_use
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(inDrawerEditorControllerProvider.notifier)
                      .reorderBlocks(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final block = blocks[index];
                  return _buildBlockItem(
                    key: ValueKey(block.id),
                    context: context,
                    ref: ref,
                    index: index,
                    block: block,
                  );
                },
              ),
            ),
          ),
        ),

        // Flat "افزودن یادداشت" placed right inside the edit area, stuck to the bottom of the canvas
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: _buildFlatAddNoteButton(context, ref),
        ),

        // Bottom action bar: Only Copy & Send to topic
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.dialogSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _copyFullDraft(
                      context,
                      ref.read(inDrawerEditorControllerProvider),
                    ),
                    icon: const Icon(CupertinoIcons.share_up, size: 14),
                    label: const Text(
                      'کپی برای ارسال',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                8.hSpace,
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor:
                          isDark ? Colors.white : colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final editorState =
                          ref.read(inDrawerEditorControllerProvider);
                      if (editorState.isEmpty) {
                        AppSnackBar.showError(
                            context, 'مطلبی برای ارسال وجود ندارد.');
                        return;
                      }

                      final isAuth =
                          ref.read(isTafakorAuthenticatedProvider);
                      if (!isAuth) {
                        AppSnackBar.showError(
                          context,
                          'برای ارسال به تاپیک، ابتدا وارد حساب کاربری تفکر شوید.',
                        );
                        final loggedIn = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const TafakorLoginScreen(),
                          ),
                        );
                        if (loggedIn != true || !context.mounted) return;
                      }

                      await SendToTopicDialog.show(context);
                    },
                    icon: Icon(
                      CupertinoIcons.paperplane_fill,
                      size: 14,
                      color: isDark ? Colors.white : colorScheme.onPrimary,
                    ),
                    label: Text(
                      'ارسال به تاپیک',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Flat, minimal button placed directly inside the edit area, stuck to the bottom of the canvas
  Widget _buildFlatAddNoteButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.lightImpact();
          ref
              .read(inDrawerEditorControllerProvider.notifier)
              .addUserTextBlock();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.add,
                size: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              6.hSpace,
              Text(
                'افزودن یادداشت',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an individual block item (exact replica of topic_editor_screen)
  Widget _buildBlockItem({
    required Key key,
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required TopicBlock block,
  }) {
    if (block.type == TopicBlockType.ayah) {
      return _buildAyahBlock(
        key: key,
        context: context,
        ref: ref,
        index: index,
        block: block,
      );
    } else {
      return _buildTextBlock(
        key: key,
        context: context,
        ref: ref,
        index: index,
        block: block,
      );
    }
  }

  /// Ayah block designed flat and simple like other blocks, with a subtle border indicating it is movable
  /// (Exact implementation from topic_editor_screen.dart)
  Widget _buildAyahBlock({
    required Key key,
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required TopicBlock block,
  }) {
    final surahText = (block.surahName != null && block.ayahNumber != null)
        ? '(سوره ${block.surahName}، آیه ${block.ayahNumber!.toPersianDigit()})'
        : '(متن آیه)';

    final captionColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar (caption + copy + delete + 3D drag handle)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    surahText,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: captionColor,
                    ),
                  ),
                ),
              ),
              // Delete button (compact InkWell)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(inDrawerEditorControllerProvider.notifier)
                      .removeBlock(block.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              6.hSpace,
              // 3D tactile circular button with vertical arrows for dragging
              _build3DReorderHandle(
                index: index,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ],
          ),

          1.vSpace,

          // Raw Arabic Text aligned to right like translations
          Text(
            block.content,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 17,
              height: 1.85,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Flat text block (translation, tafsir, notes) sitting directly on the page without cards or borders
  /// (Exact implementation from topic_editor_screen.dart)
  Widget _buildTextBlock({
    required Key key,
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required TopicBlock block,
  }) {
    String captionLabel;
    String hintText;
    TextStyle contentStyle;

    switch (block.type) {
      case TopicBlockType.translation:
        captionLabel = block.sourceTitle != null
            ? '(ترجمه: ${block.sourceTitle})'
            : '(ترجمه)';
        hintText = 'متن ترجمه...';
        contentStyle = TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 1.6,
          color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87,
        );
        break;
      case TopicBlockType.tafsir:
        captionLabel = block.sourceTitle != null
            ? '(گزیده تفسیر: ${block.sourceTitle})'
            : '(گزیده تفسیر)';
        hintText = 'گزیده تفسیر...';
        contentStyle = TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13.5,
          height: 1.6,
          color: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF2C3E50),
        );
        break;
      case TopicBlockType.userText:
      default:
        captionLabel = '(یادداشت)';
        hintText = 'یادداشت یا تأمل خود را اینجا بنویسید...';
        contentStyle = TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 1.6,
          color: isDark ? Colors.white : Colors.black87,
        );
        break;
    }

    final captionColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minimalist Caption Bar with effortless Drag & Drop support (no outer border)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    captionLabel,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: captionColor,
                    ),
                  ),
                ),
              ),
              // Delete button (compact InkWell)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(inDrawerEditorControllerProvider.notifier)
                      .removeBlock(block.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              6.hSpace,
              // 3D tactile circular button with vertical arrows for dragging
              _build3DReorderHandle(
                index: index,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ],
          ),

          1.vSpace,

          // Editable content sitting cleanly with zero extra padding
          _EditableBlockField(
            initialText: block.content,
            hintText: hintText,
            style: contentStyle,
            onChanged: (newText) {
              ref
                  .read(inDrawerEditorControllerProvider.notifier)
                  .updateBlockContent(block.id, newText);
            },
          ),
        ],
      ),
    );
  }

  /// 3D tactile circular button for reordering with vertical bidirectional arrows
  /// (Exact implementation from topic_editor_screen.dart)
  Widget _build3DReorderHandle({
    required int index,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return ReorderableDragStartListener(
      index: index,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Icon(
            Icons.unfold_more_rounded,
            size: 13,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ),
    );
  }
}

/// Standalone stateful widget for editable block text to prevent rebuilding the entire list on every keystroke
/// (Exact implementation from topic_editor_screen.dart)
class _EditableBlockField extends StatefulWidget {
  final String initialText;
  final String hintText;
  final TextStyle? style;
  final ValueChanged<String> onChanged;

  const _EditableBlockField({
    required this.initialText,
    required this.hintText,
    this.style,
    required this.onChanged,
  });

  @override
  State<_EditableBlockField> createState() => _EditableBlockFieldState();
}

class _EditableBlockFieldState extends State<_EditableBlockField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _flush();
    }
  }

  void _flush() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_controller.text != widget.initialText) {
      widget.onChanged(_controller.text);
    }
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _controller.text != widget.initialText) {
        widget.onChanged(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableBlockField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't overwrite the field while user is actively typing in it
    if (oldWidget.initialText != widget.initialText &&
        widget.initialText != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _flush();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 13.5,
      height: 1.6,
      color: isDark ? Colors.white : Colors.black87,
    );

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: widget.style ?? defaultStyle,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.5,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: _onTextChanged,
    );
  }
}
