import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bookmark_label.dart';
import '../../infrastructure/datasources/bookmark_label_local_datasource.dart';
import 'bookmarks_controller.dart';

final bookmarkLabelsControllerProvider =
    NotifierProvider<BookmarkLabelsController, List<BookmarkLabel>>(
  BookmarkLabelsController.new,
);

/// Cached O(1) hash map lookup for labels by their unique ID.
/// Automatically recomputed only when the list of labels changes.
final bookmarkLabelsMapProvider = Provider<Map<String, BookmarkLabel>>((ref) {
  final labels = ref.watch(bookmarkLabelsControllerProvider);
  return {for (final l in labels) l.id: l};
});

class BookmarkLabelsController extends Notifier<List<BookmarkLabel>> {
  late final IBookmarkLabelLocalDataSource _dataSource;

  @override
  List<BookmarkLabel> build() {
    _dataSource = ref.watch(bookmarkLabelLocalDataSourceProvider);
    _initDefaults();
    return _dataSource.getAllLabels();
  }

  Future<void> _initDefaults() async {
    await _dataSource.ensureDefaultLabelsSeeded();
    final fresh = _dataSource.getAllLabels();
    if (fresh.length != state.length) {
      state = fresh;
    }
  }

  /// Creates and saves a new custom label.
  Future<BookmarkLabel> addLabel(
    String title, {
    int? colorValue,
  }) async {
    final cleanTitle = title.trim();
    final newLabel = BookmarkLabel(
      id: 'label_${DateTime.now().millisecondsSinceEpoch}',
      title: cleanTitle,
      colorValue: colorValue ?? BookmarkLabel.presetColors.first,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isDefault: false,
    );

    await _dataSource.saveLabel(newLabel);
    state = [...state, newLabel];
    return newLabel;
  }

  /// Deletes a label by its unique ID.
  /// Also cascades and removes this labelId reference from all bookmarked ayahs.
  Future<void> deleteLabel(String labelId) async {
    await _dataSource.deleteLabel(labelId);
    state = state.where((l) => l.id != labelId).toList();

    // Cascade removal from all active bookmarks
    await ref
        .read(bookmarksControllerProvider.notifier)
        .removeLabelFromAllBookmarks(labelId);
  }

  /// Updates an existing label title or color.
  Future<void> updateLabel(
    String labelId, {
    String? title,
    int? colorValue,
  }) async {
    final index = state.indexWhere((l) => l.id == labelId);
    if (index == -1) return;

    final existing = state[index];
    final updated = existing.copyWith(
      title: title?.trim(),
      colorValue: colorValue,
    );

    await _dataSource.saveLabel(updated);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
  }

  /// Retrieves a label by its ID or null if not found.
  BookmarkLabel? getLabelById(String id) {
    return state.where((l) => l.id == id).firstOrNull;
  }
}
