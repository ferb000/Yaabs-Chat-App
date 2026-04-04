import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayerControllerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>((ref) {
      final player = AudioPlayer();
      ref.onDispose(() => player.dispose());
      return AudioPlayerController(player);
    });

class AudioPlayerState {
  final String? url; // currently loaded url
  final bool playing;
  final Duration position;
  final Duration duration;

  const AudioPlayerState({
    this.url,
    required this.playing,
    required this.position,
    required this.duration,
  });

  AudioPlayerState copyWith({
    String? url,
    bool? playing,
    Duration? position,
    Duration? duration,
  }) => AudioPlayerState(
    url: url ?? this.url,
    playing: playing ?? this.playing,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );

  static const empty = AudioPlayerState(
    url: null,
    playing: false,
    position: Duration.zero,
    duration: Duration.zero,
  );
}

class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController(this._player) : super(AudioPlayerState.empty) {
    _player.playerStateStream.listen((s) {
      state = state.copyWith(playing: s.playing);
    });

    _player.positionStream.listen((p) {
      state = state.copyWith(position: p);
    });

    _player.durationStream.listen((d) {
      state = state.copyWith(duration: d ?? Duration.zero);
    });

    _player.processingStateStream.listen((ps) {
      // reset when completed
      if (ps == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  final AudioPlayer _player;

  Future<void> toggle(String url) async {
    // If tapping the same URL, just play/pause
    if (state.url == url) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    // Different URL: stop previous and load new
    await _player.stop();
    await _player.setUrl(url);

    state = state.copyWith(url: url, position: Duration.zero);

    await _player.play();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    state = AudioPlayerState.empty;
  }
}
