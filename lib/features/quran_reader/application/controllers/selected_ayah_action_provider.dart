import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/extensions/ayah_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../domain/entities/ayah_entity.dart';
import 'quran_audio_controller.dart';
import 'quran_display_settings_controller.dart';

/// Provider for managing multi-selected Ayahs for copy and share actions.
final selectedAyahActionProvider =
    NotifierProvider<SelectedAyahActionController, Set<int>>(
  SelectedAyahActionController.new,
);

class SelectedAyahActionController extends Notifier<Set<int>> {
  int? _lastToggledAyah;
  int _lastToggleTime = 0;

  @override
  Set<int> build() => const {};

  /// Toggle selection of an Ayah with debounce to prevent duplicate events.
  void toggleAyah(int ayahNumber) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastToggledAyah == ayahNumber && (now - _lastToggleTime) < 150) {
      return;
    }
    _lastToggledAyah = ayahNumber;
    _lastToggleTime = now;

    final current = Set<int>.from(state);
    if (current.contains(ayahNumber)) {
      current.remove(ayahNumber);
    } else {
      current.add(ayahNumber);
    }
    state = Set.unmodifiable(current);

    // Suspend auto-scroll ONLY if audio is currently playing so page doesn't jump
    final isAudioPlaying =
        ref.read(quranAudioControllerProvider).status == AudioStatus.playing;
    if (isAudioPlaying && state.isNotEmpty) {
      ref.read(quranAudioControllerProvider.notifier).suspendAutoScroll();
    }
  }

  /// Explicitly select an Ayah (idempotent; does not deselect if already selected).
  void selectAyah(int ayahNumber) {
    if (state.contains(ayahNumber)) return;
    final current = Set<int>.from(state)..add(ayahNumber);
    state = Set.unmodifiable(current);

    final isAudioPlaying =
        ref.read(quranAudioControllerProvider).status == AudioStatus.playing;
    if (isAudioPlaying && state.isNotEmpty) {
      ref.read(quranAudioControllerProvider.notifier).suspendAutoScroll();
    }
  }

  /// Clear selection and return to normal reading state.
  void clearSelection() {
    _lastToggledAyah = null;
    _lastToggleTime = 0;
    if (state.isNotEmpty) {
      state = const {};
    }
  }

  /// Copy selected Ayahs to Clipboard.
  Future<void> copySelectedAyahs({
    required BuildContext context,
    required List<AyahEntity> ayahs,
    required String surahName,
  }) async {
    if (state.isEmpty) return;

    final selectedAyahsList = ayahs
        .where((a) => state.contains(a.ayahNumber))
        .toList()
      ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));

    if (selectedAyahsList.isEmpty) return;

    final removeBrackets = ref.read(quranDisplaySettingsControllerProvider).removeTranslationBrackets;

    final buffer = StringBuffer();
    for (int i = 0; i < selectedAyahsList.length; i++) {
      final item = selectedAyahsList[i];
      buffer.writeln(item.toShareableText(
        surahName: surahName,
        removeBrackets: removeBrackets,
      ));
      if (i < selectedAyahsList.length - 1) {
        buffer.writeln(); // Spacing between ayahs
      }
    }

    final formattedText = buffer.toString().trim();
    await Clipboard.setData(ClipboardData(text: formattedText));

    if (context.mounted) {
      final countStr = selectedAyahsList.length.toPersianDigit();
      AppSnackBar.showSuccess(
        context,
        '$countStr آیه با موفقیت کپی شد',
      );
    }

    clearSelection();
  }

  /// Share selected Ayahs using system share sheet.
  Future<void> shareSelectedAyahs({
    required BuildContext context,
    required List<AyahEntity> ayahs,
    required String surahName,
  }) async {
    if (state.isEmpty) return;

    final selectedAyahsList = ayahs
        .where((a) => state.contains(a.ayahNumber))
        .toList()
      ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));

    if (selectedAyahsList.isEmpty) return;

    final removeBrackets = ref.read(quranDisplaySettingsControllerProvider).removeTranslationBrackets;

    final buffer = StringBuffer();
    for (int i = 0; i < selectedAyahsList.length; i++) {
      final item = selectedAyahsList[i];
      buffer.writeln(item.toShareableText(
        surahName: surahName,
        removeBrackets: removeBrackets,
      ));
      if (i < selectedAyahsList.length - 1) {
        buffer.writeln();
      }
    }

    final formattedText = buffer.toString().trim();
    clearSelection();

    await Share.share(formattedText, subject: 'آیات سوره $surahName');
  }
}
