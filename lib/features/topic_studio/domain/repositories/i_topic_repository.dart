import '../entities/topic_item.dart';
import '../entities/topic_status.dart';

/// Contract for managing topics / study workspaces in the domain layer.
abstract class ITopicRepository {
  /// Retrieves all saved topics sorted by last updated timestamp.
  Future<List<TopicItem>> getAllTopics();

  /// Retrieves only currently active / open topics.
  Future<List<TopicItem>> getOpenTopics();

  /// Retrieves completed / closed topics.
  Future<List<TopicItem>> getClosedTopics();

  /// Retrieves a specific topic by its unique ID.
  Future<TopicItem?> getTopicById(String id);

  /// Saves or updates a topic.
  Future<void> saveTopic(TopicItem topic);

  /// Permanently removes a topic.
  Future<void> deleteTopic(String id);

  /// Toggles or updates the status of a topic (e.g. open <-> closed).
  Future<void> updateTopicStatus(String id, TopicStatus status);
}
