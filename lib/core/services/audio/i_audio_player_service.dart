import 'audio_player_state.dart';

abstract class IAudioPlayerService {
  Future<void> play(String url);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setVolume(double volume);
  Stream<AudioPlayerState> get stateStream;
  AudioPlayerState get currentState;
  void dispose();
}
