/// Domain entity representing a Quran Exegesis (Tafsir).
class TafsirEntity {
  /// Unique identifier for the Tafsir (e.g. 'tafsir.gharaati')
  final String id;

  /// Display name of the Tafsir (e.g. 'تفسیر نور')
  final String name;

  /// Author / Scholar name (e.g. 'حجت‌الاسلام محسن قرائتی')
  final String authorName;

  /// Short description / methodology summary
  final String description;

  /// Direct API or CDN URL to download the Tafsir JSON
  final String sourceUrl;

  /// Whether the Tafsir has been downloaded locally
  final bool isDownloaded;

  const TafsirEntity({
    required this.id,
    required this.name,
    required this.authorName,
    required this.description,
    required this.sourceUrl,
    this.isDownloaded = false,
  });

  TafsirEntity copyWith({
    String? id,
    String? name,
    String? authorName,
    String? description,
    String? sourceUrl,
    bool? isDownloaded,
  }) {
    return TafsirEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      authorName: authorName ?? this.authorName,
      description: description ?? this.description,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TafsirEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          authorName == other.authorName &&
          sourceUrl == other.sourceUrl &&
          isDownloaded == other.isDownloaded;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      authorName.hashCode ^
      sourceUrl.hashCode ^
      isDownloaded.hashCode;
}
