import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tafsir_entity.dart';
import '../../infrastructure/repositories/tafsir_repository_impl.dart';
import '../states/tafsir_manager_state.dart';

class TafsirManagerController extends AsyncNotifier<TafsirManagerState> {
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  FutureOr<TafsirManagerState> build() async {
    ref.onDispose(() {
      for (final token in _cancelTokens.values) {
        token.cancel();
      }
      _cancelTokens.clear();
    });
    return _loadInitialState();
  }

  Future<TafsirManagerState> _loadInitialState() async {
    final repository = ref.read(tafsirRepositoryProvider);

    final tafsirsResult = await repository.getAllTafsirs();
    final tafsirs = tafsirsResult.tryGetSuccess() ?? [];

    final activeIdResult = await repository.getActiveTafsir();
    final activeId = activeIdResult.tryGetSuccess();

    String? initialActiveId = activeId;
    if (initialActiveId == null && tafsirs.isNotEmpty) {
      final downloadedFirst = tafsirs.where((t) => t.isDownloaded).firstOrNull;
      initialActiveId = downloadedFirst?.id ?? tafsirs.first.id;
      await repository.setActiveTafsir(initialActiveId);
    }

    return TafsirManagerState(
      tafsirs: tafsirs,
      activeTafsirId: initialActiveId,
    );
  }

  /// Downloads a specific Tafsir and updates the UI progress
  Future<void> downloadTafsir(TafsirEntity tafsir) async {
    if (state.value?.downloadProgress.containsKey(tafsir.id) ?? false) return;

    final currentProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
    currentProgress[tafsir.id] = 0.0;

    state = AsyncData(state.value!.copyWith(
      downloadProgress: currentProgress,
      errorMessage: null,
    ));

    final cancelToken = CancelToken();
    _cancelTokens[tafsir.id] = cancelToken;

    final repository = ref.read(tafsirRepositoryProvider);
    final downloadResult = await repository.downloadTafsir(
      tafsir,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        final estimatedTotal = total != -1 ? total : 2500000;
        final progress = (received / estimatedTotal).clamp(0.0, 1.0);

        final updatedProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
        updatedProgress[tafsir.id] = progress;
        state = AsyncData(state.value!.copyWith(downloadProgress: updatedProgress));
      },
    );

    _cancelTokens.remove(tafsir.id);

    await downloadResult.when(
      (success) async {
        debugPrint('🎉 [TafsirController] Tafsir ${tafsir.name} successfully downloaded and registered in Hive!');
        final updatedTafsirsResult = await repository.getAllTafsirs();
        final updatedTafsirs = updatedTafsirsResult.tryGetSuccess() ?? [];

        final finalProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
        finalProgress.remove(tafsir.id);

        state = AsyncData(state.value!.copyWith(
          tafsirs: updatedTafsirs,
          activeTafsirId: tafsir.id,
          downloadProgress: finalProgress,
          errorMessage: null,
        ));
      },
      (error) {
        debugPrint('❌ [TafsirController] Tafsir download failed: ${error.message}');
        final finalProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
        finalProgress.remove(tafsir.id);

        state = AsyncData(state.value!.copyWith(
          downloadProgress: finalProgress,
          errorMessage: _sanitizeErrorMessage(error.message),
        ));
      },
    );
  }

  /// Cancels an ongoing download
  void cancelDownload(String tafsirId) {
    if (_cancelTokens.containsKey(tafsirId)) {
      _cancelTokens[tafsirId]?.cancel('توسط کاربر لغو شد');
      _cancelTokens.remove(tafsirId);
    }
    if (state.value?.downloadProgress.containsKey(tafsirId) ?? false) {
      final finalProgress = Map<String, double>.from(state.value?.downloadProgress ?? {});
      finalProgress.remove(tafsirId);
      state = AsyncData(state.value!.copyWith(downloadProgress: finalProgress));
    }
  }

  /// Deletes a downloaded Tafsir from local storage
  Future<void> deleteTafsir(String tafsirId) async {
    final repository = ref.read(tafsirRepositoryProvider);
    final deleteResult = await repository.deleteTafsir(tafsirId);

    await deleteResult.when(
      (success) async {
        final updatedTafsirsResult = await repository.getAllTafsirs();
        final updatedTafsirs = updatedTafsirsResult.tryGetSuccess() ?? [];
        state = AsyncData(state.value!.copyWith(tafsirs: updatedTafsirs));
      },
      (error) {
        state = AsyncData(state.value!.copyWith(errorMessage: _sanitizeErrorMessage(error.message)));
      },
    );
  }

  /// Sets the active Tafsir
  Future<void> setActiveTafsir(String tafsirId) async {
    final repository = ref.read(tafsirRepositoryProvider);
    final result = await repository.setActiveTafsir(tafsirId);

    result.when(
      (success) {
        state = AsyncData(state.value!.copyWith(activeTafsirId: tafsirId));
      },
      (error) {
        state = AsyncData(state.value!.copyWith(errorMessage: _sanitizeErrorMessage(error.message)));
      },
    );
  }

  /// Clears any active error message in state
  void clearErrorMessage() {
    if (state.value?.errorMessage != null) {
      state = AsyncData(state.value!.copyWith(errorMessage: null));
    }
  }

  String _sanitizeErrorMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'خطا در عملیات مورد نظر. لطفاً دوباره تلاش فرمایید.';
    }
    // If the message contains English letters or technical words, map to pure Persian
    if (RegExp(r'[a-zA-Z]').hasMatch(raw)) {
      final lower = raw.toLowerCase();
      if (lower.contains('socket') || lower.contains('network') || lower.contains('connect') || lower.contains('timeout')) {
        return 'خطا در برقراری ارتباط اینترنت. لطفاً اتصال شبکه خود را بررسی نمایید.';
      }
      if (lower.contains('storage') || lower.contains('disk') || lower.contains('space') || lower.contains('permission')) {
        return 'فضای ذخیره‌سازی دستگاه کافی نیست یا دسترسی به حافظه محدود است.';
      }
      return 'خطا در دریافت و آماده‌سازی تفسیر. لطفاً اتصال اینترنت را چک کرده و مجدداً تلاش نمایید.';
    }
    return raw;
  }
}

final tafsirManagerControllerProvider =
    AsyncNotifierProvider<TafsirManagerController, TafsirManagerState>(
  TafsirManagerController.new,
);
