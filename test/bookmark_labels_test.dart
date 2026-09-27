import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/bookmarks/domain/entities/bookmark_item.dart';
import 'package:quran/features/bookmarks/domain/entities/bookmark_label.dart';

void main() {
  group('BookmarkLabel Entity Tests', () {
    test('defaultLabels contains 5 starter labels with correct IDs', () {
      final defaults = BookmarkLabel.defaultLabels;
      expect(defaults.length, 5);
      expect(defaults.map((l) => l.id).toList(), [
        'label_dua',
        'label_tadabor',
        'label_hefz',
        'label_aramesh',
        'label_daily',
      ]);
      expect(defaults.every((l) => l.isDefault), isTrue);
    });

    test('Serialization toMap and fromMap works seamlessly', () {
      final label = BookmarkLabel(
        id: 'label_custom_1',
        title: 'آیات برگزیده',
        colorValue: 0xFF005C55,
        createdAt: 1720000000000,
        isDefault: false,
      );

      final map = label.toMap();
      final reconstructed = BookmarkLabel.fromMap(map);

      expect(reconstructed.id, 'label_custom_1');
      expect(reconstructed.title, 'آیات برگزیده');
      expect(reconstructed.colorValue, 0xFF005C55);
      expect(reconstructed.createdAt, 1720000000000);
      expect(reconstructed.isDefault, isFalse);
      expect(reconstructed, equals(label));
    });

    test('copyWith updates specified fields only', () {
      final original = BookmarkLabel(
        id: 'lbl_1',
        title: 'یادآوری',
        colorValue: 0xFFC5A059,
        createdAt: 100,
      );

      final updated = original.copyWith(title: 'یادآوری روزانه', colorValue: 0xFF0284C7);
      expect(updated.id, 'lbl_1');
      expect(updated.title, 'یادآوری روزانه');
      expect(updated.colorValue, 0xFF0284C7);
      expect(updated.createdAt, 100);
    });
  });

  group('BookmarkItem Label Integration & Backward Compatibility Tests', () {
    test('Legacy BookmarkItem without labelIds defaults gracefully to empty list', () {
      final legacyMap = {
        'surahId': 2,
        'surahName': 'البقرة',
        'ayahNumber': 255,
        'totalAyahs': 286,
        'createdAt': 1600000000000,
        'isAyahBookmark': true,
      };

      final item = BookmarkItem.fromMap(legacyMap);
      expect(item.labelIds, isEmpty);
      expect(item.surahId, 2);
      expect(item.ayahNumber, 255);
    });

    test('BookmarkItem serialization preserves labelIds', () {
      final item = BookmarkItem(
        surahId: 36,
        surahName: 'یس',
        ayahNumber: 1,
        totalAyahs: 83,
        createdAt: 1700000000000,
        labelIds: ['label_dua', 'label_tadabor'],
      );

      final map = item.toMap();
      expect(map['labelIds'], ['label_dua', 'label_tadabor']);

      final reconstructed = BookmarkItem.fromMap(map);
      expect(reconstructed.labelIds, ['label_dua', 'label_tadabor']);
      expect(reconstructed.surahId, 36);
    });

    test('copyWith can add, remove, or replace labelIds', () {
      final original = BookmarkItem(
        surahId: 1,
        surahName: 'الفاتحة',
        ayahNumber: 1,
        totalAyahs: 7,
        createdAt: 100,
        labelIds: ['label_dua'],
      );

      final updated = original.copyWith(
        labelIds: ['label_dua', 'label_hefz'],
      );

      expect(updated.labelIds, ['label_dua', 'label_hefz']);
      expect(original.labelIds, ['label_dua']); // Immutability preserved
    });

    test('Legacy BookmarkItem without note defaults to null with 100% backward compatibility', () {
      final legacyMapV1 = {
        'surahId': 2,
        'surahName': 'البقرة',
        'ayahNumber': 255,
        'totalAyahs': 286,
        'createdAt': 1600000000000,
        'isAyahBookmark': true,
        // Notice neither labelIds nor note exist here
      };

      final item = BookmarkItem.fromMap(legacyMapV1);
      expect(item.note, isNull);
      expect(item.labelIds, isEmpty);
      expect(item.surahId, 2);
    });

    test('BookmarkItem with note serializes and deserializes cleanly', () {
      final itemWithNote = BookmarkItem(
        surahId: 55,
        surahName: 'الرحمن',
        ayahNumber: 13,
        totalAyahs: 78,
        createdAt: 1700000000000,
        labelIds: ['label_tadabor'],
        note: 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ - تذکر و شکرگزاری از نعمت‌ها',
      );

      final map = itemWithNote.toMap();
      expect(map['note'], 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ - تذکر و شکرگزاری از نعمت‌ها');

      final reconstructed = BookmarkItem.fromMap(map);
      expect(reconstructed.note, 'فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ - تذکر و شکرگزاری از نعمت‌ها');
      expect(reconstructed.labelIds, ['label_tadabor']);
    });

    test('BookmarkItem with whitespace or empty note converts safely to null', () {
      final mapWithEmptyNote = {
        'surahId': 1,
        'surahName': 'الفاتحة',
        'ayahNumber': 1,
        'totalAyahs': 7,
        'createdAt': 100,
        'note': '   ',
      };

      final item = BookmarkItem.fromMap(mapWithEmptyNote);
      expect(item.note, isNull);
    });

    test('copyWith updates note or clears note with clearNote flag', () {
      final original = BookmarkItem(
        surahId: 1,
        surahName: 'الفاتحة',
        ayahNumber: 1,
        totalAyahs: 7,
        createdAt: 100,
        note: 'یادداشت اولیه',
      );

      final edited = original.copyWith(note: 'یادداشت ویرایش‌شده');
      expect(edited.note, 'یادداشت ویرایش‌شده');

      final cleared = edited.copyWith(clearNote: true);
      expect(cleared.note, isNull);
    });

    test('BookmarkItem created with note and labels has correct fields', () {
      final item = BookmarkItem(
        surahId: 18,
        surahName: 'الکهف',
        ayahNumber: 10,
        totalAyahs: 110,
        createdAt: 200,
        labelIds: ['label_dua', 'label_aramesh'],
        note: 'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً',
      );

      expect(item.surahId, 18);
      expect(item.ayahNumber, 10);
      expect(item.labelIds.length, 2);
      expect(item.note, 'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً');
    });

    test('BookmarkItem can distinguish page bookmarks from ayah bookmarks', () {
      final pageBookmark = BookmarkItem(
        surahId: 2,
        surahName: 'البقرة',
        ayahNumber: 5,
        totalAyahs: 286,
        createdAt: 100,
        isAyahBookmark: false,
      );

      final ayahBookmark = BookmarkItem(
        surahId: 2,
        surahName: 'البقرة',
        ayahNumber: 5,
        totalAyahs: 286,
        createdAt: 100,
        isAyahBookmark: true,
      );

      expect(pageBookmark.isAyahBookmark, isFalse);
      expect(ayahBookmark.isAyahBookmark, isTrue);

      final pageMap = pageBookmark.toMap();
      expect(pageMap['isAyahBookmark'], isFalse);
      expect(BookmarkItem.fromMap(pageMap).isAyahBookmark, isFalse);
    });
  });
}
