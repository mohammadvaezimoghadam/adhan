import '../../domain/entities/tafsir_entity.dart';

class TafsirManagerState {
  final List<TafsirEntity> tafsirs;
  final String? activeTafsirId;
  final Map<String, double> downloadProgress;
  final String? errorMessage;

  const TafsirManagerState({
    this.tafsirs = const [],
    this.activeTafsirId,
    this.downloadProgress = const {},
    this.errorMessage,
  });

  TafsirManagerState copyWith({
    List<TafsirEntity>? tafsirs,
    String? activeTafsirId,
    Map<String, double>? downloadProgress,
    String? errorMessage,
  }) {
    return TafsirManagerState(
      tafsirs: tafsirs ?? this.tafsirs,
      activeTafsirId: activeTafsirId ?? this.activeTafsirId,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
    );
  }
}
