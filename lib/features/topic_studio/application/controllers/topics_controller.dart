import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/topic_block.dart';
import '../../domain/entities/topic_item.dart';
import '../../domain/entities/topic_status.dart';
import '../../domain/repositories/i_topic_repository.dart';
import '../../infrastructure/repositories/topic_repository_impl.dart';

class TopicsController extends StateNotifier<List<TopicItem>> {
  final ITopicRepository _repository;

  TopicsController(this._repository) : super([]) {
    loadTopics();
  }

  Future<void> loadTopics() async {
    final list = await _repository.getAllTopics();
    state = list;
  }

  /// Creates a new topic and returns it
  Future<TopicItem> createTopic(
    String title, [
    List<TopicBlock>? initialBlocks,
  ]) async {
    final cleanTitle = title.trim();
    final topic = TopicItem.create(
      title: cleanTitle.isNotEmpty ? cleanTitle : 'موضوع بدون عنوان',
      initialBlocks: initialBlocks,
    );

    await _repository.saveTopic(topic);
    state = [topic, ...state];
    return topic;
  }

  /// Adds a single block to an existing topic
  Future<void> addBlockToTopic(String topicId, TopicBlock block) async {
    await addBlocksToTopic(topicId, [block]);
  }

  /// Adds multiple blocks sequentially to an existing topic
  Future<void> addBlocksToTopic(
    String topicId,
    List<TopicBlock> blocks,
  ) async {
    if (blocks.isEmpty) return;

    final index = state.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    var topic = state[index];
    for (final block in blocks) {
      topic = topic.addBlock(block);
    }

    await _repository.saveTopic(topic);

    final updatedList = List<TopicItem>.from(state);
    updatedList[index] = topic;
    // Re-sort so recently updated topic bubbles to top
    updatedList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = updatedList;
  }

  /// Removes a block from a topic
  Future<void> removeBlockFromTopic(String topicId, String blockId) async {
    final index = state.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    final topic = state[index].removeBlock(blockId);
    await _repository.saveTopic(topic);

    final updatedList = List<TopicItem>.from(state);
    updatedList[index] = topic;
    state = updatedList;
  }

  /// Updates an editable block's content within a topic
  Future<void> updateBlockInTopic(
    String topicId,
    TopicBlock updatedBlock,
  ) async {
    final index = state.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    final topic = state[index].updateBlock(updatedBlock);
    await _repository.saveTopic(topic);

    final updatedList = List<TopicItem>.from(state);
    updatedList[index] = topic;
    state = updatedList;
  }

  /// Reorders blocks within a topic (e.g. via ReorderableListView)
  Future<void> reorderBlocks(
    String topicId,
    int oldIndex,
    int newIndex,
  ) async {
    final index = state.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    final topic = state[index].reorderBlocks(oldIndex, newIndex);
    await _repository.saveTopic(topic);

    final updatedList = List<TopicItem>.from(state);
    updatedList[index] = topic;
    state = updatedList;
  }

  /// Updates the title of an existing topic
  Future<void> updateTopicTitle(String topicId, String newTitle) async {
    final index = state.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) return;

    final topic = state[index].copyWith(
      title: cleanTitle,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.saveTopic(topic);

    final updatedList = List<TopicItem>.from(state);
    updatedList[index] = topic;
    state = updatedList;
  }

  /// Toggles or updates the status of a topic (e.g. open <-> closed)
  Future<void> updateTopicStatus(String topicId, TopicStatus status) async {
    final index = state.indexWhere((t) => t.id == topicId);
    if (index == -1) return;

    final topic = state[index].copyWith(
      status: status,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.saveTopic(topic);

    final updatedList = List<TopicItem>.from(state);
    updatedList[index] = topic;
    state = updatedList;
  }

  /// Permanently removes a topic
  Future<void> deleteTopic(String topicId) async {
    await _repository.deleteTopic(topicId);
    state = state.where((t) => t.id != topicId).toList();
  }
}

final topicsControllerProvider =
    StateNotifierProvider<TopicsController, List<TopicItem>>((ref) {
  final repo = ref.watch(topicRepositoryProvider);
  return TopicsController(repo);
});

/// Selector provider returning all topics
final allTopicsProvider = Provider<List<TopicItem>>((ref) {
  return ref.watch(topicsControllerProvider);
});

/// Selector provider returning only active / open topics
final openTopicsProvider = Provider<List<TopicItem>>((ref) {
  final topics = ref.watch(topicsControllerProvider);
  return topics.where((t) => t.status == TopicStatus.open).toList();
});

/// Selector provider returning only completed / closed topics
final closedTopicsProvider = Provider<List<TopicItem>>((ref) {
  final topics = ref.watch(topicsControllerProvider);
  return topics.where((t) => t.status == TopicStatus.closed).toList();
});

/// Provider family for watching a single topic by ID
final topicByIdProvider =
    Provider.family<TopicItem?, String>((ref, topicId) {
  final topics = ref.watch(topicsControllerProvider);
  try {
    return topics.firstWhere((t) => t.id == topicId);
  } catch (_) {
    return null;
  }
});
