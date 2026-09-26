import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

/// A convenience widget that renders different layouts based on
/// the current screen width.
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileHomeScreen(),
///   desktop: DesktopHomeScreen(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  /// Widget rendered on mobile-sized screens (< 768px).
  final Widget mobile;

  /// Widget rendered on desktop/web/tablet-landscape screens (>= 768px).
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          return desktop;
        }
        return mobile;
      },
    );
  }
}
