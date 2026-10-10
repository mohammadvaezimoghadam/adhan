import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/core/services/audio/sleep_timer/sleep_timer_condition.dart';
import 'package:quran/core/services/audio/sleep_timer/sleep_timer_controller.dart';

void main() {
  group('SleepTimerController Tests', () {
    test('initial state should be inactive', () {
      final testContainer = ProviderContainer();
      addTearDown(testContainer.dispose);

      final state = testContainer.read(sleepTimerControllerProvider);
      expect(state.isActive, isFalse);
      expect(state.activeCondition, isNull);
      expect(state.remainingTime, isNull);
    });

    test('TimerCondition should activate and evaluate shouldStopAfter properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sleepTimerControllerProvider.notifier);

      // Future condition (10 minutes)
      final futureCondition = TimerCondition(
        duration: const Duration(minutes: 10),
        targetEndTime: DateTime.now().add(const Duration(minutes: 10)),
      );

      notifier.activate(futureCondition);

      var state = container.read(sleepTimerControllerProvider);
      expect(state.isActive, isTrue);
      expect(state.isTimerMode, isTrue);
      expect(state.remainingTime, isNotNull);

      // Not expired yet
      var shouldStop = notifier.shouldStopAfter(
        surahId: 1,
        ayahNumber: 3,
        isLastAyahInSurah: false,
      );
      expect(shouldStop, isFalse);

      // Past condition (already expired)
      final pastCondition = TimerCondition(
        duration: const Duration(seconds: 1),
        targetEndTime: DateTime.now().subtract(const Duration(seconds: 2)),
      );

      notifier.activate(pastCondition);

      shouldStop = notifier.shouldStopAfter(
        surahId: 1,
        ayahNumber: 4,
        isLastAyahInSurah: false,
      );
      expect(shouldStop, isTrue);
    });

    test('EndOfSurahCondition should stop only at last ayah of same surah', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sleepTimerControllerProvider.notifier);
      notifier.activate(const EndOfSurahCondition(surahId: 2));

      // Middle of Surah 2
      expect(
        notifier.shouldStopAfter(
          surahId: 2,
          ayahNumber: 150,
          isLastAyahInSurah: false,
        ),
        isFalse,
      );

      // Last ayah of Surah 2
      expect(
        notifier.shouldStopAfter(
          surahId: 2,
          ayahNumber: 286,
          isLastAyahInSurah: true,
        ),
        isTrue,
      );

      // If user switched to another surah, timer is cancelled
      notifier.activate(const EndOfSurahCondition(surahId: 2));
      expect(
        notifier.shouldStopAfter(
          surahId: 3,
          ayahNumber: 1,
          isLastAyahInSurah: false,
        ),
        isFalse,
      );
      expect(container.read(sleepTimerControllerProvider).isActive, isFalse);
    });

    test('EndOfHizbCondition should stop when next ayah is in another hizb', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sleepTimerControllerProvider.notifier);
      notifier.activate(const EndOfHizbCondition(hizb: 5));

      // Next ayah is still within Hizb 5
      expect(
        notifier.shouldStopAfter(
          surahId: 2,
          ayahNumber: 74,
          hizb: 5,
          nextHizb: 5,
          isLastAyahInSurah: false,
        ),
        isFalse,
      );

      // Next ayah is in Hizb 6
      expect(
        notifier.shouldStopAfter(
          surahId: 2,
          ayahNumber: 75,
          hizb: 5,
          nextHizb: 6,
          isLastAyahInSurah: false,
        ),
        isTrue,
      );

      // Surah ends
      expect(
        notifier.shouldStopAfter(
          surahId: 2,
          ayahNumber: 286,
          hizb: 5,
          nextHizb: null,
          isLastAyahInSurah: true,
        ),
        isTrue,
      );
    });

    test('TargetAyahCondition should stop when reaching target ayah number', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sleepTimerControllerProvider.notifier);
      notifier.activate(const TargetAyahCondition(surahId: 18, targetAyahNumber: 10));

      // Before target ayah
      expect(
        notifier.shouldStopAfter(
          surahId: 18,
          ayahNumber: 9,
          isLastAyahInSurah: false,
        ),
        isFalse,
      );

      // Exactly at target ayah
      expect(
        notifier.shouldStopAfter(
          surahId: 18,
          ayahNumber: 10,
          isLastAyahInSurah: false,
        ),
        isTrue,
      );

      // Beyond target ayah
      expect(
        notifier.shouldStopAfter(
          surahId: 18,
          ayahNumber: 11,
          isLastAyahInSurah: false,
        ),
        isTrue,
      );
    });

    test('cancel() should completely reset the timer state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sleepTimerControllerProvider.notifier);
      notifier.activate(const EndOfSurahCondition(surahId: 1));
      expect(container.read(sleepTimerControllerProvider).isActive, isTrue);

      notifier.cancel();
      final state = container.read(sleepTimerControllerProvider);
      expect(state.isActive, isFalse);
      expect(state.activeCondition, isNull);
      expect(state.remainingTime, isNull);
    });
  });
}
