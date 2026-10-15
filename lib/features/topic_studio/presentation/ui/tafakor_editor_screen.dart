import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/services/media/image_picker_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../tafakor/application/controllers/tafakor_auth_controller.dart';
import '../../../tafakor/presentation/ui/tafakor_login_screen.dart';
import '../../application/controllers/in_drawer_editor_controller.dart';
import '../../domain/entities/topic_block.dart';
import '../widgets/send_to_topic_dialog.dart';
import '../widgets/topic_media_picker_sheet.dart';

/// Fullscreen Editor for Contemplation Notebook («دفتر تفکر»).
/// Provides reorderable, live-editable blocks with direct publication to Tafakor channels.
class TafakorEditorScreen extends ConsumerStatefulWidget {
  const TafakorEditorScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TafakorEditorScreen(),
      ),
    );
  }

  @override
  ConsumerState<TafakorEditorScreen> createState() => _TafakorEditorScreenState();
}

class _TafakorEditorScreenState extends ConsumerState<TafakorEditorScreen> {
  late final InDrawerEditorController _editorController;
  late final TextEditingController _inputController;
  late final FocusNode _inputFocusNode;
  late final ScrollController _scrollController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _editorController = ref.read(inDrawerEditorControllerProvider.notifier);
    _inputController = TextEditingController();
    _inputFocusNode = FocusNode();
    _scrollController = ScrollController();
    _inputController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showMediaAttachmentPopup([BuildContext? buttonContext]) async {
    HapticFeedback.lightImpact();
    final currentMedia = ref.read(inDrawerEditorControllerProvider).attachedImagePath;
    if (currentMedia != null) {
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          'امکان پیوست بیش از یک فایل وجود ندارد. برای تغییر، ابتدا فایل فعلی را با دکمه ضربدر حذف کنید.',
        );
      }
      return;
    }

    final type = await TopicMediaPickerSheet.show(buttonContext ?? context);
    if (type == null || !mounted) return;

    if (type == TopicAttachmentType.image) {
      await _pickImage();
    } else if (type == TopicAttachmentType.video) {
      await _pickVideo();
    }
  }

  Future<void> _pickImage() async {
    final pickerService = ref.read(imagePickerServiceProvider);
    final image = await pickerService.pickImageFromGallery();
    if (image != null) {
      final bytes = await image.readAsBytes();
      ref.read(inDrawerEditorControllerProvider.notifier).setAttachedImage(
            path: image.path,
            bytes: bytes,
          );
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _pickVideo() async {
    final pickerService = ref.read(imagePickerServiceProvider);
    final video = await pickerService.pickVideoFromGallery();
    if (video != null) {
      ref.read(inDrawerEditorControllerProvider.notifier).setAttachedVideo(
            path: video.path,
          );
      HapticFeedback.mediumImpact();
    }
  }



  Future<void> _handleSend() async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();

    final currentText = _inputController.text.trim();
    final hasCurrentText = currentText.isNotEmpty;

    final editorState = ref.read(inDrawerEditorControllerProvider);
    if (editorState.isEmpty && !hasCurrentText) {
      AppSnackBar.showInfo(context, 'پیش‌نویس خالی است. ابتدا متنی بنویسید.');
      return;
    }

    final isAuth = ref.read(isTafakorAuthenticatedProvider);
    if (!isAuth) {
      AppSnackBar.showError(
        context,
        'برای ارسال به کانال، ابتدا وارد حساب کاربری تفکر شوید.',
      );
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          settings: const RouteSettings(name: tafakorLoginRoute),
          builder: (_) => const TafakorLoginScreen(),
        ),
      );
      if (loggedIn != true || !mounted) return;
    }

    // Temporarily add typed text to editor blocks so SendToTopicDialog can format it
    String? tempBlockId;
    if (hasCurrentText) {
      _editorController.addUserTextBlock(currentText);
      tempBlockId = ref.read(inDrawerEditorControllerProvider).blocks.last.id;
    }

    final nav = Navigator.of(context);
    final sent = await SendToTopicDialog.show(context);
    if (!mounted) return;

    if (sent == true) {
      // Sent successfully: clear the textfield and close the editor screen
      _inputController.clear();
      nav.maybePop();
    } else {
      // User cancelled: roll back the temporary block so it isn't duplicated,
      // and keep the textfield text intact so the user can continue editing.
      if (tempBlockId != null) {
        _editorController.removeBlock(tempBlockId);
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final editorState = ref.watch(inDrawerEditorControllerProvider);
    final blocks = editorState.blocks;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: !_isExpanded,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _isExpanded) {
            setState(() => _isExpanded = false);
            return;
          }
          if (didPop) {
            Future.microtask(() => _editorController.clearAll());
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: colors.cardBackground,
            elevation: 0,
            leading: IconButton(
              tooltip: 'بازگشت',
              icon: Icon(
                CupertinoIcons.chevron_forward,
                color: colorScheme.onSurface,
              ),
              onPressed: () {
                ref.read(inDrawerEditorControllerProvider.notifier).clearAll();
                Navigator.of(context).maybePop();
              },
            ),
          centerTitle: true,
          title: Text(
            'دفتر تفکر',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            if (_inputController.text.trim().isNotEmpty) ...[
              IconButton(
                tooltip: 'پاک‌سازی متن',
                icon: Icon(
                  CupertinoIcons.trash,
                  size: 19,
                  color: colorScheme.error.withValues(alpha: 0.85),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _inputController.clear();
                },
              ),
            ],
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.8),
            child: Container(
              height: 0.8,
              color: colors.cardBorder,
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: blocks.isEmpty
                    ? _buildEmptyState(context, isDark, colorScheme, colors)
                    : _buildEditorCanvas(
                        context, isDark, colorScheme, colors, blocks),
              ),

              // Expanding Input Bar
              _buildChatInputBar(context, isDark, colorScheme, colors, editorState),
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
    ColorScheme colorScheme,
    dynamic colors,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.square_pencil,
                size: 44,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            16.vSpace,
            Text(
              'دفتر تفکر قرآنی',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            8.vSpace,
            Text(
              'هنگام مطالعه قرآن با انتخاب آیات، متن آن‌ها به اینجا منتقل می‌شود.\nهمچنین می‌توانید یادداشت و تفکر خود را در کادر پایین بنویسید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12.5,
                height: 1.6,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCanvas(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    dynamic colors,
    List<TopicBlock> blocks,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ReorderableListView.builder(
          scrollController: _scrollController,
          buildDefaultDragHandles: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              isDark: isDark,
              colorScheme: colorScheme,
              colors: colors,
              index: index,
              block: block,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlockItem({
    required Key key,
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
    required dynamic colors,
    required int index,
    required TopicBlock block,
  }) {
    if (block.type == TopicBlockType.ayah) {
      return _buildAyahBlock(
        key: key,
        context: context,
        isDark: isDark,
        colorScheme: colorScheme,
        index: index,
        block: block,
      );
    } else {
      return _buildTextBlock(
        key: key,
        context: context,
        isDark: isDark,
        colorScheme: colorScheme,
        index: index,
        block: block,
      );
    }
  }

  Widget _buildAyahBlock({
    required Key key,
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
    required int index,
    required TopicBlock block,
  }) {
    final surahText = (block.surahName != null && block.ayahNumber != null)
        ? '(سوره ${block.surahName}، آیه ${block.ayahNumber!.toPersianDigit()})'
        : '(متن آیه)';

    final captionColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  surahText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: captionColor,
                  ),
                ),
              ),
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
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              6.hSpace,
              _build3DReorderHandle(
                index: index,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ],
          ),

          2.vSpace,

          Text(
            block.content,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontSize: 17.5,
              height: 1.85,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock({
    required Key key,
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  captionLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: captionColor,
                  ),
                ),
              ),
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
                    size: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              6.hSpace,
              _build3DReorderHandle(
                index: index,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ],
          ),

          2.vSpace,

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

  /// Expandable floating text field container with 80% inline expansion
  Widget _buildChatInputBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    dynamic colors,
    InDrawerEditorState editorState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final text = _inputController.text;
        final hasText = text.trim().isNotEmpty;
        final canSend = hasText || editorState.isNotEmpty;

        // Detect if text spans to a second line (newline or character wrap)
        bool isMultiLine = false;
        if (text.isNotEmpty) {
          if (text.contains('\n')) {
            isMultiLine = true;
          } else {
            final availableWidth = constraints.maxWidth - 40;
            if (availableWidth > 60) {
              final painter = TextPainter(
                text: TextSpan(
                  text: text,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textDirection: TextDirection.rtl,
                maxLines: 2,
              )..layout(maxWidth: availableWidth);
              isMultiLine = painter.computeLineMetrics().length > 1;
            } else {
              isMultiLine = text.trim().length > 35;
            }
          }
        }
        final bool showExpandIcon = isMultiLine || _isExpanded;

        // Calculate 80% fixed screen height safely avoiding keyboard overflow
        final screenHeight = MediaQuery.sizeOf(context).height;
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        final topPadding = MediaQuery.paddingOf(context).top;
        final maxAvailableHeight =
            screenHeight - bottomInset - topPadding - kToolbarHeight - 16;
        final target80 = screenHeight * 0.80;
        final double expandedHeight = (target80 > maxAvailableHeight)
            ? (maxAvailableHeight > 260 ? maxAvailableHeight : 260.0)
            : target80;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, _isExpanded ? 8 : 12),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: Container(
                height: _isExpanded ? expandedHeight : null,
                padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 14 : 10,
                  vertical: _isExpanded ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222226) : Colors.white,
                  borderRadius: BorderRadius.circular(
                    _isExpanded ? 22 : 18,
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: _isExpanded ? 0.22 : 0.18)
                        : const Color(0xFFE5E5EA),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.50)
                          : const Color(0xFF000000)
                              .withValues(alpha: _isExpanded ? 0.12 : 0.08),
                      blurRadius: _isExpanded ? 24 : 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    if (!isDark)
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: _isExpanded
                    ? _buildExpandedContent(
                        context, isDark, colorScheme, canSend, editorState)
                    : _buildCompactContent(
                        context, isDark, colorScheme, canSend, showExpandIcon, editorState),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Compact mode of the input bar (TextField at top, actions underneath)
  Widget _buildCompactContent(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    bool canSend,
    bool showExpandIcon,
    InDrawerEditorState editorState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: Expand button appears at top right when text reaches line 2
        if (showExpandIcon) ...[
          Align(
            alignment: AlignmentDirectional.topStart,
            child: _buildExpandCollapseButton(
              isDark: isDark,
              colorScheme: colorScheme,
              isExpanded: false,
            ),
          ),
          4.vSpace,
        ],

        // 1. Topmost row inside text field: 1:1 minimal image preview if attached
        if (editorState.hasAttachedImage) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _buildMinimal1x1ImagePreview(editorState, isDark),
            ),
          ),
        ],

        // 2. Text Field at top
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: TextField(
            controller: _inputController,
            focusNode: _inputFocusNode,
            minLines: 1,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              hintText: 'یادداشت یا تفکر خود را بنویسید...',
              hintTextDirection: TextDirection.rtl,
              hintStyle: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
              ),
              border: InputBorder.none,
            ),
          ),
        ),

        4.vSpace,

        // 2. Action row UNDERNEATH the text field (دکمه‌های انتخاب عکس و ارسال)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular photo picker icon button
            _buildPhotoPickerButton(isDark, colorScheme),

            // Send button
            _buildSendButton(canSend, isDark, colorScheme),
          ],
        ),
      ],
    );
  }

  /// 80% Expanded mode with full scrollable text field and collapse button
  Widget _buildExpandedContent(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    bool canSend,
    InDrawerEditorState editorState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: Collapse button at top right
        Align(
          alignment: AlignmentDirectional.topStart,
          child: _buildExpandCollapseButton(
            isDark: isDark,
            colorScheme: colorScheme,
            isExpanded: true,
          ),
        ),

        4.vSpace,

        // Topmost row inside expanded text field: 1:1 minimal image preview if attached
        if (editorState.hasAttachedImage) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: _buildMinimal1x1ImagePreview(editorState, isDark),
            ),
          ),
        ],

        // Large scrollable multiline TextField
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                height: 1.7,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                hintText:
                    'متن، تأملات و یادداشت‌های خود را با خیال راحت بنویسید...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ),
        ),

        4.vSpace,

        // Bottom Action Row in Expanded Mode: Photo Button & Send Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildPhotoPickerButton(isDark, colorScheme),
            _buildSendButton(
              canSend,
              isDark,
              colorScheme,
              onPressedOverride: () {
                setState(() => _isExpanded = false);
                _handleSend();
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Circular media attachment button (+ icon) opening ChatGPT-style popup
  Widget _buildPhotoPickerButton(
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Builder(
      builder: (btnCtx) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showMediaAttachmentPopup(btnCtx),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF2F2F7),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE5E5EA),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.plus,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 1:1 Minimalist attached media thumbnail (photo/video) with top-left cross button matching bottom dialogs
  Widget _buildMinimal1x1ImagePreview(
    InDrawerEditorState editorState,
    bool isDark,
  ) {
    if (!editorState.hasAttachedImage) {
      return const SizedBox.shrink();
    }

    const double size = 72.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1:1 square media thumbnail
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              width: 0.9,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: editorState.isVideo
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.videocam_fill,
                        size: 26,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                      4.vSpace,
                      Text(
                        'ویدیو',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  )
                : (editorState.attachedImageBytes != null
                    ? Image.memory(
                        editorState.attachedImageBytes!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink()),
          ),
        ),

        // Close button in top-left corner matching bottom dialogs
        Positioned(
          top: -4,
          left: -4,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(inDrawerEditorControllerProvider.notifier)
                  .removeAttachedImage();
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222226) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Modern Expand / Collapse icon button (Cupertino)
  Widget _buildExpandCollapseButton({
    required bool isDark,
    required ColorScheme colorScheme,
    required bool isExpanded,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        child: Tooltip(
          message: isExpanded ? 'کوچک‌نمایی' : 'بزرگ‌نمایی',
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE5E5EA),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Icon(
                  isExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  size: 19,
                  color: isDark ? Colors.white70 : const Color(0xFF3A3A3C),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Send / Action button
  Widget _buildSendButton(
    bool canSend,
    bool isDark,
    ColorScheme colorScheme, {
    VoidCallback? onPressedOverride,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canSend ? (onPressedOverride ?? _handleSend) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: canSend
                ? colorScheme.primary
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE5E5EA)),
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              CupertinoIcons.arrow_up,
              size: 20,
              color: canSend
                  ? Colors.white
                  : (isDark ? Colors.white30 : const Color(0xFF8E8E93)),
            ),
          ),
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
  }

  void _onTextChanged(String text) {
    widget.onChanged(text);
  }

  @override
  void didUpdateWidget(covariant _EditableBlockField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        widget.initialText != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
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
      autofocus: false,
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
