import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tafakor_topic.dart';
import '../../infrastructure/repositories/tafakor_topics_repository_impl.dart';

final tafakorTopicsProvider = FutureProvider.autoDispose<List<TafakorTopic>>((ref) async {
  final repo = ref.watch(tafakorTopicsRepositoryProvider);
  return repo.getTopics();
});
