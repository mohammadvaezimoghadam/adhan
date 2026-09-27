import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local/hive/hive_service_provider.dart';
import '../../../../core/data/local/hive/i_hive_service.dart';
import '../../domain/entities/bookmark_label.dart';

abstract class IBookmarkLabelLocalDataSource {
  List<BookmarkLabel> getAllLabels();
  Future<void> saveLabel(BookmarkLabel label);
  Future<void> deleteLabel(String labelId);
  Future<void> ensureDefaultLabelsSeeded();
  Future<void> clearAllLabels();
}

class BookmarkLabelLocalDataSource implements IBookmarkLabelLocalDataSource {
  static const String boxName = 'bookmark_labels_box';

  final IHiveService _hiveService;

  BookmarkLabelLocalDataSource(this._hiveService);

  @override
  Future<void> ensureDefaultLabelsSeeded() async {
    try {
      final values = _hiveService.getValues(boxName: boxName);
      if (values.isEmpty) {
        // Seed default curated labels
        for (final label in BookmarkLabel.defaultLabels) {
          await _hiveService.put(
            label.id,
            label.toMap(),
            boxName: boxName,
          );
        }
      }
    } catch (_) {
      // Gracefully handle uninitialized Hive in tests or before app init
    }
  }

  @override
  List<BookmarkLabel> getAllLabels() {
    try {
      final values = _hiveService.getValues(boxName: boxName);
      final items = <BookmarkLabel>[];

      for (final val in values) {
        if (val is Map) {
          try {
            items.add(BookmarkLabel.fromMap(val));
          } catch (_) {}
        }
      }

      if (items.isEmpty) {
        return BookmarkLabel.defaultLabels;
      }

      // Sort by createdAt ascending so default labels appear first in order
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    } catch (_) {
      // Fallback gracefully to default labels
      return BookmarkLabel.defaultLabels;
    }
  }

  @override
  Future<void> saveLabel(BookmarkLabel label) async {
    try {
      await _hiveService.put(
        label.id,
        label.toMap(),
        boxName: boxName,
      );
    } catch (_) {}
  }

  @override
  Future<void> deleteLabel(String labelId) async {
    try {
      await _hiveService.delete(
        labelId,
        boxName: boxName,
      );
    } catch (_) {}
  }

  @override
  Future<void> clearAllLabels() async {
    try {
      await _hiveService.clear(boxName: boxName);
    } catch (_) {}
  }
}

final bookmarkLabelLocalDataSourceProvider =
    Provider<IBookmarkLabelLocalDataSource>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return BookmarkLabelLocalDataSource(hiveService);
});
