import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../common/exceptions/failure.dart';
import '../../../../common/mixins/dio_exception_mapper.dart';
import '../../domain/entities/translation_entity.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/translation_local_datasource.dart';
import '../datasources/translation_remote_datasource.dart';
import '../datasources/translation_catalog.dart';

class TranslationRepositoryImpl with DioExceptionMapper implements ITranslationRepository {
  final ITranslationLocalDataSource _localDataSource;
  final ITranslationRemoteDataSource _remoteDataSource;

  TranslationRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<TranslationEntity>, Failure>> getAllTranslations() async {
    try {
      // 1. Get the list of all IDs that are currently in Hive
      final downloadedIds = _localDataSource.getDownloadedTranslationIds();
      
      // 2. Map through our hardcoded catalog and mark them as downloaded if they exist in Hive
      final translations = TranslationCatalog.allTranslations.map((translation) {
        if (downloadedIds.contains(translation.id)) {
          return translation.copyWith(isDownloaded: true);
        }
        return translation;
      }).toList();
      
      return Success(translations);
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در بارگزاری لیست ترجمه‌ها', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> downloadTranslation(
    TranslationEntity translation, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // 1. Fetch from the specific API (AlQuran or Fawaz)
      final parsedAyahs = await _remoteDataSource.fetchTranslation(
        translation.sourceUrl,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      
      // 2. If successful and data exists, save directly to Hive
      if (parsedAyahs.isNotEmpty) {
        await _localDataSource.saveTranslation(translation.id, parsedAyahs);
        return const Success(null);
      } else {
        return const Error(Failure(message: 'داده‌های ترجمه دانلود شده خالی است.'));
      }
    } on DioException catch (e, stackTrace) {
      if (CancelToken.isCancel(e)) {
        return const Error(Failure(message: 'دانلود توسط کاربر لغو شد'));
      }
      return Error(mapDioExceptionToFailure(e, stackTrace));
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در دانلود ترجمه: $e', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> preloadTranslationFromJson(String translationId, String assetPath) async {
    if (kIsWeb) {
      // In web mode, avoid loading 1.5MB JSON asset from the host server.
      // All translations on Web are fetched on-demand from AlQuran Cloud API.
      return const Success(null);
    }
    try {
      final downloadedIds = _localDataSource.getDownloadedTranslationIds();
      if (downloadedIds.contains(translationId)) {
         return const Success(null);
      }
      
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final Map<String, String> translationData = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      
      await _localDataSource.saveTranslation(translationId, translationData);
      return const Success(null);
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در بارگزاری ترجمه پیش‌فرض', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> deleteTranslation(String translationId) async {
    try {
      await _localDataSource.deleteTranslation(translationId);
      return const Success(null);
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در حذف ترجمه', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<String?, Failure>> getAyahTranslation({
    required String translationId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      final text = _localDataSource.getAyahTranslation(translationId, surahNumber, ayahNumber);
      return Success(text);
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در خواندن آیه', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<void, Failure>> setActiveTranslation(String translationId) async {
    try {
      await _localDataSource.setActiveTranslation(translationId);
      return const Success(null);
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در ثبت ترجمه فعال', stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<String?, Failure>> getActiveTranslation() async {
    try {
      final id = _localDataSource.getActiveTranslation();
      return Success(id);
    } catch (e, stackTrace) {
      return Error(Failure(message: 'خطا در خواندن ترجمه فعال', stackTrace: stackTrace));
    }
  }
}

final translationRepositoryProvider = Provider<ITranslationRepository>((ref) {
  final localDataSource = ref.watch(translationLocalDataSourceProvider);
  final remoteDataSource = ref.watch(translationRemoteDataSourceProvider);
  return TranslationRepositoryImpl(localDataSource, remoteDataSource);
});
