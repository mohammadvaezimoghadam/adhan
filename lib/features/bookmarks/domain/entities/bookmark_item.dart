import 'package:flutter/foundation.dart';

import '../../../quran_home/application/states/continue_reading_state.dart';

/// Clean model representing a saved bookmark (نشانک قرآنی) in Hive.
class BookmarkItem {
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final int totalAyahs;
  final int createdAt; // Milliseconds since epoch for precise chronological sorting
  final String? arabicText; // Optional snippet of ayah text for Ayah Tab preview
  final bool isAyahBookmark; // True if bookmarked specifically as an Ayah
  final List<String> labelIds; // List of label IDs associated with this bookmark
  final String? note; // Optional personal note/reflection written by the user for this ayah

  const BookmarkItem({
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.totalAyahs,
    required this.createdAt,
    this.arabicText,
    this.isAyahBookmark = false,
    this.labelIds = const [],
    this.note,
  });

  /// Unique key for direct O(1) Hive lookups
  String get key => '${surahId}_$ayahNumber';

  /// Converts this bookmark into [ContinueReadingState] for compatibility
  /// with the home screen reading cards and navigation.
  ContinueReadingState toContinueReadingState() {
    return ContinueReadingState(
      surahId: surahId,
      surahName: surahName,
      ayahNumber: ayahNumber,
      totalAyahs: totalAyahs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surahId': surahId,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'totalAyahs': totalAyahs,
      'createdAt': createdAt,
      'arabicText': arabicText,
      'isAyahBookmark': isAyahBookmark,
      'labelIds': labelIds,
      'note': note,
    };
  }

  factory BookmarkItem.fromMap(Map<dynamic, dynamic> map) {
    return BookmarkItem(
      surahId: map['surahId'] as int? ?? 1,
      surahName: map['surahName'] as String? ?? '',
      ayahNumber: map['ayahNumber'] as int? ?? 1,
      totalAyahs: map['totalAyahs'] as int? ?? 0,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      arabicText: map['arabicText'] as String?,
      isAyahBookmark: map['isAyahBookmark'] as bool? ?? false,
      labelIds: (map['labelIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      note: (map['note'] != null && map['note'].toString().trim().isNotEmpty)
          ? map['note'].toString().trim()
          : null,
    );
  }

  BookmarkItem copyWith({
    int? surahId,
    String? surahName,
    int? ayahNumber,
    int? totalAyahs,
    int? createdAt,
    String? arabicText,
    bool? isAyahBookmark,
    List<String>? labelIds,
    String? note,
    bool clearNote = false,
  }) {
    return BookmarkItem(
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      createdAt: createdAt ?? this.createdAt,
      arabicText: arabicText ?? this.arabicText,
      isAyahBookmark: isAyahBookmark ?? this.isAyahBookmark,
      labelIds: labelIds ?? this.labelIds,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkItem &&
          runtimeType == other.runtimeType &&
          surahId == other.surahId &&
          ayahNumber == other.ayahNumber &&
          totalAyahs == other.totalAyahs &&
          createdAt == other.createdAt &&
          arabicText == other.arabicText &&
          isAyahBookmark == other.isAyahBookmark &&
          note == other.note &&
          listEquals(labelIds, other.labelIds);

  @override
  int get hashCode => Object.hash(
        surahId,
        ayahNumber,
        totalAyahs,
        createdAt,
        arabicText,
        isAyahBookmark,
        note,
        Object.hashAll(labelIds),
      );
}
