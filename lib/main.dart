import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_patcher/flutter_patcher.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/data/local/preferences/preferences_service_provider.dart';
import 'core/services/audio/audio_player_providers.dart';
import 'core/services/audio/quran_audio_handler.dart';
import 'core/services/audio_storage/audio_storage_service_impl.dart';
import 'core/services/firebase/firebase_initializer.dart';
import 'core/services/notification/firebase_push_notification_service_impl.dart';
import 'core/services/notification/i_push_notification_service.dart';
import 'core/services/notification/push_notification_providers.dart';
import 'features/bookmarks/infrastructure/datasources/bookmark_local_datasource.dart';
import 'features/bookmarks/infrastructure/datasources/bookmark_label_local_datasource.dart';
import 'features/study_plan/infrastructure/datasources/study_plan_local_datasource.dart';
import 'features/tafsir_manager/infrastructure/datasources/tafsir_local_datasource.dart';
import 'features/topic_studio/infrastructure/datasources/topic_local_datasource.dart';
import 'features/translation_manager/infrastructure/datasources/translation_local_datasource.dart';
import 'main_widget.dart';

Future<void> _loadCustomFonts() async {
  try {
    final thuluthLoader = FontLoader('Thuluth')
      ..addFont(rootBundle.load('assets/fonts/Thuluth.ttf'));
    await thuluthLoader.load();
  } catch (_) {}
}

/// Configure audio session for proper interaction with other apps, phone calls,
/// and headphone events on real Android/iOS devices.
Future<void> _initAudioSession() async {
  if (kIsWeb) return;
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  } catch (_) {}
}

Future<void> _initHiveBoxes() async {
  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 2));
    await Future.wait([
      Hive.openBox(TranslationLocalDataSource.boxName),
      Hive.openBox(TafsirLocalDataSource.boxName),
      Hive.openBox(AudioStorageServiceImpl.boxName),
      Hive.openBox(BookmarkLocalDataSource.boxName),
      Hive.openBox(BookmarkLabelLocalDataSource.boxName),
      Hive.openBox(TopicLocalDataSource.boxName),
      Hive.openBox(StudyPlanLocalDataSource.boxName),
    ]).timeout(const Duration(seconds: 3));
    debugPrint('✅ [Hive] initialized successfully');
  } catch (e) {
    debugPrint('⚠️ [Hive] init error or timeout: $e');
  }
}

Future<SharedPreferences> _initSharedPreferences() async {
  try {
    return await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
      onTimeout: () async {
        debugPrint('⚠️ [SharedPreferences] timed out, falling back to in-memory');
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        return await SharedPreferences.getInstance();
      },
    );
  } catch (e) {
    debugPrint('⚠️ [SharedPreferences] error: $e');
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    return await SharedPreferences.getInstance();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🛑 [FlutterError] ${details.exceptionAsString()}');
    debugPrint('${details.stack}');
  };
  debugPrint('🚀 [App Startup] main() started (kIsWeb: $kIsWeb)');

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Load custom fonts in background without blocking app launch
  unawaited(_loadCustomFonts());

  // Initialize critical local services concurrently with timeouts for fast startup
  final sharedPrefsFuture = _initSharedPreferences();
  final initFutures = Future.wait([
    _initAudioSession().catchError((e) {
      debugPrint('Audio session error: $e');
    }),
    _initHiveBoxes(),
    sharedPrefsFuture,
    FirebaseInitializer.init().catchError((e) {
      debugPrint('Firebase init error: $e');
    }),
    FlutterPatcher.init().catchError((e) {
      debugPrint('FlutterPatcher init error: $e');
    }),
  ]);

  final rawPlayer = AudioPlayer();
  final QuranAudioHandler audioHandler;
  if (kIsWeb) {
    audioHandler = QuranAudioHandler(rawPlayer);
  } else {
    audioHandler = await AudioService.init(
      builder: () => QuranAudioHandler(rawPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.qurantafakor.app.audio',
        androidNotificationChannelName: 'پخش صوت قرآن',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
  }

  await initFutures;
  final sharedPreferences = await sharedPrefsFuture;
  debugPrint('🚀 [App Startup] all services ready, calling runApp()...');

  // Initialize Push Notification Service in background without blocking app launch
  final IPushNotificationService pushNotificationService;
  if (kIsWeb) {
    pushNotificationService = const WebPushNotificationServiceImpl();
  } else {
    pushNotificationService = FirebasePushNotificationServiceImpl();
    unawaited(pushNotificationService.initialize());
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(sharedPreferences),
        rawAudioPlayerProvider.overrideWithValue(rawPlayer),
        quranAudioHandlerProvider.overrideWithValue(audioHandler),
        pushNotificationServiceProvider.overrideWithValue(pushNotificationService),
      ],
      child: const MainWidget(),
    ),
  );
}
