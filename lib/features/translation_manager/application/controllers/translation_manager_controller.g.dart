// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_manager_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TranslationManagerController)
final translationManagerControllerProvider =
    TranslationManagerControllerProvider._();

final class TranslationManagerControllerProvider
    extends
        $AsyncNotifierProvider<
          TranslationManagerController,
          TranslationManagerState
        > {
  TranslationManagerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translationManagerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translationManagerControllerHash();

  @$internal
  @override
  TranslationManagerController create() => TranslationManagerController();
}

String _$translationManagerControllerHash() =>
    r'df442f67ba07f5ba7d9403a0399ba39aea14fe1e';

abstract class _$TranslationManagerController
    extends $AsyncNotifier<TranslationManagerState> {
  FutureOr<TranslationManagerState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<TranslationManagerState>,
              TranslationManagerState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<TranslationManagerState>,
                TranslationManagerState
              >,
              AsyncValue<TranslationManagerState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
