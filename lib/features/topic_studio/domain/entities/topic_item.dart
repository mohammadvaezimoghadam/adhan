import 'package:freezed_annotation/freezed_annotation.dart';

import 'topic_block.dart';
import 'topic_status.dart';

part 'topic_item.freezed.dart';

/// Represents a study topic / reflection workspace composed of modular blocks.
@freezed
abstract class TopicItem with _$TopicItem {
  const TopicItem._();

  const factory TopicItem({
    required String id,
    required String title,
    @Default(TopicStatus.open) TopicStatus status,
    @Default([]) List<TopicBlock> blocks,
    required int createdAt,
    required int updatedAt,
  }) = _TopicItem;

  static int _topicCounter = 0;

  /// Factory helper to create a fresh topic
  factory TopicItem.create({
    required String title,
    List<TopicBlock>? initialBlocks,
  }) {
    _topicCounter++;
    final now = DateTime.now().millisecondsSinceEpoch;
    return TopicItem(
      id: 'topic_${DateTime.now().microsecondsSinceEpoch}_$_topicCounter',
      title: title.trim(),
      status: TopicStatus.open,
      blocks: initialBlocks ?? const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isOpen => status.isOpen;
  bool get isClosed => status.isClosed;

  /// Count of unique ayahs present in this topic
  int get ayahCount =>
      blocks.where((b) => b.type == TopicBlockType.ayah).length;

  /// Total count of blocks
  int get blockCount => blocks.length;

  /// Whether the topic has any content blocks
  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;

  /// Compiles all blocks into pure publication text separated by blank lines,
  /// ready to be copied and pasted directly without any decorative prefixes or wrappers.
  String toFullFormattedText() {
    return TopicBlock.formatBlocksForPublication(blocks);
  }

  /// Returns a new [TopicItem] with the block added at the end (or specified index)
  TopicItem addBlock(TopicBlock block, {int? index}) {
    final newBlocks = List<TopicBlock>.from(blocks);
    if (index != null && index >= 0 && index <= newBlocks.length) {
      newBlocks.insert(index, block);
    } else {
      newBlocks.add(block);
    }
    return copyWith(
      blocks: newBlocks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns a new [TopicItem] with the specified block removed
  TopicItem removeBlock(String blockId) {
    final newBlocks = blocks.where((b) => b.id != blockId).toList();
    return copyWith(
      blocks: newBlocks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns a new [TopicItem] with a block replaced/updated
  TopicItem updateBlock(TopicBlock updatedBlock) {
    final newBlocks = blocks.map((b) {
      return b.id == updatedBlock.id ? updatedBlock : b;
    }).toList();
    return copyWith(
      blocks: newBlocks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns a new [TopicItem] with blocks reordered
  TopicItem reorderBlocks(int oldIndex, int newIndex) {
    final newBlocks = List<TopicBlock>.from(blocks);
    if (oldIndex < 0 || oldIndex >= newBlocks.length) return this;

    // Flutter ReorderableListView offset adjustment rule
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= newBlocks.length) return this;

    final item = newBlocks.removeAt(oldIndex);
    newBlocks.insert(targetIndex, item);

    return copyWith(
      blocks: newBlocks,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory TopicItem.fromMap(Map<dynamic, dynamic> map) {
    final blocksRaw = map['blocks'] as List?;
    final parsedBlocks = blocksRaw != null
        ? blocksRaw
            .whereType<Map>()
            .map((b) => TopicBlock.fromMap(b))
            .toList()
        : <TopicBlock>[];

    return TopicItem(
      id: map['id'] as String? ?? 'topic_${DateTime.now().microsecondsSinceEpoch}',
      title: map['title'] as String? ?? '',
      status: TopicStatus.fromString(map['status'] as String?),
      blocks: parsedBlocks,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
