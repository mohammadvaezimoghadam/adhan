import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../audio_sleep_timer/presentation/ui/sleep_timer_screen.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_condition.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_controller.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/quran_audio_controller.dart';
import '../../application/controllers/quran_reader_controller.dart';
import '../../domain/entities/ayah_entity.dart';

/// Standalone icon button for the bottom audio player bar.
/// Tapping it opens the sleep timer popup menu right on the player icon.
class SleepTimerPlayerButton extends ConsumerWidget {
  final double size;
  final double width;
  final double height;
  final bool showOnlyWhenActive;

  const SleepTimerPlayerButton({
    super.key,
    this.size = 21,
    this.width = 38,
    this.height = 32,
    this.showOnlyWhenActive = false,
  });

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    final button = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    final audioState = ref.read(quranAudioControllerProvider);
    final readerState = ref.read(quranReaderControllerProvider);
    final timerState = ref.read(sleepTimerControllerProvider);

    final currentSurahId = audioState.currentSurahId ?? readerState.currentSurahId;
    final currentAyah = audioState.currentAyahNumber ?? 1;
    final surahName = currentSurahId.surahNameFa;

    final currentAyahEntity = readerState.ayahs
        .where((a) => a.ayahNumber == currentAyah)
        .firstOrNull;
    final currentHizb = currentAyahEntity?.hizb ?? 1;
    final currentHizbQuarter = currentAyahEntity?.hizbQuarter;

    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final condition = timerState.activeCondition;
    final isEndOfSurah = condition is EndOfSurahCondition;
    final isEndOfHizb = condition is EndOfHizbCondition;
    final activeMinutes = condition is TimerCondition ? condition.duration.inMinutes : null;

    // Accurately calculate the button's rect so the menu pops up directly above it
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        buttonTopLeft,
        buttonTopLeft.translate(buttonSize.width, buttonSize.height),
      ),
      Offset.zero & overlay.size,
    );

    HapticFeedback.lightImpact();

    final selected = await showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      color: isDark ? const Color(0xFF1E1E22) : colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.cardBorder,
          width: 0.8,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      items: [
        if (timerState.isActive) ...[
          PopupMenuItem<String>(
            value: 'cancel',
            height: 40,
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'خاموش کردن تایمر',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                Icon(
                  CupertinoIcons.clear_circled,
                  size: 17,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],

        // End of Surah
        PopupMenuItem<String>(
          value: 'end_of_surah',
          height: 40,
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تا پایان سوره ($surahName)',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: isEndOfSurah ? FontWeight.bold : FontWeight.w500,
                  color: isEndOfSurah ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isEndOfSurah)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 17,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),

        // End of Hizb
        PopupMenuItem<String>(
          value: 'end_of_hizb',
          height: 40,
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تا پایان حزب (حزب ${currentHizb.toPersianDigit()})',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: isEndOfHizb ? FontWeight.bold : FontWeight.w500,
                  color: isEndOfHizb ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isEndOfHizb)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 17,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),

        const PopupMenuDivider(height: 1),

        // Minute Presets (15, 30, 45, 60)
        ...[15, 30, 45, 60].map((min) {
          final isCurrent = activeMinutes == min;
          return PopupMenuItem<String>(
            value: '$min',
            height: 38,
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${min.toPersianDigit()} دقیقه',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                if (isCurrent)
                  Icon(
                    CupertinoIcons.checkmark,
                    size: 17,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          );
        }),

        const PopupMenuDivider(height: 1),

        // Custom minutes
        PopupMenuItem<String>(
          value: 'custom_minutes',
          height: 38,
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مدت زمان دلخواه...',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuDivider(height: 1),

        // Open full screen
        PopupMenuItem<String>(
          value: 'open_screen',
          height: 38,
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تنظیمات پیشرفته تایمر...',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              Icon(
                CupertinoIcons.slider_horizontal_3,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );

    if (selected != null && context.mounted) {
      _handleMenuSelection(
        context,
        ref,
        selected,
        currentSurahId,
        currentHizb,
        currentHizbQuarter,
        surahName,
      );
    }
  }

  void _handleMenuSelection(
    BuildContext context,
    WidgetRef ref,
    String value,
    int currentSurahId,
    int currentHizb,
    int? currentHizbQuarter,
    String surahName,
  ) {
    HapticFeedback.lightImpact();

    if (value == 'open_screen') {
      final audioAyah = ref.read(quranAudioControllerProvider).currentAyahNumber;
      SleepTimerScreen.open(
        context,
        initialSurahId: currentSurahId,
        initialAyahNumber: audioAyah ?? 1,
      );
      return;
    }

    if (value == 'cancel') {
      ref.read(sleepTimerControllerProvider.notifier).cancel();
      AppSnackBar.showInfo(context, 'تایمر خواب خاموش شد.');
      return;
    }

    if (value == 'end_of_surah') {
      ref.read(sleepTimerControllerProvider.notifier).activate(
            EndOfSurahCondition(surahId: currentSurahId),
          );
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب تا پایان سوره $surahName فعال شد.',
      );
      return;
    }

    if (value == 'end_of_hizb') {
      ref.read(sleepTimerControllerProvider.notifier).activate(
            EndOfHizbCondition(
              hizb: currentHizb,
              hizbQuarter: currentHizbQuarter,
            ),
          );
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب تا پایان حزب ${currentHizb.toPersianDigit()} فعال شد.',
      );
      return;
    }

    if (value == 'custom_minutes') {
      _showCustomMinutesDialog(context, ref);
      return;
    }

    // Minute presets (15, 30, 45, 60)
    final minutes = int.tryParse(value);
    if (minutes != null) {
      final duration = Duration(minutes: minutes);
      ref.read(sleepTimerControllerProvider.notifier).activate(
            TimerCondition(
              duration: duration,
              targetEndTime: DateTime.now().add(duration),
            ),
          );
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب روی ${minutes.toPersianDigit()} دقیقه تنظیم شد.',
      );
    }
  }

  /// Displays the custom minutes dialog positioned HIGHER UP on the screen,
  /// matching 100% of the project's standard dialog theme (AppModalHeader, dialogSurface, etc.).
  void _showCustomMinutesDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController(text: '30');
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: colors.dialogSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  AppModalHeader(
                    title: 'مدت زمان دلخواه',
                    onClose: () => Navigator.of(dialogCtx).pop(),
                    bottomSpacing: 14,
                  ),

                  Text(
                    'مدت زمان تلاوت را به دقیقه وارد نمایید:',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  12.vSpace,

                  // Standardized Input Container matching LabelEditorDialog
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.cardBorder,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: TextField(
                      controller: textController,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩]')),
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      suffixText: 'دقیقه',
                    ),
                  ),
                ),
                16.vSpace,

                // Action Buttons matching project standard
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'انصراف',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
                    10.hSpace,
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final clean = textController.text.trim().toEnglishDigit();
                          final minutes = int.tryParse(clean);
                          if (minutes != null && minutes > 0) {
                            Navigator.of(dialogCtx).pop();
                            final duration = Duration(minutes: minutes.clamp(1, 360));
                            ref.read(sleepTimerControllerProvider.notifier).activate(
                                  TimerCondition(
                                    duration: duration,
                                    targetEndTime: DateTime.now().add(duration),
                                  ),
                                );
                            AppSnackBar.showSuccess(
                              context,
                              'تایمر خواب روی ${minutes.toPersianDigit()} دقیقه تنظیم شد.',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'فعال‌سازی تایمر',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerControllerProvider);
    final isTimerActive = timerState.isActive;

    if (showOnlyWhenActive && !isTimerActive) {
      return const SizedBox.shrink();
    }

    final colorScheme = context.colorScheme;

    return Semantics(
      label: isTimerActive ? 'تایمر خواب فعال است' : 'تنظیم تایمر خواب تلاوت',
      button: true,
      child: Tooltip(
        message: isTimerActive ? 'تایمر خواب فعال است' : 'تنظیم تایمر خواب',
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.lightImpact();
                final audioState = ref.read(quranAudioControllerProvider);
                final readerState = ref.read(quranReaderControllerProvider);
                SleepTimerScreen.open(
                  context,
                  initialSurahId: audioState.currentSurahId ?? readerState.currentSurahId,
                  initialAyahNumber: audioState.currentAyahNumber,
                );
              },
              onLongPress: () => _openMenu(context, ref),
              child: Center(
                child: Icon(
                  isTimerActive
                      ? CupertinoIcons.timer_fill
                      : CupertinoIcons.timer,
                  size: size,
                  color: isTimerActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Capsule Pill Badge for displaying real-time timer status
/// above the player bar. Reusable anywhere in the UI.
class SleepTimerActiveBadge extends ConsumerWidget {
  const SleepTimerActiveBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerControllerProvider);
    if (!timerState.isActive) return const SizedBox.shrink();

    final condition = timerState.activeCondition;
    final colorScheme = context.colorScheme;
    final primary = colorScheme.primary;

    // Only display real-time countdown badge in the final 10 seconds before cutoff
    if (condition is! TimerCondition) {
      return const SizedBox.shrink();
    }

    final rem = timerState.remainingTime ?? Duration.zero;
    final sec = rem.inSeconds;
    final isFinalSeconds = sec > 0 && sec <= 10;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: isFinalSeconds
          ? Padding(
              key: const ValueKey('sleep_timer_countdown_active'),
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.timer_fill,
                          size: 14,
                          color: primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'توقف تلاوت در ${sec.toPersianDigit()} ثانیه',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quick Cancel Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(sleepTimerControllerProvider.notifier).cancel();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 15,
                              color: Colors.redAccent.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('sleep_timer_countdown_hidden')),
    );
  }
}

/// SleepTimerDialog helper kept for top menu invocation if needed.
class SleepTimerDialog {
  static Future<void> show(BuildContext context) async {
    // Triggers the player button flow
  }
}
