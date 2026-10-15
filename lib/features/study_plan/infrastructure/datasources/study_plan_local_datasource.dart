import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local/hive/hive_service_provider.dart';
import '../../../../core/data/local/hive/i_hive_service.dart';
import '../../domain/entities/study_plan.dart';

abstract class IStudyPlanLocalDataSource {
  Future<void> savePlan(StudyPlan plan);
  Future<void> deletePlan(String id);
  Future<StudyPlan?> getPlan(String id);
  Future<List<StudyPlan>> getAllPlans();
  Future<void> setActivePlanId(String? id);
  String? getActivePlanId();
  Future<void> clearAll();
}

class StudyPlanLocalDataSource implements IStudyPlanLocalDataSource {
  static const String boxName = 'study_plans_box';
  static const String _activePlanIdKey = '_active_plan_id_meta_key';

  final IHiveService _hiveService;

  StudyPlanLocalDataSource(this._hiveService);

  @override
  Future<void> savePlan(StudyPlan plan) async {
    try {
      await _hiveService.put(plan.id, plan.toMap(), boxName: boxName);
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error saving plan: $e');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _hiveService.delete(id, boxName: boxName);
      if (getActivePlanId() == id) {
        await setActivePlanId(null);
      }
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error deleting plan: $e');
    }
  }

  @override
  Future<StudyPlan?> getPlan(String id) async {
    try {
      final val = _hiveService.get(id, boxName: boxName);
      if (val is Map) {
        return StudyPlan.fromMap(val);
      }
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error getting plan $id: $e');
    }
    return null;
  }

  @override
  Future<List<StudyPlan>> getAllPlans() async {
    try {
      final values = _hiveService.getValues(boxName: boxName);
      final plans = <StudyPlan>[];
      for (final val in values) {
        if (val is Map) {
          try {
            final map = Map<dynamic, dynamic>.from(val);
            if (map['id'] != null) {
              plans.add(StudyPlan.fromMap(map));
            }
          } catch (_) {}
        }
      }
      // Sort newest first
      plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plans;
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error loading all plans: $e');
      return [];
    }
  }

  @override
  Future<void> setActivePlanId(String? id) async {
    try {
      if (id == null) {
        await _hiveService.delete(_activePlanIdKey, boxName: boxName);
      } else {
        await _hiveService.put(_activePlanIdKey, id, boxName: boxName);
      }
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error setting active plan id: $e');
    }
  }

  @override
  String? getActivePlanId() {
    try {
      final val = _hiveService.get<dynamic>(_activePlanIdKey, boxName: boxName);
      return val?.toString();
    } catch (_) {}
    return null;
  }

  @override
  Future<void> clearAll() async {
    try {
      await _hiveService.clear(boxName: boxName);
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error clearing box: $e');
    }
  }
}

final studyPlanLocalDataSourceProvider =
    Provider<IStudyPlanLocalDataSource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return StudyPlanLocalDataSource(hiveService);
});
