import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../core/theme/app_typography.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ota_update/application/controllers/ota_update_controller.dart';

/// Clean Apple-styled Bottom Navigation Bar with Blur, Haptics, and Tafakor Mint accents.
class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final primaryColor = colorScheme.primary;
    final inactiveColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);
    // OTA Update badge
    final hasUpdate = ref.watch(hasOtaUpdateProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 60.0 + bottomPadding,
            padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 6.0,
              bottom: bottomPadding > 0 ? bottomPadding : 6.0,
            ),
            decoration: BoxDecoration(
              color: colors.cardBackground.withValues(alpha: isDark ? 0.88 : 0.94),
              border: Border(
                top: BorderSide(
                  color: colors.cardBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  label: 'خانه',
                  activeIcon: CupertinoIcons.house_fill,
                  inactiveIcon: CupertinoIcons.house,
                  primaryColor: primaryColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  label: 'سوره‌ها',
                  activeIcon: CupertinoIcons.book_fill,
                  inactiveIcon: CupertinoIcons.book,
                  primaryColor: primaryColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  label: 'جستجو',
                  activeIcon: CupertinoIcons.search,
                  inactiveIcon: CupertinoIcons.search,
                  primaryColor: primaryColor,
                  inactiveColor: inactiveColor,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  label: 'پروفایل',
                  activeIcon: CupertinoIcons.person_fill,
                  inactiveIcon: CupertinoIcons.person,
                  primaryColor: primaryColor,
                  inactiveColor: inactiveColor,
                  showBadge: hasUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color primaryColor,
    required Color inactiveColor,
    bool showBadge = false,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTabSelected(index);
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      size: 23,
                      color: isSelected ? primaryColor : inactiveColor,
                    ),
                    if (showBadge)
                      Positioned(
                        top: -7,
                        left: -18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'بروزرسانی',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? primaryColor : inactiveColor,
                    height: 1.1,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
