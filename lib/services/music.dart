import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The background music: "Up in the Sky" by Memoraphile (CC0, from
/// OpenGameArt), looping quietly under the whole app.
///
/// It goes quieter while something else needs to be heard (a question being
/// read, an animal's call), stops while the app is in the background, and
/// stays off once the player mutes it.
class Music with WidgetsBindingObserver {
  Music._();
  static final instance = Music._();

  static const _file = 'music/up_in_the_sky.ogg';
  static const _volume = 0.35;
  static const _duckedVolume = 0.08;
  static const _mutedKey = 'musicMuted';

  /// Plays alongside the animal-call player instead of taking audio focus
  /// from it.
  static final context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  AudioPlayer? _player;
  bool _started = false;
  bool _inBackground = false;

  /// True while the browser blocked autoplay; the next tap starts the music.
  bool _blocked = false;
  final _ducks = <String>{};

  /// Whether the player turned the music off. Saved between visits.
  final muted = ValueNotifier<bool>(false);

  /// Loads the saved mute setting and starts the music unless it's muted.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    muted.value = prefs.getBool(_mutedKey) ?? false;
    await _sync();
  }

  Future<void> toggleMute() async {
    muted.value = !muted.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, muted.value);
    await _sync();
  }

  /// Turns the music down while [reason] is active, such as a question
  /// on screen. Several reasons can hold it down at once.
  void duck(String reason, bool on) {
    final changed = on ? _ducks.add(reason) : _ducks.remove(reason);
    if (changed) _setVolume();
  }

  /// Browsers only allow sound after the first tap, so retry then.
  void onUserTap() {
    if (_blocked) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state != AppLifecycleState.resumed;
    _sync();
  }

  Future<void> _sync() async {
    if (!_started) return;
    try {
      if (muted.value || _inBackground) {
        await _player?.pause();
        return;
      }
      final player = _player;
      if (player == null) {
        final p = _player = AudioPlayer();
        await p.setAudioContext(context);
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setVolume(_ducks.isEmpty ? _volume : _duckedVolume);
        await p.play(AssetSource(_file));
      } else if (player.state != PlayerState.playing) {
        await player.resume();
      }
      _blocked = false;
    } catch (e) {
      // On the web this is usually autoplay being blocked until a tap.
      _blocked = true;
      debugPrint('Music unavailable: $e');
    }
  }

  void _setVolume() {
    _player
        ?.setVolume(_ducks.isEmpty ? _volume : _duckedVolume)
        .catchError((_) {});
  }
}
