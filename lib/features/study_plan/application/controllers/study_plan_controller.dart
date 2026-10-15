import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/study_plan.dart';
import '../../infrastructure/datasources/study_plan_local_datasource.dart';

class StudyPlanState {
  final List<StudyPlan> plans;
  final StudyPlan? activePlan;
  final bool isLoading;

  const StudyPlanState({
    this.plans = const [],
    this.activePlan,
    this.isLoading = false,
  });

  StudyPlanState copyWith({
    List<StudyPlan>? plans,
    StudyPlan? activePlan,
    bool? isLoading,
    bool clearActivePlan = false,
  }) {
    return StudyPlanState(
      plans: plans ?? this.plans,
      activePlan: clearActivePlan ? null : (activePlan ?? this.activePlan),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final studyPlanControllerProvider =
    NotifierProvider<StudyPlanController, StudyPlanState>(
  StudyPlanController.new,
);

/// Tracks whether study plan mode is active in the current Quran reader session.
class StudyPlanSessionActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool isActive) {
    state = isActive;
  }
}

final isStudyPlanSessionActiveProvider =
    NotifierProvider<StudyPlanSessionActiveNotifier, bool>(StudyPlanSessionActiveNotifier.new);

/// Event stream/state triggered when today's goal is completed
final todayGoalCompletedEventProvider =
    NotifierProvider<TodayGoalCompletedEventNotifier, StudyPlan?>(
  TodayGoalCompletedEventNotifier.new,
);

class TodayGoalCompletedEventNotifier extends Notifier<StudyPlan?> {
  @override
  StudyPlan? build() => null;

  void emit(StudyPlan plan) => state = plan;
  void clear() => state = null;
}

class StudyPlanController extends Notifier<StudyPlanState> {
  late final IStudyPlanLocalDataSource _dataSource;

  @override
  StudyPlanState build() {
    _dataSource = ref.read(studyPlanLocalDataSourceProvider);
    // Initial async load
    Future.microtask(() => loadPlans());
    return const StudyPlanState(isLoading: true);
  }

  Future<void> loadPlans() async {
    state = state.copyWith(isLoading: true);
    final allPlans = await _dataSource.getAllPlans();
    final activeId = _dataSource.getActivePlanId();

    StudyPlan? active;
    if (activeId != null) {
      active = allPlans.where((p) => p.id == activeId).firstOrNull;
    }
    active ??= allPlans.where((p) => p.status == StudyPlanStatus.active).firstOrNull;

    // Check day roll-over & deadline expiration for plans
    final updatedList = <StudyPlan>[];
    for (var plan in allPlans) {
      plan = _checkAndRefreshPlanDates(plan);
      updatedList.add(plan);
      if (active?.id == plan.id) {
        active = plan;
      }
    }

    state = StudyPlanState(
      plans: updatedList,
      activePlan: active,
      isLoading: false,
    );
  }

  /// Checks if a new day has arrived or if deadline passed
  StudyPlan _checkAndRefreshPlanDates(StudyPlan plan) {
    var modified = plan;
    final now = DateTime.now();

    // 1. Check completion for fixed-day plans: after the period ends
    if (!modified.isOngoing && modified.status == StudyPlanStatus.active) {
      if (now.isAfter(modified.targetEndDate)) {
        final isAllDone = modified.completedPagesCount >= modified.totalPages;
        modified = modified.copyWith(
          status: isAllDone ? StudyPlanStatus.completed : StudyPlanStatus.expired,
          lastActiveDate: now,
        );
        _dataSource.savePlan(modified);
        return modified;
      }
    }

    // 2. Auto-heal: If no pages have ever been completed, isTodayCompleted cannot be true
    if (modified.completedPagesCount == 0 && modified.isTodayCompleted) {
      modified = modified.copyWith(isTodayCompleted: false);
      _dataSource.savePlan(modified);
    }

    // 3. Calendar day transition check:
    final refDate = modified.lastActiveDate ?? modified.lastReadDate ?? modified.createdAt;
    final isDifferentDay = refDate.year != now.year ||
        refDate.month != now.month ||
        refDate.day != now.day;

    if (isDifferentDay) {
      final lastDay = DateTime(refDate.year, refDate.month, refDate.day);
      final todayDay = DateTime(now.year, now.month, now.day);
      final daysDiff = todayDay.difference(lastDay).inDays;

      int newStreak = modified.streakDays;
      if (daysDiff > 1 && !modified.isTodayCompleted) {
        newStreak = 0; // Missed more than 1 day without completion -> reset streak
      }

      // Calculate where today's slice begins:
      // Always continue from where user left off (completedPagesCount + 1)!
      final nextStart = min(
        modified.totalPages,
        modified.completedPagesCount + 1,
      );
      final nextEnd = min(
        modified.totalPages,
        nextStart + modified.dailyPagesTarget - 1,
      );

      // Check if user was in the middle of this page
      final bool wasMidPage = modified.lastReadSurahId != null &&
          modified.lastReadAyahNumber != null &&
          modified.currentPage == nextStart;

      int? nextStartAyah;
      int? updatedCompletedAyahs = modified.completedAyahsCount;
      if (modified.unit == StudyPlanUnit.ayah) {
        final advance = modified.isTodayCompleted
            ? modified.unitAmount
            : (modified.todayAyahsRead ?? 0);
        updatedCompletedAyahs = (modified.completedAyahsCount ?? 0) + advance;
        final base = modified.todayStartAyahGlobal ?? 1;
        nextStartAyah = min(6236, base + advance);
      }

      modified = modified.copyWith(
        todayStartPage: nextStart,
        todayEndPage: nextEnd,
        todayCurrentPage: nextStart,
        isTodayCompleted: false, // Refresh button for the new day to "ادامه مطالعه"!
        todayProgressFraction: 0.0, // Reset today's progress to 0% for the new day!
        streakDays: newStreak,
        lastActiveDate: now,
        clearLastReadPosition: !wasMidPage,
        todayStartAyahGlobal: nextStartAyah ?? modified.todayStartAyahGlobal,
        todayAyahsRead: 0,
        completedAyahsCount: updatedCompletedAyahs,
      );

      _dataSource.savePlan(modified);
    }

    return modified;
  }

  /// Checks all plans for date changes (called on app open, screen build, or resume)
  void checkAndRefreshAllPlans() {
    bool anyChanged = false;
    final refreshedPlans = state.plans.map((p) {
      final updated = _checkAndRefreshPlanDates(p);
      if (!identical(updated, p)) {
        anyChanged = true;
      }
      return updated;
    }).toList();

    if (anyChanged) {
      final newActive = state.activePlan != null
          ? refreshedPlans.where((p) => p.id == state.activePlan!.id).firstOrNull
          : null;
      state = state.copyWith(plans: refreshedPlans, activePlan: newActive);
    }
  }

  /// Create a new study plan and set it as active
  Future<StudyPlan> createPlan({
    required String title,
    required StudyPlanType type,
    bool isOngoing = false,
    required int targetDays,
    StudyPlanUnit unit = StudyPlanUnit.page,
    int unitAmount = 1,
    int? customDailyPages,
    int totalPages = 604,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final plan = StudyPlan.create(
      id: id,
      title: title.trim().isEmpty ? 'برنامه مطالعه قرآن' : title.trim(),
      type: type,
      isOngoing: isOngoing,
      targetDays: targetDays,
      unit: unit,
      unitAmount: unitAmount,
      customDailyPages: customDailyPages,
      totalPages: totalPages,
    );

    await _dataSource.savePlan(plan);
    await _dataSource.setActivePlanId(plan.id);

    final currentPlans = [plan, ...state.plans];
    state = state.copyWith(
      plans: currentPlans,
      activePlan: plan,
    );

    return plan;
  }

  /// Update an existing study plan's configuration and persist to Hive
  Future<StudyPlan> updatePlan({
    required String planId,
    required String title,
    required bool isOngoing,
    required int targetDays,
    required StudyPlanUnit unit,
    required int unitAmount,
    int? customDailyPages,
  }) async {
    final existing = state.plans.where((p) => p.id == planId).firstOrNull;
    if (existing == null) throw Exception('Plan not found: $planId');

    final updated = existing.updateConfiguration(
      title: title.trim().isEmpty ? existing.title : title.trim(),
      isOngoing: isOngoing,
      targetDays: targetDays,
      unit: unit,
      unitAmount: unitAmount,
      customDailyPages: customDailyPages,
    );

    await _dataSource.savePlan(updated);

    final updatedPlans =
        state.plans.map((p) => p.id == planId ? updated : p).toList();
    final newActive =
        state.activePlan?.id == planId ? updated : state.activePlan;

    state = state.copyWith(
      plans: updatedPlans,
      activePlan: newActive,
    );

    return updated;
  }

  Future<void> setActivePlan(String planId) async {
    final target = state.plans.where((p) => p.id == planId).firstOrNull;
    if (target != null) {
      var updated = target;
      if (target.status != StudyPlanStatus.active && target.status != StudyPlanStatus.completed) {
        updated = target.copyWith(status: StudyPlanStatus.active);
        await _dataSource.savePlan(updated);
      }
      await _dataSource.setActivePlanId(planId);
      final updatedPlans = state.plans.map((p) => p.id == planId ? updated : p).toList();
      state = state.copyWith(
        plans: updatedPlans,
        activePlan: updated,
      );
    }
  }

  /// Toggle status between active and inactive
  Future<void> togglePlanStatus(String planId) async {
    final target = state.plans.where((p) => p.id == planId).firstOrNull;
    if (target == null) return;

    final newStatus = target.status == StudyPlanStatus.active
        ? StudyPlanStatus.inactive
        : StudyPlanStatus.active;

    final updated = target.copyWith(status: newStatus);
    await _dataSource.savePlan(updated);

    final updatedPlans = state.plans.map((p) => p.id == planId ? updated : p).toList();

    StudyPlan? newActive = state.activePlan;
    if (newActive?.id == planId && newStatus == StudyPlanStatus.inactive) {
      newActive = updatedPlans.where((p) => p.status == StudyPlanStatus.active).firstOrNull;
      if (newActive != null) {
        await _dataSource.setActivePlanId(newActive.id);
      }
    } else if (newActive == null && newStatus == StudyPlanStatus.active) {
      newActive = updated;
      await _dataSource.setActivePlanId(updated.id);
    }

    state = state.copyWith(
      plans: updatedPlans,
      activePlan: newActive,
    );
  }

  Timer? _saveDebounceTimer;

  void _scheduleSavePlan(StudyPlan plan) {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _dataSource.savePlan(plan);
    });
  }

  /// Flushes any pending debounced save directly to disk storage (called on screen exit or app pause)
  void flushPendingSave() {
    if (_saveDebounceTimer?.isActive ?? false) {
      _saveDebounceTimer?.cancel();
      final active = state.activePlan;
      if (active != null) {
        _dataSource.savePlan(active);
      }
    }
  }

  /// Automatically records progress based on the current ayah being read.
  Future<void> recordProgress({
    required int surahId,
    String? surahName,
    int? ayahNumber,
    int? page,
    int? juz,
    int? hizb,
    bool isEndOfPage = false,
    double pageFraction = 0.0,
  }) async {
    if (page != null) {
      await recordPageRead(
        page,
        surahId: surahId,
        surahName: surahName,
        ayahNumber: ayahNumber,
        isEndOfPage: isEndOfPage,
        pageFraction: pageFraction,
      );
    }
  }

  /// Records progress (called when reading a page in quran reader)
  Future<void> recordPageRead(
    int pageNumber, {
    int? surahId,
    String? surahName,
    int? ayahNumber,
    bool isEndOfPage = false,
    double pageFraction = 0.0,
  }) async {
    // Only record reading progress for the specifically selected plan that the user is currently reading
    final targetPlanId = state.activePlan?.id;
    if (targetPlanId == null) return;

    final now = DateTime.now();
    final updatedPlans = <StudyPlan>[];
    StudyPlan? updatedActivePlan = state.activePlan;
    StudyPlan? justCompletedPlan;

    for (final plan in state.plans) {
      // Only process the selected plan; leave all other plans untouched
      if (plan.id != targetPlanId || plan.status == StudyPlanStatus.completed) {
        updatedPlans.add(plan);
        continue;
      }

      // Check if pageNumber is relevant to today's quota:
      final isInTodayRange = pageNumber >= plan.todayStartPage && pageNumber <= plan.todayEndPage;
      final isFinalPageTurned = pageNumber == plan.todayEndPage + 1;

      if (plan.unit != StudyPlanUnit.ayah && !isInTodayRange && !isFinalPageTurned) {
        // Page is outside this plan's today quota (e.g. user browsing another Surah)
        updatedPlans.add(plan);
        continue;
      }

      // How many pages of today's slice are completed?
      final int doneInTodaySlice;
      final bool isGoalReachedToday;
      final double computedTodayFraction;
      int? updatedTodayAyahsRead = plan.todayAyahsRead;

      if (plan.unit == StudyPlanUnit.ayah && surahId != null && ayahNumber != null) {
        final currentGlobal = getGlobalAyahIndex(surahId, ayahNumber);
        final baseStart = plan.todayStartAyahGlobal ?? 1;
        final targetEnd = baseStart + plan.unitAmount - 1;
        final ayahsReadCount = (currentGlobal - baseStart + 1).clamp(0, plan.unitAmount);
        updatedTodayAyahsRead = max(plan.todayAyahsRead ?? 0, ayahsReadCount);
        computedTodayFraction = (updatedTodayAyahsRead / plan.unitAmount).clamp(0.0, 1.0);
        isGoalReachedToday = updatedTodayAyahsRead >= plan.unitAmount || currentGlobal >= targetEnd;
        doneInTodaySlice = (updatedTodayAyahsRead / 15).ceil();
      } else if (isFinalPageTurned || pageNumber > plan.todayEndPage) {
        doneInTodaySlice = plan.todayTargetPagesCount;
        isGoalReachedToday = true;
        computedTodayFraction = 1.0;
      } else if (pageNumber == plan.todayEndPage && isEndOfPage) {
        // User reached the end of today's target page!
        doneInTodaySlice = plan.todayTargetPagesCount;
        isGoalReachedToday = true;
        computedTodayFraction = 1.0;
      } else {
        // Pages before pageNumber are completed; if isEndOfPage is true, pageNumber itself is also completed
        final completedPage = isEndOfPage ? pageNumber : pageNumber - 1;
        final count = completedPage - plan.todayStartPage + 1;
        doneInTodaySlice = count.clamp(0, plan.todayTargetPagesCount);
        isGoalReachedToday = false;

        // Compute live continuous fraction based on current page progress:
        final pagesBeforeCurrent = max(0, pageNumber - plan.todayStartPage);
        final livePages = pagesBeforeCurrent + (isEndOfPage ? 1.0 : pageFraction.clamp(0.0, 1.0));
        computedTodayFraction = (livePages / plan.todayTargetPagesCount).clamp(0.0, 1.0);
      }

      // Total completed pages across the entire plan (never decreases):
      final calculatedTotalCompleted = (plan.todayStartPage - 1) + doneInTodaySlice;
      final completedCount = max(
        plan.completedPagesCount,
        min(plan.totalPages, calculatedTotalCompleted),
      );

      final isWholePlanCompleted = completedCount >= plan.totalPages;

      int newStreak = plan.streakDays;
      final wasCompletedBefore = plan.isTodayCompleted;
      if (isGoalReachedToday && !wasCompletedBefore) {
        newStreak += 1;
      }

      final newFraction = max(plan.todayProgressFraction, computedTodayFraction);
      final isCompletedNow = wasCompletedBefore || isGoalReachedToday;

      // No-op check: if nothing meaningful changed, keep original plan instance
      if (plan.currentPage == pageNumber &&
          plan.todayCurrentPage == pageNumber &&
          plan.lastReadAyahNumber == ayahNumber &&
          plan.lastReadSurahId == surahId &&
          (plan.todayProgressFraction - newFraction).abs() < 0.005 &&
          plan.isTodayCompleted == isCompletedNow) {
        updatedPlans.add(plan);
        continue;
      }

      final updated = plan.copyWith(
        currentPage: pageNumber,
        todayCurrentPage: pageNumber,
        completedPagesCount: completedCount,
        isTodayCompleted: isCompletedNow,
        status: isWholePlanCompleted ? StudyPlanStatus.completed : plan.status,
        lastReadDate: now,
        lastActiveDate: now,
        streakDays: newStreak,
        lastReadSurahId: isEndOfPage ? null : (surahId ?? plan.lastReadSurahId),
        lastReadSurahName: isEndOfPage ? null : (surahName ?? plan.lastReadSurahName),
        lastReadAyahNumber: isEndOfPage ? null : (ayahNumber ?? plan.lastReadAyahNumber),
        clearLastReadPosition: isEndOfPage,
        todayProgressFraction: newFraction,
        todayAyahsRead: updatedTodayAyahsRead,
      );

      // Persist: immediate on goal completion, debounced during continuous scrolling
      if (isGoalReachedToday) {
        await _dataSource.savePlan(updated);
      } else {
        _scheduleSavePlan(updated);
      }

      updatedPlans.add(updated);

      if (updatedActivePlan?.id == updated.id) {
        updatedActivePlan = updated;
      }

      if (isGoalReachedToday && !wasCompletedBefore) {
        justCompletedPlan = updated;
      }
    }

    // If no plan actually changed, skip emitting new state entirely
    bool anyChanged = false;
    for (int i = 0; i < state.plans.length && i < updatedPlans.length; i++) {
      if (!identical(state.plans[i], updatedPlans[i])) {
        anyChanged = true;
        break;
      }
    }
    if (!anyChanged) return;

    state = state.copyWith(
      plans: updatedPlans,
      activePlan: updatedActivePlan,
    );

    if (justCompletedPlan != null) {
      ref.read(todayGoalCompletedEventProvider.notifier).emit(justCompletedPlan);
    }
  }

  /// Manually mark today's target as finished
  Future<void> markTodayAsCompleted() async {
    final current = state.activePlan;
    if (current == null) return;

    final now = DateTime.now();
    final wasCompletedBefore = current.isTodayCompleted;
    final newStreak = wasCompletedBefore ? current.streakDays : current.streakDays + 1;
    final nextTarget = min(current.totalPages, current.todayEndPage + 1);

    final updated = current.copyWith(
      todayCurrentPage: current.todayEndPage,
      currentPage: nextTarget,
      completedPagesCount: max(
        current.completedPagesCount,
        min(current.totalPages, current.todayEndPage),
      ),
      isTodayCompleted: true,
      lastReadDate: now,
      streakDays: newStreak,
      status: nextTarget >= current.totalPages
          ? StudyPlanStatus.completed
          : current.status,
    );

    await _dataSource.savePlan(updated);

    final updatedPlans = state.plans.map((p) => p.id == updated.id ? updated : p).toList();
    state = state.copyWith(
      plans: updatedPlans,
      activePlan: updated,
    );

    if (!wasCompletedBefore) {
      ref.read(todayGoalCompletedEventProvider.notifier).emit(updated);
    }
  }

  /// Delete plan
  Future<void> deletePlan(String id) async {
    await _dataSource.deletePlan(id);
    final remaining = state.plans.where((p) => p.id != id).toList();
    StudyPlan? nextActive;
    if (state.activePlan?.id == id) {
      nextActive = remaining.where((p) => p.status == StudyPlanStatus.active).firstOrNull;
      if (nextActive != null) {
        await _dataSource.setActivePlanId(nextActive.id);
      } else {
        await _dataSource.setActivePlanId(null);
      }
    } else {
      nextActive = state.activePlan;
    }

    state = state.copyWith(
      plans: remaining,
      activePlan: nextActive,
      clearActivePlan: nextActive == null,
    );
  }
}
