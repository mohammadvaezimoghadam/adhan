import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dtos/surah_dto.dart';
import 'static_surahs_data.dart';

final surahRemoteDataSourceProvider = Provider<ISurahRemoteDataSource>((ref) {
  return const SurahRemoteDataSource();
});

abstract class ISurahRemoteDataSource {
  Future<List<SurahDto>> getSurahs();
}

class SurahRemoteDataSource implements ISurahRemoteDataSource {
  const SurahRemoteDataSource();

  @override
  Future<List<SurahDto>> getSurahs() async {
    // 0ms instant load: All 114 Surahs are bundled as static compile-time constants.
    // Zero network requests, zero startup delay.
    return kStaticQuranSurahs;
  }
}

