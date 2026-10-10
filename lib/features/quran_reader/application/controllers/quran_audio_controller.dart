import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/constants/surah_constants.dart';
import '../../../../core/services/audio/audio_error_parser.dart';
import '../../../../core/services/audio/audio_player_providers.dart';
import '../../../../core/services/audio/audio_player_state.dart';
import '../../../../core/services/audio/audio_url_helper.dart';
import '../../../../core/services/audio_storage/audio_storage_providers.dart';
import '../../domain/entities/reciter_entity.dart';
import '../../domain/enums/audio_playback_mode.dart';
import '../../domain/enums/current_track_type.dart';
import '../../infrastructure/repositories/reciter_repository.dart';
import '../../../../core/data/local/preferences/preferences_service_provider.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_condition.dart';
import '../../../../core/services/audio/sleep_timer/sleep_timer_controller.dart';
import '../../domain/entities/ayah_entity.dart';
import '../ayah_service.dart';
import '../states/quran_audio_state.dart';
import 'quran_reader_controller.dart';
import '../../../subscription/application/vip_subscription_controller.dart';
import '../../../subscription/domain/models/vip_subscription_state.dart';
import '../../../subscription/domain/policy/audio_vip_policy.dart';
import '../../../surah_list/infrastructure/datasources/static_surahs_data.dart';

final quranAudioControllerProvider =
    NotifierProvider<QuranAudioController, QuranAudioState>(
  QuranAudioController.new,
);

class QuranAudioController extends Notifier<QuranAudioState> {
  StreamSubscription<AudioPlayerState>? _audioStateSubscription;
  bool _isTransitioningTrack = false;

  @override
  QuranAudioState build() {
    _initDefaultReciterAndListeners();

    // Real-time listener: When VIP expires or user has no active VIP, automatically
    // revert playbackMode to onlyQuran and selectedReciter to Parhizgar (100% free reciter).
    ref.listen<VipSubscriptionState>(
      vipSubscriptionControllerProvider,
      (previous, next) {
        if (!next.isLoading && !next.hasVipAccess) {
          _enforceFreePlaybackDefaults();
        }
      },
    );

    ref.onDispose(() {
      _audioStateSubscription?.cancel();
    });
    return const QuranAudioState();
  }

  Future<void> _initDefaultReciterAndListeners() async {
    // Register AudioHandler callbacks for notification & headset controls
    final handler = ref.read(quranAudioHandlerProvider);
    handler.onSkipNext = () async => playNextAyah();
    handler.onSkipPrevious = () async => playPreviousAyah();
    handler.onPlay = () async => resume();
    handler.onPause = () async => pause();

    final repo = ref.read(reciterRepositoryProvider);
    final prefs = ref.read(preferencesServiceProvider);
    final savedReciterId = prefs.getInt('selected_reciter_id');
    final savedTranslationReciterId = prefs.getInt('selected_translation_reciter_id');
    final savedModeIndex = prefs.getInt('audio_playback_mode');
    final savedSpeed = prefs.getDouble('audio_playback_speed') ?? 1.0;

    AudioPlaybackMode initialMode = AudioPlaybackMode.onlyQuran;
    if (savedModeIndex != null && savedModeIndex >= 0 && savedModeIndex < AudioPlaybackMode.values.length) {
      initialMode = AudioPlaybackMode.values[savedModeIndex];
    }

    if (savedSpeed != 1.0) {
      ref.read(audioPlayerServiceProvider).setSpeed(savedSpeed);
    }

    final result = await repo.getAllReciters();
    result.when(
      (reciters) {
        if (reciters.isNotEmpty) {
          final arabicReciters = reciters.where((r) => r.styleId != 4).toList();
          ReciterEntity defaultReciter;
          if (savedReciterId != null && arabicReciters.any((r) => r.id == savedReciterId)) {
            defaultReciter = arabicReciters.firstWhere((r) => r.id == savedReciterId);
          } else {
            defaultReciter = arabicReciters.firstWhere(
              (r) => AudioVipPolicy.isDefaultReciter(r.identifier),
              orElse: () => arabicReciters.isNotEmpty ? arabicReciters.first : reciters.first,
            );
          }

          ReciterEntity defaultTranslationReciter;
          final translationReciters = reciters.where((r) => r.styleId == 4).toList();
          if (savedTranslationReciterId != null && translationReciters.isNotEmpty) {
            defaultTranslationReciter = translationReciters.firstWhere(
              (r) => r.id == savedTranslationReciterId,
              orElse: () => translationReciters.first,
            );
          } else if (translationReciters.isNotEmpty) {
            defaultTranslationReciter = translationReciters.first;
          } else {
            defaultTranslationReciter = defaultReciter;
          }

          state = state.copyWith(
            selectedReciter: defaultReciter,
            selectedTranslationReciter: defaultTranslationReciter,
            playbackMode: initialMode,
            speed: savedSpeed,
          );
          _enforceFreePlaybackDefaults();
        }
      },
      (error) {},
    );

    // Listen to core AudioPlayerService state changes
    final audioService = ref.read(audioPlayerServiceProvider);
    _audioStateSubscription = audioService.stateStream.listen((playerState) {
      // Do NOT trigger continuous auto-play if stream is in error state!
      if (playerState.status == AudioStatus.error) {
        _isTransitioningTrack = false;
        state = state.copyWith(
          status: AudioStatus.error,
          errorMessage: playerState.errorMessage ?? 'خطا در پخش صوت',
        );
        return;
      }

      // ── Completion detection (evaluated before transition guard so it is NEVER swallowed) ──
      final dur = playerState.duration;
      final pos = playerState.position;
      final remaining = dur - pos;
      final isNearOrAtEnd = dur > const Duration(seconds: 1) &&
          (pos >= dur || (remaining <= const Duration(milliseconds: 250) && remaining >= Duration.zero));
      final isFinished = (playerState.status == AudioStatus.completed || isNearOrAtEnd) &&
          playerState.status != AudioStatus.loading;

      if (isFinished && !_isHandlingCompletion) {
        _isTransitioningTrack = false;
        state = state.copyWith(
          status: AudioStatus.completed,
          position: playerState.duration,
        );
        _onTrackCompleted();
        return;
      }

      // ── While transitioning between tracks, suppress intermediate states
      if (_isTransitioningTrack) {
        if (playerState.status == AudioStatus.playing || playerState.position > Duration.zero) {
          _isTransitioningTrack = false;
          state = state.copyWith(
            status: AudioStatus.playing,
            position: playerState.position,
            duration: playerState.duration,
          );
          if (state.currentAyahNumber != null) {
            ref
                .read(activeAyahProvider.notifier)
                .setActiveAyah(state.currentAyahNumber);
          }
        } else if (playerState.status == AudioStatus.error) {
          _isTransitioningTrack = false;
          state = state.copyWith(
            status: AudioStatus.error,
            errorMessage: playerState.errorMessage ?? 'خطا در بارگذاری صوت',
          );
        }
        return;
      }

      // ── Normal (non-transitioning) state handling ──
      state = state.copyWith(
        status: playerState.status,
        position: playerState.position,
        duration: playerState.duration,
        errorMessage: playerState.errorMessage,
      );

      if (playerState.status == AudioStatus.playing &&
          state.currentAyahNumber != null) {
        ref
            .read(activeAyahProvider.notifier)
            .setActiveAyah(state.currentAyahNumber);
      }
    });
  }

  CurrentTrackType _getInitialTrackType(AudioPlaybackMode mode) {
    switch (mode) {
      case AudioPlaybackMode.onlyQuran:
      case AudioPlaybackMode.quranThenTranslation:
        return CurrentTrackType.quran;
      case AudioPlaybackMode.onlyTranslation:
      case AudioPlaybackMode.translationThenQuran:
        return CurrentTrackType.translation;
    }
  }

  bool _isHandlingCompletion = false;

  Future<void> _onTrackCompleted() async {
    if (_isHandlingCompletion) return;
    _isHandlingCompletion = true;

    try {
      final currentAyah = state.currentAyahNumber;
      final surahId = state.currentSurahId;
      final totalAyahs = state.totalAyahsInSurah ??
          (surahId != null && surahId >= 1 && surahId <= 114
              ? kStaticQuranSurahs[surahId - 1].numberOfAyahs
              : null);
      final mode = state.playbackMode;
      final trackType = state.currentTrackType;

      debugPrint(
        '🎵 [_onTrackCompleted] surah: $surahId, ayah: $currentAyah / $totalAyahs, mode: $mode, isAutoPlayNext: ${state.isAutoPlayNext}',
      );

      if (currentAyah == null || surahId == null || totalAyahs == null) {
        await stop();
        return;
      }

      switch (mode) {
        case AudioPlaybackMode.onlyQuran:
          await _advanceNextAyah(
            surahId: surahId,
            currentAyah: currentAyah,
            totalAyahs: totalAyahs,
            targetTrack: CurrentTrackType.quran,
          );
          break;

        case AudioPlaybackMode.onlyTranslation:
          await _advanceNextAyah(
            surahId: surahId,
            currentAyah: currentAyah,
            totalAyahs: totalAyahs,
            targetTrack: CurrentTrackType.translation,
          );
          break;

        case AudioPlaybackMode.quranThenTranslation:
          if (trackType == CurrentTrackType.quran) {
            // Play translation for SAME ayah
            await _playTrack(
              surahId: surahId,
              ayahNumber: currentAyah,
              totalAyahsInSurah: totalAyahs,
              trackType: CurrentTrackType.translation,
              isSingleAyahMode: state.isSingleAyahMode,
            );
          } else {
            // Finished translation -> Move to next ayah, play quran
            await _advanceNextAyah(
              surahId: surahId,
              currentAyah: currentAyah,
              totalAyahs: totalAyahs,
              targetTrack: CurrentTrackType.quran,
            );
          }
          break;

        case AudioPlaybackMode.translationThenQuran:
          if (trackType == CurrentTrackType.translation) {
            // Play quran for SAME ayah
            await _playTrack(
              surahId: surahId,
              ayahNumber: currentAyah,
              totalAyahsInSurah: totalAyahs,
              trackType: CurrentTrackType.quran,
              isSingleAyahMode: state.isSingleAyahMode,
            );
          } else {
            // Finished quran -> Move to next ayah, play translation
            await _advanceNextAyah(
              surahId: surahId,
              currentAyah: currentAyah,
              totalAyahs: totalAyahs,
              targetTrack: CurrentTrackType.translation,
            );
          }
          break;
      }
    } finally {
      _isHandlingCompletion = false;
    }
  }

  Future<void> _advanceNextAyah({
    required int surahId,
    required int currentAyah,
    required int totalAyahs,
    required CurrentTrackType targetTrack,
  }) async {
    // ── Check Sleep Timer Condition ──
    final sleepTimerNotifier = ref.read(sleepTimerControllerProvider.notifier);
    final sleepTimerState = ref.read(sleepTimerControllerProvider);
    if (sleepTimerState.isActive) {
      final readerState = ref.read(quranReaderControllerProvider);
      AyahEntity? currentAyahEntity;
      AyahEntity? nextAyahEntity;
      if (readerState.currentSurahId == surahId) {
        currentAyahEntity = readerState.ayahs
            .where((a) => a.ayahNumber == currentAyah)
            .firstOrNull;
        nextAyahEntity = readerState.ayahs
            .where((a) => a.ayahNumber == currentAyah + 1)
            .firstOrNull;
      } else if (sleepTimerState.activeCondition is EndOfHizbCondition) {
        final res = await ref.read(ayahServiceProvider).getAyahsBySurah(surahId);
        res.whenSuccess((list) {
          currentAyahEntity =
              list.where((a) => a.ayahNumber == currentAyah).firstOrNull;
          nextAyahEntity =
              list.where((a) => a.ayahNumber == currentAyah + 1).firstOrNull;
        });
      }

      final shouldStop = sleepTimerNotifier.shouldStopAfter(
        surahId: surahId,
        ayahNumber: currentAyah,
        hizb: currentAyahEntity?.hizb,
        nextHizb: nextAyahEntity?.hizb,
        isLastAyahInSurah: currentAyah >= totalAyahs,
      );

      if (shouldStop) {
        debugPrint(
          '⏱ [QuranAudioController] Sleep timer boundary reached at Surah $surahId Ayah $currentAyah. Stopping playback.',
        );
        sleepTimerNotifier.cancel();
        _isTransitioningTrack = false;
        await stop();
        return;
      }
    }

    if (!state.isAutoPlayNext || state.isSingleAyahMode || currentAyah >= totalAyahs) {
      _isTransitioningTrack = false;
      await stop();
      return;
    }

    final nextAyah = currentAyah + 1;
    state = state.copyWith(status: AudioStatus.loading);
    _isTransitioningTrack = true;

    await _playTrack(
      surahId: surahId,
      ayahNumber: nextAyah,
      totalAyahsInSurah: totalAyahs,
      trackType: targetTrack,
      isSingleAyahMode: state.isSingleAyahMode,
    );
  }

  /// Select reciter safely without stream interruption crashes
  Future<void> selectReciter(ReciterEntity reciter, {bool autoRestart = true}) async {
    if (reciter.styleId == 4) {
      await selectTranslationReciter(reciter, autoRestart: autoRestart);
      return;
    }
    final isActuallyPlayingOrPaused = state.status == AudioStatus.playing || state.status == AudioStatus.loading || state.status == AudioStatus.paused;
    state = state.copyWith(selectedReciter: reciter);
    ref.read(preferencesServiceProvider).setInt('selected_reciter_id', reciter.id);

    if (autoRestart && isActuallyPlayingOrPaused && state.currentTrackType == CurrentTrackType.quran && state.currentSurahId != null && state.currentAyahNumber != null) {
      final audioService = ref.read(audioPlayerServiceProvider);
      await audioService.stop();
      await _playTrack(
        surahId: state.currentSurahId!,
        ayahNumber: state.currentAyahNumber!,
        totalAyahsInSurah: state.totalAyahsInSurah ?? 286,
        trackType: CurrentTrackType.quran,
        isSingleAyahMode: state.isSingleAyahMode,
      );
    }
  }

  /// Select translation reciter (گوینده ترجمه صوتی)
  Future<void> selectTranslationReciter(ReciterEntity reciter, {bool autoRestart = true}) async {
    if (reciter.styleId != 4) {
      await selectReciter(reciter, autoRestart: autoRestart);
      return;
    }
    final isActuallyPlayingOrPaused = state.status == AudioStatus.playing || state.status == AudioStatus.loading || state.status == AudioStatus.paused;
    state = state.copyWith(selectedTranslationReciter: reciter);
    ref.read(preferencesServiceProvider).setInt('selected_translation_reciter_id', reciter.id);

    if (autoRestart && isActuallyPlayingOrPaused && state.currentTrackType == CurrentTrackType.translation && state.currentSurahId != null && state.currentAyahNumber != null) {
      final audioService = ref.read(audioPlayerServiceProvider);
      await audioService.stop();
      await _playTrack(
        surahId: state.currentSurahId!,
        ayahNumber: state.currentAyahNumber!,
        totalAyahsInSurah: state.totalAyahsInSurah ?? 286,
        trackType: CurrentTrackType.translation,
        isSingleAyahMode: state.isSingleAyahMode,
      );
    }
  }

  /// Play a specific Ayah of a Surah
  Future<void> playAyah({
    required int surahId,
    required int ayahNumber,
    required int totalAyahsInSurah,
    bool isSingleAyahMode = false,
  }) async {
    final initialTrack = _getInitialTrackType(state.playbackMode);
    await _playTrack(
      surahId: surahId,
      ayahNumber: ayahNumber,
      totalAyahsInSurah: totalAyahsInSurah,
      trackType: initialTrack,
      isSingleAyahMode: isSingleAyahMode,
    );
  }

  Future<void> _playTrack({
    required int surahId,
    required int ayahNumber,
    required int totalAyahsInSurah,
    required CurrentTrackType trackType,
    bool isSingleAyahMode = false,
  }) async {
    _isTransitioningTrack = true;

    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }

    ReciterEntity? activeReciter;
    if (trackType == CurrentTrackType.quran) {
      activeReciter = state.selectedReciter;
      activeReciter ??= await _getFallbackReciter(isTranslation: false);
    } else {
      activeReciter = state.selectedTranslationReciter;
      activeReciter ??= await _getFallbackReciter(isTranslation: true);
    }

    // ── Enforce Audio VIP Policy defensively ──
    final isVip = ref.read(hasVipAccessProvider);
    if (trackType == CurrentTrackType.quran) {
      final canPlay = AudioVipPolicy.canPlayReciter(
        reciterIdentifier: activeReciter.identifier,
        surahId: surahId,
        isVip: isVip,
      );
      if (!canPlay) {
        _isTransitioningTrack = false;
        state = state.copyWith(
          status: AudioStatus.stopped,
          errorMessage: 'برای شنیدن تلاوت این قاری در این سوره، اشتراک ویژه لازم است.',
        );
        return;
      }
    } else if (trackType == CurrentTrackType.translation) {
      final canPlay = AudioVipPolicy.canPlayAudioTranslation(isVip: isVip);
      if (!canPlay) {
        _isTransitioningTrack = false;
        state = state.copyWith(
          status: AudioStatus.stopped,
          errorMessage: 'پخش ترجمه گویا نیازمند اشتراک ویژه است.',
        );
        return;
      }
    }

    // Update the correct reciter slot based on track type
    state = state.copyWith(
      selectedReciter: trackType == CurrentTrackType.quran
          ? activeReciter
          : state.selectedReciter,
      selectedTranslationReciter: trackType == CurrentTrackType.translation
          ? activeReciter
          : state.selectedTranslationReciter,
      currentSurahId: surahId,
      currentAyahNumber: ayahNumber,
      totalAyahsInSurah: totalAyahsInSurah,
      currentTrackType: trackType,
      isSingleAyahMode: isSingleAyahMode,
      status: AudioStatus.loading,
      lastAttemptedAyahNumber: null,
    );

    final surahName = SurahConstants.getSurahName(surahId);
    final displayReciterName = trackType == CurrentTrackType.translation
        ? '${activeReciter.name} (ترجمه)'
        : activeReciter.name;

    ref.read(quranAudioHandlerProvider).updateAyahMediaItem(
          id: 'surah_${surahId}_ayah_${ayahNumber}_${trackType.name}',
          surahName: surahName,
          ayahNumber: ayahNumber,
          reciterName: displayReciterName,
        );

    ref.read(activeAyahProvider.notifier).setActiveAyah(ayahNumber);

    final audioStorage = ref.read(audioStorageServiceProvider);
    final localPath = await audioStorage.getLocalAyahAudioPath(
      reciterId: activeReciter.id,
      surahId: surahId,
      ayahNumber: ayahNumber,
    );

    final String audioSourceToPlay;
    if (localPath != null) {
      audioSourceToPlay = localPath;
    } else if (kIsWeb) {
      // On Web, stream from server directly
      audioSourceToPlay = AudioUrlHelper.buildAyahUrl(
        subfolder: activeReciter.subfolder,
        surahNumber: surahId,
        ayahNumber: ayahNumber,
      );
    } else {
      // On Android/iOS/Desktop: file not downloaded → stop gracefully
      _isTransitioningTrack = false;
      final trackLabel = trackType == CurrentTrackType.translation
          ? 'ترجمه گویا'
          : 'تلاوت';
      state = state.copyWith(
        status: AudioStatus.stopped,
        errorMessage: 'فایل صوتی $trackLabel برای این آیه دانلود نشده است. لطفاً ابتدا دانلود کنید.',
        lastAttemptedAyahNumber: ayahNumber,
      );
      return;
    }

    try {
      final audioService = ref.read(audioPlayerServiceProvider);
      await audioService.play(audioSourceToPlay);
      if (state.speed != 1.0) {
        await audioService.setSpeed(state.speed);
      }
    } catch (e) {
      _isTransitioningTrack = false;
      await stop();
      state = state.copyWith(
        errorMessage: AudioErrorParser.parseError(e),
      );
    }
  }

  /// Ensures that non-VIP users fall back to free defaults:
  /// 1. Playback mode falls back to [AudioPlaybackMode.onlyQuran] (since translation requires VIP).
  /// 2. Reciter falls back to Ostad Parhizgar (100% free for all 114 surahs) if a non-free reciter was active.
  /// 3. If currently playing a locked track, safely stops playback.
  Future<void> _enforceFreePlaybackDefaults() async {
    final vipState = ref.read(vipSubscriptionControllerProvider);
    if (vipState.isLoading || vipState.hasVipAccess) return;

    final prefs = ref.read(preferencesServiceProvider);
    bool stateChanged = false;
    AudioPlaybackMode newMode = state.playbackMode;
    ReciterEntity? newReciter = state.selectedReciter;

    // 1. Enforce onlyQuran if translation mode is set
    if (state.playbackMode.includesTranslation) {
      newMode = AudioPlaybackMode.onlyQuran;
      await prefs.setInt('audio_playback_mode', AudioPlaybackMode.onlyQuran.index);
      stateChanged = true;
    }

    // 2. Enforce Ostad Parhizgar if current reciter is not the default free reciter
    if (state.selectedReciter != null &&
        !AudioVipPolicy.isDefaultReciter(state.selectedReciter!.identifier)) {
      final parhizgar = await _getFallbackReciter(isTranslation: false);
      newReciter = parhizgar;
      await prefs.setInt('selected_reciter_id', parhizgar.id);
      stateChanged = true;
    }

    if (stateChanged) {
      state = state.copyWith(
        playbackMode: newMode,
        selectedReciter: newReciter,
      );
    }

    // 3. Stop playback if actively playing VIP content
    final isPlayingOrLoading =
        state.status == AudioStatus.playing || state.status == AudioStatus.loading;
    if (isPlayingOrLoading) {
      final isPlayingTranslation = state.currentTrackType == CurrentTrackType.translation;
      final isPlayingLockedReciter = state.currentSurahId != null &&
          !AudioVipPolicy.canPlayReciter(
            reciterIdentifier: state.selectedReciter?.identifier,
            surahId: state.currentSurahId!,
            isVip: false,
          );

      if (isPlayingTranslation || isPlayingLockedReciter) {
        await stop();
      }
    }
  }

  Future<ReciterEntity> _getFallbackReciter({required bool isTranslation}) async {
    final repo = ref.read(reciterRepositoryProvider);
    final result = await repo.getAllReciters();
    ReciterEntity? found;
    result.when(
      (reciters) {
        if (reciters.isNotEmpty) {
          if (isTranslation) {
            final transReciters = reciters.where((r) => r.styleId == 4).toList();
            found = transReciters.isNotEmpty ? transReciters.first : reciters.first;
          } else {
            found = reciters.firstWhere(
              (r) => AudioVipPolicy.isDefaultReciter(r.identifier),
              orElse: () => reciters.first,
            );
          }
        }
      },
      (error) {},
    );
    return found ??
        const ReciterEntity(
          id: 91,
          name: 'شهریار پرهیزگار (48kbps)',
          englishName: 'Parhizgar',
          arabicName: 'شهریار پرهیزگار',
          subfolder: 'Parhizgar_48kbps',
          bitrate: '48kbps',
          identifier: 'parhizgar_48kbps',
          styleId: 1,
          styleName: 'ترتیل',
          imageUrl: 'assets/images/reciters/shahriar_parhizgar.jpg',
        );
  }

  /// Play previous ayah automatically or manually
  Future<void> playPreviousAyah() async {
    final currentAyah = state.currentAyahNumber;
    final totalAyahs = state.totalAyahsInSurah;
    final surahId = state.currentSurahId;

    if (currentAyah != null && totalAyahs != null && surahId != null && currentAyah > 1) {
      final prevAyah = currentAyah - 1;
      final initialTrack = _getInitialTrackType(state.playbackMode);
      await _playTrack(
        surahId: surahId,
        ayahNumber: prevAyah,
        totalAyahsInSurah: totalAyahs,
        trackType: initialTrack,
      );
    }
  }

  /// Play next ayah automatically or manually
  Future<void> playNextAyah() async {
    final currentAyah = state.currentAyahNumber;
    final totalAyahs = state.totalAyahsInSurah ?? 7;
    final surahId = state.currentSurahId ?? 1;

    final startAyah = currentAyah ?? 0;
    if (startAyah < totalAyahs) {
      final nextAyah = startAyah + 1;
      final initialTrack = _getInitialTrackType(state.playbackMode);
      await _playTrack(
        surahId: surahId,
        ayahNumber: nextAyah,
        totalAyahsInSurah: totalAyahs,
        trackType: initialTrack,
      );
    } else {
      _isTransitioningTrack = false;
      stop();
    }
  }

  /// Pause audio
  Future<void> pause() async {
    _isTransitioningTrack = false;
    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.pause();
  }

  /// Resume audio, or advance/replay if completed, stopped, or error
  Future<void> resume() async {
    final dur = state.duration;
    final pos = state.position;
    final remaining = dur - pos;
    final isAtEnd = dur > const Duration(seconds: 1) &&
        (pos >= dur || (remaining <= const Duration(milliseconds: 250) && remaining >= Duration.zero));
    final isCompleted = state.status == AudioStatus.completed || isAtEnd;
    final isStopped = state.status == AudioStatus.stopped || state.status == AudioStatus.initial;
    final isError = state.status == AudioStatus.error;

    if (isCompleted || isStopped || isError) {
      clearError();
      final surahId = state.currentSurahId ?? 1;
      final currentAyah = state.currentAyahNumber ?? 1;
      final totalAyahs = state.totalAyahsInSurah ??
          (surahId >= 1 && surahId <= 114
              ? kStaticQuranSurahs[surahId - 1].numberOfAyahs
              : 7);

      final targetAyah = isCompleted
          ? (currentAyah < totalAyahs ? currentAyah + 1 : 1)
          : currentAyah;

      await playAyah(
        surahId: surahId,
        ayahNumber: targetAyah,
        totalAyahsInSurah: totalAyahs,
      );
      return;
    }

    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.resume();
  }

  /// Stop audio
  Future<void> stop() async {
    _isTransitioningTrack = false;
    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.stop();
    
    // Explicitly tell the Android MediaSession (AudioHandler) to stop and dismiss the notification
    await ref.read(quranAudioHandlerProvider).stop();
    
    ref.read(activeAyahProvider.notifier).setActiveAyah(null);
    state = state.copyWith(
      currentAyahNumber: null,
      status: AudioStatus.stopped,
      isAutoScrollSuspended: false,
    );
  }

  /// Toggle AutoPlayNext
  void toggleAutoPlayNext() {
    state = state.copyWith(isAutoPlayNext: !state.isAutoPlayNext);
  }

  /// Toggle SingleAyahMode
  void toggleSingleAyahMode() {
    state = state.copyWith(isSingleAyahMode: !state.isSingleAyahMode);
  }

  /// Clear any error message state
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Suspend auto-scroll (e.g. when user interacts with an Ayah for copy/share/bookmark)
  void suspendAutoScroll() {
    if (!state.isAutoScrollSuspended) {
      state = state.copyWith(isAutoScrollSuspended: true);
    }
  }

  /// Resume auto-scroll and sync viewport immediately back to active playing Ayah
  void resumeAutoScrollAndSync() {
    state = state.copyWith(isAutoScrollSuspended: false);
    if (state.currentAyahNumber != null) {
      ref.read(activeAyahProvider.notifier).setActiveAyah(state.currentAyahNumber);
    }
    if (state.status == AudioStatus.paused) {
      resume();
    }
  }

  /// Change audio playback mode
  void setPlaybackMode(AudioPlaybackMode mode) {
    state = state.copyWith(playbackMode: mode);
    ref.read(preferencesServiceProvider).setInt('audio_playback_mode', mode.index);
  }

  /// Seek forward by specified duration (default: 5 seconds)
  Future<void> seekForward([Duration offset = const Duration(seconds: 5)]) async {
    final currentPos = state.position;
    final totalDuration = state.duration;
    var newPos = currentPos + offset;
    if (totalDuration > Duration.zero && newPos > totalDuration) {
      newPos = totalDuration;
    }
    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.seek(newPos);
  }

  /// Seek backward by specified duration (default: 5 seconds)
  Future<void> seekBackward([Duration offset = const Duration(seconds: 5)]) async {
    final currentPos = state.position;
    var newPos = currentPos - offset;
    if (newPos < Duration.zero) {
      newPos = Duration.zero;
    }
    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.seek(newPos);
  }

  /// Change audio playback speed (e.g. 0.75, 1.0, 1.25, 1.5)
  Future<void> setPlaybackSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    ref.read(preferencesServiceProvider).setDouble('audio_playback_speed', speed);
    final audioService = ref.read(audioPlayerServiceProvider);
    await audioService.setSpeed(speed);
  }

  /// Cycle through standard playback speeds (1.0 -> 1.25 -> 1.5 -> 0.75 -> 1.0)
  Future<void> cyclePlaybackSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5];
    final currentSpeed = state.speed;
    int currentIndex = speeds.indexWhere((s) => (s - currentSpeed).abs() < 0.05);
    if (currentIndex == -1) {
      currentIndex = 1; // default to 1.0
    }
    final nextIndex = (currentIndex + 1) % speeds.length;
    await setPlaybackSpeed(speeds[nextIndex]);
  }
}
