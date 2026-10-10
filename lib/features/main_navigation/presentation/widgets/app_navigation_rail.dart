import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../core/theme/app_typography.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ota_update/application/controllers/ota_update_controller.dart';

/// Apple-inspired vertical NavigationRail for desktop/web layout.
/// Glassmorphic styling matching the existing BottomNavBar aesthetic.
class AppNavigationRail extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    // OTA Update badge
    final hasUpdate = ref.watch(hasOtaUpdateProvider);

    final primaryColor = colorScheme.primary;
    final inactiveColor =
        isDark ? const Color(0xFF8E8E93) : const Color(0xFF8A8A8E);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 80,
            decoration: BoxDecoration(
              color: colors.cardBackground
                  .withValues(alpha: isDark ? 0.88 : 0.94),
              border: Border(
                left: BorderSide(
                  color: colors.cardBorder,
                  width: 0.8,
                ),
              ),
            ),
            child: SafeArea(
              right: false,
              left: false,
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Navigation Items
                  _buildNavItem(
                    context: context,
                    index: 0,
                    label: 'خانه',
                    activeIcon: CupertinoIcons.house_fill,
                    inactiveIcon: CupertinoIcons.house,
                    primaryColor: primaryColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    label: 'سوره‌ها',
                    activeIcon: CupertinoIcons.book_fill,
                    inactiveIcon: CupertinoIcons.book,
                    primaryColor: primaryColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    label: 'جستجو',
                    activeIcon: CupertinoIcons.search,
                    inactiveIcon: CupertinoIcons.search,
                    primaryColor: primaryColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 4),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    label: 'پروفایل',
                    activeIcon: CupertinoIcons.person_fill,
                    inactiveIcon: CupertinoIcons.person,
                    primaryColor: primaryColor,
                    inactiveColor: inactiveColor,
                    isDark: isDark,
                    showBadge: hasUpdate,
                  ),

                  const Spacer(),
                ],
              ),
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
    required bool isDark,
    bool showBadge = false,
  }) {
    final isSelected = currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTabSelected(index);
            },
            borderRadius: BorderRadius.circular(12),
            hoverColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            splashColor: primaryColor.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    size: 26,
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
            ),
          ),
        ),
      ),
    );
  }
}
