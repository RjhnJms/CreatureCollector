import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../state/settings.dart';
import 'music.dart';

/// The game's short sound effects. All of them are synthesized by
/// tool/make_sfx.py, so there is nothing to license or credit.
enum Sfx {
  correct,
  wrong,
  found,
  catchIt('catch'),
  levelUp('levelup'),
  gem,
  tap;

  const Sfx([this._file]);
  final String? _file;

  String get file => 'sfx/${_file ?? name}.wav';

  /// Taps are small and frequent, so they're quieter than the rest.
  double get volume => this == Sfx.tap ? 0.3 : 0.7;

  /// Plays this sound, unless sound effects are off in Settings.
  void play() => _SfxPlayer.instance.play(this);
}

class _SfxPlayer {
  _SfxPlayer._();
  static final instance = _SfxPlayer._();

  // A few players taking turns, so quick sounds can overlap (a tap right
  // before a "correct" chime) without cutting each other off.
  static const _poolSize = 3;
  final _pool = <AudioPlayer>[];
  int _next = 0;

  // Widget tests have no audio plugin.
  static final bool _inTest =
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> play(Sfx sfx) async {
    if (_inTest || !Settings.instance.soundEffects) return;
    try {
      if (_pool.length < _poolSize) {
        final p = AudioPlayer();
        await p.setAudioContext(Music.context);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        _pool.add(p);
      }
      final player = _pool[_next];
      _next = (_next + 1) % _poolSize;
      await player.stop();
      await player.setVolume(sfx.volume);
      await player.play(AssetSource(sfx.file));
    } catch (e) {
      debugPrint('Sound effect unavailable: $e');
    }
  }
}
