import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/features/tafsir_manager/domain/repositories/tafsir_repository.dart';
import 'package:quran/features/tafsir_manager/infrastructure/datasources/tafsir_catalog.dart';
import 'package:quran/features/tafsir_manager/infrastructure/datasources/tafsir_local_datasource.dart';
import 'package:quran/features/tafsir_manager/infrastructure/datasources/tafsir_remote_datasource.dart';
import 'package:quran/features/tafsir_manager/infrastructure/repositories/tafsir_repository_impl.dart';

class FakeTafsirLocalDataSource implements ITafsirLocalDataSource {
  final Map<String, Map<String, String>> _storage = {};
  String? _activeTafsirId;

  @override
  Future<void> markTafsirDownloaded(String tafsirId) async {
    _storage[tafsirId] = {
      '1_1': 'به نام خداوند بخشنده مهربان',
      '1_2': 'ستایش مخصوص پروردگار جهانیان است',
    };
  }

  @override
  Future<void> saveTafsir(String tafsirId, Map<String, String> ayahs) async {
    _storage[tafsirId] = ayahs;
  }

  @override
  Future<void> deleteTafsir(String tafsirId) async {
    _storage.remove(tafsirId);
  }

  @override
  Future<String?> getAyahTafsir(String tafsirId, int surahNumber, int ayahNumber) async {
    return _storage[tafsirId]?['${surahNumber}_$ayahNumber'];
  }

  @override
  Future<Map<int, String>> getSurahTafsirMap(String tafsirId, int surahNumber) async {
    final map = _storage[tafsirId] ?? {};
    final prefix = '${surahNumber}_';
    final result = <int, String>{};
    for (final entry in map.entries) {
      if (entry.key.startsWith(prefix)) {
        final ayah = int.tryParse(entry.key.substring(prefix.length));
        if (ayah != null) {
          result[ayah] = entry.value;
        }
      }
    }
    return result;
  }

  @override
  List<String> getDownloadedTafsirIds() {
    return _storage.keys.toList();
  }

  @override
  Future<void> setActiveTafsir(String tafsirId) async {
    _activeTafsirId = tafsirId;
  }

  @override
  String? getActiveTafsir() {
    return _activeTafsirId;
  }
}

class FakeTafsirRemoteDataSource implements ITafsirRemoteDataSource {
  @override
  Future<String> downloadAndSaveTafsir(
    String tafsirId,
    String sourceUrl, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    onReceiveProgress?.call(100, 100);
    return 'fake_path.db';
  }
}

void main() {
  group('TafsirCatalog Tests', () {
    test('Contains authentic Quran Exegeses (Tafsirs)', () {
      expect(TafsirCatalog.allTafsirs.length, equals(3));
      expect(TafsirCatalog.allTafsirs.any((t) => t.id == 'tafsir.nemouneh'), isTrue);
      expect(TafsirCatalog.allTafsirs.any((t) => t.id == 'tafsir.noor'), isTrue);
      expect(TafsirCatalog.allTafsirs.any((t) => t.id == 'tafsir.almizan'), isTrue);
    });

    test('All Tafsirs have valid URLs and non-empty metadata', () {
      for (final tafsir in TafsirCatalog.allTafsirs) {
        expect(tafsir.id.isNotEmpty, isTrue);
        expect(tafsir.name.isNotEmpty, isTrue);
        expect(tafsir.authorName.isNotEmpty, isTrue);
        expect(tafsir.sourceUrl.startsWith('https://'), isTrue);
        expect(tafsir.isDownloaded, isFalse); // All must be downloadable on start
      }
    });
  });

  group('TafsirRepositoryImpl Tests', () {
    late ITafsirRepository repository;
    late FakeTafsirLocalDataSource localDataSource;
    late FakeTafsirRemoteDataSource remoteDataSource;

    setUp(() {
      localDataSource = FakeTafsirLocalDataSource();
      remoteDataSource = FakeTafsirRemoteDataSource();
      repository = TafsirRepositoryImpl(localDataSource, remoteDataSource);
    });

    test('getAllTafsirs marks downloaded items accurately', () async {
      final initialResult = await repository.getAllTafsirs();
      final initialList = initialResult.tryGetSuccess()!;
      expect(initialList.every((t) => !t.isDownloaded), isTrue);

      // Download one tafsir
      await repository.downloadTafsir(initialList.first);

      final updatedResult = await repository.getAllTafsirs();
      final updatedList = updatedResult.tryGetSuccess()!;
      expect(updatedList.first.isDownloaded, isTrue);
      expect(updatedList.skip(1).every((t) => !t.isDownloaded), isTrue);
    });

    test('getSurahTafsirMap retrieves all ayahs for a given surah', () async {
      final tafsir = TafsirCatalog.allTafsirs.first;
      await repository.downloadTafsir(tafsir);

      final surahMapResult = await repository.getSurahTafsirMap(
        tafsirId: tafsir.id,
        surahNumber: 1,
      );

      final map = surahMapResult.tryGetSuccess()!;
      expect(map[1], equals('به نام خداوند بخشنده مهربان'));
      expect(map[2], equals('ستایش مخصوص پروردگار جهانیان است'));
      expect(map.containsKey(3), isFalse);
    });

    test('deleteTafsir removes tafsir from local storage', () async {
      final tafsir = TafsirCatalog.allTafsirs.first;
      await repository.downloadTafsir(tafsir);

      await repository.deleteTafsir(tafsir.id);
      final listResult = await repository.getAllTafsirs();
      final list = listResult.tryGetSuccess()!;
      expect(list.first.isDownloaded, isFalse);
    });
  });
}
