import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/widgets/app_theme_toggle_button.dart';
import '../../../../common/widgets/reciter/reciter_avatar_button.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/tab_navigation_controller.dart';

/// Modern Web Top Navigation Bar for Desktop / Laptop displays.
/// Features brand identity, global search pill (Ctrl+K), quick theme toggle,
/// reciter avatar, and direct actions.
class WebTopNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchTap;

  const WebTopNavBar({
    super.key,
    this.onSearchTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: isDark ? 0.90 : 0.96),
        border: Border(
          bottom: BorderSide(
            color: colors.cardBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Brand Logo & Title (Right in RTL)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appTitle.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'پرتال جامع قرآن کریم و تفکر',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 32),

          // 2. Global Universal Search Input Pill (Center)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (onSearchTap != null) {
                        onSearchTap!();
                      } else {
                        ref.read(tabNavigationControllerProvider.notifier).switchTab(2);
                      }
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF1EFEA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.cardBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.search,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'جستجو در سوره‌ها، آیات و ترجمه...',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Keyboard shortcut badge (Ctrl + K)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ctrl + K',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // 3. Right Action Tools (Theme, Reciter)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme Toggle
              const AppThemeToggleButton(),

              const SizedBox(width: 10),

              // Reciter Avatar selector
              const Tooltip(
                message: 'انتخاب قاری و صوت',
                child: ReciterAvatarButton(
                  radius: 17,
                  showLabel: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
