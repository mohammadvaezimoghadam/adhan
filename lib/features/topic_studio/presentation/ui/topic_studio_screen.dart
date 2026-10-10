import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/widgets/app_cached_network_image.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../tafakor/application/controllers/tafakor_auth_controller.dart';
import '../../../tafakor/application/controllers/tafakor_topics_controller.dart';
import '../../../tafakor/domain/entities/tafakor_topic.dart';
import '../../../tafakor/presentation/ui/tafakor_login_screen.dart';

/// Screen displaying the user's Tafakor channels (topics) where posts can be published.
class TopicStudioScreen extends ConsumerStatefulWidget {
  const TopicStudioScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TopicStudioScreen(),
      ),
    );
  }

  @override
  ConsumerState<TopicStudioScreen> createState() => _TopicStudioScreenState();
}

class _TopicStudioScreenState extends ConsumerState<TopicStudioScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final isDark = context.isDark;

    final currentUser = ref.watch(tafakorUserProvider);
    final isAuthenticated = ref.watch(isTafakorAuthenticatedProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? colorScheme.surface : const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: colors.dialogSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'دفتر تفکر',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'به‌روزرسانی',
              icon: const Icon(CupertinoIcons.refresh, size: 19),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.invalidate(tafakorTopicsProvider);
              },
            ),
            8.hSpace,
          ],
        ),
        body: !isAuthenticated
            ? _buildUnauthenticatedView(colors, colorScheme, isDark)
            : _buildChannelsView(currentUser?.phone, colors, colorScheme, isDark),
      ),
    );
  }

  /// Shown when user is not logged into Tafakor
  Widget _buildUnauthenticatedView(
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: colors.dialogSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.cardBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ورود به تفکر',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              8.vSpace,
              Text(
                'برای مشاهده کانال‌ها و ارسال یادداشت وارد شوید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              22.vSpace,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TafakorLoginScreen(),
                    ),
                  ),
                  child: const Text(
                    'ورود',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the list of channels the user can post to
  Widget _buildChannelsView(
    String? userPhone,
    dynamic colors,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final topicsAsync = ref.watch(tafakorTopicsProvider);

    return topicsAsync.when(
      loading: () => const Center(
        child: CupertinoActivityIndicator(radius: 14),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.wifi_exclamationmark,
                size: 40,
                color: colorScheme.error.withValues(alpha: 0.8),
              ),
              12.vSpace,
              Text(
                'خطا در دریافت کانال‌های تفکر',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              6.vSpace,
              Text(
                'لطفاً اتصال اینترنت خود را بررسی نمایید.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              16.vSpace,
              OutlinedButton.icon(
                onPressed: () => ref.refresh(tafakorTopicsProvider),
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                label: const Text(
                  'تلاش مجدد',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (allTopics) {
        // Filter: only topics where user can post (owner)
        final allowedTopics = allTopics.where((t) {
          return t.isOwner(userPhone);
        }).toList();

        if (allowedTopics.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tafakorTopicsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'کانالی یافت نشد',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        6.vSpace,
                        Text(
                          'کانالی با دسترسی ارسال برای این حساب وجود ندارد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12.5,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(tafakorTopicsProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: allowedTopics.length,
            separatorBuilder: (_, _) => 12.vSpace,
            itemBuilder: (context, index) {
              final topic = allowedTopics[index];
              return _buildTopicCard(
                topic: topic,
                isDark: isDark,
                colors: colors,
                colorScheme: colorScheme,
              );
            },
          ),
        );
      },
    );
  }

  /// Topic Item Card displaying only Topic Avatar & Name
  /// Non-clickable (no onTap / InkWell)
  Widget _buildTopicCard({
    required TafakorTopic topic,
    required bool isDark,
    required dynamic colors,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.dialogSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.cardBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Topic Image / Avatar
          AppCachedNetworkImage(
            imageUrl: topic.fullImageUrl,
            width: 38,
            height: 38,
            borderRadius: BorderRadius.circular(10),
            fallbackText: topic.name,
            fallbackIcon: null,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          ),
          12.hSpace,
          Expanded(
            child: Text(
              topic.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
