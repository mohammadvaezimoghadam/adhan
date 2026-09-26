import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/routes/go_router_provider.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../../surah_list/domain/entities/surah_entity.dart';
import '../../application/controllers/tafsir_manager_controller.dart';
import '../../domain/entities/tafsir_entity.dart';

/// Bottom sheet for selecting a Surah and a Tafsir using scrollable wheels (CupertinoPicker).
class TafsirManagerBottomSheet extends ConsumerStatefulWidget {
  const TafsirManagerBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TafsirManagerBottomSheet(),
    );
  }

  @override
  ConsumerState<TafsirManagerBottomSheet> createState() =>
      _TafsirManagerBottomSheetState();
}

class _TafsirManagerBottomSheetState extends ConsumerState<TafsirManagerBottomSheet> {
  int _selectedSurahIndex = 0;
  int _selectedTafsirIndex = 0;

  bool _isCurrentlyDownloading(List<TafsirEntity> tafsirs) {
    if (tafsirs.isEmpty || _selectedTafsirIndex >= tafsirs.length) return false;
    final state = ref.watch(tafsirManagerControllerProvider).value;
    if (state == null) return false;
    final selectedTafsir = tafsirs[_selectedTafsirIndex];
    return state.downloadProgress.containsKey(selectedTafsir.id);
  }

  Future<void> _handleStartReading(
    BuildContext context,
    SurahEntity surah,
    TafsirEntity tafsir,
  ) async {
    final controller = ref.read(tafsirManagerControllerProvider.notifier);

    // If it's not downloaded, ask for permission to download
    if (!tafsir.isDownloaded) {
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final colorScheme = Theme.of(ctx).colorScheme;
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppModalHeader(
                    title: 'دانلود تفسیر',
                    onClose: () => Navigator.of(ctx).pop(false),
                    bottomSpacing: 14,
                  ),
                  Text(
                    'برای مطالعه، باید «${tafsir.name}» (${tafsir.authorName}) را دانلود کنید. مایل به دانلود هستید؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(
                            'انصراف',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'دانلود',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (shouldDownload != true) return;

      // Start downloading
      await controller.downloadTafsir(tafsir);

      if (!context.mounted) return;

      final currentState = ref.read(tafsirManagerControllerProvider).value;
      if (currentState?.errorMessage != null && currentState!.errorMessage!.isNotEmpty) {
        AppSnackBar.showError(context, currentState.errorMessage!);
        controller.clearErrorMessage();
        return;
      }

      final updatedTafsir = currentState?.tafsirs.firstWhere(
        (t) => t.id == tafsir.id,
        orElse: () => tafsir,
      );

      if (updatedTafsir == null || !updatedTafsir.isDownloaded) {
        return;
      }

      AppSnackBar.showSuccess(context, 'تفسیر «${tafsir.name}» با موفقیت دانلود و ذخیره شد.');
    }

    if (!context.mounted) return;

    // Set active Tafsir
    await controller.setActiveTafsir(tafsir.id);

    if (!context.mounted) return;

    // Close bottom sheet
    Navigator.of(context).pop();

    // Navigate directly to the dedicated TafsirReaderScreen!
    ref.read(goRouterProvider).pushNamed(
      tafsirReaderRoute,
      pathParameters: {'id': surah.number.toString()},
      queryParameters: {
        'name': surah.name,
        'tafsirId': tafsir.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBgColor = isDark
        ? const Color(0xFF14181B)
        : const Color(0xFFF1EFEA);

    final surahState = ref.watch(surahListControllerProvider);
    final tafsirState = ref.watch(tafsirManagerControllerProvider);

    final surahs = surahState.surahs;
    final tafsirs = tafsirState.value?.tafsirs ?? [];

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.50,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: sheetBgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                ),
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  children: [
                    const AppModalHeader(
                      showDragHandle: true,
                      title: 'انتخاب سوره و تفسیر',
                      bottomSpacing: 14,
                    ),

                    if (surahState.isLoading || tafsirState.isLoading || tafsirs.isEmpty)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else
                      Expanded(
                        child: Row(
                          children: [
                            // --- Surahs Picker ---
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  const Text(
                                    'سوره',
                                    style: AppTypography.bottomSheetSubtitle,
                                  ),
                                  8.vSpace,
                                  Expanded(
                                    child: CupertinoPicker.builder(
                                      itemExtent: 45,
                                      useMagnifier: true,
                                      magnification: 1.15,
                                      scrollController: FixedExtentScrollController(
                                        initialItem: _selectedSurahIndex,
                                      ),
                                      onSelectedItemChanged: (index) {
                                        _selectedSurahIndex = index;
                                      },
                                      childCount: surahs.length,
                                      itemBuilder: (context, index) {
                                        final surah = surahs[index];
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              'سوره ${surah.nameFa}',
                                              style: AppTypography.bottomSheetItemLabel.copyWith(
                                                fontFamily: AppTypography.fontFamily,
                                                fontSize: 15,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            16.hSpace,

                            // --- Tafsirs Picker ---
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  const Text(
                                    'تفسیر',
                                    style: AppTypography.bottomSheetSubtitle,
                                  ),
                                  8.vSpace,
                                  Expanded(
                                    child: CupertinoPicker.builder(
                                      itemExtent: 45,
                                      useMagnifier: true,
                                      magnification: 1.15,
                                      scrollController: FixedExtentScrollController(
                                        initialItem: _selectedTafsirIndex,
                                      ),
                                      onSelectedItemChanged: (index) {
                                        setState(() {
                                          _selectedTafsirIndex = index;
                                        });
                                      },
                                      childCount: tafsirs.length,
                                      itemBuilder: (context, index) {
                                        final tafsir = tafsirs[index];
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text.rich(
                                                    TextSpan(
                                                      children: [
                                                        WidgetSpan(
                                                          alignment: PlaceholderAlignment.middle,
                                                          child: _TafsirStatusIcon(tafsir: tafsir),
                                                        ),
                                                        TextSpan(text: tafsir.name),
                                                      ],
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppTypography.bottomSheetItemLabel.copyWith(
                                                      color: colorScheme.onSurface,
                                                      fontSize: 12,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    16.vSpace,

                    // --- Action Button ---
                    Builder(
                      builder: (context) {
                        final selectedTafsir = (tafsirs.isNotEmpty &&
                                _selectedTafsirIndex < tafsirs.length)
                            ? tafsirs[_selectedTafsirIndex]
                            : null;
                        final isDownloading = _isCurrentlyDownloading(tafsirs);

                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              if (isDownloading) return;
                              if (surahs.isEmpty || selectedTafsir == null) return;

                              final selectedSurah = surahs[_selectedSurahIndex];
                              _handleStartReading(context, selectedSurah, selectedTafsir);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isDownloading) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'در حال دریافت...',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ] else if (selectedTafsir != null && !selectedTafsir.isDownloaded) ...[
                                  const Icon(CupertinoIcons.cloud_download, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'دانلود ${selectedTafsir.name}',
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ] else ...[
                                  const Icon(CupertinoIcons.book_fill, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'مطالعه تفسیر',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}

class _TafsirStatusIcon extends ConsumerWidget {
  final TafsirEntity tafsir;

  const _TafsirStatusIcon({required this.tafsir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(tafsirManagerControllerProvider).value;

    final progress = state?.downloadProgress[tafsir.id];
    final isDownloading = progress != null;

    if (tafsir.isDownloaded) {
      return Padding(
        padding: const EdgeInsets.only(left: 6.0),
        child: Icon(
          CupertinoIcons.check_mark_circled_solid,
          size: 14,
          color: Colors.green.shade600,
        ),
      );
    }

    if (isDownloading) {
      return Padding(
        padding: const EdgeInsets.only(left: 6.0),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Icon(
        CupertinoIcons.cloud_download,
        size: 14,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
