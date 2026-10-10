import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/study_plan.dart';
import '../../application/controllers/study_plan_controller.dart';

/// Clean, Simple & Modern Settings Screen for creating a Quran Study Plan.
class CreateStudyPlanScreen extends ConsumerStatefulWidget {
  const CreateStudyPlanScreen({super.key});

  @override
  ConsumerState<CreateStudyPlanScreen> createState() =>
      _CreateStudyPlanScreenState();
}

class _CreateStudyPlanScreenState extends ConsumerState<CreateStudyPlanScreen> {
  // Selected daily unit & quantity
  StudyPlanUnit _selectedUnit = StudyPlanUnit.hizb;
  int _unitAmount = 1;

  // Selected duration
  int _selectedDays = 10;
  bool _isCustomDays = false;
  final _customDaysController = TextEditingController(text: '10');

  late final TextEditingController _titleController;

  final List<int> _dayOptions = [10, 20, 30, 60];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _generateDefaultTitle());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customDaysController.dispose();
    super.dispose();
  }

  String _getUnitTitle(StudyPlanUnit unit) {
    switch (unit) {
      case StudyPlanUnit.page:
        return 'صفحه';
      case StudyPlanUnit.hizb:
        return 'حزب';
      case StudyPlanUnit.juz:
        return 'جزء';
      case StudyPlanUnit.surah:
        return 'سوره';
    }
  }

  String _generateDefaultTitle() {
    final days = _isCustomDays
        ? (int.tryParse(_customDaysController.text) ?? 10)
        : _selectedDays;
    final unitDesc = 'روزی ${_unitAmount.toPersianDigit()} ${_getUnitTitle(_selectedUnit)}';
    return 'برنامه ${days.toPersianDigit()} روزه ($unitDesc)';
  }

  void _updateTitleIfDefault() {
    _titleController.text = _generateDefaultTitle();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim().isEmpty
        ? _generateDefaultTitle()
        : _titleController.text.trim();

    int days = _selectedDays;
    if (_isCustomDays) {
      final custom = int.tryParse(_customDaysController.text.trim());
      if (custom == null || custom < 1 || custom > 730) {
        AppSnackBar.showError(
            context, 'مدت زمان باید عددی بین ۱ تا ۷۳۰ روز باشد.');
        return;
      }
      days = custom;
    }

    HapticFeedback.mediumImpact();
    await ref.read(studyPlanControllerProvider.notifier).createPlan(
          title: title,
          type: StudyPlanType.fixedDays,
          targetDays: days,
          unit: _selectedUnit,
          unitAmount: _unitAmount,
        );

    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(
        context,
        'برنامه «$title» با موفقیت ساخته و فعال شد.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colors.cardBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              CupertinoIcons.back,
              color: colorScheme.primary,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
          title: Text(
            'ایجاد برنامه مطالعه',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.marginPage,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ۱. تنظیم واحد مطالعه روزانه ──
              _buildSectionTitle('۱. روزانه چقدر می‌خوانید؟'),
              12.vSpace,
              Container(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.cardBorder, width: 0.8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Unit selector pills
                    Row(
                      children: StudyPlanUnit.values.map((unit) {
                        final isSelected = _selectedUnit == unit;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedUnit = unit;
                                  _updateTitleIfDefault();
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF7F5F0)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getUnitTitle(unit),
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    16.vSpace,

                    // Quantity Counter Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تعداد ${_getUnitTitle(_selectedUnit)} در روز:',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF7F5F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(CupertinoIcons.minus, size: 18),
                                color: _unitAmount > 1
                                    ? colorScheme.primary
                                    : Colors.grey,
                                onPressed: _unitAmount > 1
                                    ? () {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _unitAmount--;
                                          _updateTitleIfDefault();
                                        });
                                      }
                                    : null,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  _unitAmount.toPersianDigit(),
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.plus, size: 18),
                                color: colorScheme.primary,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _unitAmount++;
                                    _updateTitleIfDefault();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              24.vSpace,

              // ── ۲. مدت زمان دوره ──
              _buildSectionTitle('۲. مدت زمان برنامه (چند روزه؟)'),
              12.vSpace,
              Container(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.cardBorder, width: 0.8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Preset day chips
                    Row(
                      children: _dayOptions.map((days) {
                        final isSelected = !_isCustomDays && _selectedDays == days;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedDays = days;
                                  _isCustomDays = false;
                                  _updateTitleIfDefault();
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF7F5F0)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${days.toPersianDigit()} روزه',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 12.5,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    14.vSpace,

                    // Custom days row
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isCustomDays = true;
                          _updateTitleIfDefault();
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCustomDays
                              ? colorScheme.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isCustomDays
                                ? colorScheme.primary
                                : colors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCustomDays
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: _isCustomDays
                                  ? colorScheme.primary
                                  : colors.cardBorder,
                              size: 18,
                            ),
                            10.hSpace,
                            Expanded(
                              child: Text(
                                'تعداد روز دلخواه:',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (_isCustomDays)
                              SizedBox(
                                width: 75,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: colorScheme.primary, width: 1),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: TextField(
                                    controller: _customDaysController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _updateTitleIfDefault();
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      suffixText: 'روز',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              24.vSpace,

              // ── ۳. عنوان برنامه ──
              _buildSectionTitle('۳. عنوان برنامه:'),
              8.vSpace,
              Container(
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.cardBorder, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'عنوان برنامه مطالعه',
                  ),
                ),
              ),

              32.vSpace,

              // Action button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ثبت و شروع برنامه',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
