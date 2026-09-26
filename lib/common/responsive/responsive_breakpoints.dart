import 'package:flutter/material.dart';

/// Centralized responsive breakpoint definitions.
/// All responsive decisions throughout the app should use these constants
/// for consistency.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Mobile: 0 – 767px
  static const double mobile = 0;

  /// Tablet / Desktop / Web: 768px+
  static const double desktop = 768;

  /// Large Desktop: 1200px+
  static const double largeDesktop = 1200;

  /// Navigation Rail width for desktop layout
  static const double railWidth = 80.0;

  /// Maximum content width on wide screens
  static const double maxContentWidth = 720.0;

  /// Check if current screen is wide (desktop/web/tablet landscape)
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktop;
  }

  /// Check if current screen is mobile-sized
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < desktop;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= largeDesktop;
  }
}
