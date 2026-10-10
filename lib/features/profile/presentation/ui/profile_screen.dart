// ignore_for_file: unused_element, unused_import
import '../../../tafakor/presentation/widgets/tafakor_profile_status_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/int_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../common/utils/jalali_date.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ota_update/application/controllers/ota_update_controller.dart';
import '../../../ota_update/domain/entities/ota_patch.dart';
import '../../../ota_update/presentation/widgets/ota_update_dialog.dart';
import '../../../subscription/application/vip_subscription_controller.dart';

/// Dedicated Profile Screen featuring user status, subscription details card,
/// and direct navigation to VIP Subscription checkout.
class ProfileScreen extends ConsumerWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ProfileScreen({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = theme.brightness == Brightness.dark;




    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: context.isWideScreen
            ? null
            : PreferredSize(
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
                              context.goNamed(quranHomeRoute);
                            }
                          },
                        )
                      else
                        const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'پروفایل کاربری',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'همگام‌سازی وضعیت',
                        icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 20),
                        splashRadius: 22,
                        onPressed: () async {
                          final controller =
                              ref.read(vipSubscriptionControllerProvider.notifier);
                          await controller.syncWithStore();
                          await controller.fetchLiveProducts();
                          if (!context.mounted) return;
                          AppSnackBar.showSuccess(
                            context,
                            'وضعیت اشتراک با کافه بازار بررسی شد.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isWideScreen ? 760 : double.infinity,
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
            // Clean User Header without decorative icons
            const _UserHeader(),
            16.vSpace,

            // Account Status Grouped Section (کامنت شده به دلیل رایگان بودن تمامی امکانات)
            /*
            _buildSectionHeader('وضعیت حساب', isDark),
            8.vSpace,
            _buildGroupCard(
              context: context,
              children: [
                _buildInfoRow(
                  context: context,
                  label: 'نوع عضویت',
                  valueWidget: Text(
                    isVip ? 'عضویت ویژه تفکر' : 'کاربر عادی',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isVip
                          ? primaryColor
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (isVip) ...[
                  _buildDivider(isDark),
                  _buildInfoRow(
                    context: context,
                    label: 'اعتبار اشتراک',
                    valueWidget: Text(
                      vipState.vipExpiryDate != null
                          ? '${vipState.remainingDays.toPersianDigit()} روز باقی‌مانده'
                              ' (${JalaliDate.fromDateTime(vipState.vipExpiryDate!).format().toPersianDigit()})'
                          : 'دائمی و نامحدود',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            20.vSpace,
            */

            // Tafakor Platform Integration Section
            _buildSectionHeader('پلتفرم تفکر', isDark),
            8.vSpace,
            const TafakorProfileStatusCard(),
            20.vSpace,

            // VIP Subscription Navigation Item (کامنت شده به دلیل رایگان بودن تمامی امکانات)
            /*
            _buildSectionHeader('اشتراک ویژه', isDark),
            8.vSpace,
            _buildGroupCard(
              context: context,
              children: [
                _buildProfileTile(
                  context: context,
                  title: 'اشتراک ویژه',
                  subtitle: isVip
                      ? 'مشاهده پلن‌ها و تمدید اعتبار اشتراک تفکر'
                      : 'دسترسی نامحدود به تمامی قاریان و ترجمه‌های گویا',
                  onTap: () => context.pushNamed(vipSubscriptionRoute),
                ),
              ],
            ),
            20.vSpace,
            */

            // Settings Navigation Item
            _buildSectionHeader('تنظیمات', isDark),
            8.vSpace,
            _buildGroupCard(
              context: context,
              children: [
                _buildProfileTile(
                  context: context,
                  title: 'تنظیمات برنامه',
                  subtitle: 'قلم، تم، مدیریت ترجمه‌ها و اطلاعات نرم‌افزار',
                  onTap: () => context.pushNamed(settingsRoute),
                ),
              ],
            ),
            20.vSpace,

            // OTA Update Navigation Item
            const _OtaUpdateSection(),
            20.vSpace,
            const _ProfileVersionFooter(),
          ],
        ),
      ),
    ),
  ),
);
  }



  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFEAE7E3),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required Widget valueWidget,
  }) {
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          valueWidget,
        ],
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

  Widget _buildProfileTile({
    required BuildContext context,
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

/// Clean, typography-driven user header without decorative icons
class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'کاربر قرآن تفکر',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Dedicated OTA update section isolated from ProfileScreen rebuilds
class _OtaUpdateSection extends ConsumerWidget {
  const _OtaUpdateSection();

  void _showApplyConfirmDialog(BuildContext context, String version) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'اعمال به‌روزرسانی',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          'پچ جدید $version دانلود شده و آماده فعال‌سازی است.\nبرای اعمال تغییرات، برنامه یک‌بار مجدداً راه‌اندازی می‌شود. آیا اکنون راه‌اندازی شود؟',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            height: 1.6,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'بعداً',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await OtaUpdateController.restartApp();
            },
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'اعمال و شروع مجدد',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUpdate =
        ref.watch(otaUpdateControllerProvider.select((s) => s.hasUpdate));
    final isReadyToRestart = ref.watch(
        otaUpdateControllerProvider.select((s) => s.isReadyToRestart));
    final patchVersion =
        ref.watch(otaUpdateControllerProvider.select((s) => s.patch?.version));
    final isNativeApk = ref.watch(
        otaUpdateControllerProvider.select((s) => s.patch?.isNativeApk == true));
    final currentPatch = ref.watch(
        otaUpdateControllerProvider.select((s) => s.currentPatchVersion));

    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    String subtitleText;
    if (isReadyToRestart) {
      subtitleText =
          'پچ جدید ($patchVersion) دانلود شد؛ در اجرای بعدی اعمال می‌شود';
    } else if (hasUpdate) {
      subtitleText = isNativeApk
          ? 'نسخه نصبی جدید ($patchVersion) آماده دریافت است'
          : 'پچ جدید ($patchVersion) آماده دریافت است';
    } else {
      subtitleText = (currentPatch != null && currentPatch.isNotEmpty)
          ? 'پچ فعال: $currentPatch'
          : 'نسخه شما به‌روز است';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            'به‌روزرسانی',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF7A756D),
            ),
          ),
        ),
        8.vSpace,
        Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.cardBorder,
              width: 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                debugPrint(
                    '👆 [Profile/OTA] User tapped "بررسی به‌روزرسانی نرم‌افزار"');
                if (isReadyToRestart) {
                  _showApplyConfirmDialog(context, patchVersion ?? '');
                  return;
                }
                if (hasUpdate) {
                  debugPrint(
                      '📱 [Profile/OTA] Showing OtaUpdateDialog (hasUpdate is true, version=$patchVersion)');
                  OtaUpdateDialog.show(context);
                  return;
                }
                AppSnackBar.showInfo(context, 'در حال بررسی به‌روزرسانی...');
                final found = await ref
                    .read(otaUpdateControllerProvider.notifier)
                    .checkForUpdate(manual: true);
                debugPrint(
                    '🔍 [Profile/OTA] Manual check finished. foundUpdate=$found');
                if (!context.mounted) return;
                if (found) {
                  OtaUpdateDialog.show(context);
                } else {
                  AppSnackBar.showSuccess(
                    context,
                    'برنامه به آخرین نسخه مجهز است.',
                  );
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'بررسی به‌روزرسانی نرم‌افزار',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          2.vSpace,
                          Text(
                            subtitleText,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: isReadyToRestart
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.75),
                              fontWeight: isReadyToRestart
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    8.hSpace,
                    if (isReadyToRestart || hasUpdate) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isReadyToRestart
                              ? Colors.green
                              : (isNativeApk
                                  ? colorScheme.primary
                                  : Colors.redAccent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isReadyToRestart
                              ? 'آماده اعمال'
                              : (isNativeApk ? 'فایل APK' : 'نسخه جدید'),
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
          ),
        ),
      ],
    );
  }
}

/// Clean version footer caption with changelog viewer
class _ProfileVersionFooter extends ConsumerWidget {
  const _ProfileVersionFooter();

  void _showChangelogBottomSheet(
    BuildContext context,
    OtaPatch? patch,
    String? currentPatch,
    String? lastNotes,
    String baseVersion,
  ) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final rawNotes = (patch != null && patch.releaseNotes.isNotEmpty)
        ? patch.releaseNotes
        : (lastNotes != null && lastNotes.isNotEmpty ? lastNotes : null);

    final notes = rawNotes ?? 'تغییراتی برای این نسخه ثبت نشده است.';
    final version = patch?.version ?? currentPatch ?? baseVersion;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                16.vSpace,
                Text(
                  'تغییرات نسخه $version',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                12.vSpace,
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Text(
                    notes,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                16.vSpace,
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'بستن',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPatch = ref.watch(
        otaUpdateControllerProvider.select((s) => s.currentPatchVersion));
    final lastNotes = ref.watch(
        otaUpdateControllerProvider.select((s) => s.lastReleaseNotes));
    final patch =
        ref.watch(otaUpdateControllerProvider.select((s) => s.patch));
    final baseVersion = ref.watch(appVersionNameProvider);
    final versionDisplay = ref.watch(appVersionDisplayProvider);
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            versionDisplay,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
          6.vSpace,
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showChangelogBottomSheet(
                context,
                patch,
                currentPatch,
                lastNotes,
                baseVersion,
              );
            },
            child: Text(
              'مشاهده تغییرات',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

