import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local/preferences/preferences_service_provider.dart';
import '../audio_player_providers.dart';
import 'sleep_timer_condition.dart';
import 'sleep_timer_state.dart';

final sleepTimerControllerProvider =
    NotifierProvider<SleepTimerController, SleepTimerState>(
  SleepTimerController.new,
);

class SleepTimerController extends Notifier<SleepTimerState> {
  Timer? _countdownTimer;

  static const String _fadeOutPrefKey = 'sleep_timer_fade_out';

  @override
  SleepTimerState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    final prefs = ref.read(preferencesServiceProvider);
    final savedFadeOut = prefs.getBool(_fadeOutPrefKey) ?? true;
    return SleepTimerState(isFadeOutEnabled: savedFadeOut);
  }

  /// Toggle or update the audio fade-out preference.
  void setFadeOutEnabled(bool enabled) {
    ref.read(preferencesServiceProvider).setBool(_fadeOutPrefKey, enabled);
    state = state.copyWith(isFadeOutEnabled: () => enabled);
    if (!enabled) {
      ref.read(audioPlayerServiceProvider).setVolume(1.0);
    }
  }

  /// Activate a new sleep timer condition.
  void activate(SleepTimerCondition condition) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    ref.read(audioPlayerServiceProvider).setVolume(1.0);

    if (condition is TimerCondition) {
      final initialRemaining = condition.targetEndTime.difference(DateTime.now());
      state = state.copyWith(
        activeCondition: () => condition,
        remainingTime: () => initialRemaining > Duration.zero ? initialRemaining : Duration.zero,
      );
      _startCountdown(condition.targetEndTime);
    } else {
      state = state.copyWith(
        activeCondition: () => condition,
        remainingTime: () => null,
      );
    }
  }

  /// Cancel any active sleep timer.
  void cancel() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    ref.read(audioPlayerServiceProvider).setVolume(1.0);
    state = state.copyWith(
      activeCondition: () => null,
      remainingTime: () => null,
    );
  }

  /// Internal periodic timer to tick down remaining time for TimerCondition.
  void _startCountdown(DateTime targetEndTime) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = targetEndTime.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        timer.cancel();
        _countdownTimer = null;
        state = state.copyWith(remainingTime: () => Duration.zero);
        if (state.isFadeOutEnabled) {
          ref.read(audioPlayerServiceProvider).setVolume(1.0);
        }
      } else {
        state = state.copyWith(remainingTime: () => remaining);
        if (state.isFadeOutEnabled && remaining <= const Duration(seconds: 30)) {
          final factor = (remaining.inMilliseconds / 30000.0).clamp(0.05, 1.0);
          ref.read(audioPlayerServiceProvider).setVolume(factor);
        }
      }
    });
  }

  /// Evaluates whether audio playback should stop after the current Ayah completes.
  ///
  /// Returns `true` if the condition is met, in which case playback should cease.
  bool shouldStopAfter({
    required int surahId,
    required int ayahNumber,
    int? hizb,
    int? nextHizb,
    required bool isLastAyahInSurah,
  }) {
    final condition = state.activeCondition;
    if (condition == null) return false;

    switch (condition) {
      case TimerCondition():
        final now = DateTime.now();
        return now.isAfter(condition.targetEndTime) ||
            now.isAtSameMomentAs(condition.targetEndTime) ||
            (state.remainingTime != null && state.remainingTime! <= Duration.zero);

      case EndOfSurahCondition():
        if (surahId != condition.surahId) {
          cancel();
          return false;
        }
        return isLastAyahInSurah;

      case EndOfHizbCondition():
        if (hizb != null && hizb != condition.hizb) {
          return true;
        }
        if (nextHizb != null && nextHizb != condition.hizb) {
          return true;
        }
        if (isLastAyahInSurah) {
          return true;
        }
        return false;

      case TargetAyahCondition():
        if (surahId != condition.surahId) {
          cancel();
          return false;
        }
        return ayahNumber >= condition.targetAyahNumber;
    }
  }
}
