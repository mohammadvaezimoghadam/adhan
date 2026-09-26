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
import 'package:quran/features/quran_reader/application/controllers/quran_audio_controller.dart';
import 'package:quran/features/quran_reader/domain/entities/reciter_entity.dart';
import 'package:quran/features/quran_reader/domain/enums/audio_playback_mode.dart';
import 'package:quran/features/quran_reader/infrastructure/repositories/reciter_repository.dart';
import 'package:quran/features/subscription/application/vip_subscription_controller.dart';
import 'package:quran/features/subscription/domain/models/vip_subscription_state.dart';
import 'package:quran/features/subscription/domain/policy/audio_vip_policy.dart';

class FakeVipSubscriptionController extends VipSubscriptionController {
  final bool initialIsVip;
  FakeVipSubscriptionController({this.initialIsVip = true});

  @override
  VipSubscriptionState build() {
    return VipSubscriptionState(
      isVip: initialIsVip,
      isLoading: false,
    );
  }

  void expireVip() {
    state = const VipSubscriptionState(
      isVip: false,
      isLoading: false,
    );
  }
}

class FakeReciterRepository extends Fake implements ReciterRepository {
  static const parhizgar = ReciterEntity(
    id: 91,
    name: 'شهریار پرهیزگار (48kbps)',
    englishName: 'Parhizgar',
    arabicName: 'شهریار پرهیزگار',
    subfolder: 'Parhizgar_48kbps',
    bitrate: '48kbps',
    identifier: 'parhizgar_48kbps',
    styleId: 1,
    styleName: 'ترتیل',
  );

  static const abdulbasit = ReciterEntity(
    id: 2,
    name: 'عبدالباسط عبدالصمد',
    englishName: 'Abdulbasit',
    arabicName: 'عبد الباسط عبد الصمد',
    subfolder: 'Abdulbasit_64kbps',
    bitrate: '64kbps',
    identifier: 'abdulbasit_murattal',
    styleId: 1,
    styleName: 'مرتل',
  );

  @override
  Future<Result<List<ReciterEntity>, Failure>> getAllReciters() async {
    return const Success([parhizgar, abdulbasit]);
  }
}

class FakeQuranAudioHandler extends Fake implements QuranAudioHandler {
  @override
  Future<void> Function()? onSkipNext;
  @override
  Future<void> Function()? onSkipPrevious;
  @override
  Future<void> Function()? onPlay;
  @override
  Future<void> Function()? onPause;
}

class FakeAudioPlayerService extends Fake implements IAudioPlayerService {
  final _controller = StreamController<AudioPlayerState>.broadcast();

  @override
  Stream<AudioPlayerState> get stateStream => _controller.stream;

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VipSubscriptionState.isAllFeaturesFree = false;
  });

  tearDown(() {
    VipSubscriptionState.isAllFeaturesFree = true;
  });

  test('When VIP subscription expires, audio mode reverts to onlyQuran and reciter reverts to Parhizgar', () async {
    SharedPreferences.setMockInitialValues({
      'audio_playback_mode': AudioPlaybackMode.quranThenTranslation.index,
      'selected_reciter_id': FakeReciterRepository.abdulbasit.id,
    });
    final sharedPrefs = await SharedPreferences.getInstance();

    final fakeVipController = FakeVipSubscriptionController(initialIsVip: true);
    final fakeAudioHandler = FakeQuranAudioHandler();
    final fakeAudioPlayer = FakeAudioPlayerService();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(sharedPrefs),
        preferencesServiceProvider.overrideWithValue(PreferencesServiceImpl(sharedPrefs)),
        reciterRepositoryProvider.overrideWithValue(FakeReciterRepository()),
        vipSubscriptionControllerProvider.overrideWith(() => fakeVipController),
        quranAudioHandlerProvider.overrideWithValue(fakeAudioHandler),
        audioPlayerServiceProvider.overrideWithValue(fakeAudioPlayer),
      ],
    );
    addTearDown(container.dispose);

    // Read audio controller to initialize
    container.read(quranAudioControllerProvider.notifier);
    await Future.delayed(const Duration(milliseconds: 50));

    // Initially VIP is active: mode is quranThenTranslation and reciter is Abdulbasit
    var state = container.read(quranAudioControllerProvider);
    expect(state.playbackMode, AudioPlaybackMode.quranThenTranslation);
    expect(state.selectedReciter?.id, FakeReciterRepository.abdulbasit.id);

    // Now VIP subscription expires!
    fakeVipController.expireVip();
    await Future.delayed(const Duration(milliseconds: 50));

    // Audio controller must have automatically reverted to onlyQuran and Parhizgar
    state = container.read(quranAudioControllerProvider);
    expect(state.playbackMode, AudioPlaybackMode.onlyQuran);
    expect(AudioVipPolicy.isDefaultReciter(state.selectedReciter?.identifier), isTrue);
    expect(state.selectedReciter?.id, FakeReciterRepository.parhizgar.id);

    // Preferences must also be updated
    expect(sharedPrefs.getInt('audio_playback_mode'), AudioPlaybackMode.onlyQuran.index);
    expect(sharedPrefs.getInt('selected_reciter_id'), FakeReciterRepository.parhizgar.id);
  });

  test('Non-VIP user on initial launch with saved translation mode automatically falls back to onlyQuran and Parhizgar', () async {
    SharedPreferences.setMockInitialValues({
      'audio_playback_mode': AudioPlaybackMode.onlyTranslation.index,
      'selected_reciter_id': FakeReciterRepository.abdulbasit.id,
    });
    final sharedPrefs = await SharedPreferences.getInstance();

    final fakeVipController = FakeVipSubscriptionController(initialIsVip: false);
    final fakeAudioHandler = FakeQuranAudioHandler();
    final fakeAudioPlayer = FakeAudioPlayerService();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesInstanceProvider.overrideWithValue(sharedPrefs),
        preferencesServiceProvider.overrideWithValue(PreferencesServiceImpl(sharedPrefs)),
        reciterRepositoryProvider.overrideWithValue(FakeReciterRepository()),
        vipSubscriptionControllerProvider.overrideWith(() => fakeVipController),
        quranAudioHandlerProvider.overrideWithValue(fakeAudioHandler),
        audioPlayerServiceProvider.overrideWithValue(fakeAudioPlayer),
      ],
    );
    addTearDown(container.dispose);

    container.read(quranAudioControllerProvider.notifier);
    await Future.delayed(const Duration(milliseconds: 50));

    final state = container.read(quranAudioControllerProvider);
    expect(state.playbackMode, AudioPlaybackMode.onlyQuran);
    expect(AudioVipPolicy.isDefaultReciter(state.selectedReciter?.identifier), isTrue);
    expect(state.selectedReciter?.id, FakeReciterRepository.parhizgar.id);

    expect(sharedPrefs.getInt('audio_playback_mode'), AudioPlaybackMode.onlyQuran.index);
    expect(sharedPrefs.getInt('selected_reciter_id'), FakeReciterRepository.parhizgar.id);
  });
}
