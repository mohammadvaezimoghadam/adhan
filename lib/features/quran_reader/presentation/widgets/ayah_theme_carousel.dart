import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/ayah_theme_entity.dart';

/// Horizontal Telegram-style Color Themes Carousel for Ayah Backgrounds.
class AyahThemeCarousel extends StatelessWidget {
  final String selectedThemeId;
  final ValueChanged<String> onThemeSelected;

  const AyahThemeCarousel({
    super.key,
    required this.selectedThemeId,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themes = AyahThemePresets.all;

    return SizedBox(
      height: 124.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        itemCount: themes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = theme.id == selectedThemeId;

          return _buildThemeCard(
            context: context,
            theme: theme,
            isSelected: isSelected,
            colorScheme: colorScheme,
          );
        },
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required AyahThemeEntity theme,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    final activeBorderColor = colorScheme.primary;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onThemeSelected(theme.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 82.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Card Preview (Thumbnail with Image Overlay) ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 80.0,
              height: 92.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isSelected
                      ? activeBorderColor.withValues(alpha: 0.80)
                      : theme.borderColor.withValues(alpha: 0.18),
                  width: isSelected ? 1.2 : 0.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeBorderColor.withValues(alpha: 0.18),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 3.0,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Base theme color / gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.evenColor,
                            theme.oddColor,
                          ],
                        ),
                      ),
                    ),

                    // 2. Texture Image Overlay (using ayah_card_bg.png)
                    Opacity(
                      opacity: theme.isDark ? 0.12 : 0.20,
                      child: Image.asset(
                        theme.previewAsset,
                        fit: BoxFit.cover,
                        colorBlendMode: BlendMode.dstIn,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),

                    // 3. Simple Minimalist Mock Ayah Preview (Clean floating lines, no heavy nested container)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 3.5,
                            width: 38.0,
                            decoration: BoxDecoration(
                              color: theme.isDark
                                  ? Colors.white.withValues(alpha: 0.70)
                                  : const Color(0xFF2C3E3A).withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(2.0),
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 3.5,
                                width: 22.0,
                                decoration: BoxDecoration(
                                  color: theme.isDark
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : const Color(0xFF2C3E3A).withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Container(
                                width: 7.0,
                                height: 7.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.headerTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 4. Selected Checkmark Indicator (Telegram style floating badge)
                    if (isSelected)
                      Positioned(
                        top: 5.0,
                        right: 5.0,
                        child: Container(
                          width: 17.0,
                          height: 17.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeBorderColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 3.0,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.checkmark,
                              size: 10.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6.0),

            // ── Theme Name Label ──
            Text(
              theme.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? activeBorderColor
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
