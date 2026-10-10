import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

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

  Box? _box;

  Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
      return _box!;
    }
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  @override
  Future<void> savePlan(StudyPlan plan) async {
    try {
      final box = await _getBox();
      await box.put(plan.id, plan.toMap());
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error saving plan: $e');
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      final box = await _getBox();
      await box.delete(id);
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
      final box = await _getBox();
      final val = box.get(id);
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
      final box = await _getBox();
      final plans = <StudyPlan>[];
      for (final key in box.keys) {
        if (key == _activePlanIdKey) continue;
        final val = box.get(key);
        if (val is Map) {
          try {
            plans.add(StudyPlan.fromMap(val));
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
      final box = await _getBox();
      if (id == null) {
        await box.delete(_activePlanIdKey);
      } else {
        await box.put(_activePlanIdKey, id);
      }
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error setting active plan id: $e');
    }
  }

  @override
  String? getActivePlanId() {
    try {
      if (_box != null && _box!.isOpen) {
        return _box!.get(_activePlanIdKey)?.toString();
      }
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName).get(_activePlanIdKey)?.toString();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      debugPrint('⚠️ [StudyPlanDataSource] Error clearing box: $e');
    }
  }
}

final studyPlanLocalDataSourceProvider =
    Provider<IStudyPlanLocalDataSource>((ref) {
  return StudyPlanLocalDataSource();
});
