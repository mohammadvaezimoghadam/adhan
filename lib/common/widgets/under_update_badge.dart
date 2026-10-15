import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Reusable Apple-styled minimal neutral badge indicating a feature is "به‌زودی".
class UnderUpdateBadge extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final double? size;
  final double? iconSize;

  const UnderUpdateBadge({
    super.key,
    this.text = 'به‌زودی',
    this.fontSize = 9.5,
    this.padding,
    this.size,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 2,
          ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          height: 1.2,
        ),
      ),
    );
  }
}
