import 'package:flutter/widgets.dart';

/// Identifier for all available tools in the quick access ecosystem
enum QuickAccessToolType {
  downloads('downloads', 'دانلودها'),
  lastRead('last_read', 'ادامه قرائت'),
  bookmarks('bookmarks', 'نشانه‌ها'),
  dictionary('dictionary', 'لغت‌نامه'),
  pinnedSurah('pinned_surah', 'سوره منتخب'),
  personalList('personal_list', 'فهرست من'),
  topicStudio('topic_studio', 'دفتر تفکر');

  final String id;
  final String title;

  const QuickAccessToolType(this.id, this.title);

  static QuickAccessToolType? fromId(String? id) {
    if (id == null) return null;
    if (id.startsWith('pinned_surah:') || id.startsWith('surah_')) {
      return QuickAccessToolType.pinnedSurah;
    }
    return QuickAccessToolType.values.where((t) => t.id == id).firstOrNull;
  }
}

/// Domain entity representing an individual tool selectable for quick access
class QuickAccessToolEntity {
  final QuickAccessToolType type;
  final String title;
  final String description;
  final IconData? iconData;
  final String? routeName;
  final bool isReady;
  final int? surahId;
  final String? surahName;
  final int? ayahCount;

  const QuickAccessToolEntity({
    required this.type,
    required this.title,
    required this.description,
    this.iconData,
    this.routeName,
    this.isReady = true,
    this.surahId,
    this.surahName,
    this.ayahCount,
  });

  bool get isSurah => type == QuickAccessToolType.pinnedSurah && surahId != null;
}
