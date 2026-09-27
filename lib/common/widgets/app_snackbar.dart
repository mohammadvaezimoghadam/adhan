import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

class AppSnackBar {
  static void _show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Soft elegant slate capsule (identical calm tone in both light and dark mode)
    const backgroundColor = Color(0xFF2C2C2E);
    const borderColor = Color(0xFF3E3E42);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null || !messenger.mounted) return;

    try {
      messenger.hideCurrentSnackBar();
    } catch (_) {}

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        action: action,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderColor, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
      ),
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, action: action, duration: duration);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message,
      action: action,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message,
      action: action,
      duration: duration,
    );
  }
}
