import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../quran_reader/domain/entities/ayah_entity.dart';
import 'topic_block.dart';

/// Data payload passed when dragging one or more Ayahs into Topic Studio.
class TopicDragData {
  final List<AyahEntity> ayahs;
  final String surahName;
  final Map<int, String>? translations;
  final String? sourceTitle;
  final bool removeBrackets;

  const TopicDragData({
    required this.ayahs,
    required this.surahName,
    this.translations,
    this.sourceTitle,
    this.removeBrackets = false,
  });

  bool get isMultiple => ayahs.length > 1;
  int get count => ayahs.length;

  /// Converts the dragged Ayahs into TopicBlock entities.
  /// Generates both Ayah (Arabic) and Translation blocks when translation is available.
  List<TopicBlock> toBlocks() {
    final blocks = <TopicBlock>[];

    for (final a in ayahs) {
      // 1. Arabic Ayah block
      blocks.add(
        TopicBlock.create(
          type: TopicBlockType.ayah,
          content: a.arabicText,
          surahId: a.surahId,
          surahName: surahName,
          ayahNumber: a.ayahNumber,
        ),
      );

      // 2. Translation block (if available)
      final rawTranslation = translations?[a.ayahNumber] ?? a.translationText;
      if (rawTranslation != null && rawTranslation.trim().isNotEmpty) {
        var translationContent = removeBrackets
            ? rawTranslation.removeTranslatorExplanations().trim()
            : rawTranslation.trim();
        final persianNumber = a.ayahNumber.toPersianDigit();
        final suffix = '($persianNumber)';
        if (!translationContent.endsWith(suffix) &&
            !translationContent.endsWith('(${a.ayahNumber})')) {
          translationContent = '$translationContent $suffix';
        }

        blocks.add(
          TopicBlock.create(
            type: TopicBlockType.translation,
            content: translationContent,
            surahId: a.surahId,
            surahName: surahName,
            ayahNumber: a.ayahNumber,
            sourceTitle: sourceTitle,
          ),
        );
      }
    }

    return blocks;
  }
}

