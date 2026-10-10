import '../entities/tafakor_topic.dart';

abstract class ITafakorTopicsRepository {
  Future<List<TafakorTopic>> getTopics();
}
