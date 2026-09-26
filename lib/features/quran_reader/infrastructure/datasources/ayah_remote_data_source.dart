import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/constants/app_constants.dart';
import '../../../../core/data/remote/network_service.dart';
import '../../domain/entities/ayah_entity.dart';

final ayahRemoteDataSourceProvider = Provider<IAyahRemoteDataSource>((ref) {
  final dio = ref.watch(networkServiceProvider);
  return AyahRemoteDataSource(dio);
});

abstract class IAyahRemoteDataSource {
  Future<List<AyahEntity>> getAyahsBySurah(int surahId, {String? translationId});
}

class AyahRemoteDataSource implements IAyahRemoteDataSource {
  final Dio _dio;
  final Map<String, List<AyahEntity>> _cache = {};

  AyahRemoteDataSource(this._dio);

  @override
  Future<List<AyahEntity>> getAyahsBySurah(int surahId, {String? translationId}) async {
    final edition = (translationId != null && translationId.trim().isNotEmpty)
        ? translationId.trim()
        : 'fa.makarem';
    final cacheKey = '$surahId-$edition';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final url = '${AppConstants.alQuranCloudBaseUrl}/surah/$surahId/editions/quran-uthmani,$edition';
      debugPrint('🌐 [AyahRemoteDataSource] Fetching ayahs for surah $surahId ($edition) from $url ...');
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List<dynamic>;
        if (data.isNotEmpty) {
          final uthmaniEdition = data[0];
          final uthmaniAyahs = (uthmaniEdition['ayahs'] as List<dynamic>);

          final Map<int, String> translationsMap = {};
          if (data.length > 1) {
            final transEdition = data[1];
            final transAyahs = (transEdition['ayahs'] as List<dynamic>);
            for (final t in transAyahs) {
              final numInSurah = t['numberInSurah'] as int? ?? 0;
              final text = t['text'] as String? ?? '';
              translationsMap[numInSurah] = text;
            }
          }

          final List<AyahEntity> ayahs = [];
          for (final a in uthmaniAyahs) {
            final numInSurah = a['numberInSurah'] as int? ?? 1;
            final globalId = a['number'] as int? ?? numInSurah;
            final textUthmani = a['text'] as String? ?? '';
            final translation = translationsMap[numInSurah];
            final page = a['page'] as int?;
            final juz = a['juz'] as int?;
            final hizbQuarter = a['hizbQuarter'] as int?;

            ayahs.add(AyahEntity(
              id: globalId,
              surahId: surahId,
              ayahNumber: numInSurah,
              arabicText: textUthmani,
              translationText: translation,
              page: page,
              juz: juz,
              hizbQuarter: hizbQuarter,
            ));
          }

          _cache[cacheKey] = ayahs;
          debugPrint('✅ [AyahRemoteDataSource] Loaded ${ayahs.length} ayahs for surah $surahId ($edition).');
          return ayahs;
        }
      }
      throw Exception('API returned status ${response.statusCode}');
    } catch (e, st) {
      debugPrint('🛑 [AyahRemoteDataSource Error] $e\n$st');
      rethrow;
    }
  }
}
