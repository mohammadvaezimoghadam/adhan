import 'dart:async';

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
import '../../../../core/services/audio/sleep_timer/sleep_timer_condition.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_controller.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_state.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_reader_controller.dart';
import '../../../quran_reader/domain/entities/ayah_entity.dart';
import '../../../surah_list/infrastructure/datasources/static_surahs_data.dart';

/// Serene, luxury Sleep Timer screen strictly aligned with the app's sacred theme.
/// Provides one-tap minute presets, Quranic boundary stops, active hero countdown,
/// and infrastructure for future intelligent sleep features (Fade-out, Shake to extend).
class SleepTimerScreen extends ConsumerStatefulWidget {
  final int? initialSurahId;
  final int? initialAyahNumber;

  const SleepTimerScreen({
    super.key,
    this.initialSurahId,
    this.initialAyahNumber,
  });

  /// Opens the Sleep Timer bottom sheet modal.
  static Future<void> show(
    BuildContext context, {
    int? initialSurahId,
    int? initialAyahNumber,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => SleepTimerScreen(
        initialSurahId: initialSurahId,
        initialAyahNumber: initialAyahNumber,
      ),
    );
  }

  static Future<void> open(
    BuildContext context, {
    int? initialSurahId,
    int? initialAyahNumber,
  }) => show(context, initialSurahId: initialSurahId, initialAyahNumber: initialAyahNumber);

  @override
  ConsumerState<SleepTimerScreen> createState() => _SleepTimerScreenState();
}

class _SleepTimerScreenState extends ConsumerState<SleepTimerScreen> {
  static const List<int> _presetMinutes = [5, 10, 15, 30, 45, 60];
  double _sliderMinutes = 0.0;
  Timer? _uiCountdownTimer;
  int _remainingSeconds = 0;
  bool _isWindupActive = false;
  bool _isUserDragging = false;
  bool _isTimerConfiguring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final timerState = ref.read(sleepTimerControllerProvider);
      if (timerState.isActive) {
        if (timerState.activeCondition is TimerCondition) {
          final rem = timerState.remainingTime ?? Duration.zero;
          if (rem > Duration.zero) {
            setState(() {
              _isTimerConfiguring = true;
              _remainingSeconds = rem.inSeconds;
              _sliderMinutes = (rem.inSeconds / 60.0).clamp(0.0, 120.0);
              _isWindupActive = true;
            });
            _startWindupCountdown();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _uiCountdownTimer?.cancel();
    super.dispose();
  }

  void _startWindupCountdown() {
    _uiCountdownTimer?.cancel();
    _uiCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _sliderMinutes = (_remainingSeconds / 60.0).clamp(0.0, 120.0);
        });
      } else {
        timer.cancel();
        _cancelTimer(showSnackbar: false);
      }
    });
  }

  void _activateDurationTimer(int minutes) {
    HapticFeedback.mediumImpact();
    final duration = Duration(minutes: minutes);
    final condition = TimerCondition(
      duration: duration,
      targetEndTime: DateTime.now().add(duration),
    );

    ref.read(sleepTimerControllerProvider.notifier).activate(condition);

    setState(() {
      _isTimerConfiguring = true;
      _remainingSeconds = minutes * 60;
      _sliderMinutes = minutes.toDouble().clamp(0.0, 120.0);
      _isWindupActive = true;
      _isUserDragging = false;
    });
    _startWindupCountdown();

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

    _uiCountdownTimer?.cancel();
    _uiCountdownTimer = null;
    setState(() {
      _isTimerConfiguring = false;
      _isWindupActive = false;
      _sliderMinutes = 0.0;
      _remainingSeconds = 0;
    });

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

    _uiCountdownTimer?.cancel();
    _uiCountdownTimer = null;
    setState(() {
      _isTimerConfiguring = false;
      _isWindupActive = false;
      _sliderMinutes = 0.0;
      _remainingSeconds = 0;
    });

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        'تایمر خواب تا پایان حزب ${hizb.toPersianDigit()} فعال شد.',
      );
    }
  }

  void _cancelTimer({bool showSnackbar = true}) {
    HapticFeedback.lightImpact();
    ref.read(sleepTimerControllerProvider.notifier).cancel();

    _uiCountdownTimer?.cancel();
    _uiCountdownTimer = null;
    setState(() {
      _isTimerConfiguring = false;
      _isWindupActive = false;
      _isUserDragging = false;
      _sliderMinutes = 0.0;
      _remainingSeconds = 0;
    });

    if (showSnackbar && mounted) {
      AppSnackBar.showInfo(
        context,
        'تایمر خواب خاموش شد.',
      );
    }
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

    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: colors.dialogSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(26.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppModalHeader(
                showDragHandle: true,
                title: 'تایمر خواب تلاوت',
                onClose: () => Navigator.of(context).pop(),
                bottomSpacing: 6.0,
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 20.0),
                  children: [
                    // ── Top Instant Slider Bar ──
                    _buildRealtimeTimerSliderCard(
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      colorScheme: colorScheme,
                      timerState: timerState,
                    ),
                    16.0.vSpace,

                    // ── Section 2: Quranic Boundaries ──
                    _buildSectionHeader(
                      title: 'توقف بر اساس آیات و سوره‌ها',
                      colorScheme: colorScheme,
                    ),
                    8.0.vSpace,

                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                        border: Border.all(
                          color: cardBorder,
                          width: 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // End of Surah
                          _buildToggleOptionTile(
                            title: 'پایان سوره جاری',
                            subtitle: 'تلاوت تا پایان سوره $surahName ($totalAyahs آیه)',
                            value: _isEndOfSurahActive(timerState, currentSurahId),
                            colorScheme: colorScheme,
                            onChanged: (val) {
                              if (val) {
                                _activateEndOfSurah(currentSurahId);
                              } else {
                                _cancelTimer(showSnackbar: true);
                              }
                            },
                          ),
                          _buildHairlineDivider(cardBorder),

                          // End of Hizb
                          _buildToggleOptionTile(
                            title: 'پایان حزب جاری',
                            subtitle: 'تلاوت تا پایان حزب ${currentHizb.toPersianDigit()}',
                            value: _isEndOfHizbActive(timerState, currentHizb),
                            colorScheme: colorScheme,
                            onChanged: (val) {
                              if (val) {
                                _activateEndOfHizb(
                                  currentHizb,
                                  currentAyahEntity?.hizbQuarter,
                                );
                              } else {
                                _cancelTimer(showSnackbar: true);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    16.0.vSpace,

                    // ── Section 3: Intelligent Sleep Features ──
                    _buildSectionHeader(
                      title: 'امکانات هوشمند خواب',
                      colorScheme: colorScheme,
                    ),
                    8.0.vSpace,

                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
                        border: Border.all(
                          color: cardBorder,
                          width: 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildSwitchFeatureTile(
                        title: 'کاهش تدریجی صدا',
                        subtitle: 'کاهش آرام بلندی صدا در ۳۰ ثانیه پایانی جهت جلوگیری از بیداری ناگهانی',
                        value: timerState.isFadeOutEnabled,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          ref.read(sleepTimerControllerProvider.notifier).setFadeOutEnabled(val);
                        },
                        colorScheme: colorScheme,
                      ),
                    ),

                    16.0.vSpace,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Top Real-time Timer Slider Card (کوک کردن لحظه‌ای مانند اسلایدر فونت)
  // ─────────────────────────────────────────────────────────────

  Widget _buildRealtimeTimerSliderCard({
    required Color cardBg,
    required Color cardBorder,
    required ColorScheme colorScheme,
    required SleepTimerState timerState,
  }) {
    final isDark = context.isDark;
    final isTimerCondition =
        timerState.isActive && timerState.activeCondition is TimerCondition;
    final rem = timerState.remainingTime ?? Duration.zero;

    // Mutually exclusive: Timer mode is active only if TimerCondition is active or user is configuring it
    final bool isSleepTimerActive = _isUserDragging ||
        isTimerCondition ||
        (_isTimerConfiguring && timerState.activeCondition == null) ||
        (_isWindupActive && _remainingSeconds > 0 && isTimerCondition);

    final int activeRemainingSeconds = _isUserDragging
        ? _remainingSeconds
        : (isTimerCondition ? rem.inSeconds : _remainingSeconds);

    final double activeSliderMinutes = _isUserDragging
        ? _sliderMinutes
        : (isTimerCondition
            ? (rem.inSeconds / 60.0).clamp(0.0, 120.0)
            : (_isWindupActive
                ? (_remainingSeconds / 60.0).clamp(0.0, 120.0)
                : _sliderMinutes));

    String captionText;
    if (_isUserDragging) {
      final m = _sliderMinutes.round();
      captionText = (m == 0)
          ? 'نوار زیر را جابه‌جا کنید یا یک زمان انتخاب نمایید:'
          : 'کوک شده روی: ${m.toPersianDigit()} دقیقه';
    } else if (isSleepTimerActive && isTimerCondition && activeRemainingSeconds > 0) {
      final m = (activeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (activeRemainingSeconds % 60).toString().padLeft(2, '0');
      captionText = 'زمان باقی‌مانده: ${'$m:$s'.toPersianDigit()}';
    } else if (_isWindupActive && _remainingSeconds > 0 && isTimerCondition) {
      final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
      captionText = 'زمان باقی‌مانده: ${'$m:$s'.toPersianDigit()}';
    } else if (isSleepTimerActive) {
      captionText = 'نوار زیر را جابه‌جا کنید یا یک زمان انتخاب نمایید:';
    } else {
      captionText = 'روشن کردن تایمر برای توقف خودکار تلاوت';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusDefault),
        border: Border.all(
          color: cardBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کوک کردن لحظه‌ای تایمر خواب',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    3.0.vSpace,
                    Text(
                      isSleepTimerActive
                          ? captionText
                          : 'روشن کردن تایمر برای توقف خودکار تلاوت',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: isSleepTimerActive
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: isSleepTimerActive,
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    if (val) {
                      if (timerState.isActive && !isTimerCondition) {
                        ref.read(sleepTimerControllerProvider.notifier).cancel();
                      }
                      setState(() {
                        _isTimerConfiguring = true;
                        _sliderMinutes = 0.0;
                        _remainingSeconds = 0;
                        _isWindupActive = false;
                        _isUserDragging = false;
                      });
                    } else {
                      _cancelTimer(showSnackbar: true);
                    }
                  },
                ),
              ),
            ],
          ),

          // Animated Slider Section (نمایش نوار کوکی و کلیدها با فعال شدن تاگل)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isSleepTimerActive
                ? Column(
                    children: [
                      10.0.vSpace,
                      Row(
                        children: [
                          Text(
                            '۰'.toPersianDigit(),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: colorScheme.primary,
                                inactiveTrackColor:
                                    colorScheme.outline.withValues(alpha: 0.2),
                                thumbColor: Colors.white,
                                overlayColor:
                                    colorScheme.primary.withValues(alpha: 0.15),
                                trackHeight: 4.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                  elevation: 2,
                                ),
                              ),
                              child: Slider(
                                value: activeSliderMinutes.clamp(0.0, 120.0),
                                min: 0.0,
                                max: 120.0,
                                onChanged: (val) {
                                  _uiCountdownTimer?.cancel();
                                  final roundedMin = val.round();
                                  if (roundedMin != _sliderMinutes.round()) {
                                    HapticFeedback.selectionClick();
                                  }
                                  setState(() {
                                    _isUserDragging = true;
                                    _sliderMinutes = val;
                                    _remainingSeconds = roundedMin * 60;
                                  });
                                },
                                onChangeEnd: (val) {
                                  setState(() {
                                    _isUserDragging = false;
                                  });
                                  final roundedMin = val.round();
                                  if (roundedMin > 0) {
                                    _activateDurationTimer(roundedMin);
                                  } else {
                                    _cancelTimer();
                                  }
                                },
                              ),
                            ),
                          ),
                          Text(
                            '۲ ساعت'.toPersianDigit(),
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      12.0.vSpace,

                      // ── Quick Duration Preset Chips (باکس‌های کوچک ردیفی بدون بورد و بدون استیت سلکت) ──
                      Row(
                        children: _presetMinutes.map((minutes) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _activateDurationTimer(minutes);
                                  },
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    height: 32.0,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${minutes.toPersianDigit()} دقیقه',
                                          style: TextStyle(
                                            fontFamily: AppTypography.fontFamily,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Section Header Helper
  // ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }




  // ─────────────────────────────────────────────────────────────
  // Clean Toggle Option Tile Helper
  // ─────────────────────────────────────────────────────────────

  Widget _buildToggleOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ColorScheme colorScheme,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        fontSize: 14,
                        fontWeight: value ? FontWeight.bold : FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    3.0.vSpace,
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              12.0.hSpace,
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: value,
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: Colors.white,
                  onChanged: (newVal) {
                    HapticFeedback.lightImpact();
                    onChanged(newVal);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchFeatureTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                3.0.vSpace,
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11.5,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          12.0.hSpace,
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              activeTrackColor: colorScheme.primary,
              activeThumbColor: Colors.white,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildUpcomingFeatureTile({
  //   required String title,
  //   required String subtitle,
  //   required Color cardBorder,
  //   required ColorScheme colorScheme,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 title,
  //                 style: TextStyle(
  //                   fontFamily: AppTypography.fontFamily,
  //                   fontSize: 13.5,
  //                   fontWeight: FontWeight.bold,
  //                   color: colorScheme.onSurface,
  //                 ),
  //               ),
  //             ),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //               decoration: BoxDecoration(
  //                 color: colorScheme.primary.withValues(alpha: 0.08),
  //                 borderRadius: BorderRadius.circular(6),
  //               ),
  //               child: Text(
  //                 'به زودی',
  //                 style: TextStyle(
  //                   fontFamily: AppTypography.fontFamily,
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.bold,
  //                   color: colorScheme.primary,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         4.0.vSpace,
  //         Text(
  //           subtitle,
  //           style: TextStyle(
  //             fontFamily: AppTypography.fontFamily,
  //             fontSize: 11.5,
  //             height: 1.4,
  //             color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHairlineDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 16,
      endIndent: 16,
      color: borderColor.withValues(alpha: 0.7),
    );
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
