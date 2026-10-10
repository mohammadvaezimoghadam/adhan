import 'dart:math';

enum StudyPlanType {
  continuousDaily, // روزانه مستمر (همیشه فعال)
  fixedDays,       // دوره مشخص (مثلاً ۱۰ روزه)
}

enum StudyPlanUnit {
  page, // صفحه
  hizb, // حزب
  juz, // جزء
  surah, // سوره
}

enum StudyPlanStatus {
  active,
  inactive,
  completed, // تموم شده
  expired,
}

/// Domain model representing a user's Quran Study / Khatm Plan persisted in Hive.
class StudyPlan {
  final String id;
  final String title;
  final StudyPlanType type;
  final bool isOngoing; // آیا روزانه همیشگی است یا دوره محدود دارد
  final StudyPlanUnit unit;
  final int unitAmount;
  final int targetDays; // تعداد روزهای دوره (مثلاً ۱۰ روزه)
  final int dailyPagesTarget;
  final int totalPages; // کل صفحات هدف دوره
  final DateTime startDate;
  final DateTime targetEndDate;
  final int currentPage; // آخرین صفحه خوانده شده
  final int completedPagesCount;
  final StudyPlanStatus status;

  // Today's target & progress
  final int todayStartPage;
  final int todayEndPage;
  final int todayCurrentPage;
  final bool isTodayCompleted;
  final DateTime? lastReadDate;
  final int streakDays;
  final DateTime createdAt;

  const StudyPlan({
    required this.id,
    required this.title,
    required this.type,
    this.isOngoing = false,
    this.unit = StudyPlanUnit.page,
    this.unitAmount = 1,
    required this.targetDays,
    required this.dailyPagesTarget,
    this.totalPages = 604,
    required this.startDate,
    required this.targetEndDate,
    this.currentPage = 1,
    this.completedPagesCount = 0,
    this.status = StudyPlanStatus.active,
    required this.todayStartPage,
    required this.todayEndPage,
    this.todayCurrentPage = 1,
    this.isTodayCompleted = false,
    this.lastReadDate,
    this.streakDays = 0,
    required this.createdAt,
  });

  /// Factory helper to create a new plan with initial defaults
  factory StudyPlan.create({
    required String id,
    required String title,
    required StudyPlanType type,
    bool isOngoing = false,
    required int targetDays,
    StudyPlanUnit unit = StudyPlanUnit.page,
    int unitAmount = 1,
    int? customDailyPages,
    int totalPages = 604,
    DateTime? startDate,
  }) {
    final start = startDate ?? DateTime.now();

    // Calculate pages per day based on selected unit
    int calculatedDaily;
    if (customDailyPages != null) {
      calculatedDaily = customDailyPages;
    } else {
      switch (unit) {
        case StudyPlanUnit.hizb:
          calculatedDaily = max(1, 5 * unitAmount); // ~5 pages per Hizb
          break;
        case StudyPlanUnit.juz:
          calculatedDaily = max(1, 20 * unitAmount); // ~20 pages per Juz
          break;
        case StudyPlanUnit.page:
          calculatedDaily = max(1, unitAmount);
          break;
        case StudyPlanUnit.surah:
          calculatedDaily = max(1, unitAmount * 2);
          break;
      }
    }

    // For ongoing daily plan, end date is in far future, targetDays is 0
    final effectiveDays = isOngoing ? 3650 : max(1, targetDays);
    final end = start.add(Duration(days: effectiveDays));
    final planTotalPages = isOngoing
        ? totalPages
        : min(totalPages, max(1, targetDays * calculatedDaily));
    final todayEnd = min(planTotalPages, 1 + calculatedDaily - 1);

    return StudyPlan(
      id: id,
      title: title,
      type: type,
      isOngoing: isOngoing,
      unit: unit,
      unitAmount: unitAmount,
      targetDays: isOngoing ? 0 : targetDays,
      dailyPagesTarget: calculatedDaily,
      totalPages: planTotalPages,
      startDate: start,
      targetEndDate: end,
      currentPage: 1,
      completedPagesCount: 0,
      status: StudyPlanStatus.active,
      todayStartPage: 1,
      todayEndPage: todayEnd,
      todayCurrentPage: 1,
      isTodayCompleted: false,
      lastReadDate: null,
      streakDays: 0,
      createdAt: DateTime.now(),
    );
  }

  /// User-friendly Persian description of daily quota
  String get unitDescription {
    switch (unit) {
      case StudyPlanUnit.page:
        return 'روزی $unitAmount صفحه';
      case StudyPlanUnit.hizb:
        return 'روزی $unitAmount حزب';
      case StudyPlanUnit.juz:
        return 'روزی $unitAmount جزء';
      case StudyPlanUnit.surah:
        return 'روزی $unitAmount سوره';
    }
  }

  /// User-friendly duration description
  String get durationDescription {
    if (isOngoing) {
      return 'برنامه روزانه همیشگی';
    }
    return '${targetDays.toString()} روزه';
  }

  /// Calculates total progress as percentage between 0.0 and 1.0
  double get overallProgress {
    if (totalPages <= 0) return 0.0;
    return (completedPagesCount / totalPages).clamp(0.0, 1.0);
  }

  /// Calculates today's progress as percentage between 0.0 and 1.0
  double get todayProgress {
    if (isTodayCompleted) return 1.0;
    final range = todayEndPage - todayStartPage + 1;
    if (range <= 0) return 0.0;
    
    final completedBeforeToday = todayStartPage - 1;
    final doneToday = completedPagesCount - completedBeforeToday;
    
    return (max(0, doneToday) / range).clamp(0.0, 1.0);
  }

  /// Remaining days until target deadline (0 if ongoing)
  int get remainingDays {
    if (isOngoing) return 0;
    final now = DateTime.now();
    final diff = targetEndDate.difference(now).inDays;
    return max(0, diff);
  }

  /// Checks if deadline has passed
  bool get isPeriodEnded {
    if (isOngoing) return false;
    return DateTime.now().isAfter(targetEndDate);
  }

  StudyPlan copyWith({
    String? id,
    String? title,
    StudyPlanType? type,
    bool? isOngoing,
    StudyPlanUnit? unit,
    int? unitAmount,
    int? targetDays,
    int? dailyPagesTarget,
    int? totalPages,
    DateTime? startDate,
    DateTime? targetEndDate,
    int? currentPage,
    int? completedPagesCount,
    StudyPlanStatus? status,
    int? todayStartPage,
    int? todayEndPage,
    int? todayCurrentPage,
    bool? isTodayCompleted,
    DateTime? lastReadDate,
    int? streakDays,
    DateTime? createdAt,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      isOngoing: isOngoing ?? this.isOngoing,
      unit: unit ?? this.unit,
      unitAmount: unitAmount ?? this.unitAmount,
      targetDays: targetDays ?? this.targetDays,
      dailyPagesTarget: dailyPagesTarget ?? this.dailyPagesTarget,
      totalPages: totalPages ?? this.totalPages,
      startDate: startDate ?? this.startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      currentPage: currentPage ?? this.currentPage,
      completedPagesCount: completedPagesCount ?? this.completedPagesCount,
      status: status ?? this.status,
      todayStartPage: todayStartPage ?? this.todayStartPage,
      todayEndPage: todayEndPage ?? this.todayEndPage,
      todayCurrentPage: todayCurrentPage ?? this.todayCurrentPage,
      isTodayCompleted: isTodayCompleted ?? this.isTodayCompleted,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      streakDays: streakDays ?? this.streakDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'isOngoing': isOngoing,
      'unit': unit.name,
      'unitAmount': unitAmount,
      'targetDays': targetDays,
      'dailyPagesTarget': dailyPagesTarget,
      'totalPages': totalPages,
      'startDate': startDate.toIso8601String(),
      'targetEndDate': targetEndDate.toIso8601String(),
      'currentPage': currentPage,
      'completedPagesCount': completedPagesCount,
      'status': status.name,
      'todayStartPage': todayStartPage,
      'todayEndPage': todayEndPage,
      'todayCurrentPage': todayCurrentPage,
      'isTodayCompleted': isTodayCompleted,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'streakDays': streakDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudyPlan.fromMap(Map<dynamic, dynamic> map) {
    return StudyPlan(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'برنامه مطالعه قرآن',
      type: StudyPlanType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StudyPlanType.fixedDays,
      ),
      isOngoing: map['isOngoing'] == true,
      unit: StudyPlanUnit.values.firstWhere(
        (e) => e.name == map['unit'],
        orElse: () => StudyPlanUnit.page,
      ),
      unitAmount: (map['unitAmount'] as num?)?.toInt() ?? 1,
      targetDays: (map['targetDays'] as num?)?.toInt() ?? 10,
      dailyPagesTarget: (map['dailyPagesTarget'] as num?)?.toInt() ?? 5,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 604,
      startDate: DateTime.tryParse(map['startDate']?.toString() ?? '') ??
          DateTime.now(),
      targetEndDate:
          DateTime.tryParse(map['targetEndDate']?.toString() ?? '') ??
              DateTime.now().add(const Duration(days: 10)),
      currentPage: (map['currentPage'] as num?)?.toInt() ?? 1,
      completedPagesCount:
          (map['completedPagesCount'] as num?)?.toInt() ?? 0,
      status: StudyPlanStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StudyPlanStatus.active,
      ),
      todayStartPage: (map['todayStartPage'] as num?)?.toInt() ?? 1,
      todayEndPage: (map['todayEndPage'] as num?)?.toInt() ?? 5,
      todayCurrentPage: (map['todayCurrentPage'] as num?)?.toInt() ?? 1,
      isTodayCompleted: map['isTodayCompleted'] == true,
      lastReadDate: map['lastReadDate'] != null
          ? DateTime.tryParse(map['lastReadDate'].toString())
          : null,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
