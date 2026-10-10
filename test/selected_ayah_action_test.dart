import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/features/quran_reader/application/controllers/selected_ayah_action_provider.dart';
import 'package:quran/features/quran_reader/application/controllers/quran_audio_controller.dart';
import 'package:quran/features/quran_reader/application/states/quran_audio_state.dart';

class FakeQuranAudioController extends QuranAudioController {
  @override
  QuranAudioState build() {
    return const QuranAudioState();
  }

  @override
  void suspendAutoScroll() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SelectedAyahActionController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          quranAudioControllerProvider.overrideWith(FakeQuranAudioController.new),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('selectAyah adds ayah idempotently', () {
      final controller =
          container.read(selectedAyahActionProvider.notifier);

      controller.selectAyah(1);
      expect(container.read(selectedAyahActionProvider), {1});

      // Calling selectAyah again should not remove or change state
      controller.selectAyah(1);
      expect(container.read(selectedAyahActionProvider), {1});
    });

    test('toggleAyah debounces rapid duplicate calls on the same Ayah', () {
      final controller =
          container.read(selectedAyahActionProvider.notifier);

      // First toggle: selects Ayah 1
      controller.toggleAyah(1);
      expect(container.read(selectedAyahActionProvider), {1});

      // Immediate second toggle (<150ms): should be ignored by debounce!
      controller.toggleAyah(1);
      expect(container.read(selectedAyahActionProvider), {1});
    });

    test('multi-selection deselect works correctly without re-selecting', () async {
      final controller =
          container.read(selectedAyahActionProvider.notifier);

      // Select Ayah 1
      controller.selectAyah(1);
      // Select Ayah 2
      controller.selectAyah(2);
      // Select Ayah 3
      controller.selectAyah(3);

      expect(container.read(selectedAyahActionProvider), {1, 2, 3});

      // Wait 200ms to allow debounce window to pass
      await Future.delayed(const Duration(milliseconds: 200));

      // Now deselect Ayah 2
      controller.toggleAyah(2);

      // Ayah 2 should be cleanly removed, leaving {1, 3}
      expect(container.read(selectedAyahActionProvider), {1, 3});

      // Rapid duplicate event on Ayah 2 (which previously caused immediate re-selection)
      controller.toggleAyah(2);

      // Should STILL be {1, 3} because duplicate call was debounced!
      expect(container.read(selectedAyahActionProvider), {1, 3});
    });

    test('clearSelection clears all selected ayahs', () {
      final controller =
          container.read(selectedAyahActionProvider.notifier);

      controller.selectAyah(1);
      controller.selectAyah(2);
      expect(container.read(selectedAyahActionProvider), {1, 2});

      controller.clearSelection();
      expect(container.read(selectedAyahActionProvider), isEmpty);
    });
  });
}
