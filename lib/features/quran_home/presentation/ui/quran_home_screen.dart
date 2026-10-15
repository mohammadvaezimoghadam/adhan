import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/responsive/responsive_layout.dart';
import '../../../../common/widgets/app_theme_toggle_button.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../main_navigation/application/tab_navigation_controller.dart';
import '../../../mini_audio_player/presentation/widgets/mini_audio_player_bar.dart';
import '../../application/controllers/continue_reading_controller.dart';
import '../../../bookmarks/application/controllers/bookmarks_controller.dart';
import 'widgets/continue_reading_card.dart';
import 'widgets/home_quick_access_grid.dart';
import 'widgets/home_search_bar_widget.dart';
import 'web_quran_home_view.dart';
import '../../../quick_access/presentation/ui/quick_access_row.dart';
import '../../../study_plan/presentation/widgets/study_plan_home_card.dart';

/// Clean Apple-Style Quran Home Screen with Tafakor Mint Green Theme
class QuranHomeScreen extends ConsumerWidget {
  final bool showBottomMiniPlayer;

  const QuranHomeScreen({
    super.key,
    this.showBottomMiniPlayer = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final colorScheme = context.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBody: true,
      appBar: context.isWideScreen
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(116.0),
              child: Container(
                padding: EdgeInsets.only(
                  top: topPadding + 4.0,
                  left: 14.0,
                  right: 14.0,
                  bottom: 8.0,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: Top Bar with theme toggle & title
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          // Theme Toggle Button (Apple circular pill on Left)
                          const AppThemeToggleButton(),

                          // Centered Clean Title "قرآن تفکر"
                          Expanded(
                            child: Text(
                              AppConstants.appTitle.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''),
                              textAlign: TextAlign.center,
                              style: AppTypography.appBarTitle.copyWith(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),

                          // Settings Button (Left side in RTL)
                          IconButton(
                            tooltip: 'تنظیمات',
                            icon: Icon(
                              CupertinoIcons.gear_alt,
                              size: 22,
                              color: colorScheme.primary,
                            ),
                            splashRadius: 22,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.pushNamed(settingsRoute);
                            },
                          ),
                        ],
                      ),
                    ),

                    6.vSpace,

                    // Row 2: Search Bar as part of Header (identical to Surah List Header)
                    HomeSearchBarWidget(
                      onTap: () =>
                          ref.read(tabNavigationControllerProvider.notifier).switchTab(2),
                    ),
                  ],
                ),
              ),
            ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        desktop: const WebQuranHomeView(),
      ),
      bottomNavigationBar:
          (showBottomMiniPlayer && !context.isWideScreen) ? const MiniAudioPlayerBar() : null,
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        top: 10.0,
        left: AppDimens.marginPage,
        right: AppDimens.marginPage,
        bottom: AppDimens.marginPage + 60.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Primary Navigation Action Buttons (سوره‌ها، ترجمه، تنظیمات)
          const HomeQuickAccessGrid(),
          AppDimens.stackLg.vSpace,

          // 2. Customizable 4-Slot Toolbox Row (جعبه ابزار شخصی‌سازی‌شده)
          const QuickAccessRow(),
          AppDimens.stackLg.vSpace,

          // 3. Quran Study / Khatm Plan Card (کارت برنامه مطالعه و ختم)
          const StudyPlanHomeCard(),
          AppDimens.stackLg.vSpace,

          // 4. Continue Reading Card (در پایین صفحه)
          Consumer(
            builder: (context, ref, child) {
              final continueReadingState =
                  ref.watch(continueReadingControllerProvider);
              final bookmarks = ref.watch(bookmarksControllerProvider);
              final bookmarkState = bookmarks.isNotEmpty
                  ? bookmarks.first.toContinueReadingState()
                  : null;

              return ContinueReadingCard(
                autoState: continueReadingState,
                bookmarkState: bookmarkState,
              );
            },
          ),
          AppDimens.stackLg.vSpace,
        ],
      ),
    );
  }
}
