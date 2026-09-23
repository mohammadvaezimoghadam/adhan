// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayah_translation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the translated text for a specific Ayah using the currently active translation.

@ProviderFor(ayahTranslation)
final ayahTranslationProvider = AyahTranslationFamily._();

/// Provides the translated text for a specific Ayah using the currently active translation.

final class AyahTranslationProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Provides the translated text for a specific Ayah using the currently active translation.
  AyahTranslationProvider._({
    required AyahTranslationFamily super.from,
    required (int, int, String?) super.argument,
  }) : super(
         retry: null,
         name: r'ayahTranslationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ayahTranslationHash();

  @override
  String toString() {
    return r'ayahTranslationProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as (int, int, String?);
    return ayahTranslation(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is AyahTranslationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ayahTranslationHash() => r'6a324c5dd4d4a187ad3e11b5a4ad9d596e84a8b5';

/// Provides the translated text for a specific Ayah using the currently active translation.

final class AyahTranslationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, (int, int, String?)> {
  AyahTranslationFamily._()
    : super(
        retry: null,
        name: r'ayahTranslationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the translated text for a specific Ayah using the currently active translation.

  AyahTranslationProvider call(
    int surahNumber,
    int ayahNumber,
    String? translationId,
  ) => AyahTranslationProvider._(
    argument: (surahNumber, ayahNumber, translationId),
    from: this,
  );

  @override
  String toString() => r'ayahTranslationProvider';
}
