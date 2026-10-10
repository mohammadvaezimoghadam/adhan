import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sleep_timer_condition.dart';
import 'sleep_timer_state.dart';

final sleepTimerControllerProvider =
    NotifierProvider<SleepTimerController, SleepTimerState>(
  SleepTimerController.new,
);

class SleepTimerController extends Notifier<SleepTimerState> {
  Timer? _countdownTimer;

  @override
  SleepTimerState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const SleepTimerState();
  }

  /// Activate a new sleep timer condition.
  void activate(SleepTimerCondition condition) {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    if (condition is TimerCondition) {
      final initialRemaining = condition.targetEndTime.difference(DateTime.now());
      state = SleepTimerState(
        activeCondition: condition,
        remainingTime: initialRemaining > Duration.zero ? initialRemaining : Duration.zero,
      );
      _startCountdown(condition.targetEndTime);
    } else {
      state = SleepTimerState(
        activeCondition: condition,
        remainingTime: null,
      );
    }
  }

  /// Cancel any active sleep timer.
  void cancel() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = const SleepTimerState();
  }

  /// Internal periodic timer to tick down remaining time for TimerCondition.
  void _startCountdown(DateTime targetEndTime) {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = targetEndTime.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        timer.cancel();
        _countdownTimer = null;
        state = state.copyWith(remainingTime: () => Duration.zero);
      } else {
        state = state.copyWith(remainingTime: () => remaining);
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
