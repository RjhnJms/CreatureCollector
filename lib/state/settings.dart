import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the home scene is sunny or starry.
enum SceneMode { auto, day, night }

enum ReadSpeed { slow, normal, fast }

/// The player's settings, saved on the phone. Music on/off lives in
/// [Music] itself; everything else is here.
class Settings extends ChangeNotifier {
  Settings._();
  static final instance = Settings._();

  SharedPreferences? _prefs;

  SceneMode scene = SceneMode.auto;
  bool animalCalls = true;

  /// Chimes for right and wrong answers, catches, and taps.
  bool soundEffects = true;

  /// Read each question aloud as soon as it appears.
  bool autoRead = false;
  ReadSpeed readSpeed = ReadSpeed.normal;
  bool largeText = false;

  /// Fewer bouncy animations, on top of the phone's own setting.
  bool calmMotion = false;

  /// Minutes of play before the partner suggests a break. 0 is off.
  int breakMinutes = 0;

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    scene =
        SceneMode.values.asNameMap()[p.getString('setting.scene')] ??
        SceneMode.auto;
    animalCalls = p.getBool('setting.animalCalls') ?? true;
    soundEffects = p.getBool('setting.soundEffects') ?? true;
    autoRead = p.getBool('setting.autoRead') ?? false;
    readSpeed =
        ReadSpeed.values.asNameMap()[p.getString('setting.readSpeed')] ??
        ReadSpeed.normal;
    largeText = p.getBool('setting.largeText') ?? false;
    calmMotion = p.getBool('setting.calmMotion') ?? false;
    breakMinutes = p.getInt('setting.breakMinutes') ?? 0;
    notifyListeners();
  }

  /// Changes settings, then saves them all and tells listeners.
  Future<void> update(void Function(Settings s) change) async {
    change(this);
    notifyListeners();
    final p = _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      p.setString('setting.scene', scene.name),
      p.setBool('setting.animalCalls', animalCalls),
      p.setBool('setting.soundEffects', soundEffects),
      p.setBool('setting.autoRead', autoRead),
      p.setString('setting.readSpeed', readSpeed.name),
      p.setBool('setting.largeText', largeText),
      p.setBool('setting.calmMotion', calmMotion),
      p.setInt('setting.breakMinutes', breakMinutes),
    ]);
  }

  /// Whether the home scene is sunny at [now]. Auto is sunny 6 am to 6 pm.
  bool isDay(DateTime now) => switch (scene) {
    SceneMode.day => true,
    SceneMode.night => false,
    SceneMode.auto => now.hour >= 6 && now.hour < 18,
  };
}
