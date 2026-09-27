import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bookmark_item.dart';
import '../../infrastructure/datasources/bookmark_local_datasource.dart';

final bookmarksControllerProvider =
    NotifierProvider<BookmarksController, List<BookmarkItem>>(
  BookmarksController.new,
);

class BookmarksController extends Notifier<List<BookmarkItem>> {
  late final IBookmarkLocalDataSource _dataSource;

  @override
  List<BookmarkItem> build() {
    _dataSource = ref.watch(bookmarkLocalDataSourceProvider);
    _initAndMigrate();
    return _dataSource.getAllBookmarks();
  }

  Future<void> _initAndMigrate() async {
    await _dataSource.checkAndMigrateOldPreferencesBookmark();
    final reloaded = _dataSource.getAllBookmarks();
    if (reloaded.length != state.length) {
      state = reloaded;
    }
  }

  /// Toggles the bookmark for the specified Ayah.
  /// Returns `true` if newly added, `false` if removed.
  Future<bool> toggleBookmark({
    required int surahId,
    required String surahName,
    required int ayahNumber,
    required int totalAyahs,
    String? arabicText,
    bool isAyahBookmark = false,
    List<String> labelIds = const [],
    String? note,
  }) async {
    final existingIndex = state.indexWhere(
      (b) => b.surahId == surahId && b.ayahNumber == ayahNumber,
    );

    if (existingIndex != -1) {
      // Remove bookmark
      await _dataSource.removeBookmark(surahId, ayahNumber);
      state = [
        ...state.sublist(0, existingIndex),
        ...state.sublist(existingIndex + 1),
      ];
      return false;
    } else {
      // Add new bookmark at the front (newest first)
      final newItem = BookmarkItem(
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        totalAyahs: totalAyahs,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        arabicText: arabicText,
        isAyahBookmark: isAyahBookmark,
        labelIds: labelIds,
        note: note,
      );

      await _dataSource.saveBookmark(newItem);
      state = [newItem, ...state];
      return true;
    }
  }

  /// Saves a new bookmark or updates an existing bookmark with note and labels.
  Future<void> saveOrUpdateAyahBookmark({
    required int surahId,
    required String surahName,
    required int ayahNumber,
    required int totalAyahs,
    String? arabicText,
    List<String> labelIds = const [],
    String? note,
    bool isAyahBookmark = true,
  }) async {
    final existingIndex = state.indexWhere(
      (b) => b.surahId == surahId && b.ayahNumber == ayahNumber,
    );

    final trimmedNote = note?.trim();
    final cleanNote = (trimmedNote != null && trimmedNote.isNotEmpty) ? trimmedNote : null;

    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final updated = existing.copyWith(
        surahName: surahName.isNotEmpty ? surahName : existing.surahName,
        arabicText: arabicText ?? existing.arabicText,
        isAyahBookmark: isAyahBookmark,
        labelIds: labelIds,
        note: cleanNote,
        clearNote: cleanNote == null,
      );
      await _dataSource.saveBookmark(updated);
      state = [
        ...state.sublist(0, existingIndex),
        updated,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      final newItem = BookmarkItem(
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        totalAyahs: totalAyahs,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        arabicText: arabicText,
        isAyahBookmark: isAyahBookmark,
        labelIds: labelIds,
        note: cleanNote,
      );
      await _dataSource.saveBookmark(newItem);
      state = [newItem, ...state];
    }
  }

  /// Updates or removes personal note for a specific bookmarked Ayah.
  Future<void> updateBookmarkNote({
    required int surahId,
    required int ayahNumber,
    String? note,
  }) async {
    final index = state.indexWhere(
      (b) => b.surahId == surahId && b.ayahNumber == ayahNumber,
    );
    if (index == -1) return;

    final trimmed = note?.trim();
    final updated = state[index].copyWith(
      note: (trimmed != null && trimmed.isNotEmpty) ? trimmed : null,
      clearNote: trimmed == null || trimmed.isEmpty,
    );

    await _dataSource.saveBookmark(updated);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
  }

  /// Updates labels for a specific bookmarked Ayah.
  Future<void> updateBookmarkLabels({
    required int surahId,
    required int ayahNumber,
    required List<String> labelIds,
  }) async {
    final index = state.indexWhere(
      (b) => b.surahId == surahId && b.ayahNumber == ayahNumber,
    );
    if (index == -1) return;

    final updated = state[index].copyWith(labelIds: labelIds);
    await _dataSource.saveBookmark(updated);
    state = [
      ...state.sublist(0, index),
      updated,
      ...state.sublist(index + 1),
    ];
  }

  /// Removes a labelId reference from all active bookmarks (e.g. when a label is deleted).
  Future<void> removeLabelFromAllBookmarks(String labelId) async {
    final updatedList = <BookmarkItem>[];
    bool hasChanged = false;

    for (final item in state) {
      if (item.labelIds.contains(labelId)) {
        final newLabels = item.labelIds.where((id) => id != labelId).toList();
        final updated = item.copyWith(labelIds: newLabels);
        await _dataSource.saveBookmark(updated);
        updatedList.add(updated);
        hasChanged = true;
      } else {
        updatedList.add(item);
      }
    }

    if (hasChanged) {
      state = updatedList;
    }
  }

  /// Gets a bookmark by surah ID and ayah number, or null if not found.
  BookmarkItem? getBookmark(int surahId, int ayahNumber) {
    return state.where(
      (b) => b.surahId == surahId && b.ayahNumber == ayahNumber,
    ).firstOrNull;
  }

  /// Removes a single bookmark by surah ID and ayah number.
  Future<void> removeBookmark(int surahId, int ayahNumber) async {
    await _dataSource.removeBookmark(surahId, ayahNumber);
    state = state
        .where((b) => !(b.surahId == surahId && b.ayahNumber == ayahNumber))
        .toList();
  }

  /// Clears all bookmarks from Hive and memory.
  Future<void> clearAll() async {
    await _dataSource.clearAllBookmarks();
    state = const [];
  }

  /// Checks if a specific Ayah is currently bookmarked.
  bool isAyahBookmarked(int surahId, int ayahNumber) {
    return state.any((b) => b.surahId == surahId && b.ayahNumber == ayahNumber);
  }
}
