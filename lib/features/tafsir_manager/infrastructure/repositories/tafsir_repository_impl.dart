import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../common/exceptions/failure.dart';
import '../../../../common/mixins/dio_exception_mapper.dart';
import '../../domain/entities/tafsir_entity.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../datasources/tafsir_catalog.dart';
import '../datasources/tafsir_local_datasource.dart';
import '../datasources/tafsir_remote_datasource.dart';

class TafsirRepositoryImpl with DioExceptionMapper implements ITafsirRepository {
  final ITafsirLocalDataSource _localDataSource;
  final ITafsirRemoteDataSource _remoteDataSource;

  TafsirRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<TafsirEntity>, Failure>> getAllTafsirs() async {
    try {
      final downloadedIds = _localDataSource.getDownloadedTafsirIds();

      final tafsirs = TafsirCatalog.allTafsirs.map((tafsir) {
        if (downloadedIds.contains(tafsir.id)) {
          return tafsir.copyWith(isDownloaded: true);
        }
        return tafsir;
      }).toList();

      return Success(tafsirs);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] getAllTafsirs error: $e');
      return Error(Failure(message: 'خطا در بارگزاری لیست تفاسیر. لطفاً مجدداً تلاش فرمایید.', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> downloadTafsir(
    TafsirEntity tafsir, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _remoteDataSource.downloadAndSaveTafsir(
        tafsir.id,
        tafsir.sourceUrl,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      await _localDataSource.markTafsirDownloaded(tafsir.id);
      return const Success(null);
    } on DioException catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] DioException during download: ${e.message}');
      final failure = mapDioExceptionToFailure(e, stackTrace);
      final cleanMessage = _cleanNetworkErrorMessage(failure.message, e);
      return Error(Failure(message: cleanMessage, stackTrace: stackTrace));
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] General error during download: $e');
      final cleanMessage = _cleanGeneralErrorMessage(e);
      return Error(Failure(message: cleanMessage, stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> deleteTafsir(String tafsirId) async {
    try {
      await _localDataSource.deleteTafsir(tafsirId);
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] deleteTafsir error: $e');
      return Error(Failure(message: 'خطا در حذف فایل تفسیر از حافظه دستگاه.', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<String?, Failure>> getAyahTafsir({
    required String tafsirId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      final text = await _localDataSource.getAyahTafsir(tafsirId, surahNumber, ayahNumber);
      return Success(text);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] getAyahTafsir error: $e');
      return Error(Failure(message: 'خطا در بارگزاری متن تفسیر آیه.', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<Map<int, String>, Failure>> getSurahTafsirMap({
    required String tafsirId,
    required int surahNumber,
  }) async {
    try {
      final map = await _localDataSource.getSurahTafsirMap(tafsirId, surahNumber);
      return Success(map);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] getSurahTafsirMap error: $e');
      return Error(Failure(message: 'خطا در بارگزاری تفسیر آیات سوره.', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> setActiveTafsir(String tafsirId) async {
    try {
      await _localDataSource.setActiveTafsir(tafsirId);
      return const Success(null);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] setActiveTafsir error: $e');
      return Error(Failure(message: 'خطا در ثبت تفسیر فعال.', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<String?, Failure>> getActiveTafsir() async {
    try {
      final active = _localDataSource.getActiveTafsir();
      return Success(active);
    } catch (e, stackTrace) {
      debugPrint('⚠️ [TafsirRepository] getActiveTafsir error: $e');
      return Error(Failure(message: 'خطا در بازیابی تفسیر فعال.', stackTrace: stackTrace));
    }
  }

  String _cleanNetworkErrorMessage(String rawMessage, DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.error is SocketException ||
        e.toString().contains('SocketException')) {
      return 'خطا در برقراری ارتباط اینترنت. لطفاً اتصال شبکه خود را بررسی و مجدداً تلاش کنید.';
    }
    if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
      return 'مهلت دریافت پاسخ از سرور به پایان رسید. لطفاً مجدداً امتحان کنید.';
    }
    if (e.type == DioExceptionType.cancel) {
      return 'دانلود لغو گردید.';
    }
    // If the raw message has English words, replace with polite Persian message
    if (RegExp(r'[a-zA-Z]').hasMatch(rawMessage)) {
      return 'خطا در ارتباط با سرور برای دریافت تفسیر. لطفاً اتصال اینترنت خود را بررسی نمایید.';
    }
    return rawMessage;
  }

  String _cleanGeneralErrorMessage(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('socket') || str.contains('network') || str.contains('connect') || str.contains('timeout')) {
      return 'خطا در برقراری ارتباط با اینترنت. لطفاً اتصال شبکه را بررسی نمایید.';
    }
    if (str.contains('space') || str.contains('disk') || str.contains('storage') || str.contains('permission') || str.contains('filesystem')) {
      return 'فضای ذخیره‌سازی دستگاه کافی نیست یا دسترسی به حافظه ممکن نمی‌باشد.';
    }
    if (str.contains('archive') || str.contains('tar') || str.contains('xz') || str.contains('corrupt') || str.contains('format')) {
      return 'فایل دانلود شده ناقص است. لطفاً اتصال اینترنت را چک کرده و مجدداً تلاش فرمایید.';
    }
    return 'خطا در دانلود و آماده‌سازی فایل تفسیر. لطفاً مجدداً تلاش نمایید.';
  }
}

final tafsirRepositoryProvider = Provider<ITafsirRepository>((ref) {
  final localDataSource = ref.watch(tafsirLocalDataSourceProvider);
  final remoteDataSource = ref.watch(tafsirRemoteDataSourceProvider);
  return TafsirRepositoryImpl(localDataSource, remoteDataSource);
});
