import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/quick_access_controller.dart';
import '../../domain/entities/quick_access_tool_entity.dart';
import 'pinned_surah_picker_bottom_sheet.dart';

class QuickAccessPickerBottomSheet extends ConsumerWidget {
  final int slotIndex;

  const QuickAccessPickerBottomSheet({
    super.key,
    required this.slotIndex,
  });

  static Future<void> show(BuildContext context, int slotIndex) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAccessPickerBottomSheet(slotIndex: slotIndex),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final colors = context.colors;
    final colorScheme = context.colorScheme;

    final controller = ref.read(quickAccessControllerProvider.notifier);
    final availableTools = controller.getAvailableToolsForPicker();

    return Container(
      decoration: BoxDecoration(
        color: colors.dialogSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppModalHeader(
              showDragHandle: true,
              bottomSpacing: 12.0,
              title: 'انتخاب ابزار برای این جایگاه',
            ),

            if (availableTools.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'تمام ابزارهای در دسترس هم‌اکنون در جایگاه‌ها قرار دارند.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableTools.length,
                separatorBuilder: (context, index) => 6.vSpace,
                itemBuilder: (context, index) {
                  final tool = availableTools[index];
                  final isTopic = tool.type == QuickAccessToolType.topicStudio;

                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      if (tool.type == QuickAccessToolType.pinnedSurah) {
                        PinnedSurahPickerBottomSheet.show(
                          context,
                          slotIndex: slotIndex,
                        );
                      } else {
                        await controller.assignToolToSlot(slotIndex, tool.type);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 8.0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colorScheme.primary
                                  .withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                              image: isTopic
                                  ? DecorationImage(
                                      image: const AssetImage(AppConstants.splashBgAsset),
                                      fit: BoxFit.cover,
                                      colorFilter: isDark
                                          ? ColorFilter.mode(
                                              Colors.black.withValues(alpha: 0.45),
                                              BlendMode.darken,
                                            )
                                          : null,
                                    )
                                  : null,
                            ),
                            child: isTopic
                                ? Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ImageFiltered(
                                          imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 5),
                                          child: Container(
                                            width: 32,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.90),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.90),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'تفکر',
                                          style: TextStyle(
                                            fontFamily: AppTypography.fontFamily,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white : AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Icon(
                                    tool.iconData,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                          ),
                          14.hSpace,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      tool.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (!tool.isReady) ...[
                                      8.hSpace,
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6.0,
                                          vertical: 2.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                                        ),
                                        child: const Text(
                                          'به‌زودی',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                4.vSpace,
                                Text(
                                  tool.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_left,
                            size: 16,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
