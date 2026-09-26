import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_error_parser.dart';
import 'audio_player_state.dart';
import 'i_audio_player_service.dart';

class JustAudioPlayerService implements IAudioPlayerService {
  final AudioPlayer _audioPlayer;
  final StreamController<AudioPlayerState> _stateController =
      StreamController<AudioPlayerState>.broadcast();
  AudioPlayerState _state = AudioPlayerState.initial();

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  bool _isInternalTransition = false;

  /// Generation counter to cancel stale retry loops when a new play() is invoked.
  int _playGeneration = 0;

  /// Maximum time to wait for a network audio source to load before timing out.
  static const Duration _loadTimeout = Duration(seconds: 12);

  /// Maximum number of retry attempts for transient network failures.
  static const int _maxRetries = 2;

  JustAudioPlayerService({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _initListeners();
  }

  void _initListeners() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (playerState) {
        final processingState = playerState.processingState;
        final isPlaying = playerState.playing;

        // Skip emitting stopped or stale completed states during internal track transitions
        if (_isInternalTransition &&
            (processingState == ProcessingState.idle ||
             processingState == ProcessingState.completed)) {
          return;
        }

        AudioStatus status;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          status = AudioStatus.loading;
        } else if (processingState == ProcessingState.completed) {
          status = AudioStatus.completed;
        } else if (processingState == ProcessingState.idle) {
          status = AudioStatus.stopped;
        } else if (isPlaying) {
          status = AudioStatus.playing;
        } else {
          status = AudioStatus.paused;
        }

        _updateState(_state.copyWith(status: status));
      },
      onError: (Object e, StackTrace s) {
        _updateState(
          _state.copyWith(
            status: AudioStatus.error,
            errorMessage: AudioErrorParser.parseError(e),
          ),
        );
      },
    );

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (_state.status == AudioStatus.completed) {
        _state = _state.copyWith(position: position);
        return;
      }
      final dur = _state.duration;
      final remaining = dur - position;
      final isNearOrAtEnd = dur > const Duration(seconds: 1) &&
          (position >= dur || (remaining <= const Duration(milliseconds: 250) && remaining >= Duration.zero));

      if (isNearOrAtEnd && _state.status == AudioStatus.playing) {
        _updateState(_state.copyWith(
          position: position,
          status: AudioStatus.completed,
        ));
        return;
      }
      _updateState(_state.copyWith(position: position));
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (_state.status == AudioStatus.completed) {
        _state = _state.copyWith(duration: duration ?? Duration.zero);
        return;
      }
      _updateState(_state.copyWith(duration: duration ?? Duration.zero));
    });
  }

  void _updateState(AudioPlayerState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  @override
  AudioPlayerState get currentState => _state;

  @override
  Stream<AudioPlayerState> get stateStream => _stateController.stream;

  @override
  Future<void> play(String url) async {
    // Increment generation so any in-flight retry loop from a previous play() exits silently.
    final generation = ++_playGeneration;

    _updateState(
      _state.copyWith(
        status: AudioStatus.loading,
        currentUrl: url,
        errorMessage: null,
      ),
    );

    _isInternalTransition = true;
    try {
      if (kIsWeb) {
        // On Web, HTML5 <audio> element must be stopped before changing source.
        // play() on web resolves only when playback ENDS, so if a track is playing,
        // setUrl(newUrl) may be ignored because the element is still attached to the old source.
        // Calling stop() releases the element and resets it for a clean source switch.
        if (_audioPlayer.playing || _audioPlayer.processingState == ProcessingState.completed) {
          await _audioPlayer.stop();
        }

        for (int attempt = 0; attempt <= _maxRetries; attempt++) {
          if (_playGeneration != generation) return;

          try {
            await _audioPlayer.setUrl(url).timeout(
              _loadTimeout,
              onTimeout: () {
                throw TimeoutException(
                  'سرور صوت پاسخ نمی‌دهد. لطفاً اتصال اینترنت خود را بررسی کنید.',
                  _loadTimeout,
                );
              },
            );

            if (_playGeneration != generation) return;

            // Proactively emit playing status on web
            _updateState(_state.copyWith(status: AudioStatus.playing));

            unawaited(_audioPlayer.play().catchError((e) {
              debugPrint('🛑 [Web Audio Play Error] $e');
              if (_playGeneration == generation) {
                _updateState(
                  _state.copyWith(
                    status: AudioStatus.error,
                    errorMessage: AudioErrorParser.parseError(e),
                  ),
                );
              }
            }));
            return; // Exit retry loop on success
          } catch (e) {
            if (_playGeneration != generation) return;
            final isLastAttempt = attempt == _maxRetries;
            final isRetryable = _isRetryableError(e);
            if (isLastAttempt || !isRetryable) {
              if (_playGeneration == generation) {
                _updateState(
                  _state.copyWith(
                    status: AudioStatus.error,
                    errorMessage: AudioErrorParser.parseError(e),
                  ),
                );
              }
              return;
            }
            await Future.delayed(Duration(seconds: 1 << attempt));
          }
        }
        return;
      }

      // Non-web platforms (Android, iOS, Desktop)
      // We DO NOT call pause() or stop() before setUrl.
      // Calling pause() sets playing=false, which drops the Android wakelock
      // and causes aggressive battery optimizers (like Oppo) to sleep the app
      // before the next track can load. setUrl() while playing is safe.

      // Bail out if a newer play() was called during stop/delay
      if (_playGeneration != generation) return;

      // Retry loop for transient network failures
      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        // Check before each attempt — a newer play() supersedes this one
        if (_playGeneration != generation) return;

        try {
          final isRemote = url.startsWith('http://') || url.startsWith('https://');
          if (isRemote) {
            await _audioPlayer.setUrl(url).timeout(
              _loadTimeout,
              onTimeout: () {
                throw TimeoutException(
                  'سرور صوت پاسخ نمی‌دهد. لطفاً اتصال اینترنت خود را بررسی کنید.',
                  _loadTimeout,
                );
              },
            );
          } else {
            final cleanPath = url.startsWith('file://')
                ? Uri.parse(url).toFilePath()
                : url;
            await _audioPlayer.setFilePath(cleanPath).timeout(
              _loadTimeout,
              onTimeout: () {
                throw TimeoutException(
                  'خطا در بارگذاری فایل صوت محلی.',
                  _loadTimeout,
                );
              },
            );
          }

          // Bail out if superseded while waiting for setUrl
          if (_playGeneration != generation) return;

          // Removed seek(Duration.zero) as setUrl/setFilePath already resets the position,
          // and seeking immediately after can cause ExoPlayer to stall on some devices.

          // Fire-and-forget: just_audio's play() Future completes only when
          // playback finishes (not when it starts).  Awaiting it here would
          // block the entire call-chain (including QuranAudioController's
          // _onTrackCompleted), preventing the completion handler from ever
          // firing for the *next* track.
          unawaited(_audioPlayer.play().catchError((e) {
            debugPrint('🛑 [Native Audio Play Error] $e');
            if (_playGeneration == generation) {
              _updateState(
                _state.copyWith(
                  status: AudioStatus.error,
                  errorMessage: AudioErrorParser.parseError(e),
                ),
              );
            }
          }));
          return; // Exit retry loop on success
        } catch (e) {
          if (_playGeneration != generation) return;

          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('interrupted') || errorStr.contains('abort')) {
            return;
          }

          final isLastAttempt = attempt == _maxRetries;
          final isRetryable = _isRetryableError(e);

          if (isLastAttempt || !isRetryable) {
            if (_playGeneration == generation) {
              _updateState(
                _state.copyWith(
                  status: AudioStatus.error,
                  errorMessage: AudioErrorParser.parseError(e),
                ),
              );
            }
            return;
          }

          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      }
    } finally {
      if (_playGeneration == generation) {
        _isInternalTransition = false;
      }
    }
  }

  /// Determines if an error is transient and worth retrying.
  bool _isRetryableError(dynamic error) {
    final msg = error.toString().toLowerCase();
    // Retry on network issues and timeouts; do NOT retry on 404 or format errors.
    if (msg.contains('404') || msg.contains('not found')) return false;
    if (msg.contains('format') || msg.contains('codec')) return false;
    return msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('timed out') ||
        msg.contains('handshake') ||
        msg.contains('network') ||
        msg.contains('failed to connect') ||
        msg.contains('failed host lookup') ||
        msg.contains('dns') ||
        msg.contains('reset') ||
        error is TimeoutException;
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> resume() async {
    if (kIsWeb) {
      unawaited(_audioPlayer.play().catchError((e) {
        debugPrint('🛑 [Web Audio Resume Error] $e');
      }));
    } else {
      final dur = _audioPlayer.duration;
      final isNearEnd = dur != null &&
          dur > const Duration(seconds: 1) &&
          (_audioPlayer.position >= dur ||
           (dur - _audioPlayer.position) <= const Duration(milliseconds: 250));
      if (_audioPlayer.processingState == ProcessingState.completed || isNearEnd) {
        await _audioPlayer.seek(Duration.zero);
      }
      // Fire-and-forget: same rationale as play() — avoid blocking the
      // caller until playback finishes.
      unawaited(_audioPlayer.play().catchError((e) {
        debugPrint('🛑 [Native Audio Resume Error] $e');
      }));
    }
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    _updateState(_state.copyWith(speed: speed));
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateController.close();
    _audioPlayer.dispose();
  }
}
