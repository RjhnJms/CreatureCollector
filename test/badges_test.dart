import 'package:creature_collector/data/content.dart';
import 'package:creature_collector/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final firstFind = achievements.firstWhere((a) => a.id == 'first_catch');
  final dex = achievements.firstWhere((a) => a.id == 'collector_all');

  test('every badge pays gems, and harder badges pay more', () {
    for (final a in achievements) {
      expect(a.gems, greaterThan(0), reason: a.id);
    }
    expect(dex.gems, greaterThan(firstFind.gems));
  });

  test('an earned badge pays its gems once', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.name': 'Ana',
      'flutter.achievements': ['first_catch'],
    });
    final game = await GameState.load();
    final before = game.gems;
    expect(game.unclaimedCount, 1);

    expect(await game.claimBadge(firstFind), firstFind.gems);
    expect(game.gems, before + firstFind.gems);
    expect(game.unclaimedCount, 0);

    // A second tap pays nothing.
    expect(await game.claimBadge(firstFind), 0);
    expect(game.gems, before + firstFind.gems);

    // It stays claimed after a restart.
    final again = await GameState.load();
    expect(again.canClaim(firstFind), isFalse);
  });

  test('a locked badge cannot be claimed', () async {
    SharedPreferences.setMockInitialValues({'flutter.name': 'Ana'});
    final game = await GameState.load();
    expect(await game.claimBadge(dex), 0);
    expect(game.gems, 0);
  });
}
