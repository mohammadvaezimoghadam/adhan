import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/widgets/app_modal_header.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../bookmarks/presentation/widgets/manage_labels_bottom_sheet.dart';
import '../../../main_navigation/application/tab_navigation_controller.dart';
import '../../../quran_reader/presentation/widgets/quick_settings_drawer.dart';
import '../../../subscription/application/vip_subscription_controller.dart';
import '../../../translation_manager/presentation/widgets/translation_manager_bottom_sheet.dart';

/// Clean Apple-Style Settings Screen with Profile & Subscription Integration
class SettingsScreen extends ConsumerWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const SettingsScreen({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;
    final isVip = ref.watch(hasVipAccessProvider);
    final vipState = ref.watch(vipSubscriptionControllerProvider);

    final profileSubtitle = isVip
        ? (vipState.remainingDays > 0
            ? 'اشتراک ویژه فعال است (${vipState.remainingDays} روز باقی‌مانده)'
                .toPersianDigit()
            : 'اشتراک ویژه فعال است (مشاهده و تمدید)')
        : 'کاربر عادی - خرید و ارتقا به اشتراک ویژه تفکر';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62.0),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8.0,
            right: 8.0,
            bottom: 6.0,
          ),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: colors.cardBorder,
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showBackButton)
                IconButton(
                  tooltip: 'بازگشت',
                  icon: Icon(
                    CupertinoIcons.chevron_forward,
                    size: 24,
                    color: colorScheme.onSurface,
                  ),
                  splashRadius: 22,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onBackPressed != null) {
                      onBackPressed!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      ref
                          .read(tabNavigationControllerProvider.notifier)
                          .handleBackPress();
                    }
                  },
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'تنظیمات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        children: [
          // Section 1: Profile & Account (No icon, identical to other items)
          _buildSectionHeader('پروفایل', isDark),
          6.vSpace,
          _buildGroupCard(
            context: context,
            children: [
              _buildSettingsTile(
                context: context,
                title: 'پروفایل',
                subtitle: profileSubtitle,
                trailing: isVip
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.18 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withValues(
                              alpha: isDark ? 0.35 : 0.25,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'ویژه',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : null,
                onTap: () => context.pushNamed(profileRoute),
              ),
            ],
          ),
          18.vSpace,

          // Section 2: Reading Experience & Content
          _buildSectionHeader('مطالعه و محتوا', isDark),
          6.vSpace,
          _buildGroupCard(
            context: context,
            children: [
              _buildSettingsTile(
                context: context,
                title: 'تنظیمات متن و قرائت',
                subtitle: 'اندازه قلم، نوع خط، فاصله خطوط و رنگ اعراب',
                onTap: () => QuickSettingsDrawer.show(context),
              ),
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 16,
                endIndent: 16,
                color: colors.cardBorder,
              ),
              _buildSettingsTile(
                context: context,
                title: 'مدیریت ترجمه‌ها',
                subtitle: 'انتخاب مترجم و تنظیمات نمایش ترجمه',
                onTap: () => TranslationManagerBottomSheet.show(context),
              ),
            ],
          ),
          18.vSpace,

          // Section 3: Labels Management
          _buildSectionHeader('برچسب‌ها', isDark),
          6.vSpace,
          _buildGroupCard(
            context: context,
            children: [
              _buildSettingsTile(
                context: context,
                title: 'مدیریت برچسب‌ها',
                subtitle: 'ایجاد، ویرایش و حذف برچسب‌های نشانک',
                onTap: () => ManageLabelsBottomSheet.show(context),
              ),
            ],
          ),
          18.vSpace,

          // Section 4: App Information (No icon, uniform styling)
          _buildSectionHeader('اطلاعات برنامه', isDark),
          6.vSpace,
          _buildGroupCard(
            context: context,
            children: [
              _buildSettingsTile(
                context: context,
                title: 'درباره قرآن تفکر',
                subtitle: 'نسخه ۱.۰.۰',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: colors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppModalHeader(
                  title: 'درباره قرآن تفکر',
                  onClose: () => Navigator.of(dialogCtx).pop(),
                  bottomSpacing: 14,
                ),
                const SizedBox(height: 4),
                Text(
                  'قرآن تفکر',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نسخه ۱.۰.۰',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'اپلیکیشن جامع قرآن تفکر با رسم‌الخط‌های استاندارد، ترجمه‌های معتبر، امکانات پیشرفته مطالعه، تلاوت قاریان برجسته و جستجوی هوشمند در آیات کلام‌الله مجید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    height: 1.6,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'بستن',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : const Color(0xFF7A756D),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.cardBorder,
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    IconData? icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.14 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 19,
                  ),
                ),
                12.hSpace,
              ],

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    2.vSpace,
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              8.hSpace,

              // Trailing Indicator (Status Badge & Chevron)
              if (trailing != null) ...[
                trailing,
                6.hSpace,
              ],
              Icon(
                CupertinoIcons.chevron_left,
                size: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
