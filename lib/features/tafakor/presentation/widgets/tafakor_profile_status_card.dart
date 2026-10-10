import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/extensions/string_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/controllers/tafakor_auth_controller.dart';
import '../ui/tafakor_login_screen.dart';

/// Clean, typography-driven Tafakor status card without decorative icons,
/// perfectly matching the Quran app Apple-style design system.
class TafakorProfileStatusCard extends ConsumerStatefulWidget {
  const TafakorProfileStatusCard({super.key});

  @override
  ConsumerState<TafakorProfileStatusCard> createState() =>
      _TafakorProfileStatusCardState();
}

class _TafakorProfileStatusCardState extends ConsumerState<TafakorProfileStatusCard> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefresh();
    });
  }

  Future<void> _autoRefresh() async {
    final authState = ref.read(tafakorAuthControllerProvider);
    if (!authState.isAuthenticated) return;
    if (_isRefreshing) return;
    _refresh();
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await ref.read(tafakorAuthControllerProvider.notifier).refreshProfile();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _manualRefresh() async {
    HapticFeedback.lightImpact();
    setState(() => _isRefreshing = true);
    await ref.read(tafakorAuthControllerProvider.notifier).refreshProfile();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final authState = ref.watch(tafakorAuthControllerProvider);
    final controller = ref.read(tafakorAuthControllerProvider.notifier);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

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
        children: [
          if (!isAuthenticated) ...[
            // Unauthenticated state: Clean tile with title, subtitle, and action button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TafakorLoginScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'اتصال به سامانه تفکر',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      12.hSpace,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ورود / ثبت‌نام',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (user != null) ...[
            // Authenticated state: Detailed information rows
            _buildRow(
              context: context,
              label: 'شماره متصل',
              valueWidget: Text(
                user.phone.toPersianDigit(),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            _buildDivider(isDark),
            _buildRow(
              context: context,
              label: 'ربات پیام‌رسان بله',
              valueWidget: _buildStatusPill(
                label: user.isBaleConnected ? 'فعال' : 'در انتظار اتصال',
                isActive: user.isBaleConnected,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ),
            _buildDivider(isDark),
            _buildRow(
              context: context,
              label: 'ربات تلگرام',
              valueWidget: _buildStatusPill(
                label: user.isTelegramConnected ? 'فعال' : 'در انتظار اتصال',
                isActive: user.isTelegramConnected,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ),
            _buildDivider(isDark),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isRefreshing ? null : _manualRefresh,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRefreshing) ...[
                        const CupertinoActivityIndicator(radius: 7),
                        8.hSpace,
                      ] else ...[
                        Icon(
                          CupertinoIcons.arrow_clockwise,
                          size: 13.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        6.hSpace,
                      ],
                      Text(
                        _isRefreshing ? 'در حال بررسی وضعیت...' : 'بروزرسانی وضعیت اتصال',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDivider(isDark),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showLogoutDialog(context, controller);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'خروج از حساب تفکر',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String label,
    required Widget valueWidget,
  }) {
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required bool isActive,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final color = isActive ? Colors.green.shade600 : const Color(0xFF8A847C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
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

  void _showLogoutDialog(BuildContext context, TafakorAuthController controller) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(
          'خروج از حساب تفکر',
          style: TextStyle(fontFamily: AppTypography.fontFamily),
        ),
        content: const Text(
          'آیا از خروج از حساب کاربری تفکر اطمینان دارید؟',
          style: TextStyle(fontFamily: AppTypography.fontFamily),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              'انصراف',
              style: TextStyle(fontFamily: AppTypography.fontFamily),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text(
              'خروج',
              style: TextStyle(fontFamily: AppTypography.fontFamily),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.logout();
            },
          ),
        ],
      ),
    );
  }
}
