import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/extensions/size_extension.dart';
import '../../../bookmarks/application/controllers/bookmarks_controller.dart';
import '../../../quick_access/presentation/ui/quick_access_row.dart';
import '../../application/controllers/continue_reading_controller.dart';
import '../ui/widgets/continue_reading_card.dart';
import '../ui/widgets/home_quick_access_grid.dart';
import '../widgets/web_popular_surahs_grid.dart';
import '../widgets/web_quick_navigator_card.dart';

/// Professional Web Dashboard for Quran Home.
/// Tailored for wide monitors, laptops, and desktop browsers.
class WebQuranHomeView extends ConsumerWidget {
  const WebQuranHomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueReadingState = ref.watch(continueReadingControllerProvider);
    final bookmarks = ref.watch(bookmarksControllerProvider);
    final bookmarkState =
        bookmarks.isNotEmpty ? bookmarks.first.toContinueReadingState() : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Section: Two-Column Row (Reading Progress & Quick Tools)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Column (Flex 3): Continue Reading + Direct Navigation
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ContinueReadingCard(
                          autoState: continueReadingState,
                          bookmarkState: bookmarkState,
                        ),
                        16.vSpace,
                        const WebQuickNavigatorCard(),
                      ],
                    ),
                  ),

                  24.hSpace,

                  // Side Column (Flex 2): Primary Navigation & Tool row
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HomeQuickAccessGrid(),
                        16.vSpace,
                        const QuickAccessRow(),
                      ],
                    ),
                  ),
                ],
              ),

              32.vSpace,

              // 3. Bottom Section: Popular / Famous Surahs Grid
              const WebPopularSurahsGrid(),

              40.vSpace,
            ],
          ),
        ),
      ),
    );
  }
}
