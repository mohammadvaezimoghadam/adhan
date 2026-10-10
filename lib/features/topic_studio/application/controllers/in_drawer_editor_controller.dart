import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/topic_block.dart';
import '../../domain/entities/topic_drag_data.dart';

class InDrawerEditorState {
  final List<TopicBlock> blocks;

  const InDrawerEditorState({
    this.blocks = const [],
  });

  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;
  int get count => blocks.length;

  InDrawerEditorState copyWith({
    List<TopicBlock>? blocks,
  }) {
    return InDrawerEditorState(
      blocks: blocks ?? this.blocks,
    );
  }
}

final inDrawerEditorControllerProvider =
    NotifierProvider<InDrawerEditorController, InDrawerEditorState>(
  InDrawerEditorController.new,
);

class InDrawerEditorController extends Notifier<InDrawerEditorState> {
  @override
  InDrawerEditorState build() {
    return const InDrawerEditorState();
  }

  /// Appends dragged Ayah blocks into the editor
  void addAyahData(TopicDragData data) {
    final newBlocks = data.toBlocks();
    state = state.copyWith(
      blocks: [...state.blocks, ...newBlocks],
    );
  }

  /// Sets/replaces all blocks in the editor (fresh session)
  void setBlocks(List<TopicBlock> newBlocks) {
    state = InDrawerEditorState(blocks: newBlocks);
  }

  /// Appends multiple blocks
  void addBlocks(List<TopicBlock> newBlocks) {
    state = state.copyWith(
      blocks: [...state.blocks, ...newBlocks],
    );
  }

  /// Adds a new editable user text block
  void addUserTextBlock([String initialText = '']) {
    final newBlock = TopicBlock.create(
      type: TopicBlockType.userText,
      content: initialText,
    );
    state = state.copyWith(
      blocks: [...state.blocks, newBlock],
    );
  }

  /// Updates textual content of a specific block
  void updateBlockContent(String blockId, String newContent) {
    state = state.copyWith(
      blocks: state.blocks.map((b) {
        if (b.id == blockId) {
          return b.copyWith(content: newContent);
        }
        return b;
      }).toList(),
    );
  }

  /// Removes a single block
  void removeBlock(String blockId) {
    state = state.copyWith(
      blocks: state.blocks.where((b) => b.id != blockId).toList(),
    );
  }

  /// Reorders blocks dynamically
  void reorderBlocks(int oldIndex, int newIndex) {
    final list = [...state.blocks];
    var adjustedNewIndex = newIndex;
    if (oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(adjustedNewIndex, item);
    state = state.copyWith(blocks: list);
  }

  /// Clears all blocks in the editor
  void clearAll() {
    state = const InDrawerEditorState();
  }
}
