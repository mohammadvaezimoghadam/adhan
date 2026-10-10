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
import '../../../../common/extensions/string_extension.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../application/controllers/topics_controller.dart';
import '../../domain/entities/topic_block.dart';
import '../../domain/entities/topic_item.dart';
import 'new_topic_dialog.dart';

/// Modal bottom sheet to select or create a topic in «دفتر تفکر» and append blocks.
class AddToTopicBottomSheet extends ConsumerStatefulWidget {
  final int? surahId;
  final String? surahName;
  final int? ayahNumber;
  final String? arabicText;
  final String? translationText;
  final String? tafsirText;
  final String? customText;
  final String? sourceTitle;

  const AddToTopicBottomSheet({
    super.key,
    this.surahId,
    this.surahName,
    this.ayahNumber,
    this.arabicText,
    this.translationText,
    this.tafsirText,
    this.customText,
    this.sourceTitle,
  });

  /// Helper to launch the bottom sheet
  static Future<void> show(
    BuildContext context, {
    int? surahId,
    String? surahName,
    int? ayahNumber,
    String? arabicText,
    String? translationText,
    String? tafsirText,
    String? customText,
    String? sourceTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToTopicBottomSheet(
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        arabicText: arabicText,
        translationText: translationText,
        tafsirText: tafsirText,
        customText: customText,
        sourceTitle: sourceTitle,
      ),
    );
  }

  @override
  ConsumerState<AddToTopicBottomSheet> createState() =>
      _AddToTopicBottomSheetState();
}

class _AddToTopicBottomSheetState extends ConsumerState<AddToTopicBottomSheet> {
  late bool _includeAyah;
  late bool _includeTranslation;

  @override
  void initState() {
    super.initState();
    _includeAyah = widget.arabicText != null && widget.arabicText!.isNotEmpty;
    _includeTranslation =
        widget.translationText != null && widget.translationText!.isNotEmpty;
  }

  List<TopicBlock> _buildSelectedBlocks() {
    final blocks = <TopicBlock>[];

    // 1. Ayah block
    if (_includeAyah && widget.arabicText != null && widget.arabicText!.isNotEmpty) {
      blocks.add(
        TopicBlock.create(
          type: TopicBlockType.ayah,
          content: widget.arabicText!,
          surahId: widget.surahId,
          surahName: widget.surahName,
          ayahNumber: widget.ayahNumber,
        ),
      );
    }

    // 2. Translation block
    if (_includeTranslation &&
        widget.translationText != null &&
        widget.translationText!.isNotEmpty) {
      final removeBrackets = ref
          .read(quranDisplaySettingsControllerProvider)
          .removeTranslationBrackets;
      String translationContent = removeBrackets
          ? widget.translationText!.removeTranslatorExplanations().trim()
          : widget.translationText!.trim();

      // If ayah text and translation come together (e.g. from long press on ayah),
      // ensure the Persian ayah number is placed at the end of translation: e.g. (۱)
      if (widget.ayahNumber != null &&
          widget.arabicText != null &&
          widget.arabicText!.isNotEmpty) {
        final persianNumber = widget.ayahNumber!.toPersianDigit();
        final suffix = '($persianNumber)';
        if (!translationContent.endsWith(suffix) &&
            !translationContent.endsWith('(${widget.ayahNumber})')) {
          translationContent = '$translationContent $suffix';
        }
      }

      blocks.add(
        TopicBlock.create(
          type: TopicBlockType.translation,
          content: translationContent,
          surahId: widget.surahId,
          surahName: widget.surahName,
          ayahNumber: widget.ayahNumber,
          sourceTitle: widget.sourceTitle,
        ),
      );
    }

    // 3. Tafsir excerpt block
    if (widget.tafsirText != null && widget.tafsirText!.isNotEmpty) {
      blocks.add(
        TopicBlock.create(
          type: TopicBlockType.tafsir,
          content: widget.tafsirText!,
          surahId: widget.surahId,
          surahName: widget.surahName,
          ayahNumber: widget.ayahNumber,
          sourceTitle: widget.sourceTitle ?? 'تفسیر',
        ),
      );
    }

    // 4. Custom user text block
    if (widget.customText != null && widget.customText!.isNotEmpty) {
      blocks.add(
        TopicBlock.create(
          type: TopicBlockType.userText,
          content: widget.customText!,
          surahId: widget.surahId,
          surahName: widget.surahName,
          ayahNumber: widget.ayahNumber,
          sourceTitle: widget.sourceTitle,
        ),
      );
    }

    return blocks;
  }

  Future<void> _appendToTopic(TopicItem topic) async {
    final blocks = _buildSelectedBlocks();
    if (blocks.isEmpty) {
      AppSnackBar.showInfo(context, 'حداقل یک بخش را برای افزودن انتخاب کنید.');
      return;
    }

    HapticFeedback.lightImpact();
    await ref
        .read(topicsControllerProvider.notifier)
        .addBlocksToTopic(topic.id, blocks);

    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(
        context,
        'به موضوع «${topic.title}» در دفتر تفکر افزوده شد.',
      );
    }
  }

  Future<void> _createNewTopicAndAppend() async {
    final blocks = _buildSelectedBlocks();
    if (blocks.isEmpty) {
      AppSnackBar.showInfo(context, 'حداقل یک بخش را برای افزودن انتخاب کنید.');
      return;
    }

    final newTopic = await NewTopicDialog.show(
      context,
      initialBlocks: blocks,
    );

    if (newTopic != null && mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(
        context,
        'موضوع «${newTopic.title}» ایجاد شد و مطالب به آن افزوده شدند.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final allTopics = ref.watch(allTopicsProvider);

    final hasBothAyahAndTranslation = (widget.arabicText != null &&
            widget.arabicText!.isNotEmpty) &&
        (widget.translationText != null && widget.translationText!.isNotEmpty);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxSheetHeight = (screenHeight * 0.78).clamp(380.0, 680.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxSheetHeight,
        ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Pinned Modal Header
              Padding(
                padding: const EdgeInsets.only(
                  left: AppDimens.marginPage,
                  right: AppDimens.marginPage,
                  top: 12,
                ),
                child: AppModalHeader(
                  showDragHandle: true,
                  title: 'افزودن به دفتر تفکر',
                  bottomSpacing: 10,
                ),
              ),

              // 2. Optional Content Checkboxes if both Ayah and Translation are passed
              if (hasBothAyahAndTranslation) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.marginPage,
                  ),
                  child: Material(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'متن آیه',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              value: _includeAyah,
                              activeColor: colorScheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  _includeAyah = val ?? true;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'ترجمه آیه',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              value: _includeTranslation,
                              activeColor: colorScheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  _includeTranslation = val ?? true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                10.vSpace,
              ],

              // 3. Selection section header (Pinned above list)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.marginPage,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'انتخاب موضوع:',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onPressed: _createNewTopicAndAppend,
                      icon: const Icon(CupertinoIcons.add_circled, size: 16),
                      label: const Text(
                        'موضوع جدید',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              6.vSpace,

              // 4. Scrollable Topics List (Flexible and Scrollbar-protected against overflow)
              if (allTopics.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppDimens.marginPage),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.square_list,
                          size: 32,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        10.vSpace,
                        Text(
                          'هنوز موضوعی در دفتر تفکر ندارید.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        6.vSpace,
                        Text(
                          'با زدن دکمه زیر، اولین موضوع خود را ایجاد کنید.',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            color: isDark ? Colors.white38 : Colors.black45,
                          ),
                        ),
                        14.vSpace,
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _createNewTopicAndAppend,
                          icon: const Icon(CupertinoIcons.add, size: 16),
                          label: const Text('ایجاد اولین موضوع'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.marginPage,
                        4,
                        AppDimens.marginPage,
                        16,
                      ),
                      itemCount: allTopics.length,
                      separatorBuilder: (_, _) => 6.vSpace,
                      itemBuilder: (context, index) {
                        final topic = allTopics[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _appendToTopic(topic),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF7F5F0),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colors.cardBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.folder,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  12.hSpace,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          topic.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        4.vSpace,
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: topic.isOpen
                                                    ? colorScheme.primary.withValues(
                                                        alpha: isDark ? 0.20 : 0.10,
                                                      )
                                                    : (isDark
                                                        ? Colors.white.withValues(alpha: 0.08)
                                                        : Colors.black.withValues(alpha: 0.05)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                topic.isOpen ? 'در حال تدوین' : 'تکمیل‌شده',
                                                style: TextStyle(
                                                  fontFamily: AppTypography.fontFamily,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: topic.isOpen
                                                      ? colorScheme.primary
                                                      : (isDark ? Colors.white60 : Colors.black54),
                                                ),
                                              ),
                                            ),
                                            6.hSpace,
                                            Expanded(
                                              child: Text(
                                                '${topic.blockCount.toPersianDigit()} بخش • ${topic.ayahCount.toPersianDigit()} آیه',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTypography.fontFamily,
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black45,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_left,
                                    size: 14,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
