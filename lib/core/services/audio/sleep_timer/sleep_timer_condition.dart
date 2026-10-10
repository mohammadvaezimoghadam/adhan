import 'package:flutter/foundation.dart';

/// Sealed class representing the condition under which audio playback should automatically stop.
@immutable
sealed class SleepTimerCondition {
  const SleepTimerCondition();
}

/// Condition 1: Stop after a specified duration (time-based countdown).
class TimerCondition extends SleepTimerCondition {
  final Duration duration;
  final DateTime targetEndTime;

  const TimerCondition({
    required this.duration,
    required this.targetEndTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerCondition &&
          other.duration == duration &&
          other.targetEndTime == targetEndTime;

  @override
  int get hashCode => Object.hash(duration, targetEndTime);

  @override
  String toString() =>
      'TimerCondition(duration: $duration, targetEndTime: $targetEndTime)';
}

/// Condition 2: Stop at the end of the specified Surah.
class EndOfSurahCondition extends SleepTimerCondition {
  final int surahId;

  const EndOfSurahCondition({
    required this.surahId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndOfSurahCondition && other.surahId == surahId;

  @override
  int get hashCode => surahId.hashCode;

  @override
  String toString() => 'EndOfSurahCondition(surahId: $surahId)';
}

/// Condition 3: Stop at the end of the specified Hizb.
class EndOfHizbCondition extends SleepTimerCondition {
  final int hizb;
  final int? hizbQuarter;

  const EndOfHizbCondition({
    required this.hizb,
    this.hizbQuarter,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EndOfHizbCondition &&
          other.hizb == hizb &&
          other.hizbQuarter == hizbQuarter;

  @override
  int get hashCode => Object.hash(hizb, hizbQuarter);

  @override
  String toString() =>
      'EndOfHizbCondition(hizb: $hizb, hizbQuarter: $hizbQuarter)';
}

/// Condition 4: Stop upon completing a specific target Ayah.
class TargetAyahCondition extends SleepTimerCondition {
  final int surahId;
  final int targetAyahNumber;

  const TargetAyahCondition({
    required this.surahId,
    required this.targetAyahNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetAyahCondition &&
          other.surahId == surahId &&
          other.targetAyahNumber == targetAyahNumber;

  @override
  int get hashCode => Object.hash(surahId, targetAyahNumber);

  @override
  String toString() =>
      'TargetAyahCondition(surahId: $surahId, targetAyahNumber: $targetAyahNumber)';
}
