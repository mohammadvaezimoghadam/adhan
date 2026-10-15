import 'dart:math';

import '../../../surah_list/infrastructure/datasources/static_surahs_data.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';

enum StudyPlanType {
  continuousDaily, // روزانه مستمر (همیشه فعال)
  fixedDays,       // دوره مشخص (مثلاً ۱۰ روزه)
}

enum StudyPlanUnit {
  ayah, // آیه
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

/// Calculates the 1-based global index of an ayah in the Quran (1 to 6236)
int getGlobalAyahIndex(int surahId, int ayahNumber) {
  int total = 0;
  for (int i = 0; i < surahId - 1 && i < kStaticQuranSurahs.length; i++) {
    total += kStaticQuranSurahs[i].numberOfAyahs;
  }
  return total + ayahNumber;
}

/// Converts a 1-based global ayah index (1 to 6236) back to (surahId, ayahNumber)
({int surahId, int ayahNumber}) getSurahAndAyahFromGlobalIndex(int globalIndex) {
  int current = globalIndex.clamp(1, 6236);
  for (int i = 0; i < kStaticQuranSurahs.length; i++) {
    final count = kStaticQuranSurahs[i].numberOfAyahs;
    if (current <= count) {
      return (surahId: i + 1, ayahNumber: current);
    }
    current -= count;
  }
  return (surahId: 114, ayahNumber: 6);
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
  final DateTime? lastActiveDate;
  final int streakDays;
  final DateTime createdAt;

  // Exact reading position & live fraction
  final int? lastReadSurahId;
  final String? lastReadSurahName;
  final int? lastReadAyahNumber;
  final double todayProgressFraction;

  // Ayah-specific tracking
  final int? todayStartAyahGlobal;
  final int? todayAyahsRead;
  final int? completedAyahsCount;

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
    this.lastActiveDate,
    this.streakDays = 0,
    required this.createdAt,
    this.lastReadSurahId,
    this.lastReadSurahName,
    this.lastReadAyahNumber,
    this.todayProgressFraction = 0.0,
    this.todayStartAyahGlobal,
    this.todayAyahsRead = 0,
    this.completedAyahsCount = 0,
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
        case StudyPlanUnit.ayah:
          calculatedDaily = max(1, (unitAmount / 15).ceil());
          break;
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
      lastActiveDate: start,
      streakDays: 0,
      createdAt: DateTime.now(),
      todayStartAyahGlobal: unit == StudyPlanUnit.ayah ? 1 : null,
      todayAyahsRead: 0,
      completedAyahsCount: 0,
    );
  }

  /// Returns a new StudyPlan with modified user configuration (title, mode, duration, unit, amount)
  /// while preserving user's current reading progress, completed pages, and streak.
  StudyPlan updateConfiguration({
    required String title,
    required bool isOngoing,
    required int targetDays,
    required StudyPlanUnit unit,
    required int unitAmount,
    int? customDailyPages,
  }) {
    int calculatedDaily;
    if (customDailyPages != null) {
      calculatedDaily = customDailyPages;
    } else {
      switch (unit) {
        case StudyPlanUnit.ayah:
          calculatedDaily = max(1, (unitAmount / 15).ceil());
          break;
        case StudyPlanUnit.hizb:
          calculatedDaily = max(1, 5 * unitAmount);
          break;
        case StudyPlanUnit.juz:
          calculatedDaily = max(1, 20 * unitAmount);
          break;
        case StudyPlanUnit.page:
          calculatedDaily = max(1, unitAmount);
          break;
        case StudyPlanUnit.surah:
          calculatedDaily = max(1, unitAmount * 2);
          break;
      }
    }

    final effectiveDays = isOngoing ? 3650 : max(1, targetDays);
    final end = startDate.add(Duration(days: effectiveDays));
    final planTotalPages = isOngoing
        ? totalPages
        : min(totalPages, max(1, targetDays * calculatedDaily));
    final newTodayEnd = min(planTotalPages, todayStartPage + calculatedDaily - 1);

    return copyWith(
      title: title,
      type: isOngoing ? StudyPlanType.continuousDaily : StudyPlanType.fixedDays,
      isOngoing: isOngoing,
      unit: unit,
      unitAmount: unitAmount,
      targetDays: isOngoing ? 0 : targetDays,
      dailyPagesTarget: calculatedDaily,
      totalPages: planTotalPages,
      targetEndDate: end,
      todayEndPage: newTodayEnd,
      todayStartAyahGlobal: unit == StudyPlanUnit.ayah ? (todayStartAyahGlobal ?? 1) : null,
    );
  }

  /// User-friendly Persian description of daily quota
  String get unitDescription {
    final amountFa = unitAmount.toPersianDigit();
    switch (unit) {
      case StudyPlanUnit.ayah:
        return 'روزی $amountFa آیه';
      case StudyPlanUnit.page:
        return 'روزی $amountFa صفحه';
      case StudyPlanUnit.hizb:
        return 'روزی $amountFa حزب';
      case StudyPlanUnit.juz:
        return 'روزی $amountFa جزء';
      case StudyPlanUnit.surah:
        return 'روزی $amountFa سوره';
    }
  }

  /// User-friendly duration description (empty for ongoing to prevent repetition)
  String get durationDescription {
    if (isOngoing) {
      return '';
    }
    return '${targetDays.toPersianDigit()} روزه';
  }

  /// Clean quota text without redundant 'برنامه روزانه'
  String get quotaDescription {
    if (isOngoing || durationDescription.isEmpty) {
      return unitDescription;
    }
    return '$unitDescription • $durationDescription';
  }

  /// User-facing display title for cards (e.g. "روزی ۲ صفحه" or "روزی ۳ صفحه (۱۰ روز)")
  String get displayTitle {
    final clean = cleanTitle;
    final isDefault = clean == 'برنامه روزانه' ||
        clean.isEmpty ||
        RegExp(r'^برنامه\s+(مطالعه\s+)?([0-9۰-۹]+)?\s*روزه?$').hasMatch(clean);
    if (isDefault) {
      if (!isOngoing && targetDays > 0) {
        return '$unitDescription (${targetDays.toPersianDigit()} روز)';
      }
      return unitDescription;
    }
    if (!isOngoing && targetDays > 0) {
      return '$clean (${targetDays.toPersianDigit()} روز)';
    }
    return clean;
  }

  /// Strips any leading 'سوره' or 'سُورَةُ' to prevent repeating the word 'سوره'
  static String _cleanSurahName(String raw) {
    final clean = raw
        .replaceAll(RegExp(r'^(سُورَةُ\s*|سُورَةِ\s*|سوره\s*|سورة\s*)'), '')
        .trim();
    return clean.isEmpty ? raw : clean;
  }

  /// Short summarized location or completion status for home card (top-left)
  String get summarizedLocation {
    if (isTodayCompleted) {
      return 'تکمیل شده';
    }

    if (unit == StudyPlanUnit.ayah) {
      final currentGlobal =
          min(6236, (todayStartAyahGlobal ?? 1) + (todayAyahsRead ?? 0));
      final pos = getSurahAndAyahFromGlobalIndex(currentGlobal);
      final surahName = _cleanSurahName(pos.surahId.surahNameFa);
      return 'سوره $surahName • آیه ${pos.ayahNumber.toPersianDigit()}';
    }

    final targetPage = nextPageToRead;
    String surahName = '';
    for (int i = kStaticQuranSurahs.length - 1; i >= 0; i--) {
      if (kStaticQuranSurahs[i].startPage <= targetPage) {
        surahName = kStaticQuranSurahs[i].number.surahNameFa;
        break;
      }
    }
    surahName = _cleanSurahName(surahName);

    if (lastReadSurahName != null &&
        lastReadAyahNumber != null &&
        currentPage >= nextPageToRead) {
      final cleanLastSurah = _cleanSurahName(lastReadSurahName!);
      return 'سوره $cleanLastSurah • آیه ${lastReadAyahNumber!.toPersianDigit()}';
    }

    return 'صفحه ${targetPage.toPersianDigit()} • سوره $surahName';
  }

  /// Calculates total progress as percentage between 0.0 and 1.0
  double get overallProgress {
    if (unit == StudyPlanUnit.ayah) {
      final totalAyahsTarget =
          isOngoing ? 6236 : max(1, targetDays * unitAmount);
      return ((completedAyahsCount ?? 0) / totalAyahsTarget).clamp(0.0, 1.0);
    }
    if (totalPages <= 0) return 0.0;
    return (completedPagesCount / totalPages).clamp(0.0, 1.0);
  }

  /// Total target pages for today's slice
  int get todayTargetPagesCount => max(1, todayEndPage - todayStartPage + 1);

  /// Number of pages read in today's slice
  int get todayCompletedPagesCount {
    if (isTodayCompleted) return todayTargetPagesCount;
    final count = completedPagesCount - (todayStartPage - 1);
    return count.clamp(0, todayTargetPagesCount);
  }

  /// Calculates today's progress as percentage between 0.0 and 1.0
  double get todayProgress {
    if (isTodayCompleted) return 1.0;
    if (unit == StudyPlanUnit.ayah) {
      if (unitAmount <= 0) return 0.0;
      final ayahFraction = (todayAyahsRead ?? 0) / unitAmount;
      return max(todayProgressFraction, ayahFraction).clamp(0.0, 1.0);
    }
    if (todayTargetPagesCount <= 0) return 0.0;
    final pagesFraction = todayCompletedPagesCount / todayTargetPagesCount;
    return max(todayProgressFraction, pagesFraction).clamp(0.0, 1.0);
  }

  /// User's current reading location (Surah, Ayah, Page)
  String get currentLocationDescription {
    if (isTodayCompleted) {
      if (unit == StudyPlanUnit.ayah) {
        final lastGlobal =
            min(6236, (todayStartAyahGlobal ?? 1) + unitAmount - 1);
        final pos = getSurahAndAyahFromGlobalIndex(lastGlobal);
        final surahName = _cleanSurahName(pos.surahId.surahNameFa);
        return 'تکمیل امروز • تا سوره $surahName، آیه ${pos.ayahNumber.toPersianDigit()}';
      }
      return 'تکمیل امروز • تا پایان صفحه ${todayEndPage.toPersianDigit()}';
    }

    if (unit == StudyPlanUnit.ayah) {
      final currentGlobal =
          min(6236, (todayStartAyahGlobal ?? 1) + (todayAyahsRead ?? 0));
      final pos = getSurahAndAyahFromGlobalIndex(currentGlobal);
      final surahName = _cleanSurahName(pos.surahId.surahNameFa);
      final readCount = ((todayAyahsRead ?? 0) + 1)
          .clamp(1, unitAmount)
          .toPersianDigit();
      final total = unitAmount.toPersianDigit();
      return 'موقعیت: سوره $surahName، آیه ${pos.ayahNumber.toPersianDigit()} (آیه $readCount از $total)';
    }

    // Page-based (or juz/hizb)
    final hasUnfinishedAyah = lastReadSurahName != null &&
        lastReadAyahNumber != null &&
        currentPage >= nextPageToRead;

    final targetPage = nextPageToRead;
    String surahName = '';
    for (int i = kStaticQuranSurahs.length - 1; i >= 0; i--) {
      if (kStaticQuranSurahs[i].startPage <= targetPage) {
        surahName = kStaticQuranSurahs[i].number.surahNameFa;
        break;
      }
    }
    surahName = _cleanSurahName(surahName);

    if (hasUnfinishedAyah) {
      final cleanLast = _cleanSurahName(lastReadSurahName!);
      return 'موقعیت: سوره $cleanLast، آیه ${lastReadAyahNumber!.toPersianDigit()} (صفحه ${targetPage.toPersianDigit()})';
    }

    final todayPageNumber =
        (targetPage - todayStartPage + 1).clamp(1, todayTargetPagesCount);
    return 'موقعیت: صفحه ${targetPage.toPersianDigit()} • سوره $surahName (صفحه ${todayPageNumber.toPersianDigit()} از ${todayTargetPagesCount.toPersianDigit()})';
  }

  /// The next page number that needs to be read
  int get nextPageToRead {
    if (isTodayCompleted) return todayEndPage;
    return min(todayEndPage, todayStartPage + todayCompletedPagesCount);
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
    DateTime? lastActiveDate,
    int? streakDays,
    DateTime? createdAt,
    int? lastReadSurahId,
    String? lastReadSurahName,
    int? lastReadAyahNumber,
    double? todayProgressFraction,
    bool clearLastReadPosition = false,
    int? todayStartAyahGlobal,
    int? todayAyahsRead,
    int? completedAyahsCount,
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
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      streakDays: streakDays ?? this.streakDays,
      createdAt: createdAt ?? this.createdAt,
      lastReadSurahId: clearLastReadPosition ? null : (lastReadSurahId ?? this.lastReadSurahId),
      lastReadSurahName: clearLastReadPosition ? null : (lastReadSurahName ?? this.lastReadSurahName),
      lastReadAyahNumber: clearLastReadPosition ? null : (lastReadAyahNumber ?? this.lastReadAyahNumber),
      todayProgressFraction: todayProgressFraction ?? (clearLastReadPosition ? 0.0 : this.todayProgressFraction),
      todayStartAyahGlobal: todayStartAyahGlobal ?? this.todayStartAyahGlobal,
      todayAyahsRead: todayAyahsRead ?? this.todayAyahsRead,
      completedAyahsCount: completedAyahsCount ?? this.completedAyahsCount,
    );
  }

  /// Title with any parenthesized text stripped out (e.g. "برنامه روزانه (روزی ۱ صفحه)" -> "برنامه روزانه")
  String get cleanTitle {
    final clean = title.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    return clean.isEmpty ? title : clean;
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
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'streakDays': streakDays,
      'createdAt': createdAt.toIso8601String(),
      'lastReadSurahId': lastReadSurahId,
      'lastReadSurahName': lastReadSurahName,
      'lastReadAyahNumber': lastReadAyahNumber,
      'todayProgressFraction': todayProgressFraction,
      'todayStartAyahGlobal': todayStartAyahGlobal,
      'todayAyahsRead': todayAyahsRead,
      'completedAyahsCount': completedAyahsCount,
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
      isTodayCompleted: ((map['completedPagesCount'] as num?)?.toInt() ?? 0) > 0 &&
          map['isTodayCompleted'] == true,
      lastReadDate: map['lastReadDate'] != null
          ? DateTime.tryParse(map['lastReadDate'].toString())
          : null,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.tryParse(map['lastActiveDate'].toString())
          : null,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      lastReadSurahId: (map['lastReadSurahId'] as num?)?.toInt(),
      lastReadSurahName: map['lastReadSurahName']?.toString(),
      lastReadAyahNumber: (map['lastReadAyahNumber'] as num?)?.toInt(),
      todayProgressFraction: (map['todayProgressFraction'] as num?)?.toDouble() ?? 0.0,
      todayStartAyahGlobal: (map['todayStartAyahGlobal'] as num?)?.toInt(),
      todayAyahsRead: (map['todayAyahsRead'] as num?)?.toInt() ?? 0,
      completedAyahsCount: (map['completedAyahsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
