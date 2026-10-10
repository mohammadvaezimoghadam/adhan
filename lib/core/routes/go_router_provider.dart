import '../../features/tafakor/presentation/ui/tafakor_login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio_manager/presentation/ui/audio_download_manager_screen.dart';
import '../../features/bookmarks/presentation/ui/bookmarks_screen.dart';
import '../../features/download_manager/presentation/ui/download_hub_screen.dart';
import '../../features/main_navigation/presentation/ui/main_navigation_screen.dart';
import '../../features/profile/presentation/ui/profile_screen.dart';
import '../../features/quran_home/presentation/ui/quran_home_screen.dart';
import '../../features/quran_reader/presentation/ui/quran_reader_screen.dart';
import '../../features/quran_reader/presentation/ui/surah_dictionary_screen.dart';
import '../../features/search/presentation/ui/search_screen.dart';
import '../../features/settings/presentation/ui/settings_screen.dart';
import '../../features/smart_device/presentation/ui/smart_device_settings_screen.dart';
import '../../features/splash/presentation/ui/splash_screen.dart';
import '../../features/subscription/presentation/ui/vip_subscription_screen.dart';
import '../../features/surah_list/presentation/ui/surah_list_screen.dart';
import '../../features/study_plan/presentation/ui/create_study_plan_screen.dart';
import '../../features/study_plan/presentation/ui/study_plans_screen.dart';
import '../../features/tafsir_manager/presentation/ui/tafsir_reader_screen.dart';
import 'route_name.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: kIsWeb ? '/main' : '/splash',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/main',
      ),
      GoRoute(
        path: '/splash',
        name: splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/main',
        name: mainNavigationRoute,
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: bookmarksRoute,
        builder: (context, state) => const BookmarksScreen(showBackButton: true),
      ),
      GoRoute(
        path: '/quran-home',
        name: quranHomeRoute,
        builder: (context, state) => const QuranHomeScreen(),
      ),
      GoRoute(
        path: '/surah-list',
        name: surahListRoute,
        builder: (context, state) => const SurahListScreen(showBottomMiniPlayer: true),
      ),
      GoRoute(
        path: '/search',
        name: searchRoute,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: settingsRoute,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/vip-subscription',
        name: vipSubscriptionRoute,
        builder: (context, state) => const VipSubscriptionScreen(),
      ),
      GoRoute(
        path: '/tafakor-login',
        name: tafakorLoginRoute,
        builder: (context, state) => const TafakorLoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: profileRoute,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/smart-device',
        name: smartDeviceRoute,
        builder: (context, state) => const SmartDeviceSettingsScreen(),
      ),
      GoRoute(
        path: '/quran-reader/:id',
        name: quranReaderRoute,
        builder: (context, state) {
          final surahId = int.parse(state.pathParameters['id']!);
          final surahName = state.uri.queryParameters['name'] ?? 'سوره';
          final ayahString = state.uri.queryParameters['ayah'];
          final translationId = state.uri.queryParameters['translationId'];
          final initialAyah = ayahString != null ? int.tryParse(ayahString) : null;
          return QuranReaderScreen(
            surahId: surahId,
            surahName: surahName,
            initialAyahNumber: initialAyah,
            translationId: translationId,
          );
        },
      ),
      GoRoute(
        path: '/audio-download-manager',
        name: audioDownloadManagerRoute,
        builder: (context, state) {
          final surahIdStr = state.uri.queryParameters['surahId'];
          final reciterIdStr = state.uri.queryParameters['reciterId'];
          final isTranslationStr = state.uri.queryParameters['isTranslation'];
          final surahId = surahIdStr != null ? int.tryParse(surahIdStr) : null;
          final reciterId = reciterIdStr != null ? int.tryParse(reciterIdStr) : null;
          final isTranslationMode = isTranslationStr == 'true';
          return AudioDownloadManagerScreen(
            initialSurahId: surahId,
            initialReciterId: reciterId,
            isTranslationMode: isTranslationMode,
          );
        },
      ),
      GoRoute(
        path: '/download-hub',
        name: downloadHubRoute,
        builder: (context, state) => const DownloadHubScreen(),
      ),
      GoRoute(
        path: '/surah-dictionary/:id',
        name: surahDictionaryRoute,
        builder: (context, state) {
          final surahId =
              int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final surahName = state.uri.queryParameters['name'] ?? '';
          return SurahDictionaryScreen(
            surahId: surahId,
            surahName: surahName,
          );
        },
      ),
      GoRoute(
        path: '/tafsir-reader/:id',
        name: tafsirReaderRoute,
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
          final surahName = state.uri.queryParameters['name'] ?? 'سوره';
          final tafsirId = state.uri.queryParameters['tafsirId'];
          final initialAyah = int.tryParse(state.uri.queryParameters['ayah'] ?? '');
          return TafsirReaderScreen(
            surahId: surahId,
            surahName: surahName,
            tafsirId: tafsirId,
            initialAyahNumber: initialAyah,
          );
        },
      ),
      GoRoute(
        path: '/study-plans',
        name: studyPlansRoute,
        builder: (context, state) => const StudyPlansScreen(),
      ),
      GoRoute(
        path: '/create-study-plan',
        name: createStudyPlanRoute,
        builder: (context, state) => const CreateStudyPlanScreen(),
      ),
    ],
  );
});
