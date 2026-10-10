import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/quran_reader/domain/entities/ayah_entity.dart';
import 'package:quran/features/topic_studio/application/controllers/topics_controller.dart';
import 'package:quran/features/topic_studio/domain/entities/topic_block.dart';
import 'package:quran/features/topic_studio/domain/entities/topic_drag_data.dart';
import 'package:quran/features/topic_studio/domain/entities/topic_item.dart';
import 'package:quran/features/topic_studio/domain/entities/topic_status.dart';
import 'package:quran/features/topic_studio/domain/repositories/i_topic_repository.dart';

void main() {
  group('TopicStudio Domain Layer Tests', () {
    test('TopicBlock honors editability rule based on block type', () {
      final ayahBlock = TopicBlock.create(
        type: TopicBlockType.ayah,
        content: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        surahName: 'فاتحه',
        ayahNumber: 2,
      );

      final translationBlock = TopicBlock.create(
        type: TopicBlockType.translation,
        content: 'ستایش خدایی را که پروردگار جهانیان است',
        surahName: 'فاتحه',
        ayahNumber: 2,
        sourceTitle: 'انصاریان',
      );

      final tafsirBlock = TopicBlock.create(
        type: TopicBlockType.tafsir,
        content: 'حمد به معنای ستایش در برابر نعمت اختیاری است.',
        sourceTitle: 'تفسیر نمونه',
      );

      final userTextBlock = TopicBlock.create(
        type: TopicBlockType.userText,
        content: 'نکته‌ای که در زندگی من بسیار راهگشا بود...',
      );

      // Ayah block text must strictly be non-editable by the user
      expect(ayahBlock.isEditable, isFalse);

      // Other blocks must be editable
      expect(translationBlock.isEditable, isTrue);
      expect(tafsirBlock.isEditable, isTrue);
      expect(userTextBlock.isEditable, isTrue);
    });

    test('TopicItem supports adding, updating, and reordering blocks', () {
      var topic = TopicItem.create(title: 'تدبر در سوره کهف');

      final block1 = TopicBlock.create(
        type: TopicBlockType.ayah,
        content: 'قُلْ إِنَّمَا أَنَا بَشَرٌ مِثْلُكُمْ',
        surahName: 'کهف',
        ayahNumber: 110,
      );

      final block2 = TopicBlock.create(
        type: TopicBlockType.translation,
        content: 'بگو من فقط بشری مثل شما هستم...',
      );

      final block3 = TopicBlock.create(
        type: TopicBlockType.userText,
        content: 'مفهوم تواضع پیامبر اکرم (ص)',
      );

      topic = topic.addBlock(block1);
      topic = topic.addBlock(block2);
      topic = topic.addBlock(block3);

      expect(topic.blockCount, equals(3));
      expect(topic.ayahCount, equals(1));
      expect(topic.blocks[0].type, equals(TopicBlockType.ayah));
      expect(topic.blocks[2].type, equals(TopicBlockType.userText));

      // Reorder: Move block3 (index 2) to the beginning (index 0)
      topic = topic.reorderBlocks(2, 0);
      expect(topic.blocks[0].content, equals('مفهوم تواضع پیامبر اکرم (ص)'));
      expect(topic.blocks[1].type, equals(TopicBlockType.ayah));
    });

    test('toFullFormattedText formats pure raw text without wrappers or prefixes', () {
      final topic = TopicItem.create(
        title: 'اخلاق گفتگو',
        initialBlocks: [
          TopicBlock.create(
            type: TopicBlockType.ayah,
            content: 'وَقُولُوا لِلنَّاسِ حُسْنًا',
            surahName: 'بقره',
            ayahNumber: 83,
          ),
          TopicBlock.create(
            type: TopicBlockType.translation,
            content: 'و با مردم [به نیکی و] با خوش‌زبانی سخن بگویید',
            sourceTitle: 'انصاریان',
          ),
          TopicBlock.create(
            type: TopicBlockType.userText,
            content: 'چقدر این اصل در ارتباطات امروز ما در فضای مجازی راهگشاست.',
          ),
        ],
      );

      final formatted = topic.toFullFormattedText();
      // Pure raw content only - no title header emoji, no artificial brackets, no prefixes
      expect(formatted, isNot(contains('📌')));
      expect(formatted, isNot(contains('ترجمه:')));
      expect(formatted, contains('وَقُولُوا لِلنَّاسِ حُسْنًا'));
      expect(formatted, contains('و با مردم [به نیکی و] با خوش‌زبانی سخن بگویید'));
      expect(formatted, contains('چقدر این اصل در ارتباطات امروز ما'));
    });

    test('TopicItem serialization toMap and fromMap works seamlessly', () {
      final topic = TopicItem(
        id: 'topic_123',
        title: 'موضوع آزمایشی',
        status: TopicStatus.closed,
        blocks: [
          TopicBlock(
            id: 'blk_1',
            type: TopicBlockType.ayah,
            content: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            surahId: 1,
            surahName: 'فاتحه',
            ayahNumber: 1,
            createdAt: 1000,
          ),
        ],
        createdAt: 1000,
        updatedAt: 2000,
      );

      final map = topic.toMap();
      final restored = TopicItem.fromMap(map);

      expect(restored.id, equals('topic_123'));
      expect(restored.title, equals('موضوع آزمایشی'));
      expect(restored.status, equals(TopicStatus.closed));
      expect(restored.isClosed, isTrue);
      expect(restored.blocks.length, equals(1));
      expect(restored.blocks.first.content, equals('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'));
      expect(restored.blocks.first.isEditable, isFalse);
    });

    test('TopicsController full lifecycle and block management', () async {
      final fakeRepo = _FakeTopicRepository();
      final controller = TopicsController(fakeRepo);

      // 1. Create Topic
      final topic = await controller.createTopic('تدبر در کهف');
      expect(controller.state.length, equals(1));
      expect(controller.state.first.title, equals('تدبر در کهف'));
      expect(controller.state.first.isOpen, isTrue);

      // 2. Add Blocks
      final ayahBlock = TopicBlock.create(
        type: TopicBlockType.ayah,
        content: 'الْحَمْدُ لِلَّهِ',
        ayahNumber: 1,
      );
      final translationBlock = TopicBlock.create(
        type: TopicBlockType.translation,
        content: 'ستایش مخصوص خداست',
      );

      await controller.addBlocksToTopic(topic.id, [ayahBlock, translationBlock]);
      var updated = controller.state.first;
      expect(updated.blockCount, equals(2));
      expect(updated.ayahCount, equals(1));

      // 3. Update Block
      final editedTranslation = updated.blocks[1].copyWith(content: 'سپاس و ستایش خدای را');
      await controller.updateBlockInTopic(topic.id, editedTranslation);
      updated = controller.state.first;
      expect(updated.blocks[1].content, equals('سپاس و ستایش خدای را'));

      // 4. Reorder Blocks
      await controller.reorderBlocks(topic.id, 1, 0);
      updated = controller.state.first;
      expect(updated.blocks[0].content, equals('سپاس و ستایش خدای را'));
      expect(updated.blocks[1].type, equals(TopicBlockType.ayah));

      // 5. Toggle Status
      await controller.updateTopicStatus(topic.id, TopicStatus.closed);
      updated = controller.state.first;
      expect(updated.isClosed, isTrue);

      // 6. Delete Topic
      await controller.deleteTopic(topic.id);
      expect(controller.state.isEmpty, isTrue);
    });

    test('TopicDragData supports single and multiple Ayahs and conversion to blocks', () {
      const ayah1 = AyahEntity(
        id: 1,
        surahId: 2,
        ayahNumber: 153,
        arabicText: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
      );
      const ayah2 = AyahEntity(
        id: 2,
        surahId: 2,
        ayahNumber: 154,
        arabicText: 'وَلَا تَقُولُوا لِمَن يُقْتَلُ فِي سَبِيلِ اللَّهِ أَمْوَاتٌ',
      );

      final singleDrag = TopicDragData(
        ayahs: const [ayah1],
        surahName: 'بقره',
      );
      expect(singleDrag.isMultiple, isFalse);
      expect(singleDrag.count, equals(1));
      final singleBlocks = singleDrag.toBlocks();
      expect(singleBlocks.length, equals(1));
      expect(singleBlocks.first.type, equals(TopicBlockType.ayah));
      expect(singleBlocks.first.ayahNumber, equals(153));

      final multiDrag = TopicDragData(
        ayahs: const [ayah1, ayah2],
        surahName: 'بقره',
      );
      expect(multiDrag.isMultiple, isTrue);
      expect(multiDrag.count, equals(2));
      final multiBlocks = multiDrag.toBlocks();
      expect(multiBlocks.length, equals(2));
      expect(multiBlocks[0].ayahNumber, equals(153));
      expect(multiBlocks[1].ayahNumber, equals(154));
    });

    test('TopicDragData generates both Ayah and Translation blocks when translation is available', () {
      const ayahWithTranslation = AyahEntity(
        id: 1,
        surahId: 2,
        ayahNumber: 153,
        arabicText: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ',
        translationText: 'ای کسانی که ایمان آورده‌اید، از صبر و نماز کمک بجویید',
      );

      final dragData = TopicDragData(
        ayahs: const [ayahWithTranslation],
        surahName: 'بقره',
      );

      final blocks = dragData.toBlocks();
      expect(blocks.length, equals(2));
      expect(blocks[0].type, equals(TopicBlockType.ayah));
      expect(blocks[0].content, equals('يَا أَيُّهَا الَّذِينَ آمَنُوا اسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ'));
      expect(blocks[1].type, equals(TopicBlockType.translation));
      expect(blocks[1].content, contains('ای کسانی که ایمان آورده‌اید'));
      expect(blocks[1].content, contains('(۱۵۳)'));
    });
  });
}

class _FakeTopicRepository implements ITopicRepository {
  final Map<String, TopicItem> _storage = {};

  @override
  Future<List<TopicItem>> getAllTopics() async => _storage.values.toList();

  @override
  Future<List<TopicItem>> getOpenTopics() async =>
      _storage.values.where((t) => t.status == TopicStatus.open).toList();

  @override
  Future<List<TopicItem>> getClosedTopics() async =>
      _storage.values.where((t) => t.status == TopicStatus.closed).toList();

  @override
  Future<TopicItem?> getTopicById(String id) async => _storage[id];

  @override
  Future<void> saveTopic(TopicItem topic) async {
    _storage[topic.id] = topic;
  }

  @override
  Future<void> deleteTopic(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> updateTopicStatus(String id, TopicStatus status) async {
    final t = _storage[id];
    if (t != null) {
      _storage[id] = t.copyWith(status: status);
    }
  }
}
