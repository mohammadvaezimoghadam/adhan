import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/topics_controller.dart';
import '../../domain/entities/topic_block.dart';
import '../../domain/entities/topic_item.dart';

/// Clean, minimal centered dialog for creating or renaming a topic in «دفتر تفکر».
class NewTopicDialog extends ConsumerStatefulWidget {
  final String? topicId;
  final String? initialTitle;
  final List<TopicBlock>? initialBlocks;
  final bool isEditing;

  const NewTopicDialog({
    super.key,
    this.topicId,
    this.initialTitle,
    this.initialBlocks,
    this.isEditing = false,
  });

  /// Helper to show the dialog and return the created/updated topic
  static Future<TopicItem?> show(
    BuildContext context, {
    String? topicId,
    String? initialTitle,
    List<TopicBlock>? initialBlocks,
    bool isEditing = false,
  }) {
    return showDialog<TopicItem>(
      context: context,
      builder: (context) => NewTopicDialog(
        topicId: topicId,
        initialTitle: initialTitle,
        initialBlocks: initialBlocks,
        isEditing: isEditing,
      ),
    );
  }

  @override
  ConsumerState<NewTopicDialog> createState() => _NewTopicDialogState();
}

class _NewTopicDialogState extends ConsumerState<NewTopicDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialTitle!.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.lightImpact();

    if (widget.isEditing) {
      if (mounted) {
        Navigator.of(context).pop(
          TopicItem(
            id: widget.topicId ?? '',
            title: title,
            blocks: widget.initialBlocks ?? const [],
            createdAt: 0,
            updatedAt: 0,
          ),
        );
      }
      return;
    }

    final created = await ref
        .read(topicsControllerProvider.notifier)
        .createTopic(title, widget.initialBlocks);

    if (mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: colors.dialogSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors.cardBorder,
            width: 1,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppModalHeader(
                    title: widget.isEditing ? 'ویرایش عنوان موضوع' : 'موضوع تفکر جدید',
                    showDragHandle: false,
                    bottomSpacing: 14,
                  ),
                  Text(
                    'یک عنوان مفهوم‌محور برای این موضوع تفکر انتخاب کنید:',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  12.vSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.cardBorder,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLength: 60,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'مثال: تدبر در سوره کهف، اخلاق گفتگو...',
                        hintStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  20.vSpace,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: colors.cardBorder,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('انصراف'),
                        ),
                      ),
                      12.hSpace,
                      Expanded(
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _controller,
                          builder: (context, value, _) {
                            final canSubmit = value.text.trim().isNotEmpty;
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: canSubmit ? _submit : null,
                              child: Text(
                                widget.isEditing ? 'ذخیره' : 'ایجاد موضوع',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
