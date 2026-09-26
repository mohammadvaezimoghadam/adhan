import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../common/exceptions/failure.dart';
import '../../../translation_manager/application/controllers/translation_manager_controller.dart';
import '../../domain/entities/ayah_entity.dart';
import '../../domain/entities/word_entity.dart';
import '../../domain/repositories/i_ayah_repository.dart';
import '../datasources/ayah_local_data_source.dart';
import '../datasources/ayah_remote_data_source.dart';

final ayahRepositoryProvider = Provider<IAyahRepository>((ref) {
  if (kIsWeb) {
    final remoteDataSource = ref.watch(ayahRemoteDataSourceProvider);
    final activeTransId = ref.watch(translationManagerControllerProvider).value?.activeTranslationId ?? 'fa.makarem';
    return AyahRemoteRepository(remoteDataSource, activeTranslationId: activeTransId);
  }
  final localDataSource = ref.watch(ayahLocalDataSourceProvider);
  return AyahRepository(localDataSource);
});

class AyahRepository implements IAyahRepository {
  final IAyahLocalDataSource _localDataSource;

  AyahRepository(this._localDataSource);

  @override
  Future<Result<List<AyahEntity>, Failure>> getAyahsBySurah(int surahId) async {
    try {
      final dtos = await _localDataSource.getAyahsBySurah(surahId);
      
      if (dtos.isEmpty) {
        return Error(const Failure(message: 'هیچ آیه‌ای برای این سوره یافت نشد.'));
      }

      final entities = dtos.map((dto) => dto.toDomain()).toList();
      return Success(entities);
    } catch (e, s) {
      return Error(Failure(
        message: 'خطا در دریافت آیات: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
        stackTrace: s,
      ));
    }
  }

  @override
  Future<Result<List<WordEntity>, Failure>> getAyahWords(int surahId, int ayahNumber) async {
    try {
      final dtos = await _localDataSource.getAyahWords(surahId, ayahNumber);
      
      final entities = dtos.map((dto) => dto.toDomain()).toList();
      return Success(entities);
    } catch (e, s) {
      return Error(Failure(
        message: 'خطا در واکشی لغت‌نامه: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
        stackTrace: s,
      ));
    }
  }

  @override
  Future<Result<List<WordEntity>, Failure>> getSurahWords(int surahId) async {
    try {
      final dtos = await _localDataSource.getSurahWords(surahId);
      
      final entities = dtos.map((dto) => dto.toDomain()).toList();
      return Success(entities);
    } catch (e, s) {
      return Error(Failure(
        message: 'خطا در واکشی لغت‌نامه سوره: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
        stackTrace: s,
      ));
    }
  }
}

class AyahRemoteRepository implements IAyahRepository {
  final IAyahRemoteDataSource _remoteDataSource;
  final String activeTranslationId;

  AyahRemoteRepository(
    this._remoteDataSource, {
    this.activeTranslationId = 'fa.makarem',
  });

  @override
  Future<Result<List<AyahEntity>, Failure>> getAyahsBySurah(int surahId) async {
    try {
      final entities = await _remoteDataSource.getAyahsBySurah(
        surahId,
        translationId: activeTranslationId,
      );
      if (entities.isEmpty) {
        return const Error(Failure(message: 'هیچ آیه‌ای برای این سوره یافت نشد.'));
      }
      return Success(entities);
    } catch (e, s) {
      return Error(Failure(
        message: 'خطا در دریافت آیات از سرور: $e',
        exception: e is Exception ? e : Exception(e.toString()),
        stackTrace: s,
      ));
    }
  }

  @override
  Future<Result<List<WordEntity>, Failure>> getAyahWords(int surahId, int ayahNumber) async {
    return const Success([]);
  }

  @override
  Future<Result<List<WordEntity>, Failure>> getSurahWords(int surahId) async {
    return const Success([]);
  }
}
