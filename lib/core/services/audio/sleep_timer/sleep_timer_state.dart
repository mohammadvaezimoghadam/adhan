import 'package:flutter/foundation.dart';
import 'sleep_timer_condition.dart';

@immutable
class SleepTimerState {
  final SleepTimerCondition? activeCondition;
  final Duration? remainingTime;
  final bool isFadeOutEnabled;

  const SleepTimerState({
    this.activeCondition,
    this.remainingTime,
    this.isFadeOutEnabled = true,
  });

  bool get isActive => activeCondition != null;

  bool get isTimerMode => activeCondition is TimerCondition;

  SleepTimerState copyWith({
    SleepTimerCondition? Function()? activeCondition,
    Duration? Function()? remainingTime,
    bool Function()? isFadeOutEnabled,
  }) {
    return SleepTimerState(
      activeCondition:
          activeCondition != null ? activeCondition() : this.activeCondition,
      remainingTime:
          remainingTime != null ? remainingTime() : this.remainingTime,
      isFadeOutEnabled:
          isFadeOutEnabled != null ? isFadeOutEnabled() : this.isFadeOutEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepTimerState &&
        other.activeCondition == activeCondition &&
        other.remainingTime == remainingTime &&
        other.isFadeOutEnabled == isFadeOutEnabled;
  }

  @override
  int get hashCode => Object.hash(activeCondition, remainingTime, isFadeOutEnabled);

  @override
  String toString() =>
      'SleepTimerState(activeCondition: $activeCondition, remainingTime: $remainingTime, isFadeOutEnabled: $isFadeOutEnabled)';
}
