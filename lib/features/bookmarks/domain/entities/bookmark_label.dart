import 'package:flutter/material.dart';

/// Represents a classification tag/label for Quranic bookmarks.
class BookmarkLabel {
  final String id;
  final String title;
  final int colorValue;
  final int createdAt;
  final bool isDefault;

  const BookmarkLabel({
    required this.id,
    required this.title,
    required this.colorValue,
    required this.createdAt,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'colorValue': colorValue,
      'createdAt': createdAt,
      'isDefault': isDefault,
    };
  }

  factory BookmarkLabel.fromMap(Map<dynamic, dynamic> map) {
    return BookmarkLabel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      colorValue: map['colorValue'] as int? ?? 0xFF005C55,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  BookmarkLabel copyWith({
    String? id,
    String? title,
    int? colorValue,
    int? createdAt,
    bool? isDefault,
  }) {
    return BookmarkLabel(
      id: id ?? this.id,
      title: title ?? this.title,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Default starter labels with curated Islamic/Quranic palette colors
  static List<BookmarkLabel> get defaultLabels => const [
        BookmarkLabel(
          id: 'label_dua',
          title: 'دعا و مناجات',
          colorValue: 0xFF005C55, // Primary Emerald Green
          createdAt: 1,
          isDefault: true,
        ),
        BookmarkLabel(
          id: 'label_tadabor',
          title: 'تدبر و اندیشه',
          colorValue: 0xFFC5A059, // Radiant Gold
          createdAt: 2,
          isDefault: true,
        ),
        BookmarkLabel(
          id: 'label_hefz',
          title: 'حفظ و مرور',
          colorValue: 0xFF0284C7, // Sky Blue
          createdAt: 3,
          isDefault: true,
        ),
        BookmarkLabel(
          id: 'label_aramesh',
          title: 'آرامش و تسکین',
          colorValue: 0xFF7C3AED, // Soft Violet / Indigo
          createdAt: 4,
          isDefault: true,
        ),
        BookmarkLabel(
          id: 'label_daily',
          title: 'تلاوت روزانه',
          colorValue: 0xFFE11D48, // Coral Rose
          createdAt: 5,
          isDefault: true,
        ),
      ];

  /// Curated color choices for user-created custom labels
  static const List<int> presetColors = [
    0xFF005C55, // Emerald
    0xFFC5A059, // Gold
    0xFF0284C7, // Ocean Blue
    0xFF7C3AED, // Violet
    0xFFE11D48, // Rose
    0xFFD97706, // Amber
    0xFF0D9488, // Teal
    0xFF4B5563, // Slate Gray
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkLabel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          colorValue == other.colorValue &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(id, title, colorValue, isDefault);
}
