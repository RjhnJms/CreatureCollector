import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../state/settings.dart';

/// Reads questions aloud for kids who are still learning to read.
class Speech {
  Speech._();
  static final instance = Speech._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.05);
    _ready = true;
  }

  // Browsers and phones count speech rate differently.
  double get _rate => switch (Settings.instance.readSpeed) {
    ReadSpeed.slow => kIsWeb ? 0.75 : 0.35,
    ReadSpeed.normal => kIsWeb ? 0.9 : 0.45,
    ReadSpeed.fast => kIsWeb ? 1.1 : 0.55,
  };

  Future<void> speak(String text) async {
    try {
      await _init();
      await _tts.setSpeechRate(_rate);
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      // Some devices have no text-to-speech voice installed. The game still
      // works without it, so just log and carry on.
      debugPrint('Speech unavailable: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
