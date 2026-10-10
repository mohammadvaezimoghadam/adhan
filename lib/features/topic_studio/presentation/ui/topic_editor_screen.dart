import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/topics_controller.dart';
import '../../domain/entities/topic_block.dart';
import '../../domain/entities/topic_item.dart';
import '../../domain/entities/topic_status.dart';
import '../widgets/new_topic_dialog.dart';

/// Workspace Canvas for viewing, editing, reordering, and copying a specific Topic in «دفتر تفکر».
class TopicEditorScreen extends ConsumerStatefulWidget {
  final String topicId;

  const TopicEditorScreen({
    super.key,
    required this.topicId,
  });

  static Future<void> push(BuildContext context, String topicId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TopicEditorScreen(topicId: topicId),
      ),
    );
  }

  @override
  ConsumerState<TopicEditorScreen> createState() => _TopicEditorScreenState();
}

class _TopicEditorScreenState extends ConsumerState<TopicEditorScreen> {
  Future<void> _copyFullTopic(TopicItem topic) async {
    final text = topic.toFullFormattedText();
    if (text.isEmpty) {
      AppSnackBar.showInfo(context, 'موضوع خالی است.');
      return;
    }

    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppSnackBar.showSuccess(context, 'کل متن موضوع در کلیپ‌بورد کپی شد.');
    }
  }

  Future<void> _addNewUserTextBlock(TopicItem topic) async {
    HapticFeedback.lightImpact();
    final newBlock = TopicBlock.create(
      type: TopicBlockType.userText,
      content: '',
    );
    await ref
        .read(topicsControllerProvider.notifier)
        .addBlockToTopic(topic.id, newBlock);
  }

  Future<void> _toggleStatus(TopicItem topic) async {
    HapticFeedback.lightImpact();
    final nextStatus =
        topic.isOpen ? TopicStatus.closed : TopicStatus.open;
    await ref
        .read(topicsControllerProvider.notifier)
        .updateTopicStatus(topic.id, nextStatus);

    if (mounted) {
      final msg = nextStatus.isOpen
          ? 'موضوع به حالت «در حال تدوین» بازگشت.'
          : 'موضوع با موفقیت «تکمیل» شد.';
      AppSnackBar.showSuccess(context, msg);
    }
  }

  Future<void> _editTitle(TopicItem topic) async {
    final updated = await NewTopicDialog.show(
      context,
      topicId: topic.id,
      initialTitle: topic.title,
      isEditing: true,
    );
    if (updated != null &&
        updated.title.trim().isNotEmpty &&
        updated.title.trim() != topic.title) {
      await ref
          .read(topicsControllerProvider.notifier)
          .updateTopicTitle(topic.id, updated.title.trim());
    }
  }

  Future<void> _confirmDelete(TopicItem topic) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
            'حذف موضوع تفکر',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'آیا از حذف موضوع «${topic.title}» اطمینان دارید؟',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
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
                'حذف',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(topicsControllerProvider.notifier).deleteTopic(topic.id);
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.showInfo(context, 'موضوع حذف شد.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final topic = ref.watch(topicByIdProvider(widget.topicId));

    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('موضوع یافت نشد')),
        body: const Center(child: Text('این موضوع حذف شده است.')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? colorScheme.surface : const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: colors.dialogSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _editTitle(topic),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      topic.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  4.hSpace,
                  Icon(
                    CupertinoIcons.pencil,
                    size: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Status Switcher Pill
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _toggleStatus(topic),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: topic.isOpen
                        ? colorScheme.primary.withValues(
                            alpha: isDark ? 0.20 : 0.10,
                          )
                        : (isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: topic.isOpen
                          ? colorScheme.primary.withValues(alpha: 0.35)
                          : (isDark ? Colors.white24 : Colors.black12),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    topic.isOpen ? 'در حال تدوین' : 'تکمیل',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: topic.isOpen
                          ? colorScheme.primary
                          : (isDark
                              ? Colors.white70
                              : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ),
            // Toggle Status Button (Confirm completion or revert to in-progress)
            IconButton(
              tooltip: topic.isOpen
                  ? 'تایید و رفتن به حالت تکمیل'
                  : 'بازگشت به حالت تدوین',
              icon: Icon(
                topic.isOpen
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.arrow_uturn_right,
                size: 21,
              ),
              color: topic.isOpen
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                  : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
              onPressed: () => _toggleStatus(topic),
            ),
            // Delete Topic
            IconButton(
              tooltip: 'حذف موضوع',
              icon: const Icon(CupertinoIcons.trash, size: 20),
              onPressed: () => _confirmDelete(topic),
            ),
            8.hSpace,
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.marginPage,
            vertical: 10,
          ),
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
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _addNewUserTextBlock(topic),
                    icon: const Icon(CupertinoIcons.add, size: 16),
                    label: const Text(
                      'افزودن یادداشت',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                12.hSpace,
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _copyFullTopic(topic),
                    icon: const Icon(CupertinoIcons.share_up, size: 16),
                    label: const Text(
                      'کپی برای ارسال',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: topic.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.square_pencil,
                        size: 48,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      14.vSpace,
                      Text(
                        'هنوز مطلبی در این موضوع وجود ندارد.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      8.vSpace,
                      Text(
                        'هنگام مطالعه قرآن یا تفسیر، با انتخاب «افزودن به دفتر تفکر» آیات و نکات را به اینجا منتقل کنید.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          height: 1.6,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      18.vSpace,
                      OutlinedButton.icon(
                        onPressed: () => _addNewUserTextBlock(topic),
                        icon: const Icon(CupertinoIcons.add, size: 16),
                        label: const Text('نوشتن اولین یادداشت'),
                      ),
                    ],
                  ),
                ),
              )
            : Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.transparent,
                ),
                child: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: topic.blocks.length,
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
                              child: IgnorePointer(
                                child: child,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(topicsControllerProvider.notifier)
                          .reorderBlocks(topic.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final block = topic.blocks[index];
                      return _buildBlockItem(
                        key: ValueKey(block.id),
                        index: index,
                        block: block,
                        topic: topic,
                        isDark: isDark,
                        colors: colors,
                        colorScheme: colorScheme,
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBlockItem({
    required Key key,
    required int index,
    required TopicBlock block,
    required TopicItem topic,
    required bool isDark,
    required dynamic colors,
    required ColorScheme colorScheme,
  }) {
    if (block.type == TopicBlockType.ayah) {
      return _buildAyahBlock(
        key: key,
        index: index,
        block: block,
        topic: topic,
        isDark: isDark,
        colors: colors,
        colorScheme: colorScheme,
      );
    } else {
      return _buildTextBlock(
        key: key,
        index: index,
        block: block,
        topic: topic,
        isDark: isDark,
        colors: colors,
        colorScheme: colorScheme,
      );
    }
  }

  /// Ayah block designed flat and simple like other blocks, with a subtle border indicating it is movable
  Widget _buildAyahBlock({
    required Key key,
    required int index,
    required TopicBlock block,
    required TopicItem topic,
    required bool isDark,
    required dynamic colors,
    required ColorScheme colorScheme,
  }) {
    final surahText = (block.surahName != null && block.ayahNumber != null)
        ? '(سوره ${block.surahName}، آیه ${block.ayahNumber!.toPersianDigit()})'
        : '(متن آیه)';

    final captionColor = isDark ? Colors.white38 : Colors.black38;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.14);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar (caption + delete + drag handle, identical to text blocks)
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
                      .read(topicsControllerProvider.notifier)
                      .removeBlockFromTopic(topic.id, block.id);
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

          4.vSpace,

          // Raw Arabic Text exactly as given (without artificial brackets)
          Text(
            block.content,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
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
  Widget _buildTextBlock({
    required Key key,
    required int index,
    required TopicBlock block,
    required TopicItem topic,
    required bool isDark,
    required dynamic colors,
    required ColorScheme colorScheme,
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
                      .read(topicsControllerProvider.notifier)
                      .removeBlockFromTopic(topic.id, block.id);
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
              final updated = block.copyWith(content: newText);
              ref
                  .read(topicsControllerProvider.notifier)
                  .updateBlockInTopic(topic.id, updated);
            },
          ),
        ],
      ),
    );
  }

  /// 3D tactile circular button for reordering with vertical bidirectional arrows
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
