import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;

  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;

  /// When true, we're in an active playback session.
  /// The notification stays alive until explicitly stopped via [customStop].
  bool _hasActiveSession = false;

  QuranAudioHandler(this._player) {
    _init();
  }

  void _init() {
    // Listen to playback events (play/pause/seek/buffer) instead of constant position changes.
    // Constantly broadcasting position breaks Android's seekbar interpolation and causes lag.
    _playerStateSubscription = _player.playbackEventStream.listen((_) {
      _broadcastState();
    });

    // Duration — update MediaItem when the real duration is known
    _durationSubscription = _player.durationStream.listen((duration) {
      if (mediaItem.value != null &&
          duration != null &&
          duration != Duration.zero) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  void _broadcastState() {
    if (!_hasActiveSession) return;

    final isPlaying = _player.playing;
    final processingState = _player.processingState;

    AudioProcessingState audioProcessingState;
    switch (processingState) {
      case ProcessingState.idle:
        // Player is idle (between tracks) — show buffering to keep notification alive
        audioProcessingState = AudioProcessingState.buffering;
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        audioProcessingState = AudioProcessingState.buffering;
        break;
      case ProcessingState.ready:
        audioProcessingState = AudioProcessingState.ready;
        break;
      case ProcessingState.completed:
        // Track completed — show buffering (next ayah is about to load)
        audioProcessingState = AudioProcessingState.buffering;
        break;
    }

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: audioProcessingState,
        playing: isPlaying,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        updateTime: DateTime.now(), // ⬅️ Forces Android to sync position immediately
      ),
    );
  }

  @override
  Future<void> play() async {
    if (onPlay != null) {
      await onPlay!();
    } else {
      await _player.play();
    }
  }

  @override
  Future<void> pause() async {
    if (onPause != null) {
      await onPause!();
    } else {
      await _player.pause();
    }
  }

  @override
  Future<void> stop() async {
    _hasActiveSession = false;
    await _player.stop();
    playbackState.add(
      PlaybackState(
        controls: [],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (onSkipNext != null) {
      await onSkipNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipPrevious != null) {
      await onSkipPrevious!();
    }
  }

  /// Update metadata for active surah/ayah and push to Android Media Notification.
  /// Also marks the session as active so the notification stays persistent.
  void updateAyahMediaItem({
    required String id,
    required String surahName,
    required int ayahNumber,
    required String reciterName,
    Duration? duration,
  }) {
    _hasActiveSession = true;
    mediaItem.add(
      MediaItem(
        id: id,
        album: 'قرآن کریم',
        title: 'سوره $surahName • آیه $ayahNumber',
        artist: reciterName,
        duration: duration ?? _player.duration,
      ),
    );
    _broadcastState();
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
  }
}
