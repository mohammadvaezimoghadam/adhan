import 'package:dio/dio.dart';
import 'package:multiple_result/multiple_result.dart';
import '../../../../common/exceptions/failure.dart';
import '../entities/tafsir_entity.dart';

/// Abstract repository defining the contract for managing Quran Exegeses (Tafsirs).
abstract class ITafsirRepository {
  /// Returns all available Tafsirs in the catalog and their download status.
  Future<Result<List<TafsirEntity>, Failure>> getAllTafsirs();

  /// Downloads a Tafsir from remote CDN and saves it to local Hive storage.
  Future<Result<void, Failure>> downloadTafsir(
    TafsirEntity tafsir, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  });

  /// Deletes a downloaded Tafsir from local storage.
  Future<Result<void, Failure>> deleteTafsir(String tafsirId);

  /// Retrieves the Tafsir text for a specific Ayah.
  Future<Result<String?, Failure>> getAyahTafsir({
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
  });

  /// Retrieves the entire Surah's Tafsir map (key: ayahNumber, value: tafsirText)
  Future<Result<Map<int, String>, Failure>> getSurahTafsirMap({
    required String tafsirId,
    required int surahNumber,
  });

  /// Sets the currently active Tafsir identifier.
  Future<Result<void, Failure>> setActiveTafsir(String tafsirId);

  /// Gets the currently active Tafsir identifier.
  Future<Result<String?, Failure>> getActiveTafsir();
}
