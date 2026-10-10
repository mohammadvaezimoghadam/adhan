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

    // Check completion for fixed-day plans: after the period ends, status becomes completed!
    if (!modified.isOngoing && modified.status == StudyPlanStatus.active) {
      if (now.isAfter(modified.targetEndDate)) {
        modified = modified.copyWith(status: StudyPlanStatus.completed);
        _dataSource.savePlan(modified);
      }
    }

    // Check if new calendar day has started
    if (modified.lastReadDate != null) {
      final last = modified.lastReadDate!;
      final isDifferentDay = last.year != now.year ||
          last.month != now.month ||
          last.day != now.day;

      if (isDifferentDay) {
        // Roll over today's target to the next slice of pages
        final nextStart = min(
          modified.totalPages,
          modified.completedPagesCount + 1,
        );
        final nextEnd = min(
          modified.totalPages,
          nextStart + modified.dailyPagesTarget - 1,
        );

        modified = modified.copyWith(
          todayStartPage: nextStart,
          todayEndPage: nextEnd,
          todayCurrentPage: nextStart,
          isTodayCompleted: false,
        );
        _dataSource.savePlan(modified);
      }
    }

    return modified;
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
    final activePlan = state.activePlan ?? plan;
    await _dataSource.setActivePlanId(activePlan.id);

    final currentPlans = [plan, ...state.plans];
    state = state.copyWith(
      plans: currentPlans,
      activePlan: activePlan,
    );

    return plan;
  }

  /// Select a plan as the current active plan for the home card
  Future<void> setActivePlan(String planId) async {
    final target = state.plans.where((p) => p.id == planId).firstOrNull;
    if (target != null) {
      await _dataSource.setActivePlanId(planId);
      state = state.copyWith(activePlan: target);
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

  /// Automatically records progress based on the current ayah being read.
  Future<void> recordProgress({
    required int surahId,
    int? page,
    int? juz,
    int? hizb,
  }) async {
    if (page != null) {
      await recordPageRead(page);
    }
  }

  /// Records progress (called when reading a page in quran reader)
  Future<void> recordPageRead(int pageNumber) async {
    final activePlans = state.plans.where((p) => p.status == StudyPlanStatus.active).toList();
    if (activePlans.isEmpty) return;

    final now = DateTime.now();
    final updatedPlans = <StudyPlan>[];
    StudyPlan? updatedActivePlan = state.activePlan;

    for (final plan in state.plans) {
      if (plan.status != StudyPlanStatus.active) {
        updatedPlans.add(plan);
        continue;
      }

      final newCurrentPage = max(plan.currentPage, pageNumber);
      final newTodayCurrent = max(plan.todayCurrentPage, pageNumber);

      // Calculate completed pages count: user has read up to pageNumber
      final completedCount = min(
        plan.totalPages,
        max(plan.completedPagesCount, pageNumber),
      );

      final isGoalReachedToday = newTodayCurrent >= plan.todayEndPage;
      final isWholePlanCompleted = completedCount >= plan.totalPages;

      int newStreak = plan.streakDays;
      if (isGoalReachedToday && !plan.isTodayCompleted) {
        newStreak += 1;
      }

      final updated = plan.copyWith(
        currentPage: newCurrentPage,
        todayCurrentPage: newTodayCurrent,
        completedPagesCount: completedCount,
        isTodayCompleted: plan.isTodayCompleted || isGoalReachedToday,
        status: isWholePlanCompleted ? StudyPlanStatus.completed : plan.status,
        lastReadDate: now,
        streakDays: newStreak,
      );

      await _dataSource.savePlan(updated);
      updatedPlans.add(updated);

      if (updatedActivePlan?.id == updated.id) {
        updatedActivePlan = updated;
      }
    }

    state = state.copyWith(
      plans: updatedPlans,
      activePlan: updatedActivePlan,
    );
  }

  /// Manually mark today's target as finished
  Future<void> markTodayAsCompleted() async {
    final current = state.activePlan;
    if (current == null) return;

    final now = DateTime.now();
    final newStreak = current.isTodayCompleted ? current.streakDays : current.streakDays + 1;
    final nextTarget = min(current.totalPages, current.todayEndPage + 1);

    final updated = current.copyWith(
      todayCurrentPage: current.todayEndPage,
      currentPage: nextTarget,
      completedPagesCount: min(current.totalPages, current.todayEndPage),
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
