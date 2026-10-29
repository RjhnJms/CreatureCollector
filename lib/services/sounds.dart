import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/models.dart';
import 'music.dart';
import 'speech.dart';

/// Plays creatures' real calls. One at a time: starting a call stops the
/// last one and any question being read aloud.
class Sounds {
  Sounds._();
  static final instance = Sounds._();

  // Made on first use, so screens that never play a sound (and widget
  // tests) don't touch the audio plugin.
  AudioPlayer? _player;

  // Stops long recordings early (see [CreatureSound.maxSeconds]).
  Timer? _cutoff;

  /// The sound playing now, so a Listen button can show it's playing.
  final playing = ValueNotifier<CreatureSound?>(null);

  Future<void> play(CreatureSound sound) async {
    try {
      await Speech.instance.stop();
      var player = _player;
      if (player == null) {
        player = _player = AudioPlayer();
        await player.setAudioContext(Music.context);
        player.onPlayerComplete.listen((_) => _done());
      }
      _cutoff?.cancel();
      await player.stop();
      playing.value = sound;
      Music.instance.duck('call', true);
      await player.play(AssetSource('sounds/${sound.file}'));
      if (sound.maxSeconds case final secs?) {
        _cutoff = Timer(Duration(seconds: secs), () {
          if (playing.value == sound) stop();
        });
      }
    } catch (e) {
      _done();
      debugPrint('Sound unavailable: $e');
    }
  }

  void _done() {
    _cutoff?.cancel();
    playing.value = null;
    Music.instance.duck('call', false);
  }

  Future<void> stop() async {
    _done();
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
