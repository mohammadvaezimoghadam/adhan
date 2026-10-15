import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/responsive/responsive_layout.dart';
import '../../../../common/widgets/app_snackbar.dart';
import '../../../mini_audio_player/presentation/widgets/mini_audio_player_bar.dart';
import '../../../quran_home/presentation/ui/quran_home_screen.dart';
import '../../../profile/presentation/ui/profile_screen.dart';
import '../../../search/presentation/ui/search_screen.dart';
import '../../../surah_list/presentation/ui/surah_list_screen.dart';
import '../../../ota_update/application/controllers/ota_update_controller.dart';
import '../../../ota_update/application/controllers/ota_update_state.dart';
import '../../../ota_update/presentation/widgets/ota_update_dialog.dart';
import '../../application/tab_navigation_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_navigation_rail.dart';
import '../widgets/web_docked_audio_player_bar.dart';
import '../widgets/web_top_nav_bar.dart';

/// Enterprise-Grade Main Shell Screen with:
/// - Lazy Tab Instantiation (zero overhead for unvisited tabs)
/// - Offstage (zero GPU paint/layout for background tabs)
/// - TickerMode (frozen animations/spinners for background tabs)
/// - Deduplicated MRU History Stack (no infinite back loops)
/// - Double-tap Back-to-exit protection
/// - Floating Mini Player integration
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final Set<int> _loadedTabs = {0};
  final Map<int, Widget> _tabCache = {};
  DateTime? _lastBackPressTime;
  bool _isForceDialogShowing = false;

  @override
  void initState() {
    super.initState();
    // بررسی خودکار به‌روزرسانی به محض ورود به شل اصلی برنامه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentOta = ref.read(otaUpdateControllerProvider);
      final isMandatoryInitial = (currentOta.hasUpdate &&
              currentOta.patch?.isForce == true) ||
          (currentOta.isStoreUpdateRequired && currentOta.storeIsMandatory);

      if (isMandatoryInitial && !_isForceDialogShowing) {
        _isForceDialogShowing = true;
        OtaUpdateDialog.show(context, isForce: true).then((_) {
          _isForceDialogShowing = false;
        });
      }
      ref.read(otaUpdateControllerProvider.notifier).checkForUpdate();
    });

    // Crash Guard: ریست کردن شمارنده کرش بعد از ۳ ثانیه پایداری اجرای برنامه
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(otaUpdateControllerProvider.notifier).resetCrashCounter();
      }
    });
  }

  Widget _getOrCreateTabWidget(int index) {
    return _tabCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const QuranHomeScreen(showBottomMiniPlayer: false);
        case 1:
          return SurahListScreen(
            showBackButton: true,
            onBackPressed: () {
              ref
                  .read(tabNavigationControllerProvider.notifier)
                  .handleBackPress();
            },
          );
        case 2:
          return SearchScreen(
            showBackButton: true,
            onBackPressed: () {
              ref
                  .read(tabNavigationControllerProvider.notifier)
                  .handleBackPress();
            },
          );
        case 3:
          return ProfileScreen(
            showBackButton: true,
            onBackPressed: () {
              ref
                  .read(tabNavigationControllerProvider.notifier)
                  .handleBackPress();
            },
          );
        default:
          return const SizedBox.shrink();
      }
    });
  }

  Widget _buildTab(int index, bool isActive) {
    // True On-Demand Lazy Initialization:
    // If the user hasn't clicked/visited this tab yet, it is NEVER created or kept in memory.
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return Offstage(
      offstage: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: Focus(
          canRequestFocus: isActive,
          descendantsAreFocusable: isActive,
          child: _getOrCreateTabWidget(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unfocus active inputs and dismiss keyboard on any tab change
    ref.listen<TabNavigationState>(tabNavigationControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.currentIndex != next.currentIndex) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });

    // در صورت وجود به‌روزرسانی اجباری (پچ یا استور)، دیالوگ فوراً باز می‌شود
    ref.listen<OtaUpdateState>(otaUpdateControllerProvider, (previous, next) {
      final isMandatory = (next.hasUpdate && next.patch?.isForce == true) ||
          (next.isStoreUpdateRequired && next.storeIsMandatory);

      if (isMandatory && !_isForceDialogShowing && context.mounted) {
        _isForceDialogShowing = true;
        OtaUpdateDialog.show(context, isForce: true).then((_) {
          _isForceDialogShowing = false;
        });
      } else if (next.isStoreUpdateRequired &&
          !next.storeIsMandatory &&
          previous?.status != OtaStatus.storeUpdateRequired &&
          !_isForceDialogShowing &&
          context.mounted) {
        _isForceDialogShowing = true;
        OtaUpdateDialog.show(context, isForce: false).then((_) {
          _isForceDialogShowing = false;
        });
      }
    });

    final navState = ref.watch(tabNavigationControllerProvider);
    final activeIndex = navState.currentIndex;

    // Ensure the newly selected tab is marked as loaded
    if (!_loadedTabs.contains(activeIndex)) {
      _loadedTabs.add(activeIndex);
    }

    final body = Stack(
      children: [
        _buildTab(0, activeIndex == 0),
        _buildTab(1, activeIndex == 1),
        _buildTab(2, activeIndex == 2),
        _buildTab(3, activeIndex == 3),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        FocusManager.instance.primaryFocus?.unfocus();

        // 1. Check if we can pop tab history stack
        final isAtRootHome = ref
            .read(tabNavigationControllerProvider.notifier)
            .handleBackPress();

        if (isAtRootHome) {
          // 2. Double-press back to exit gracefully
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) >
                  const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            AppSnackBar.showInfo(
              context,
              'برای خروج از برنامه، دوباره بازگشت را لمس کنید',
            );
            return;
          }
          SystemNavigator.pop();
        }
      },
      child: ResponsiveLayout(
        // Mobile Layout (Bottom Nav)
        mobile: Scaffold(
          body: body,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floating Mini Player (only displays content when an audio item is loaded)
              const MiniAudioPlayerBar(),
              // Glassmorphic Tab Bar
              AppBottomNavBar(
                currentIndex: activeIndex,
                onTabSelected: (index) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  ref
                      .read(tabNavigationControllerProvider.notifier)
                      .switchTab(index);
                },
              ),
            ],
          ),
        ),
        // Desktop Layout (Sidebar Nav + Top Web Nav + Docked Web Audio Player)
        desktop: Scaffold(
          body: Row(
            children: [
              // Navigation Rail (Right side for RTL)
              AppNavigationRail(
                currentIndex: activeIndex,
                onTabSelected: (index) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  ref
                      .read(tabNavigationControllerProvider.notifier)
                      .switchTab(index);
                },
              ),
              // Main Content Area with Top Bar and Docked Player
              Expanded(
                child: Column(
                  children: [
                    // Universal Web Top Navigation Bar
                    WebTopNavBar(
                      onSearchTap: () {
                        ref
                            .read(tabNavigationControllerProvider.notifier)
                            .switchTab(2);
                      },
                    ),
                    // Active Tab Body
                    Expanded(child: body),
                    // Docked Web Audio Player (spans full content width)
                    const WebDockedAudioPlayerBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
