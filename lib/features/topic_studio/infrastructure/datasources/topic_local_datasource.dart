import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local/hive/hive_service_provider.dart';
import '../../../../core/data/local/hive/i_hive_service.dart';
import '../../domain/entities/topic_item.dart';

abstract class ITopicLocalDataSource {
  List<TopicItem> getAllTopics();
  Future<void> saveTopic(TopicItem topic);
  Future<void> deleteTopic(String topicId);
  Future<void> clearAllTopics();
}

class TopicLocalDataSource implements ITopicLocalDataSource {
  static const String boxName = 'topics_box';

  final IHiveService _hiveService;

  TopicLocalDataSource(this._hiveService);

  @override
  List<TopicItem> getAllTopics() {
    try {
      _hiveService.clear(boxName: boxName);
    } catch (_) {}
    return const [];
  }

  @override
  Future<void> saveTopic(TopicItem topic) async {
    try {
      await _hiveService.put(
        topic.id,
        topic.toMap(),
        boxName: boxName,
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    try {
      await _hiveService.delete(
        topicId,
        boxName: boxName,
      );
    } catch (_) {}
  }

  @override
  Future<void> clearAllTopics() async {
    try {
      await _hiveService.clear(boxName: boxName);
    } catch (_) {}
  }
}

final topicLocalDataSourceProvider = Provider<ITopicLocalDataSource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return TopicLocalDataSource(hiveService);
});
