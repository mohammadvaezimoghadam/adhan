import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/repositories/tafsir_repository_impl.dart';
import 'tafsir_manager_controller.dart';

/// Provides the full map of Tafsir texts for all Ayahs in a Surah (key: ayahNumber, value: tafsirText)
final surahTafsirProvider = FutureProvider.family<Map<int, String>, ({int surahNumber, String? tafsirId})>(
  (ref, params) async {
    final effectiveTafsirId = params.tafsirId ??
        ref.watch(tafsirManagerControllerProvider.select((s) => s.value?.activeTafsirId));

    if (effectiveTafsirId == null) return {};

    final repository = ref.read(tafsirRepositoryProvider);
    final result = await repository.getSurahTafsirMap(
      tafsirId: effectiveTafsirId,
      surahNumber: params.surahNumber,
    );

    return result.tryGetSuccess() ?? {};
  },
);

/// Provides the Tafsir text for a single Ayah
final ayahTafsirProvider = FutureProvider.family<String?, ({int surahNumber, int ayahNumber, String? tafsirId})>(
  (ref, params) async {
    final effectiveTafsirId = params.tafsirId ??
        ref.watch(tafsirManagerControllerProvider.select((s) => s.value?.activeTafsirId));

    if (effectiveTafsirId == null) return null;

    final repository = ref.read(tafsirRepositoryProvider);
    final result = await repository.getAyahTafsir(
      tafsirId: effectiveTafsirId,
      surahNumber: params.surahNumber,
      ayahNumber: params.ayahNumber,
    );

    return result.tryGetSuccess();
  },
);
