import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/common/exceptions/failure.dart';
import 'package:quran/core/data/local/preferences/preferences_service_impl.dart';
import 'package:quran/core/data/local/preferences/preferences_service_provider.dart';
import 'package:quran/core/services/audio/audio_player_providers.dart';
import 'package:quran/core/services/audio/audio_player_state.dart';
import 'package:quran/core/services/audio/i_audio_player_service.dart';
import 'package:quran/core/services/audio/quran_audio_handler.dart';
import 'package:quran/core/services/audio_storage/audio_storage_providers.dart';
import 'package:quran/core/services/audio_storage/i_audio_storage_service.dart';
import 'package:quran/features/quran_reader/application/controllers/quran_audio_controller.dart';
import 'package:quran/features/quran_reader/domain/entities/reciter_entity.dart';
import 'package:quran/features/quran_reader/infrastructure/repositories/reciter_repository.dart';
import 'package:quran/features/subscription/application/vip_subscription_controller.dart';
import 'package:quran/features/subscription/domain/models/vip_subscription_state.dart';

class MockReciterRepo extends Fake implements ReciterRepository {
  static const parhizgar = ReciterEntity(
    id: 1,
    name: 'استاد شهریار پرهیزگار',
    arabicName: 'شهريار برهيزكار',
    englishName: 'Parhizgar',
    subfolder: 'Parhizgar_48kbps',
    bitrate: '48kbps',
    identifier: 'parhizgar_48kbps',
    styleId: 1,
    styleName: 'مرتل',
  );

  @override
  Future<Result<List<ReciterEntity>, Failure>> getAllReciters() async {
    return const Success([parhizgar]);
  }
}

class FakeVipSubscriptionController extends VipSubscriptionController {
  @override
  VipSubscriptionState build() {
    return const VipSubscriptionState(isVip: true, isLoading: false);
  }
}

class MockAudioHandler extends Fake implements QuranAudioHandler {
  @override
  Future<void> Function()? onSkipNext;
  @override
  Future<void> Function()? onSkipPrevious;
  @override
  Future<void> Function()? onPlay;
  @override
  Future<void> Function()? onPause;

  @override
  void updateAyahMediaItem({
    required String id,
    required String surahName,
    required int ayahNumber,
    required String reciterName,
    Duration? duration,
  }) {}
}

class MockAudioStorageService extends Fake implements IAudioStorageService {
  @override
  Future<String?> getLocalAyahAudioPath({
    required int reciterId,
    required int surahId,
    required int ayahNumber,
  }) async => null;
}

class TestableAudioPlayerService extends Fake implements IAudioPlayerService {
  final _controller = StreamController<AudioPlayerState>.broadcast();
  List<String> playedUrls = [];

  @override
  Stream<AudioPlayerState> get stateStream => _controller.stream;

  @override
  Future<void> play(String url) async {
    playedUrls.add(url);
    _controller.add(
      AudioPlayerState(
        status: AudioStatus.playing,
        currentUrl: url,
        position: Duration.zero,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void emitState(AudioPlayerState state) {
    _controller.add(state);
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> stop() async {
    _controller.add(
      AudioPlayerState(
        status: AudioStatus.stopped,
        position: Duration.zero,
        duration: Duration.zero,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Continuous playback advances to next ayah even with 150ms MP3 padding difference', () async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();
    final prefsService = PreferencesServiceImpl(sharedPrefs);
    final mockPlayer = TestableAudioPlayerService();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(sharedPrefs),
        preferencesServiceProvider.overrideWithValue(prefsService),
        reciterRepositoryProvider.overrideWithValue(MockReciterRepo()),
        quranAudioHandlerProvider.overrideWithValue(MockAudioHandler()),
        audioStorageServiceProvider.overrideWithValue(MockAudioStorageService()),
        audioPlayerServiceProvider.overrideWithValue(mockPlayer),
        vipSubscriptionControllerProvider.overrideWith(() => FakeVipSubscriptionController()),
      ],
    );

    addTearDown(container.dispose);

    final controller = container.read(quranAudioControllerProvider.notifier);

    // Start playing Surah 1, Ayah 1 (7 total ayahs)
    await controller.playAyah(
      surahId: 1,
      ayahNumber: 1,
      totalAyahsInSurah: 7,
    );

    expect(container.read(quranAudioControllerProvider).currentAyahNumber, 1);
    expect(mockPlayer.playedUrls.length, 1);

    // Simulate ExoPlayer stopping at 2.85s of a 3.0s file (150ms before duration)
    // Near-end within 250ms tolerance triggers completion!
    mockPlayer.emitState(
      const AudioPlayerState(
        status: AudioStatus.playing,
        position: Duration(milliseconds: 2850),
        duration: Duration(seconds: 3),
      ),
    );

    // Allow event loop to process completion & advance
    await Future.delayed(const Duration(milliseconds: 50));

    // Verify it automatically advanced to Ayah 2!
    expect(container.read(quranAudioControllerProvider).currentAyahNumber, 2);
    expect(mockPlayer.playedUrls.length, 2);
  });
}
