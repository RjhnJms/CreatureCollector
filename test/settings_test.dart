import 'package:creature_collector/state/game_state.dart';
import 'package:creature_collector/state/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('scene follows the clock on Auto, and stays put when picked', () {
    final s = Settings.instance;
    final noon = DateTime(2026, 10, 14, 12);
    final night = DateTime(2026, 10, 14, 21);
    s.scene = SceneMode.auto;
    expect(s.isDay(noon), isTrue);
    expect(s.isDay(night), isFalse);
    expect(s.isDay(DateTime(2026, 10, 14, 6)), isTrue);
    expect(s.isDay(DateTime(2026, 10, 14, 18)), isFalse);
    s.scene = SceneMode.day;
    expect(s.isDay(night), isTrue);
    s.scene = SceneMode.night;
    expect(s.isDay(noon), isFalse);
    s.scene = SceneMode.auto;
  });

  test('starting over erases progress but keeps settings', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.name': 'Ana',
      'flutter.caught': ['eagle'],
    });
    final game = await GameState.load();
    await Settings.instance.load();
    await Settings.instance.update((s) => s.largeText = true);
    await game.resetProgress();

    expect(game.name, isEmpty);
    expect(game.caught, isEmpty);
    await Settings.instance.load();
    expect(Settings.instance.largeText, isTrue);
    await Settings.instance.update((s) => s.largeText = false);
  });
}
