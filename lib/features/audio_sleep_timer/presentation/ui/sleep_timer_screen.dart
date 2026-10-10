import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_condition.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_controller.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_state.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_reader_controller.dart';
import '../../../quran_reader/domain/entities/ayah_entity.dart';
import '../../../surah_list/infrastructure/datasources/static_surahs_data.dart';

/// Minimal, serene Sleep Timer screen inspired by Spotify & Castbox.
/// Provides instant one-tap activation, zero clutter, and beautiful typography.
class SleepTimerScreen extends ConsumerStatefulWidget {
  final int? initialSurahId;
  final int? initialAyahNumber;

  const SleepTimerScreen({
    super.key,
    this.initialSurahId,
    this.initialAyahNumber,
  });

  /// Navigates to the Sleep Timer screen.
  static Future<void> open(
    BuildContext context, {
    int? initialSurahId,
    int? initialAyahNumber,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SleepTimerScreen(
          initialSurahId: initialSurahId,
          initialAyahNumber: initialAyahNumber,
        ),
      ),
    );
  }

  @override
  ConsumerState<SleepTimerScreen> createState() => _SleepTimerScreenState();
}

class _SleepTimerScreenState extends ConsumerState<SleepTimerScreen> {
  static const List<int> _presetMinutes = [5, 10, 15, 30, 45, 60];

  void _activateDurationTimer(int minutes) {
    HapticFeedback.mediumImpact();
    final duration = Duration(minutes: minutes);
    final condition = TimerCondition(
      duration: duration,
      targetEndTime: DateTime.now().add(duration),
    );

    ref.read(sleepTimerControllerProvider.notifier).activate(condition);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب روی ${minutes.toPersianDigit()} دقیقه فعال شد.',
      );
    }
  }

  void _activateEndOfSurah(int surahId) {
    HapticFeedback.mediumImpact();
    final condition = EndOfSurahCondition(surahId: surahId);
    ref.read(sleepTimerControllerProvider.notifier).activate(condition);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب تا پایان سوره ${surahId.surahNameFa} فعال شد.',
      );
    }
  }

  void _activateEndOfHizb(int hizb, int? hizbQuarter) {
    HapticFeedback.mediumImpact();
    final condition = EndOfHizbCondition(
      hizb: hizb,
      hizbQuarter: hizbQuarter,
    );
    ref.read(sleepTimerControllerProvider.notifier).activate(condition);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب تا پایان حزب ${hizb.toPersianDigit()} فعال شد.',
      );
    }
  }

  void _activateTargetAyah(int surahId, int ayahNumber) {
    HapticFeedback.mediumImpact();
    final condition = TargetAyahCondition(
      surahId: surahId,
      targetAyahNumber: ayahNumber,
    );
    ref.read(sleepTimerControllerProvider.notifier).activate(condition);

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب تا انتهای آیه ${ayahNumber.toPersianDigit()} فعال شد.',
      );
    }
  }

  void _cancelTimer() {
    HapticFeedback.lightImpact();
    ref.read(sleepTimerControllerProvider.notifier).cancel();

    if (mounted) {
      AppSnackBar.showInfo(
        context,
        'تایمر خواب غیرفعال شد.',
      );
    }
  }

  void _showCustomMinutesDialog(BuildContext context) {
    final textController = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'مدت زمان دلخواه',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مدت زمان تلاوت را به دقیقه وارد نمایید:',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              16.0.vSpace,
              Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    suffixText: 'دقیقه ',
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final clean = textController.text.trim().toEnglishDigit();
              final minutes = int.tryParse(clean);
              if (minutes != null && minutes > 0) {
                Navigator.of(dialogCtx).pop();
                _activateDurationTimer(minutes.clamp(1, 360));
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            child: const Text('فعال‌سازی'),
          ),
        ],
      ),
    );
  }

  void _showCustomAyahDialog(
    BuildContext context, {
    required int currentSurahId,
    required int currentAyah,
    required int totalAyahs,
    required String surahName,
  }) {
    final defaultTarget = (currentAyah + 5).clamp(currentAyah, totalAyahs);
    final textController = TextEditingController(text: defaultTarget.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'توقف در انتهای آیه',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سوره $surahName (آیه ۱ تا ${totalAyahs.toPersianDigit()})\nآیه در حال تلاوت: آیه ${currentAyah.toPersianDigit()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              16.0.vSpace,
              Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    prefixText: 'آیه ',
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              final clean = textController.text.trim().toEnglishDigit();
              final target = int.tryParse(clean);
              if (target != null && target >= 1 && target <= totalAyahs) {
                Navigator.of(dialogCtx).pop();
                _activateTargetAyah(currentSurahId, target);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            child: const Text('فعال‌سازی'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final timerState = ref.watch(sleepTimerControllerProvider);

    final audioState = ref.watch(quranAudioControllerProvider);
    final readerState = ref.watch(quranReaderControllerProvider);

    final currentSurahId = widget.initialSurahId ??
        audioState.currentSurahId ??
        readerState.currentSurahId;

    final currentAyah = widget.initialAyahNumber ??
        audioState.currentAyahNumber ??
        1;

    final totalAyahs = (currentSurahId >= 1 && currentSurahId <= 114)
        ? kStaticQuranSurahs[currentSurahId - 1].numberOfAyahs
        : 286;

    final surahName = currentSurahId.surahNameFa;

    final currentAyahEntity = readerState.ayahs
        .where((a) => a.ayahNumber == currentAyah)
        .firstOrNull;
    final currentHizb = currentAyahEntity?.hizb ?? 1;

    final cardBg = colors.cardBackground;
    final cardBorder = colors.cardBorder;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(
                bottom: BorderSide(
                  color: cardBorder,
                  width: 0.6,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'بازگشت',
                      icon: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 24,
                        color: colorScheme.onSurface,
                      ),
                      splashRadius: 22,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).maybePop();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'تایمر خواب تلاوت',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
            ),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          children: [
            // ── Hero Active Countdown Card (When timer is running) ──
            if (timerState.isActive) ...[
              _buildActiveHeroCard(
                timerState: timerState,
                surahName: surahName,
                cardBg: cardBg,
                colorScheme: colorScheme,
              ),
              20.0.vSpace,
            ],

            // ── Clean Grouped List of Sleep Timer Options ──
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardBorder,
                  width: 0.8,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Preset Minutes (5, 10, 15, 30, 45, 60)
                  ..._presetMinutes.asMap().entries.map((entry) {
                    final minutes = entry.value;
                    final isActive = _isMinutesActive(timerState, minutes);

                    return Column(
                      children: [
                        _buildOptionTile(
                          title: '${minutes.toPersianDigit()} دقیقه',
                          subtitle: 'توقف خودکار پس از گذشت ${minutes.toPersianDigit()} دقیقه',
                          isActive: isActive,
                          colorScheme: colorScheme,
                          onTap: () => _activateDurationTimer(minutes),
                        ),
                        _buildHairlineDivider(cardBorder),
                      ],
                    );
                  }),

                  // End of Surah
                  _buildOptionTile(
                    title: 'پایان سوره جاری',
                    subtitle: 'سوره $surahName',
                    isActive: _isEndOfSurahActive(timerState, currentSurahId),
                    colorScheme: colorScheme,
                    onTap: () => _activateEndOfSurah(currentSurahId),
                  ),
                  _buildHairlineDivider(cardBorder),

                  // End of Hizb
                  _buildOptionTile(
                    title: 'پایان حزب جاری',
                    subtitle: 'حزب ${currentHizb.toPersianDigit()}',
                    isActive: _isEndOfHizbActive(timerState, currentHizb),
                    colorScheme: colorScheme,
                    onTap: () => _activateEndOfHizb(
                      currentHizb,
                      currentAyahEntity?.hizbQuarter,
                    ),
                  ),
                  _buildHairlineDivider(cardBorder),

                  // Custom Minutes Option
                  _buildOptionTile(
                    title: 'مدت زمان دلخواه...',
                    subtitle: 'تعیین دستی تعداد دقیقه به انتخاب شما',
                    isActive: false,
                    colorScheme: colorScheme,
                    onTap: () => _showCustomMinutesDialog(context),
                  ),
                  _buildHairlineDivider(cardBorder),

                  // Custom Ayah Option
                  _buildOptionTile(
                    title: 'تا انتهای آیه مشخص...',
                    subtitle: 'توقف در آیه دلخواه از سوره $surahName',
                    isActive: timerState.activeCondition is TargetAyahCondition,
                    colorScheme: colorScheme,
                    onTap: () => _showCustomAyahDialog(
                      context,
                      currentSurahId: currentSurahId,
                      currentAyah: currentAyah,
                      totalAyahs: totalAyahs,
                      surahName: surahName,
                    ),
                  ),
                ],
              ),
            ),

            14.0.vSpace,

            // ── Serene Bottom Note ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'صوت در میانه آیه قطع نمی‌شود؛ ابتدا تلاوت آیه جاری به طور کامل تمام شده و سپس پخش خودکار متوقف می‌گردد.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),

            24.0.vSpace,
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helper Components: Hero Countdown Card & Clean List Tiles
  // ─────────────────────────────────────────────────────────────

  Widget _buildActiveHeroCard({
    required SleepTimerState timerState,
    required String surahName,
    required Color cardBg,
    required ColorScheme colorScheme,
  }) {
    final condition = timerState.activeCondition;

    String? digitalClock;
    String statusTitle = '';
    double? progress;

    if (condition is TimerCondition) {
      final rem = timerState.remainingTime ?? Duration.zero;
      final m = rem.inMinutes.toString().padLeft(2, '0');
      final s = (rem.inSeconds % 60).toString().padLeft(2, '0');
      digitalClock = '$m:$s'.toPersianDigit();
      statusTitle = 'زمان باقی‌مانده تا توقف تلاوت';

      final totalSec = condition.duration.inSeconds > 0
          ? condition.duration.inSeconds
          : (rem.inSeconds > 0 ? rem.inSeconds : 1);
      progress = (1.0 - (rem.inSeconds / totalSec)).clamp(0.0, 1.0);
    } else if (condition is EndOfSurahCondition) {
      statusTitle = 'توقف در پایان سوره $surahName فعال است';
    } else if (condition is EndOfHizbCondition) {
      statusTitle = 'توقف در پایان حزب ${condition.hizb.toPersianDigit()} فعال است';
    } else if (condition is TargetAyahCondition) {
      statusTitle =
          'توقف در انتهای آیه ${condition.targetAyahNumber.toPersianDigit()} سوره $surahName فعال است';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
              ),
              8.0.hSpace,
              Text(
                'تایمر خواب فعال است',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          8.0.vSpace,
          if (digitalClock != null) ...[
            Text(
              digitalClock,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: colorScheme.primary,
              ),
            ),
            2.0.vSpace,
            Text(
              statusTitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            12.0.vSpace,
            if (progress != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4.5,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  color: colorScheme.primary,
                ),
              ),
          ] else ...[
            Text(
              statusTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
          10.0.vSpace,
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _cancelTimer,
            child: const Text(
              'خاموش کردن تایمر',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool isActive,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                    3.0.vSpace,
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: isActive
                            ? colorScheme.primary.withValues(alpha: 0.8)
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 20,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHairlineDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 18,
      endIndent: 0,
      color: borderColor.withValues(alpha: 0.7),
    );
  }

  bool _isMinutesActive(SleepTimerState timerState, int minutes) {
    final condition = timerState.activeCondition;
    if (condition is TimerCondition) {
      return condition.duration.inMinutes == minutes;
    }
    return false;
  }

  bool _isEndOfSurahActive(SleepTimerState timerState, int surahId) {
    final condition = timerState.activeCondition;
    if (condition is EndOfSurahCondition) {
      return condition.surahId == surahId;
    }
    return false;
  }

  bool _isEndOfHizbActive(SleepTimerState timerState, int hizb) {
    final condition = timerState.activeCondition;
    if (condition is EndOfHizbCondition) {
      return condition.hizb == hizb;
    }
    return false;
  }
}
