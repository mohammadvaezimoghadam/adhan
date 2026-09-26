import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/app_constants.dart';
import '../../../../common/extensions/context_extension.dart';
import '../../../../common/extensions/surah_name_extension.dart';
import '../../../../common/responsive/responsive_layout.dart';
import '../../../../common/widgets/app_snackbar.dart';
import 'web_surah_catalog_view.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/services/audio_storage/audio_storage_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../audio_manager/application/controllers/audio_download_controller.dart';
import '../../../main_navigation/application/tab_navigation_controller.dart';
import '../../../mini_audio_player/presentation/widgets/mini_audio_player_bar.dart';
import '../../../quran_reader/application/controllers/quran_audio_controller.dart';
import '../../../quran_reader/application/controllers/quran_display_settings_controller.dart';
import '../../../subscription/application/vip_subscription_controller.dart';
import '../../../subscription/domain/policy/audio_vip_policy.dart';
import '../../../subscription/presentation/utils/audio_vip_helper.dart';
import '../../application/controllers/favorite_surahs_controller.dart';
import '../../application/controllers/surah_list_controller.dart';
import '../../domain/entities/surah_entity.dart';
import '../widgets/surah_action_dialog.dart';
import '../widgets/surah_error_view.dart';
import '../widgets/surah_list_apple_header.dart';
import '../widgets/surah_list_continue_reading_bar.dart';
import '../widgets/surah_list_item.dart';
import '../widgets/surah_list_quick_actions.dart';
import '../widgets/surah_sort_bottom_sheet.dart';

/// Root screen – uses StatefulWidget so that the FocusNode survives rebuilds
/// and we can explicitly control keyboard dismiss on navigation.
class SurahListScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showBottomMiniPlayer;

  const SurahListScreen({
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
    this.showBottomMiniPlayer = false,
  });

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isQuickActionsVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      ref.read(surahListControllerProvider.notifier).searchSurahs('');
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _isQuickActionsVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only select what we need at root to avoid full-page rebuilds
    final isOnlyFavorites = ref.watch(
      surahListControllerProvider.select((s) => s.isOnlyFavorites),
    );
    final isSearching = ref.watch(
      surahListControllerProvider.select((s) => s.searchQuery.trim().isNotEmpty),
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _searchController.clear();
          ref.read(surahListControllerProvider.notifier).searchSurahs('');
          ref.read(surahListControllerProvider.notifier).setOnlyFavorites(false);
          _isQuickActionsVisible.value = true;
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: context.isWideScreen
            ? null
            : SurahListAppleHeader(
                showBackButton: widget.showBackButton,
                title: isOnlyFavorites ? 'فهرست شخصی' : AppConstants.surahListScreenTitle,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSearchChanged: (query) {
                  ref.read(surahListControllerProvider.notifier).searchSurahs(query);
                },
                onBackPressed: () {
                  if (isOnlyFavorites) {
                    ref.read(surahListControllerProvider.notifier).setOnlyFavorites(false);
                  }
                  _dismissSearchAndNavigate(() {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      ref
                          .read(tabNavigationControllerProvider.notifier)
                          .handleBackPress();
                    }
                  });
                },
                onAudioDownloadManagerTap: () {
                  _dismissSearchAndNavigate(() {
                    context.pushNamed(audioDownloadManagerRoute);
                  });
                },
                onSortTap: () {
                  SurahSortBottomSheet.show(context);
                },
                onToggleFavoritesTap: () {
                  ref.read(surahListControllerProvider.notifier).toggleOnlyFavorites();
                },
                isOnlyFavorites: isOnlyFavorites,
              ),
        body: _SurahListBody(
          isOnlyFavorites: isOnlyFavorites,
          isSearching: isSearching,
          isQuickActionsVisible: _isQuickActionsVisible,
          onOpenReader: _openReader,
          onDownloadTap: _handleSurahDownloadTap,
          onBeforeNavigation: () => _dismissSearchAndNavigate(() {}),
        ),
        bottomNavigationBar: (!context.isWideScreen && (!isSearching || widget.showBottomMiniPlayer))
            ? SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSearching)
                      SurahListContinueReadingBar(
                        onBeforeNavigation: () => _dismissSearchAndNavigate(() {}),
                      ),
                    if (widget.showBottomMiniPlayer)
                      const MiniAudioPlayerBar(includeBottomInset: true),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  void _handleSurahDownloadTap(SurahEntity surah) async {
    final reciter = ref.read(quranAudioControllerProvider).selectedReciter;
    final storageService = ref.read(audioStorageServiceProvider);

    bool isDownloaded = false;
    if (reciter != null) {
      final isMarked = storageService.isSurahDownloaded(reciter.id, surah.number);
      final firstAyahPath = await storageService.getLocalAyahAudioPath(
        reciterId: reciter.id,
        surahId: surah.number,
        ayahNumber: 1,
      );
      isDownloaded = isMarked || firstAyahPath != null;
    }

    if (isDownloaded || kIsWeb) {
      _openReader(surah);
      return;
    }

    // Check VIP permission BEFORE showing download dialog
    if (reciter != null) {
      final isVip = ref.read(hasVipAccessProvider);
      final canDownload = AudioVipPolicy.canPlayReciter(
        reciterIdentifier: reciter.identifier,
        surahId: surah.number,
        isVip: isVip,
      );

      if (!canDownload) {
        if (!mounted) return;
        await AudioVipHelper.checkAndPromptVip(
          context: context,
          ref: ref,
          surahId: surah.number,
          targetReciter: reciter,
          onSwitchedToDefaultReciter: () {
            // User switched to Ostad Parhizgar! Re-trigger download flow
            _handleSurahDownloadTap(surah);
          },
        );
        return;
      }
    }

    if (!mounted) return;

    final fontScript = ref.read(
      quranDisplaySettingsControllerProvider.select((s) => s.fontScript),
    );
    final surahFontFamily = AppTypography.getFontFamilyByScript(fontScript);

    SurahActionDialog.show(
      context: context,
      surah: surah,
      surahFontFamily: surahFontFamily,
      message: 'برای دانلود صوت سوره ${surah.nameFa} می‌توانید از «دانلود سریع» استفاده کنید یا وارد «مدیریت دانلود» شوید.',
      reciter: reciter,
      isTranslation: reciter?.styleId == 4,
      onReadSurah: () => _openReader(surah),
      onQuickDownload: reciter != null
          ? () {
              ref.read(audioDownloadControllerProvider.notifier).startDownload(
                reciter: reciter,
                surahId: surah.number,
              );
              AppSnackBar.showSuccess(
                context,
                'دانلود صوت سوره ${surah.nameFa} شروع شد.',
              );
            }
          : null,
      onDownloadAudio: () {
        final router = GoRouter.of(context);
        _dismissSearchAndNavigate(() {
          router.pushNamed(
            audioDownloadManagerRoute,
            queryParameters: {'surahId': surah.number.toString()},
          );
        });
      },
    );
  }

  void _openReader(SurahEntity surah) {
    _dismissSearchAndNavigate(() {
      ref.read(quranDisplaySettingsControllerProvider.notifier).toggleArabicText(true);
      context.pushNamed(
        quranReaderRoute,
        pathParameters: {'id': surah.number.toString()},
        queryParameters: {'name': surah.name},
      );
    });
  }

  /// Unfocus the search field, clear query, then navigate.
  /// Using addPostFrameCallback ensures the keyboard is dismissed
  /// BEFORE the navigation happens, so it won't re-appear on pop.
  void _dismissSearchAndNavigate(VoidCallback navigate) {
    _searchFocusNode.unfocus();
    _searchController.clear();
    ref.read(surahListControllerProvider.notifier).searchSurahs('');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) navigate();
    });
  }
}

/// Isolated Body widget to eliminate unnecessary rebuilds of Scaffold, Header,
/// and Bottom Bar when list contents or search filters update.
class _SurahListBody extends ConsumerWidget {
  final bool isOnlyFavorites;
  final bool isSearching;
  final ValueNotifier<bool> isQuickActionsVisible;
  final ValueChanged<SurahEntity> onOpenReader;
  final ValueChanged<SurahEntity> onDownloadTap;
  final VoidCallback onBeforeNavigation;

  const _SurahListBody({
    required this.isOnlyFavorites,
    required this.isSearching,
    required this.isQuickActionsVisible,
    required this.onOpenReader,
    required this.onDownloadTap,
    required this.onBeforeNavigation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      surahListControllerProvider.select((s) => s.isLoading),
    );
    final errorMessage = ref.watch(
      surahListControllerProvider.select((s) => s.errorMessage),
    );

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return SurahErrorView(
        errorMessage: errorMessage,
        onRetry: () {
          ref.read(surahListControllerProvider.notifier).build();
        },
      );
    }

    final initialFiltered = ref.watch(
      surahListControllerProvider.select((s) => s.filteredSurahs),
    );

    // Conditionally watch favorites only when in isOnlyFavorites mode.
    // In normal mode, favorite changes only rebuild the individual item star button.
    final List<SurahEntity> filteredSurahs;
    if (isOnlyFavorites) {
      final favoriteSurahIds = ref.watch(favoriteSurahsProvider);
      filteredSurahs = initialFiltered
          .where((surah) => favoriteSurahIds.contains(surah.number))
          .toList();
    } else {
      filteredSurahs = initialFiltered;
    }

    final showQuickActions = !isSearching && !isOnlyFavorites;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification) {
          if (notification.direction == ScrollDirection.reverse) {
            // Scrolling down -> smoothly collapse quick actions
            if (isQuickActionsVisible.value && notification.metrics.pixels > 15) {
              isQuickActionsVisible.value = false;
            }
          } else if (notification.direction == ScrollDirection.forward) {
            // Scrolling up -> smoothly expand quick actions
            if (!isQuickActionsVisible.value) {
              isQuickActionsVisible.value = true;
            }
          }
        }
        if (notification.metrics.pixels <= 0) {
          if (!isQuickActionsVisible.value) {
            isQuickActionsVisible.value = true;
          }
        }
        return false;
      },
      child: ResponsiveLayout(
        mobile: _buildMobileLayout(
          context,
          filteredSurahs: filteredSurahs,
          showQuickActions: showQuickActions,
          isOnlyFavorites: isOnlyFavorites,
        ),
        desktop: WebSurahCatalogView(
          onOpenReader: onOpenReader,
          onDownloadTap: onDownloadTap,
          onBeforeNavigation: onBeforeNavigation,
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required List<SurahEntity> filteredSurahs,
    required bool showQuickActions,
    required bool isOnlyFavorites,
  }) {
    return Column(
      children: [
        // Isolated Quick Actions collapse/expand via ValueListenableBuilder
        ValueListenableBuilder<bool>(
          valueListenable: isQuickActionsVisible,
          builder: (context, isVisible, child) {
            final shouldShow = isVisible && showQuickActions;
            return ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedOpacity(
                  opacity: shouldShow ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: shouldShow
                      ? SurahListQuickActions(
                          onBeforeNavigation: onBeforeNavigation,
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
              ),
            );
          },
        ),
        Expanded(
          child: filteredSurahs.isEmpty
              ? _buildEmptyState(isOnlyFavorites)
              : ListView.separated(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    top: showQuickActions ? 4 : 8,
                    bottom: 84,
                  ),
                  itemCount: filteredSurahs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.6,
                    indent: 68,
                    endIndent: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, index) {
                    final surah = filteredSurahs[index];
                    return SurahListItem(
                      key: ValueKey(surah.number),
                      surah: surah,
                      onTap: () => onOpenReader(surah),
                      onDownloadTap: () => onDownloadTap(surah),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isOnlyFavorites) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          isOnlyFavorites
              ? 'فهرست شخصی شما خالی است.\nبا زدن آیکون ستاره در کنار هر سوره می‌توانید آن را به این فهرست اضافه کنید.'
              : AppConstants.noSurahFound,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            color: Colors.grey,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
