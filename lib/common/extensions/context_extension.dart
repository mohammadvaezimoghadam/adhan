import 'package:flutter/material.dart';

import '../../core/theme/quran_theme_colors.dart';
import '../responsive/responsive_breakpoints.dart';

/// Context extension for clean, ergonomic, and theme-driven UI development.
extension ThemeContextExtension on BuildContext {
  /// Quick access to ThemeData
  ThemeData get theme => Theme.of(this);

  /// Quick access to ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to QuranThemeColors ThemeExtension (fallback to mode-appropriate defaults)
  QuranThemeColors get colors {
    final ext = Theme.of(this).extension<QuranThemeColors>();
    if (ext != null) return ext;
    return isDark ? QuranThemeColors.dark : QuranThemeColors.light;
  }

  /// Quick access to TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Whether current theme brightness is dark
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Quick access to MediaQueryData
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Quick access to Screen Size
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Screen Width
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen Height
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Screen padding (notch, bottom bar, etc.)
  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);

  // ── Responsive Helpers ──

  /// Whether the screen is wide enough for desktop/web layout (>= 768px)
  bool get isWideScreen => ResponsiveBreakpoints.isWideScreen(this);

  /// Maximum content width for the current screen size.
  /// On wide screens, content is constrained to avoid overly-long lines.
  double get contentMaxWidth => isWideScreen
      ? ResponsiveBreakpoints.maxContentWidth
      : screenWidth;
}

