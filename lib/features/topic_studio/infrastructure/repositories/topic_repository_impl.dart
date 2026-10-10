import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/topic_item.dart';
import '../../domain/entities/topic_status.dart';
import '../../domain/repositories/i_topic_repository.dart';
import '../datasources/topic_local_datasource.dart';

class TopicRepositoryImpl implements ITopicRepository {
  final ITopicLocalDataSource _localDataSource;

  TopicRepositoryImpl(this._localDataSource);

  @override
  Future<List<TopicItem>> getAllTopics() async {
    return _localDataSource.getAllTopics();
  }

  @override
  Future<List<TopicItem>> getOpenTopics() async {
    final all = _localDataSource.getAllTopics();
    return all.where((t) => t.status == TopicStatus.open).toList();
  }

  @override
  Future<List<TopicItem>> getClosedTopics() async {
    final all = _localDataSource.getAllTopics();
    return all.where((t) => t.status == TopicStatus.closed).toList();
  }

  @override
  Future<TopicItem?> getTopicById(String id) async {
    final all = _localDataSource.getAllTopics();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTopic(TopicItem topic) async {
    await _localDataSource.saveTopic(topic);
  }

  @override
  Future<void> deleteTopic(String id) async {
    await _localDataSource.deleteTopic(id);
  }

  @override
  Future<void> updateTopicStatus(String id, TopicStatus status) async {
    final topic = await getTopicById(id);
    if (topic != null) {
      final updated = topic.copyWith(
        status: status,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _localDataSource.saveTopic(updated);
    }
  }
}

final topicRepositoryProvider = Provider<ITopicRepository>((ref) {
  final localDataSource = ref.watch(topicLocalDataSourceProvider);
  return TopicRepositoryImpl(localDataSource);
});
