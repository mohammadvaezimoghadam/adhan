import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// Media selection type from the compact attachment popup
enum TopicAttachmentType {
  image,
  video,
}

/// A compact ChatGPT-style attachment popup anchored directly above the button.
class TopicMediaPickerSheet extends StatelessWidget {
  const TopicMediaPickerSheet({super.key});

  /// Displays the compact popup anchored right at the button location
  static Future<TopicAttachmentType?> show(
    BuildContext context, {
    GlobalKey? anchorKey,
  }) {
    HapticFeedback.lightImpact();

    RenderBox? renderBox;
    if (anchorKey?.currentContext != null) {
      renderBox = anchorKey!.currentContext!.findRenderObject() as RenderBox?;
    } else {
      renderBox = context.findRenderObject() as RenderBox?;
    }

    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? const Size(38, 38);

    const double popupWidth = 148.0;
    const double popupHeight = 104.0;

    return showGeneralDialog<TopicAttachmentType>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 170),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        final screenSize = MediaQuery.sizeOf(ctx);

        // Position comfortably above the button with a 12px gap
        double top = offset.dy - popupHeight - 12;
        if (top < MediaQuery.paddingOf(ctx).top + 16) {
          top = offset.dy + size.height + 12;
        }

        // Align right edge in RTL
        double left = offset.dx + size.width - popupWidth;
        if (left < 16) left = 16;
        if (left + popupWidth > screenSize.width - 16) {
          left = screenSize.width - popupWidth - 16;
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: const TopicMediaPickerSheet(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colorScheme = context.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222226) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFE5E5EA),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option 1: Image (Solid filled photo icon matching CupertinoIcons.videocam)
              _buildCompactOption(
                context: context,
                isDark: isDark,
                colorScheme: colorScheme,
                icon: CupertinoIcons.photo_fill,
                iconSize: 17,
                title: 'تصویر',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(TopicAttachmentType.image);
                },
              ),

              4.vSpace,

              // Option 2: Video (CupertinoIcons.videocam)
              _buildCompactOption(
                context: context,
                isDark: isDark,
                colorScheme: colorScheme,
                icon: CupertinoIcons.videocam,
                iconSize: 19,
                title: 'ویدیو',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(TopicAttachmentType.video);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactOption({
    required BuildContext context,
    required bool isDark,
    required ColorScheme colorScheme,
    required IconData icon,
    required double iconSize,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              // Circular icon container matching the action button style
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF2F2F7),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFE5E5EA),
                    width: 0.9,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

              10.hSpace,

              // Title (no arrows, no dividers)
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
