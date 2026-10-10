import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../common/widgets/surah_picker_dialog.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../quran_home/application/controllers/continue_reading_controller.dart';
import '../../../surah_list/application/controllers/surah_list_controller.dart';
import '../../application/controllers/pinned_surah_controller.dart';
import '../../application/controllers/quick_access_controller.dart';
import '../../domain/entities/quick_access_tool_entity.dart';
import '../widgets/bookmarks_manager_bottom_sheet.dart';
import '../widgets/pinned_surah_picker_bottom_sheet.dart';
import '../widgets/quick_access_picker_bottom_sheet.dart';
import '../widgets/quick_access_slot_card.dart';
// import '../../../tafakor/application/controllers/tafakor_auth_controller.dart';
// import '../../../tafakor/presentation/ui/tafakor_login_screen.dart';
// import '../../../topic_studio/presentation/ui/topic_studio_screen.dart';

class QuickAccessRow extends ConsumerWidget {
  const QuickAccessRow({super.key});

  Future<void> _handleToolTap(
    BuildContext context,
    WidgetRef ref,
    QuickAccessToolEntity tool,
  ) async {
    if (tool.routeName != null) {
      context.pushNamed(tool.routeName!);
      return;
    }

    switch (tool.type) {
      case QuickAccessToolType.lastRead:
        final lastReadState = ref.read(continueReadingControllerProvider);
        if (lastReadState != null) {
          context.pushNamed(
            quranReaderRoute,
            pathParameters: {'id': lastReadState.surahId.toString()},
            queryParameters: {
              'name': lastReadState.surahName,
              'ayah': lastReadState.ayahNumber.toString(),
            },
          );
        } else {
          AppSnackBar.showInfo(
            context,
            'هنوز هیچ آیه‌ای به عنوان آخرین مطالعه ثبت نشده است.',
          );
        }
        break;

      case QuickAccessToolType.bookmarks:
        BookmarksManagerBottomSheet.show(context, isFullScreen: true);
        break;

      case QuickAccessToolType.personalList:
        ref.read(surahListControllerProvider.notifier).setOnlyFavorites(true);
        context.pushNamed(surahListRoute);
        break;

      case QuickAccessToolType.pinnedSurah:
        final surahId = tool.surahId ?? ref.read(pinnedSurahIdProvider);
        if (surahId != null) {
          context.pushNamed(
            quranReaderRoute,
            pathParameters: {'id': surahId.toString()},
            queryParameters: {'name': tool.surahName ?? tool.title},
          );
        } else {
          PinnedSurahPickerBottomSheet.show(context);
        }
        break;

      case QuickAccessToolType.dictionary:
        final surah = await SurahPickerDialog.show(
          context,
          title: 'لغت‌نامه سوره',
        );
        if (surah != null && context.mounted) {
          context.pushNamed(
            surahDictionaryRoute,
            pathParameters: {'id': surah.number.toString()},
            queryParameters: {'name': surah.nameFa},
          );
        }
        break;

      case QuickAccessToolType.downloads:
        context.pushNamed(downloadHubRoute);
        break;

      case QuickAccessToolType.topicStudio:
        // Temporarily commented out
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickAccessControllerProvider);
    final controller = ref.read(quickAccessControllerProvider.notifier);

    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtle Fixed-Height Header: Title + Edit Mode Switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SizedBox(
            height: 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'دسترسی سریع',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF5A554E),
                  ),
                ),
                const Spacer(),
                if (state.isEditMode)
                  InkWell(
                    onTap: () => controller.setEditMode(false),
                    borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          4.hSpace,
                          Text(
                            'اتمام ویرایش',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.setEditMode(true);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.pencil,
                            size: 13,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'شخصی‌سازی',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 4 Slots in a Clean Single Horizontal Row
        Row(
          children: List.generate(4, (index) {
            final tool = state.slots[index];
            final isPinnedSurah = tool?.type == QuickAccessToolType.pinnedSurah;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: QuickAccessSlotCard(
                  tool: tool,
                  isEditMode: state.isEditMode,
                  onTap: () {
                    if (tool == null) {
                      QuickAccessPickerBottomSheet.show(context, index);
                    } else if (state.isEditMode && isPinnedSurah) {
                      PinnedSurahPickerBottomSheet.show(
                        context,
                        slotIndex: index,
                      );
                    } else {
                      _handleToolTap(context, ref, tool);
                    }
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    controller.setEditMode(true);
                  },
                  onDelete: () {
                    HapticFeedback.lightImpact();
                    controller.removeSlot(index);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
