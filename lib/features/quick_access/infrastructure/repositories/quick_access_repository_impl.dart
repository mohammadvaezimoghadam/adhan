import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../common/exceptions/failure.dart';
import '../../../../core/routes/route_name.dart';
import '../../domain/entities/quick_access_tool_entity.dart';
import '../../domain/repositories/quick_access_repository.dart';
import '../datasources/quick_access_local_datasource.dart';

final quickAccessRepositoryProvider = Provider<IQuickAccessRepository>((ref) {
  final localDataSource = ref.watch(quickAccessLocalDataSourceProvider);
  return QuickAccessRepositoryImpl(localDataSource);
});

class QuickAccessRepositoryImpl implements IQuickAccessRepository {
  final IQuickAccessLocalDataSource _localDataSource;

  QuickAccessRepositoryImpl(this._localDataSource);

  @override
  List<QuickAccessToolEntity> getAllToolsCatalog() {
    return const [
      QuickAccessToolEntity(
        type: QuickAccessToolType.downloads,
        title: 'دانلودها',
        description: 'مدیریت فایل‌های صوتی و ترجمه‌ها',
        iconData: CupertinoIcons.arrow_down_circle,
        routeName: downloadHubRoute,
      ),
      QuickAccessToolEntity(
        type: QuickAccessToolType.lastRead,
        title: 'ادامه قرائت',
        description: 'پرش مستقیم به آخرین آیه مطالعه‌شده',
        iconData: CupertinoIcons.book,
      ),
      QuickAccessToolEntity(
        type: QuickAccessToolType.bookmarks,
        title: 'نشانه‌ها',
        description: 'فهرست آیات و صفحات نشانه‌گذاری شده',
        iconData: CupertinoIcons.bookmark,
      ),
      QuickAccessToolEntity(
        type: QuickAccessToolType.dictionary,
        title: 'لغت‌نامه',
        description: 'ترجمه کلمه به کلمه و واژگان سوره‌ها',
        iconData: CupertinoIcons.textformat_abc_dottedunderline,
        isReady: true,
      ),
      QuickAccessToolEntity(
        type: QuickAccessToolType.pinnedSurah,
        title: 'سوره منتخب',
        description: 'سنجاق کردن یک سوره خاص برای قرائت روزانه',
        iconData: CupertinoIcons.star,
        isReady: true,
      ),
      QuickAccessToolEntity(
        type: QuickAccessToolType.personalList,
        title: 'فهرست من',
        description: 'برنامه‌ریزی و مجموعه‌های شخصی قرائت',
        iconData: CupertinoIcons.square_list,
        isReady: true,
      ),
      // QuickAccessToolEntity(
      //   type: QuickAccessToolType.topicStudio,
      //   title: 'دفتر تفکر',
      //   description: 'ثبت تأملات و تدوین یادداشت‌های موضوعی',
      //   iconData: CupertinoIcons.square_pencil,
      //   isReady: true,
      // ),
    ];
  }

  @override
  int? getPinnedSurahId() {
    return _localDataSource.getPinnedSurahId();
  }

  @override
  Future<Result<void, Failure>> savePinnedSurahId(int? surahId) async {
    try {
      await _localDataSource.savePinnedSurahId(surahId);
      return const Success(null);
    } catch (e, stack) {
      return Error(Failure(message: 'خطا در ذخیره سوره منتخب: $e', stackTrace: stack));
    }
  }

  @override
  Future<Result<List<String?>, Failure>> getRawSlotIds() async {
    try {
      final slotIds = _localDataSource.getSavedSlotIds();
      while (slotIds.length < 4) {
        slotIds.add(null);
      }
      return Success(slotIds.take(4).toList());
    } catch (e, stack) {
      return Error(Failure(message: 'خطا در خواندن اسلات‌های خام: $e', stackTrace: stack));
    }
  }

  @override
  Future<Result<void, Failure>> setRawSlotId(int index, String? rawSlotId) async {
    try {
      final slotIds = _localDataSource.getSavedSlotIds();
      while (slotIds.length < 4) {
        slotIds.add(null);
      }
      slotIds[index] = rawSlotId;
      await _localDataSource.saveSlotIds(slotIds);
      return const Success(null);
    } catch (e, stack) {
      return Error(Failure(message: 'خطا در ذخیره شناسه خام اسلات: $e', stackTrace: stack));
    }
  }

  @override
  Future<Result<List<QuickAccessToolType?>, Failure>> getSlots() async {
    try {
      final slotIds = _localDataSource.getSavedSlotIds();
      final slots = slotIds.map((id) => QuickAccessToolType.fromId(id)).toList();
      while (slots.length < 4) {
        slots.add(null);
      }
      return Success(slots.take(4).toList());
    } catch (e, stack) {
      return Error(Failure(message: 'خطا در خواندن اسلات‌ها: $e', stackTrace: stack));
    }
  }

  @override
  Future<Result<void, Failure>> setSlot(int index, QuickAccessToolType? toolType) async {
    return setRawSlotId(index, toolType?.id);
  }

  @override
  Future<Result<void, Failure>> clearSlot(int index) async {
    return setRawSlotId(index, null);
  }
}
