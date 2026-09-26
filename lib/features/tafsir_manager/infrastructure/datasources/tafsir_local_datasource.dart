import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/data/local/preferences/i_preferences_service.dart';
import '../../../../core/data/local/preferences/preferences_service_provider.dart';
import 'tafsir_catalog.dart';

abstract class ITafsirLocalDataSource {
  Future<void> markTafsirDownloaded(String tafsirId);
  Future<void> saveTafsir(String tafsirId, Map<String, String> ayahs);
  Future<void> deleteTafsir(String tafsirId);
  Future<String?> getAyahTafsir(String tafsirId, int surahNumber, int ayahNumber);
  Future<Map<int, String>> getSurahTafsirMap(String tafsirId, int surahNumber);
  List<String> getDownloadedTafsirIds();

  Future<void> setActiveTafsir(String tafsirId);
  String? getActiveTafsir();
}

class TafsirLocalDataSource implements ITafsirLocalDataSource {
  static const String boxName = 'tafsirsBox';
  static const String activeTafsirKey = 'active_tafsir_id';

  final IPreferencesService _prefs;
  Box? _box;

  TafsirLocalDataSource(this._prefs, [this._box]);

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
      return _box!;
    }
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  Box? get _openBox {
    if (_box != null && _box!.isOpen) return _box!;
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
      return _box!;
    }
    return null;
  }

  static String _cleanTafsirText(String raw) {
    var text = raw.trim();
    if (text.contains('<') && text.contains('>')) {
      text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
      text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
      text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    }
    return text.trim();
  }

  Future<String> _getDbPathForTafsir(String tafsirId) async {
    final databasesDir = await getDatabasesPath();
    final cleanId = tafsirId.replaceAll('.', '_');
    return join(databasesDir, 'tafsir_$cleanId.db');
  }

  @override
  Future<void> markTafsirDownloaded(String tafsirId) async {
    final box = await _getBox();
    await box.put('db_$tafsirId', {
      'id': tafsirId,
      'downloadedAt': DateTime.now().toIso8601String(),
    });
    await _prefs.setString(
      'tafsir_downloaded_at_$tafsirId',
      DateTime.now().toIso8601String(),
    );
    debugPrint('💾 [Tafsir] Registered $tafsirId in Hive as downloaded.');
  }

  @override
  Future<void> saveTafsir(String tafsirId, Map<String, String> ayahs) async {
    await markTafsirDownloaded(tafsirId);
  }

  @override
  Future<void> deleteTafsir(String tafsirId) async {
    final box = await _getBox();
    await box.delete('db_$tafsirId');
    await box.delete('meta_$tafsirId');
    await box.delete(tafsirId);
    for (int s = 1; s <= 114; s++) {
      await box.delete('${tafsirId}_$s');
    }
    await _prefs.remove('tafsir_downloaded_at_$tafsirId');

    try {
      final dbPath = await _getDbPathForTafsir(tafsirId);
      final file = File(dbPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      final walFile = File('$dbPath-wal');
      if (walFile.existsSync()) walFile.deleteSync();
      final shmFile = File('$dbPath-shm');
      if (shmFile.existsSync()) shmFile.deleteSync();
    } catch (_) {}

    debugPrint('🗑️ [Tafsir] Deleted tafsir $tafsirId from device storage.');
  }

  @override
  Future<String?> getAyahTafsir(String tafsirId, int surahNumber, int ayahNumber) async {
    final surahMap = await getSurahTafsirMap(tafsirId, surahNumber);
    return surahMap[ayahNumber];
  }

  @override
  Future<Map<int, String>> getSurahTafsirMap(String tafsirId, int surahNumber) async {
    // 1. High-Performance SQLite on-demand Surah query (zero memory footprint)
    try {
      final dbPath = await _getDbPathForTafsir(tafsirId);
      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        final db = await openDatabase(dbPath, readOnly: true);
        try {
          final tables = (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'"))
              .map((r) => r['name'] as String)
              .toSet();

          final result = <int, String>{};

          if (tables.contains('ayah_mapping')) {
            final tableInfo = await db.rawQuery("PRAGMA table_info('content')");
            final colNames = tableInfo.map((c) => c['name'] as String).toSet();
            final contentCol = colNames.contains('content_fa') ? 'content_fa' : 'content';

            final rows = await db.rawQuery('''
              SELECT m.ayah_number, c.$contentCol AS tafsir
              FROM ayah_mapping m
              JOIN content c ON m.content_id = c.content_id
              WHERE m.surah_number = ?
              ORDER BY m.ayah_number ASC
            ''', [surahNumber]);

            for (final row in rows) {
              final a = row['ayah_number'];
              final t = row['tafsir'] as String?;
              if (a is int && t != null && t.trim().isNotEmpty) {
                result[a] = _cleanTafsirText(t);
              }
            }
            return result;
          } else if (tables.contains('tafsir')) {
            final rows = await db.rawQuery(
              "SELECT ayah_key, text FROM tafsir WHERE ayah_key LIKE ?",
              ['$surahNumber:%'],
            );

            for (final row in rows) {
              final key = row['ayah_key'] as String?;
              final text = row['text'] as String?;
              if (key != null && text != null && text.trim().isNotEmpty) {
                final parts = key.split(':');
                if (parts.length == 2 && parts[0] == surahNumber.toString()) {
                  final ayahNum = int.tryParse(parts[1]);
                  if (ayahNum != null) {
                    result[ayahNum] = _cleanTafsirText(text);
                  }
                }
              }
            }
            return result;
          }
        } finally {
          await db.close();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Tafsir] Error reading SQLite db for $tafsirId: $e');
    }

    // 2. Fallback to Hive storage for previously cached items
    final box = _openBox;
    if (box != null) {
      final surahData = box.get('${tafsirId}_$surahNumber');
      if (surahData != null) {
        final rawMap = Map<dynamic, dynamic>.from(surahData as Map);
        final result = <int, String>{};
        for (final entry in rawMap.entries) {
          final ayahNum = int.tryParse(entry.key.toString());
          if (ayahNum != null) {
            result[ayahNum] = entry.value.toString();
          }
        }
        return result;
      }

      final tafsirMap = box.get(tafsirId);
      if (tafsirMap != null) {
        final map = Map<String, dynamic>.from(tafsirMap as Map);
        final prefix = '${surahNumber}_';
        final result = <int, String>{};
        for (final entry in map.entries) {
          if (entry.key.startsWith(prefix)) {
            final ayahStr = entry.key.substring(prefix.length);
            final ayahNum = int.tryParse(ayahStr);
            if (ayahNum != null) {
              result[ayahNum] = entry.value.toString();
            }
          }
        }
        return result;
      }
    }

    return {};
  }

  @override
  List<String> getDownloadedTafsirIds() {
    final ids = <String>{};
    final box = _openBox;

    if (box != null) {
      for (final tafsir in TafsirCatalog.allTafsirs) {
        if (box.containsKey('db_${tafsir.id}') ||
            box.containsKey('meta_${tafsir.id}') ||
            box.containsKey(tafsir.id)) {
          ids.add(tafsir.id);
        }
      }
    }

    return ids.toList();
  }

  @override
  Future<void> setActiveTafsir(String tafsirId) async {
    await _prefs.setString(activeTafsirKey, tafsirId);
  }

  @override
  String? getActiveTafsir() {
    return _prefs.getString(activeTafsirKey);
  }
}

final tafsirLocalDataSourceProvider = Provider<ITafsirLocalDataSource>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return TafsirLocalDataSource(prefs);
});
