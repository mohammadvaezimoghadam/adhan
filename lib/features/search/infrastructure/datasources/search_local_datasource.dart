import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../core/data/local/sqflite/i_sqflite_service.dart';
import '../../../../core/data/local/sqflite/sqflite_service_provider.dart';
import '../../domain/entities/search_filter_type.dart';
import '../../domain/entities/search_result_item.dart';

import 'package:dio/dio.dart';
import '../../../../common/constants/app_constants.dart';
import '../../../../core/data/remote/network_service.dart';
import '../../../surah_list/domain/repositories/i_surah_repository.dart';
import '../../../surah_list/infrastructure/repositories/surah_repository.dart';

final searchLocalDataSourceProvider = Provider<ISearchLocalDataSource>((ref) {
  if (kIsWeb) {
    final dio = ref.watch(networkServiceProvider);
    final surahRepo = ref.watch(surahRepositoryProvider);
    return SearchWebDataSource(dio, surahRepo);
  }
  final sqfliteService = ref.watch(sqfliteServiceProvider);
  return SearchLocalDataSource(sqfliteService);
});

class SearchWebDataSource implements ISearchLocalDataSource {
  final Dio _dio;
  final ISurahRepository _surahRepository;

  SearchWebDataSource(this._dio, this._surahRepository);

  @override
  Future<List<SearchResultItem>> search({
    required String query,
    SearchFilterType filter = SearchFilterType.all,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final normalizedQuery = cleanQuery.normalizeForSearch();
    final queryLower = cleanQuery.toLowerCase();
    final queryNumber = int.tryParse(cleanQuery);
    final results = <SearchResultItem>[];

    // 1. Search Surahs (instant via Surah Repository)
    if (filter == SearchFilterType.all || filter == SearchFilterType.surahs) {
      try {
        final surahsResult = await _surahRepository.getSurahs();
        final surahs = surahsResult.tryGetSuccess() ?? [];
        for (final surah in surahs) {
          final matchesName = surah.name.normalizeForSearch().contains(normalizedQuery);
          final matchesPersian = surah.number.surahNameFa.normalizeForSearch().contains(normalizedQuery);
          final matchesEnglish = surah.englishName.toLowerCase().contains(queryLower);
          final matchesNumber = queryNumber != null && surah.number == queryNumber;

          if (matchesName || matchesPersian || matchesEnglish || matchesNumber) {
            results.add(SearchResultItem(
              kind: SearchResultKind.surah,
              surahNumber: surah.number,
              surahName: surah.name,
              englishName: surah.englishName,
              numberOfAyahs: surah.numberOfAyahs,
              revelationType: surah.revelationType,
            ));
          }
        }
      } catch (e) {
        debugPrint('⚠️ [SearchWebDataSource] Surah search error: $e');
      }
    }

    if (filter == SearchFilterType.surahs) {
      return results;
    }

    // 2. Search Ayahs via AlQuran Cloud API
    try {
      final encoded = Uri.encodeComponent(cleanQuery);
      final futures = <Future<Response>>[];
      final searchArabic = filter == SearchFilterType.all || filter == SearchFilterType.ayahs;
      final searchPersian = filter == SearchFilterType.all || filter == SearchFilterType.translations;

      if (searchArabic) {
        futures.add(_dio.get(
          '${AppConstants.alQuranCloudBaseUrl}/search/$encoded/all/quran-uthmani',
          options: Options(validateStatus: (s) => s == 200 || s == 404),
        ));
      }
      if (searchPersian) {
        futures.add(_dio.get(
          '${AppConstants.alQuranCloudBaseUrl}/search/$encoded/all/fa.makarem',
          options: Options(validateStatus: (s) => s == 200 || s == 404),
        ));
      }

      final responses = await Future.wait(futures);
      final arabicResp = searchArabic && responses.isNotEmpty ? responses[0] : null;
      final persianResp = searchPersian ? (searchArabic ? (responses.length > 1 ? responses[1] : null) : responses[0]) : null;
      final Set<int> seenGlobalAyahIds = {};

      if (arabicResp != null && arabicResp.statusCode == 200 && arabicResp.data != null) {
        final matches = (arabicResp.data['data']?['matches'] as List<dynamic>?) ?? [];
        for (final m in matches) {
          final globalNum = m['number'] as int? ?? 0;
          final numInSurah = m['numberInSurah'] as int? ?? 1;
          final surahObj = m['surah'] as Map<String, dynamic>? ?? {};
          final surahNum = surahObj['number'] as int? ?? 1;
          final surahName = surahObj['name'] as String? ?? 'سوره $surahNum';
          final englishName = surahObj['englishName'] as String? ?? '';
          final text = m['text'] as String? ?? '';
          final page = m['page'] as int?;
          final juz = m['juz'] as int?;

          seenGlobalAyahIds.add(globalNum);
          results.add(SearchResultItem(
            kind: SearchResultKind.ayah,
            surahNumber: surahNum,
            surahName: surahName,
            englishName: englishName,
            numberOfAyahs: surahObj['numberOfAyahs'] as int?,
            revelationType: surahObj['revelationType'] as String?,
            ayahNumber: numInSurah,
            arabicText: text,
            translationText: '',
            pageNumber: page,
            juzNumber: juz,
            matchedInArabic: true,
            matchedInTranslation: false,
          ));
        }
      }

      if (persianResp != null && persianResp.statusCode == 200 && persianResp.data != null) {
        final matches = (persianResp.data['data']?['matches'] as List<dynamic>?) ?? [];
        for (final m in matches) {
          final globalNum = m['number'] as int? ?? 0;
          final numInSurah = m['numberInSurah'] as int? ?? 1;
          final surahObj = m['surah'] as Map<String, dynamic>? ?? {};
          final surahNum = surahObj['number'] as int? ?? 1;
          final surahName = surahObj['name'] as String? ?? 'سوره $surahNum';
          final englishName = surahObj['englishName'] as String? ?? '';
          final transText = m['text'] as String? ?? '';
          final page = m['page'] as int?;
          final juz = m['juz'] as int?;

          if (seenGlobalAyahIds.contains(globalNum)) {
            final idx = results.indexWhere(
              (r) => r.isAyah && r.surahNumber == surahNum && r.ayahNumber == numInSurah,
            );
            if (idx != -1) {
              final old = results[idx];
              results[idx] = SearchResultItem(
                kind: SearchResultKind.ayah,
                surahNumber: old.surahNumber,
                surahName: old.surahName,
                englishName: old.englishName,
                numberOfAyahs: old.numberOfAyahs,
                revelationType: old.revelationType,
                ayahNumber: old.ayahNumber,
                arabicText: old.arabicText,
                translationText: transText,
                pageNumber: old.pageNumber,
                juzNumber: old.juzNumber,
                matchedInArabic: old.matchedInArabic,
                matchedInTranslation: true,
              );
            }
          } else {
            results.add(SearchResultItem(
              kind: SearchResultKind.ayah,
              surahNumber: surahNum,
              surahName: surahName,
              englishName: englishName,
              numberOfAyahs: surahObj['numberOfAyahs'] as int?,
              revelationType: surahObj['revelationType'] as String?,
              ayahNumber: numInSurah,
              arabicText: '',
              translationText: transText,
              pageNumber: page,
              juzNumber: juz,
              matchedInArabic: false,
              matchedInTranslation: true,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SearchWebDataSource] Remote search error: $e');
    }

    return results;
  }
}

abstract class ISearchLocalDataSource {
  Future<List<SearchResultItem>> search({
    required String query,
    SearchFilterType filter = SearchFilterType.all,
  });
}

class _IndexedSurah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final String revelationType;
  final String normalizedName;
  final String normalizedPersianName;
  final String normalizedEnglishName;

  _IndexedSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.revelationType,
    required this.normalizedName,
    required this.normalizedPersianName,
    required this.normalizedEnglishName,
  });
}

class _IndexedAyah {
  final int surahNumber;
  final int ayahNumber;
  final String arabicText;
  final String translationText;
  final int page;
  final int juz;
  final String normalizedArabic;
  final String normalizedTranslation;

  _IndexedAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabicText,
    required this.translationText,
    required this.page,
    required this.juz,
    required this.normalizedArabic,
    required this.normalizedTranslation,
  });
}

class SearchLocalDataSource implements ISearchLocalDataSource {
  final ISqfliteService _sqfliteService;

  List<_IndexedSurah>? _cachedSurahs;
  List<_IndexedAyah>? _cachedAyahs;
  Map<int, _IndexedSurah>? _surahMap;
  bool _isIndexing = false;

  SearchLocalDataSource(this._sqfliteService);

  /// Initializes in-memory normalized cache on demand for instant microsecond searching
  Future<void> _ensureIndexed() async {
    if (_cachedSurahs != null && _cachedAyahs != null) return;
    if (_isIndexing) {
      while (_isIndexing) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return;
    }

    _isIndexing = true;
    try {
      // 1. Fetch Surahs
      final surahMaps = await _sqfliteService.query('surahs', orderBy: 'id ASC');
      final surahs = <_IndexedSurah>[];
      final surahMap = <int, _IndexedSurah>{};

      for (final map in surahMaps) {
        final number = map['id'] as int;
        final name = map['name'] as String;
        final englishName = map['english_name'] as String;
        final numberOfAyahs = map['number_of_ayahs'] as int;
        final revelationType = (map['revelation_type'] as String?) ?? 'Meccan';

        final indexed = _IndexedSurah(
          number: number,
          name: name,
          englishName: englishName,
          numberOfAyahs: numberOfAyahs,
          revelationType: revelationType,
          normalizedName: name.normalizeForSearch(),
          normalizedPersianName: number.surahNameFa.normalizeForSearch(),
          normalizedEnglishName: englishName.toLowerCase(),
        );
        surahs.add(indexed);
        surahMap[number] = indexed;
      }

      // 2. Fetch Ayahs with Makarem Persian translation
      const ayahsSql = '''
        SELECT 
          a.surah_number,
          a.number_in_surah,
          a.text_uthmani,
          a.page,
          a.juz,
          COALESCE(t.text, '') AS translation
        FROM ayahs a
        LEFT JOIN translations t ON a.id = t.ayah_id AND t.translation_id = 'fa.makarem'
        ORDER BY a.surah_number ASC, a.number_in_surah ASC
      ''';

      final ayahMaps = await _sqfliteService.rawQuery(ayahsSql);
      final ayahs = <_IndexedAyah>[];

      for (final map in ayahMaps) {
        final arabic = (map['text_uthmani'] as String?) ?? '';
        final translation = (map['translation'] as String?) ?? '';

        ayahs.add(_IndexedAyah(
          surahNumber: map['surah_number'] as int,
          ayahNumber: map['number_in_surah'] as int,
          arabicText: arabic,
          translationText: translation,
          page: (map['page'] as int?) ?? 1,
          juz: (map['juz'] as int?) ?? 1,
          normalizedArabic: arabic.normalizeForSearch(),
          normalizedTranslation: translation.normalizeForSearch(),
        ));
      }

      _cachedSurahs = surahs;
      _surahMap = surahMap;
      _cachedAyahs = ayahs;
    } finally {
      _isIndexing = false;
    }
  }

  @override
  Future<List<SearchResultItem>> search({
    required String query,
    SearchFilterType filter = SearchFilterType.all,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    await _ensureIndexed();

    final normalizedQuery = cleanQuery.normalizeForSearch();
    final queryLower = cleanQuery.toLowerCase();
    final results = <SearchResultItem>[];

    // Check if query is a pure number (e.g. searching surah # or ayah #)
    final queryNumber = int.tryParse(cleanQuery.normalizeForSearch());

    // 1. Search Surahs
    for (final surah in _cachedSurahs!) {
      final matchesName = surah.normalizedName.contains(normalizedQuery);
      final matchesPersian =
          surah.normalizedPersianName.contains(normalizedQuery);
      final matchesEnglish = surah.normalizedEnglishName.contains(queryLower);
      final matchesNumber = queryNumber != null && surah.number == queryNumber;

      if (matchesName || matchesPersian || matchesEnglish || matchesNumber) {
        results.add(SearchResultItem(
          kind: SearchResultKind.surah,
          surahNumber: surah.number,
          surahName: surah.name,
          englishName: surah.englishName,
          numberOfAyahs: surah.numberOfAyahs,
          revelationType: surah.revelationType,
        ));
      }
    }

    // 2. Search Ayahs (Arabic & Translation)
    for (final ayah in _cachedAyahs!) {
      final matchesArabic = ayah.normalizedArabic.contains(normalizedQuery);
      final matchesTranslation =
          ayah.normalizedTranslation.contains(normalizedQuery);

      if (matchesArabic || matchesTranslation) {
        final surah = _surahMap?[ayah.surahNumber];
        results.add(SearchResultItem(
          kind: SearchResultKind.ayah,
          surahNumber: ayah.surahNumber,
          surahName: surah?.name ?? 'سوره ${ayah.surahNumber}',
          englishName: surah?.englishName ?? '',
          numberOfAyahs: surah?.numberOfAyahs,
          revelationType: surah?.revelationType,
          ayahNumber: ayah.ayahNumber,
          arabicText: ayah.arabicText,
          translationText: ayah.translationText,
          pageNumber: ayah.page,
          juzNumber: ayah.juz,
          matchedInArabic: matchesArabic,
          matchedInTranslation: matchesTranslation,
        ));
      }
    }

    return results;
  }
}
