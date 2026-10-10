import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic_block.freezed.dart';

/// Types of content blocks that can be placed inside a topic.
enum TopicBlockType {
  /// Holy Quranic Arabic text. Immutable/non-editable by user to preserve sanctity.
  ayah,

  /// Ayah translation text (editable if user wishes to refine phrasing).
  translation,

  /// Selected excerpt from Tafsir commentaries (editable, with source attribution).
  tafsir,

  /// Free-form user reflection, question, or commentary text.
  userText;

  static TopicBlockType fromString(String? value) {
    switch (value) {
      case 'ayah':
        return TopicBlockType.ayah;
      case 'translation':
        return TopicBlockType.translation;
      case 'tafsir':
        return TopicBlockType.tafsir;
      case 'userText':
      default:
        return TopicBlockType.userText;
    }
  }

  String get titlePersian {
    switch (this) {
      case TopicBlockType.ayah:
        return 'متن آیه';
      case TopicBlockType.translation:
        return 'ترجمه';
      case TopicBlockType.tafsir:
        return 'گزیده تفسیر';
      case TopicBlockType.userText:
        return 'توضیحات و دل‌نوشته';
    }
  }
}

/// Represents an individual content block within a topic.
/// Blocks can be dynamically reordered within the topic flow.
@freezed
abstract class TopicBlock with _$TopicBlock {
  const TopicBlock._();

  const factory TopicBlock({
    required String id,
    required TopicBlockType type,
    required String content,
    int? surahId,
    String? surahName,
    int? ayahNumber,
    String? sourceTitle, // e.g. "تفسیر نمونه", "ترجمه مکارم"
    required int createdAt,
  }) = _TopicBlock;

  static int _idCounter = 0;

  /// Factory helper to create a unique block with timestamp defaults
  factory TopicBlock.create({
    required TopicBlockType type,
    required String content,
    int? surahId,
    String? surahName,
    int? ayahNumber,
    String? sourceTitle,
  }) {
    _idCounter++;
    return TopicBlock(
      id: 'blk_${DateTime.now().microsecondsSinceEpoch}_$_idCounter',
      type: type,
      content: content.trim(),
      surahId: surahId,
      surahName: surahName,
      ayahNumber: ayahNumber,
      sourceTitle: sourceTitle,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Whether the user is allowed to edit this block's textual content.
  /// Holy Quranic Arabic text is strictly immutable, but its position can be moved.
  bool get isEditable => type != TopicBlockType.ayah;

  /// Pure raw text representation for export/copying without any prefixes or wrappers
  String toFormattedText() {
    return content.trim();
  }

  /// Returns the exact clean publication text for this block as displayed and edited in the editor.
  /// - Ayah: pure Quranic Arabic text without decorative brackets.
  /// - Translation, User text, Tafsir: the exact text content from the editor.
  String toPublicationText() {
    final text = content.trim();
    if (text.isEmpty) return '';

    if (type == TopicBlockType.ayah) {
      // Strip any accidental brackets or quotes to ensure pure Arabic text
      return text
          .replaceAll('﴿', '')
          .replaceAll('﴾', '')
          .replaceAll('«', '')
          .replaceAll('»', '')
          .trim();
    }
    return text;
  }

  /// Formats a list of draft blocks into the standard publication and sharing format
  /// separated by blank lines (paragraphs).
  static String formatBlocksForPublication(List<TopicBlock> blocks) {
    final buffer = StringBuffer();
    final validTexts = blocks
        .map((b) => b.toPublicationText().trim())
        .where((t) => t.isNotEmpty)
        .toList();

    for (int i = 0; i < validTexts.length; i++) {
      buffer.writeln(validTexts[i]);
      if (i < validTexts.length - 1) {
        buffer.writeln(); // Blank line between blocks
      }
    }
    return buffer.toString().trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'surahId': surahId,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'sourceTitle': sourceTitle,
      'createdAt': createdAt,
    };
  }

  factory TopicBlock.fromMap(Map<dynamic, dynamic> map) {
    return TopicBlock(
      id: map['id'] as String? ?? 'blk_${DateTime.now().microsecondsSinceEpoch}',
      type: TopicBlockType.fromString(map['type'] as String?),
      content: map['content'] as String? ?? '',
      surahId: map['surahId'] as int?,
      surahName: map['surahName'] as String?,
      ayahNumber: map['ayahNumber'] as int?,
      sourceTitle: map['sourceTitle'] as String?,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
