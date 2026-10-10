import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../domain/entities/quick_access_tool_entity.dart';
import '../../infrastructure/repositories/quick_access_repository_impl.dart';
import '../states/quick_access_state.dart';

final quickAccessControllerProvider =
    NotifierProvider<QuickAccessController, QuickAccessState>(
  QuickAccessController.new,
);

class QuickAccessController extends Notifier<QuickAccessState> {
  @override
  QuickAccessState build() {
    ref.listen(surahListControllerProvider.select((s) => s.surahs), (prev, next) {
      if (next.isNotEmpty) {
        loadSlots();
      }
    });

    Future.microtask(() => loadSlots());
    return const QuickAccessState();
  }

  /// Loads the 4 configured slots from the repository
  Future<void> loadSlots() async {
    state = state.copyWith(isLoading: true);
    final repository = ref.read(quickAccessRepositoryProvider);
    final catalog = repository.getAllToolsCatalog();
    final surahs = ref.read(surahListControllerProvider.select((s) => s.surahs));

    final result = await repository.getRawSlotIds();

    result.when(
      (rawSlotIds) {
        final mappedSlots = rawSlotIds.map<QuickAccessToolEntity?>((rawId) {
          if (rawId == null) return null;

          // Check if this slot represents a pinned surah (e.g. 'pinned_surah:36')
          if (rawId.startsWith('pinned_surah:')) {
            final surahId = int.tryParse(rawId.substring('pinned_surah:'.length));
            if (surahId != null) {
              final surah = surahs.where((s) => s.number == surahId).firstOrNull;
              return QuickAccessToolEntity(
                type: QuickAccessToolType.pinnedSurah,
                title: surah != null ? 'سوره ${surah.name}' : 'سوره $surahId',
                description: surah != null
                    ? 'قرائت مستقیم سوره ${surah.name} (${surah.numberOfAyahs} آیه)'
                    : 'سوره شماره $surahId',
                iconData: null, // Surahs have no icon!
                surahId: surahId,
                surahName: surah?.name,
                ayahCount: surah?.numberOfAyahs,
              );
            }
          }

          final type = QuickAccessToolType.fromId(rawId);
          if (type == null || type == QuickAccessToolType.topicStudio) return null;
          return catalog.where((c) => c.type == type).firstOrNull;
        }).toList();

        while (mappedSlots.length < 4) {
          mappedSlots.add(null);
        }

        state = state.copyWith(
          isLoading: false,
          slots: mappedSlots.take(4).toList(),
        );
      },
      (error) {
        state = state.copyWith(isLoading: false);
      },
    );
  }

  /// Toggles the Jiggle / Edit Mode
  void toggleEditMode() {
    state = state.copyWith(isEditMode: !state.isEditMode);
  }

  /// Sets edit mode explicitly
  void setEditMode(bool value) {
    state = state.copyWith(isEditMode: value);
  }

  /// Empties a slot, turning it into a '+' card
  Future<void> removeSlot(int index) async {
    if (index < 0 || index >= 4) return;
    final repository = ref.read(quickAccessRepositoryProvider);
    await repository.clearSlot(index);
    await loadSlots();
  }

  /// Assigns a chosen tool to an empty slot
  Future<void> assignToolToSlot(int index, QuickAccessToolType toolType) async {
    if (index < 0 || index >= 4) return;
    final repository = ref.read(quickAccessRepositoryProvider);
    await repository.setSlot(index, toolType);
    await loadSlots();
  }

  /// Assigns a specific surah to a slot
  Future<void> assignSurahToSlot(int index, int surahId) async {
    if (index < 0 || index >= 4) return;
    final repository = ref.read(quickAccessRepositoryProvider);
    await repository.setRawSlotId(index, 'pinned_surah:$surahId');
    await loadSlots();
  }

  /// Returns all tools in the catalog available for the picker.
  /// Pinned surah can be selected multiple times (up to all 4 slots).
  List<QuickAccessToolEntity> getAvailableToolsForPicker() {
    final repository = ref.read(quickAccessRepositoryProvider);
    final allCatalog = repository.getAllToolsCatalog();
    final occupiedTypes = state.slots
        .whereType<QuickAccessToolEntity>()
        .where((e) => e.type != QuickAccessToolType.pinnedSurah)
        .map((e) => e.type)
        .toSet();

    return allCatalog.where((tool) {
      if (tool.type == QuickAccessToolType.pinnedSurah) {
        return true; // Can always be picked again
      }
      return !occupiedTypes.contains(tool.type);
    }).toList();
  }
}
