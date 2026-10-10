import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/ota_update_controller.dart';
import '../../application/controllers/ota_update_state.dart';

/// Modal dialog for OTA Hot Update prompt, download progress, and restart notification.
class OtaUpdateDialog extends ConsumerWidget {
  final bool isForce;

  const OtaUpdateDialog({
    super.key,
    this.isForce = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    bool isForce = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isForce,
      builder: (_) => OtaUpdateDialog(isForce: isForce),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otaState = ref.watch(otaUpdateControllerProvider);
    final controller = ref.read(otaUpdateControllerProvider.notifier);

    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final patch = otaState.patch;

    final isMandatory = isForce || (patch?.isForce == true);

    return PopScope(
      canPop: !isMandatory && !otaState.isDownloading,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppModalHeader(
                  title: patch?.isNativeApk == true
                      ? 'ارتقای نسخه نرم‌افزار (APK)'
                      : 'به‌روزرسانی نرم‌افزار',
                  onClose: (isMandatory || otaState.isDownloading)
                      ? null
                      : () {
                          controller.dismissUpdate();
                          Navigator.of(context).pop(false);
                        },
                  showDragHandle: false,
                  showDivider: true,
                  bottomSpacing: 14,
                ),

                // Simple Minimal Version Header (بدون آیکون و رنگ‌های تند)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patch?.isNativeApk == true
                          ? 'نسخه نصبی: ${patch?.version ?? ""}'
                          : 'نسخه جدید: ${patch?.version ?? ""}',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (isMandatory) ...[
                      4.vSpace,
                      Text(
                        'این به‌روزرسانی الزامی است.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    if (patch?.formattedSize.isNotEmpty == true) ...[
                      4.vSpace,
                      Text(
                        'حجم بسته: ${patch!.formattedSize}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),

                14.vSpace,

                // Release notes (if any)
                if (patch != null && patch.releaseNotes.isNotEmpty) ...[
                  Text(
                    'تغییرات این نسخه:',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  6.vSpace,
                  Container(
                    constraints: const BoxConstraints(maxHeight: 110),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        patch.releaseNotes,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  14.vSpace,
                ],

                // Download Progress View
                if (otaState.isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: otaState.progress > 0 ? otaState.progress : null,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      minHeight: 7,
                    ),
                  ),
                  8.vSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPhaseDescription(otaState.status),
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (otaState.progress > 0)
                        Text(
                          '${(otaState.progress * 100).toInt().toPersianDigit()}٪',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  14.vSpace,
                ],

                // Ready to restart message
                if (otaState.isReadyToRestart) ...[
                  Text(
                    'به‌روزرسانی با موفقیت دریافت شد. برنامه جهت اعمال تغییرات مجدداً راه‌اندازی می‌شود.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  14.vSpace,
                ],

                // Error message
                if (otaState.errorMessage != null) ...[
                  Text(
                    otaState.errorMessage!,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      color: colorScheme.error,
                    ),
                  ),
                  14.vSpace,
                ],

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isMandatory &&
                        !otaState.isDownloading &&
                        !otaState.isReadyToRestart) ...[
                      TextButton(
                        onPressed: () {
                          controller.dismissUpdate();
                          Navigator.of(context).pop(false);
                        },
                        child: Text(
                          'بعداً',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      10.hSpace,
                    ],
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: otaState.isDownloading
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              if (otaState.isReadyToRestart) {
                                await OtaUpdateController.restartApp();
                              } else if (otaState.patch?.isNativeApk == true) {
                                await controller.startDownloadAndApply();
                                if (!isMandatory && context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } else {
                                final success =
                                    await controller.startDownloadAndApply();
                                if (success) {
                                  if (isMandatory) {
                                    await Future.delayed(
                                        const Duration(milliseconds: 600));
                                    await OtaUpdateController.restartApp();
                                  } else {
                                    if (context.mounted) {
                                      Navigator.of(context).pop(true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'به‌روزرسانی با موفقیت دریافت شد و در اجرای بعدی اعمال خواهد شد.',
                                            style: TextStyle(
                                              fontFamily: AppTypography.fontFamily,
                                            ),
                                          ),
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            },
                      child: Text(
                        _getButtonLabel(otaState),
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPhaseDescription(OtaStatus status) {
    switch (status) {
      case OtaStatus.downloading:
        return 'در حال دانلود بسته به‌روزرسانی...';
      case OtaStatus.verifying:
        return 'در حال اعتبارسنجی هش و سلامت فایل...';
      case OtaStatus.finalizing:
        return 'در حال آماده‌سازی و نصب پچ...';
      default:
        return 'در حال پردازش...';
    }
  }

  String _getButtonLabel(OtaUpdateState state) {
    if (state.isReadyToRestart) {
      return 'راه‌اندازی مجدد برنامه';
    }
    if (state.isDownloading) {
      return 'در حال دانلود...';
    }
    if (state.errorMessage != null) {
      return 'تلاش مجدد';
    }
    if (state.patch?.isNativeApk == true) {
      return 'دانلود و نصب مستقیم فایل APK';
    }
    return 'دریافت و اعمال پچ';
  }
}
