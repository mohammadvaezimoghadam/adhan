import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/local/sqflite/i_sqflite_service.dart';
import '../../../../core/data/local/sqflite/sqflite_service_provider.dart';
import '../dtos/page_navigation_dto.dart';

import 'package:dio/dio.dart';
import '../../../../common/constants/app_constants.dart';
import '../../../../core/data/remote/network_service.dart';

final pageNavigationLocalDataSourceProvider = Provider<IPageNavigationLocalDataSource>((ref) {
  if (kIsWeb) {
    final dio = ref.watch(networkServiceProvider);
    return PageNavigationWebDataSource(dio);
  }
  final sqfliteService = ref.watch(sqfliteServiceProvider);
  return PageNavigationLocalDataSourceImpl(sqfliteService);
});

/// Interface for local data source
abstract class IPageNavigationLocalDataSource {
  /// Queries the local database to find Surah and Ayah details for a given page
  Future<PageNavigationDto?> getSurahInfoByPage(int pageNumber);
}

/// Implementation of the local data source
class PageNavigationLocalDataSourceImpl implements IPageNavigationLocalDataSource {
  final ISqfliteService _sqfliteService;

  PageNavigationLocalDataSourceImpl(this._sqfliteService);

  @override
  Future<PageNavigationDto?> getSurahInfoByPage(int pageNumber) async {
    const sql = '''
      SELECT 
        a.surah_number as surah_id,
        a.number_in_surah as ayah_number,
        s.name as surah_name
      FROM ayahs a
      JOIN surahs s ON a.surah_number = s.id
      WHERE a.page = ?
      ORDER BY a.surah_number ASC, a.number_in_surah ASC
      LIMIT 1
    ''';

    final List<Map<String, dynamic>> maps = await _sqfliteService.rawQuery(
      sql,
      [pageNumber],
    );

    if (maps.isNotEmpty) {
      return PageNavigationDto.fromSqlite(maps.first);
    }
    return null;
  }
}

class PageNavigationWebDataSource implements IPageNavigationLocalDataSource {
  final Dio _dio;
  final Map<int, PageNavigationDto> _cache = {};

  PageNavigationWebDataSource(this._dio);

  @override
  Future<PageNavigationDto?> getSurahInfoByPage(int pageNumber) async {
    if (_cache.containsKey(pageNumber)) {
      return _cache[pageNumber];
    }

    try {
      final url = '${AppConstants.alQuranCloudBaseUrl}/page/$pageNumber/quran-uthmani';
      debugPrint('🌐 [PageNavigationWebDataSource] Fetching page $pageNumber from $url ...');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final ayahs = (data?['ayahs'] as List<dynamic>?) ?? [];
        if (ayahs.isNotEmpty) {
          final firstAyah = ayahs.first;
          final surahObj = firstAyah['surah'] as Map<String, dynamic>? ?? {};
          final dto = PageNavigationDto(
            surahId: surahObj['number'] as int? ?? 1,
            ayahNumber: firstAyah['numberInSurah'] as int? ?? 1,
            surahName: surahObj['name'] as String? ?? 'الفاتحة',
          );
          _cache[pageNumber] = dto;
          return dto;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PageNavigationWebDataSource] Error loading page $pageNumber: $e');
    }

    return PageNavigationDto(
      surahId: 1,
      ayahNumber: 1,
      surahName: 'الفاتحة',
    );
  }
}

