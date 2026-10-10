import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/quick_access_tool_entity.dart';

class QuickAccessSlotCard extends ConsumerStatefulWidget {
  final QuickAccessToolEntity? tool;
  final String? subtitle;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const QuickAccessSlotCard({
    super.key,
    required this.tool,
    this.subtitle,
    required this.isEditMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  ConsumerState<QuickAccessSlotCard> createState() =>
      _QuickAccessSlotCardState();
}

class _QuickAccessSlotCardState extends ConsumerState<QuickAccessSlotCard>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _badgeController;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();

    // 1. Gentle initial wiggle/shake animation on entering edit mode
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -0.005)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.005, end: 0.005)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.005, end: -0.0035)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.0035, end: 0.002)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.002, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_shakeController);

    // 2. Smooth scale animation for the delete 'X' badge
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isEditMode ? 1.0 : 0.0,
    );

    _badgeScale = CurvedAnimation(
      parent: _badgeController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    if (widget.isEditMode) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(QuickAccessSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEditMode && !oldWidget.isEditMode) {
      // Trigger subtle shake and scale in the badge
      _shakeController.forward(from: 0.0);
      _badgeController.forward();
    } else if (!widget.isEditMode && oldWidget.isEditMode) {
      _badgeController.reverse();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colors = context.colors;
    final colorScheme = context.colorScheme;

    final isEmpty = widget.tool == null;
    final isTopicStudio = widget.tool?.type == QuickAccessToolType.topicStudio;

    final cardBgColor = isDark
        ? (isEmpty ? Colors.white.withValues(alpha: 0.025) : colors.cardBackground)
        : (isEmpty ? colors.cardBackgroundSubtle : colors.cardBackground);

    final cardBorderColor = isDark
        ? (isEmpty
            ? Colors.white.withValues(alpha: 0.06)
            : (widget.isEditMode
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colors.cardBorder))
        : (isEmpty
            ? colors.cardBorder
            : (widget.isEditMode
                ? colorScheme.primary.withValues(alpha: 0.50)
                : colors.cardBorder));

    return RotationTransition(
      turns: _shakeAnimation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base Slot Card Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 84,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTopicStudio
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.20)
                        : colorScheme.primary.withValues(alpha: 0.35))
                    : cardBorderColor,
                width: 0.8,
              ),
              image: isTopicStudio
                  ? DecorationImage(
                      image: const AssetImage(AppConstants.splashBgAsset),
                      fit: BoxFit.cover,
                      colorFilter: isDark
                          ? ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.50),
                              BlendMode.darken,
                            )
                          : null,
                    )
                  : null,
              boxShadow: (!isDark && !isEmpty)
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10.0,
                        offset: const Offset(0, 2.0),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
              child: InkWell(
                onTap: widget.isEditMode ? null : widget.onTap,
                onLongPress: widget.onLongPress,
                borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isEmpty) ...[
                          Icon(
                            CupertinoIcons.plus,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF9E998F),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'افزودن',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF9E998F),
                            ),
                          ),
                        ] else if (widget.tool!.isSurah) ...[
                          // Clean Surah-Only Card: NO ICON, beautiful Surah typography
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: isDark ? 0.16 : 0.09,
                              ),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              'سوره ${widget.tool!.surahId.toString().toPersianDigit()}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          4.vSpace,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.tool!.surahId != null
                                    ? widget.tool!.surahId!.surahNameFa
                                    : (widget.tool!.surahName ?? widget.tool!.title)
                                        .replaceAll('سورة', '')
                                        .replaceAll('سوره', '')
                                        .trim(),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2C2A29),
                                ),
                              ),
                            ),
                          ),
                          if (widget.tool!.ayahCount != null) ...[
                            2.vSpace,
                            Text(
                              '${widget.tool!.ayahCount.toString().toPersianDigit()} آیه',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ] else if (isTopicStudio) ...[
                          // Topic Studio: Soft feathered glow fading seamlessly into transparency (like splash screen)
                          SizedBox(
                            height: 24,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 6),
                                  child: Container(
                                    width: 48,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white.withValues(alpha: 0.92),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          blurRadius: 10,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  'تفکر',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          6.vSpace,
                          Text(
                            widget.tool!.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : const Color(0xFF2C2A29),
                              shadows: [
                                Shadow(
                                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Icon(
                            widget.tool!.iconData ?? CupertinoIcons.star,
                            color: colorScheme.primary,
                            size: widget.subtitle != null ? 22 : 26,
                          ),
                          (widget.subtitle != null ? 3.0 : 8.0).vSpace,
                          if (widget.subtitle != null) ...[
                            Text(
                              widget.tool!.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF6E685F),
                              ),
                            ),
                            2.vSpace,
                            Text(
                              widget.subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ] else ...[
                            Text(
                              widget.tool!.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF2C2A29),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Clean Overlaid Delete Badge (×) Placed Directly On The Card Corner
          if (!isEmpty)
            Positioned(
              top: 6,
              right: 6,
              child: ScaleTransition(
                scale: _badgeScale,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
