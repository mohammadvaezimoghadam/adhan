import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/translation_entity.dart';
import '../../infrastructure/repositories/translation_repository_impl.dart';
import '../states/translation_manager_state.dart';

part 'translation_manager_controller.g.dart';

@Riverpod(keepAlive: true)
class TranslationManagerController extends _$TranslationManagerController {
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  FutureOr<TranslationManagerState> build() async {
    ref.onDispose(() {
      for (final token in _cancelTokens.values) {
        token.cancel();
      }
      _cancelTokens.clear();
    });
    return _loadInitialState();
  }

  Future<TranslationManagerState> _loadInitialState() async {
    final repository = ref.read(translationRepositoryProvider);
    
    // Ensure default Makarem translation is preloaded on native platforms
    if (!kIsWeb) {
      await repository.preloadTranslationFromJson('fa.makarem', 'assets/database/fa_makarem.json');
    }
    
    final translationsResult = await repository.getAllTranslations();
    final translations = translationsResult.tryGetSuccess() ?? [];
    
    final activeIdResult = await repository.getActiveTranslation();
    final activeId = activeIdResult.tryGetSuccess();

    String? initialActiveId = activeId ?? 'fa.makarem';
    if (activeId == null) {
      await repository.setActiveTranslation('fa.makarem');
    }

    return TranslationManagerState(
      translations: translations,
      activeTranslationId: initialActiveId,
    );
  }

  /// Downloads a specific translation and updates the UI state
  Future<void> downloadTranslation(TranslationEntity translation) async {
    if (state.value?.downloadProgress.containsKey(translation.id) ?? false) return;

    final currentProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
    currentProgress[translation.id] = 0.0;
    
    state = AsyncData(state.value!.copyWith(
      downloadProgress: currentProgress,
      errorMessage: null,
    ));

    final cancelToken = CancelToken();
    _cancelTokens[translation.id] = cancelToken;

    final repository = ref.read(translationRepositoryProvider);
    final downloadResult = await repository.downloadTranslation(
      translation,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        // Many APIs don't send content-length (total == -1). 
        // We estimate a typical translation JSON size to be ~1.5MB for a smooth determinate loading bar.
        final estimatedTotal = total != -1 ? total : 1500000;
        final progress = (received / estimatedTotal).clamp(0.0, 1.0);
        
        final updatedProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
        updatedProgress[translation.id] = progress;
        state = AsyncData(state.value!.copyWith(downloadProgress: updatedProgress));
      },
    );

    _cancelTokens.remove(translation.id);

    await downloadResult.when(
      (success) async {
        final updatedTranslationsResult = await repository.getAllTranslations();
        final updatedTranslations = updatedTranslationsResult.tryGetSuccess() ?? [];
        
        final finalProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
        finalProgress.remove(translation.id);
        
        state = AsyncData(state.value!.copyWith(
          translations: updatedTranslations,
          downloadProgress: finalProgress,
        ));
      },
      (error) {
        final finalProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
        finalProgress.remove(translation.id);
        
        state = AsyncData(state.value!.copyWith(
          downloadProgress: finalProgress,
          errorMessage: error.message,
        ));
      },
    );
  }

  /// Cancels an ongoing download for a translation
  void cancelDownload(String translationId) {
    if (_cancelTokens.containsKey(translationId)) {
      _cancelTokens[translationId]?.cancel('توسط کاربر لغو شد');
      _cancelTokens.remove(translationId);
    }
    if (state.value?.downloadProgress.containsKey(translationId) ?? false) {
      final finalProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
      finalProgress.remove(translationId);
      state = AsyncData(state.value!.copyWith(downloadProgress: finalProgress));
    }
  }

  /// Deletes a downloaded translation from local storage
  Future<void> deleteTranslation(String translationId) async {
    final repository = ref.read(translationRepositoryProvider);
    final deleteResult = await repository.deleteTranslation(translationId);

    await deleteResult.when(
      (success) async {
        final updatedTranslationsResult = await repository.getAllTranslations();
        final updatedTranslations = updatedTranslationsResult.tryGetSuccess() ?? [];
        state = AsyncData(state.value!.copyWith(translations: updatedTranslations));
      },
      (error) {
        state = AsyncData(state.value!.copyWith(errorMessage: error.message));
      },
    );
  }

  /// Sets the currently active translation that the user wants to read
  Future<void> setActiveTranslation(String translationId) async {
    final repository = ref.read(translationRepositoryProvider);
    final setActiveResult = await repository.setActiveTranslation(translationId);

    setActiveResult.when(
      (success) {
        state = AsyncData(state.value!.copyWith(activeTranslationId: translationId));
      },
      (error) {
        state = AsyncData(state.value!.copyWith(errorMessage: error.message));
      },
    );
  }
}
